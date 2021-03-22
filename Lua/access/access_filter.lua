-- 准入过滤

local constants = require "constants"
local page_alert = require "util.page_alert"
local cjson = require "cjson"
local table_helper = require "util.table_helper"
local auth_info = require "auth.auth_info"
local debug_logger = require "util.debug_logger"
require "util.string_helper"

local debug = false
local waf_on = false --waf默认关闭

if ngx.var.backend=="default" then
    ngx.exit(404)
end

-- 获取接入层配置
-- local udb_share = ngx.shared.udb_share
-- local config_info = udb_share:get(constants.CONFIG_SHARE_KEY)
--if not config_info then
--    page_alert:alert("请求中断，cause:接入层配置信息为空！")
--    return
--end
-- config_info = cjson.decode(config_info)
-- if not config_info then
--     page_alert:alert("请求中断，cause:接入层配置信息为空！")
--     return
-- end
--local time = os.time()
--if not config_info.time or time - config_info.time > constants.CONFIG_EXPIRE then
--    page_alert:alert("请求中断，cause:接入层配置已过期！" .. tostring(time - config_info.time))
--    return
--end

-- 是否开启waf
waf_on = config_info["wafOn"] ~= nil and config_info["wafOn"] or false
if waf_on and waf_on ~= "false" then
    -- 首先执行waf
    local simple_waf = require "waf"
    simple_waf.check()
    ngx.log(ngx.DEBUG, "waf检查通过")
else
    ngx.log(ngx.DEBUG, "waf检查关闭")
end

-- 限流检查
-- 单个客户端的限流实现
-- todo 整个站点总qps的限制
local limiter = ngx.ctx.limiter
if limiter then
    ngx.log(ngx.DEBUG, "限流检查开启")
    local key = ngx.var.binary_remote_addr
    local delay, err = limiter:incoming(key, true)
    if not delay then
        if err == "rejected" then
            return ngx.exit(429)
        end
        ngx.log(ngx.ERR, "failed to limit req: ", err)
        return ngx.exit(500)
    end
    if delay >= 0.001 then
        ngx.sleep(delay)
    end
    ngx.log(ngx.DEBUG, "限流检查通过")
else
    ngx.log(ngx.DEBUG, "限流检查未配置")
end

-- 接入层api前缀
local api_prefix = config_info["accessPath"]
-- todo 接入的应用自己的api_prefix
local app_prefixs = nil
-- 系统登录跳转地址
local login_url = config_info["loginPage"]
-- 系统认证方式
local auth_type = config_info["authType"]
-- 系统session cookie name
local session_cookie_name = config_info["sessionCookieName"]
-- url白名单
local white_url_list = config_info["whiteList"]
-- jwt token header名
local jwt_token_header = config_info["jwtTokenHeaderName"]
-- return url 键名
local return_url_name = config_info["returnUrlName"];
-- 运行模式
local run_type = config_info["runType"]
-- 是否开启debug
debug = config_info["debug"] ~= nil and "true"==tostring(config_info["debug"]) or false

local url = ngx.req.get_headers()["x-sal-before"] ~= nil and ngx.req.get_headers()["x-sal-before"] or ngx.var.uri

if "rio-adapter" == run_type then
    -- pass白名单
    -- todo antpath match in lua
elseif table_helper:is_antpath_include(url, white_url_list) then
    -- pass白名单
    ngx.log(ngx.DEBUG, "request_uri: ", url, " is included by the white url list, pass access filter.")
    if debug then
        debug_logger.log("request_uri: ".. url.." is included by the white url list, pass access filter.")
    end
elseif login_url == url then
    ngx.log(ngx.DEBUG, "request_uri: ", url, " is the tgac login url, pass access filter.")
elseif string.startWith(url, api_prefix) then
    ngx.log(ngx.DEBUG, "request_uri: ", url, " is start with tgac api_prefix, pass access filter.")
    --elseif string.match(url, "/api/") ~= nil then
    -- todo 检查是否是其他接入平台应用的api_prefix,如果是 也通过, 暂时折中办法判断url中是否有/api/部分
    --    ngx.log(ngx.DEBUG, "request_uri: " .. url .. "is probably a api request, pass access filter.")
else
    -- 302重定向到登录页面
    if "jwt" == auth_type then
        -- jwt方式
        -- 获取header的jwt token
        local headers = ngx.req.get_headers()
        local jwt_token = headers[jwt_token_header]
        if not jwt_token or string.len(jwt_token) < 1 then
            jwt_token = ngx.req.get_uri_args()[jwt_token_header]
            if not jwt_token then
                ngx.log(ngx.DEBUG, "auth type:jwt, request_uri: ", url, " has no jwt token, redirect to login page:", login_url)
                if debug then
                    debug_logger.log("auth type:jwt, request_uri: "..url.. " has no jwt token, redirect to login page:".. login_url)
                end
                return ngx.redirect(string.find(url, "?") and login_url .. "&" .. return_url_name .. "=" .. url or login_url .. "?" .. return_url_name .. "=" .. url, ngx.HTTP_MOVED_TEMPORARILY)
            end
        else
            ngx.log(ngx.DEBUG, "auth type:jwt, request_uri: ", url, " got jwt token:", token)
            local auth_info_payload = auth_info.new("jwt", nil, jwt_token)
            if auth_info_payload:validate() then
                ngx.log(ngx.DEBUG, "auth type:jwt, request_uri: ", url, ", jwt token auth success")
            else
                ngx.log(ngx.WARN, "auth type:jwt, request_uri: ", url, ", jwt token auth failed")
                if debug then
                    debug_logger.log("auth type:jwt, request_uri: ".. url.. ", jwt token auth failed, redirect to login page:"..login_url)
                end
                return ngx.redirect(string.find(url, "?") and login_url .. "&" .. return_url_name .. "=" .. url or login_url .. "?" .. return_url_name .. "=" .. url, ngx.HTTP_MOVED_TEMPORARILY)
            end
        end
    else
        -- 默认session方式
        local session_id = ngx.var["cookie_" .. session_cookie_name]
        if not session_id or string.len(session_id) < 1 then
            ngx.log(ngx.DEBUG, "auth type:session, request_uri: ", url, " has no session cookie: ", session_cookie_name, ", redirect to login page:", login_url)
            if debug then
                debug_logger.log("auth type:session, request_uri: " .. url .. " has no session cookie: " .. session_cookie_name .. ", redirect to login page:" .. login_url)
            end
            return ngx.redirect(string.find(url, "?") and login_url .. "&" .. return_url_name .. "=" .. url or login_url .. "?" .. return_url_name .. "=" .. url, ngx.HTTP_MOVED_TEMPORARILY)
        else
            ngx.log(ngx.DEBUG, "auth type:session, request_uri: ", url, " got session id:", session_id)
            local auth_info_payload = auth_info.new("session", session_id, nil)
            if auth_info_payload:validate() then
                ngx.log(ngx.DEBUG, "auth type:session, request_uri: ", url, ", session auth success")
            else
                ngx.log(ngx.WARN, "auth type:session, request_uri: ", url, ", session auth failed")
                if debug then
                    debug_logger.log("auth type:session, request_uri: " .. url .. ", session auth failed, redirect to login page:" .. login_url)
                end
                -- 登出重定向处理
                if string.find(ngx.var.uri,"_tif_logout") then
                    local returnUrl = ngx.var.upstream_http_location
                    return ngx.redirect(login_url .. "?" .. return_url_name .. "=" .. returnUrl, ngx.HTTP_MOVED_TEMPORARILY)
                end
                return ngx.redirect(string.find(url, "?") and login_url .. "&" .. return_url_name .. "=" .. url or login_url .. "?" .. return_url_name .. "=" .. url, ngx.HTTP_MOVED_TEMPORARILY)
            end
        end
    end
end