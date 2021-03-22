---
--- 核心路由器 
---

local constants = require "constants"
local http = require "lualib.resty.http"
local cjson = require "cjson"
local table_helper = require "util.table_helper"
require "util.string_helper"
require "util.simple_antpath_matcher"
local balancer = require "ngx.balancer"
local debug_logger = require "util.debug_logger"
local reflection_util = require "util.reflection_util"
local str = require "resty.string"
local resty_sha256 = require "resty.sha256"

local _M = {}
local mt = { __index = _M }

_M._VERSION = "1.0.0"

-- 默认backend
local default = "default"

-- ngx.ctx.proxy_timeout = '60'
-- ngx.ctx.connect_timeout = '60'

local debug = false --debug模式默认关闭

-- 获取接入层配置
local udb_share = ngx.shared.udb_share
-- local config_info = udb_share:get(constants.CONFIG_SHARE_KEY)
local time = os.time()
if not config_info or not config_info.time or time - config_info.time > constants.CONFIG_EXPIRE then
    ngx.log(ngx.ERR, "请求中断，cause:接入层配置为空已过期！")
    --放入站点报错头 用于提示
    ngx.req.set_header("x-sal-site-error", "op config is null")
    return default
end
if not app_info or not app_info.time or time - app_info.time > constants.CONFIG_EXPIRE then
    ngx.log(ngx.ERR, "请求中断，cause:app配置为空或已过期！")
    --放入站点报错头 用于提示
    ngx.req.set_header("x-sal-site-error", "op app is null")
    return default
end
-- config_info = cjson.decode(config_info)
-- if not config_info then
--     return default
-- end
-- 接入层api前缀
local api_prefix = config_info["accessPath"]
-- location配置
local locations = config_info["locations"]

-- 是否开启debug
debug = config_info["debug"] ~= nil and "true" == tostring(config_info["debug"]) or false


-- resty这一层的独立session 无他用，主要用于负载
local session_id = nil
local session = require "lualib.resty.session".start { name = 'sal_sid' }
if session.present then
    session_id = ngx.encode_base64(session.id)
    ngx.log(ngx.DEBUG, "session, ", session_id)
else
    ngx.log(ngx.DEBUG, "no session")
end

local request_uri = ngx.var.request_uri
if request_uri == '/' then
    ngx.req.set_uri("/index.html")
    request_uri = "/index.html"
end

local acc_backends = constants.ACC_BACKENDS

ngx.log(ngx.DEBUG, "request_uri: ", request_uri, ", api_prefix: ", api_prefix)
-- 路由判断
-- if string.startWith(request_uri, api_prefix) then
-- 接入层接管
--    ngx.log(ngx.DEBUG, "request_uri: " .. request_uri .. " will be processed by sal.")
--    local cur_acc_backend = acc_backends[math.random(1, #acc_backends)]
--    ngx.log(ngx.DEBUG, "current sal peer ", cur_acc_backend["host"], ":", cur_acc_backend["port"])
--    if debug then
--        debug_logger.log("request_uri: " .. request_uri .. "符合接入服务gateway前缀，will be processed by gateway:" .. cur_acc_backend["host"] .. ":" .. cur_acc_backend["port"])
--    end
--    return cur_acc_backend["host"] .. ":" .. cur_acc_backend["port"]
ngx.log(ngx.DEBUG, "request_uri:", request_uri, " will be processed by app sites.")
-- 站点
if locations == nil or #locations == 0 then
    ngx.log(ngx.WARN, "site configuration is empty, return default thus 404.")
    if debug then
        debug_logger.log("接入服务没有配置任何站点！")
    end
    ngx.req.set_header("x-sal-err-code", 404)
    return default
end
for i, location in pairs(locations) do
    -- 简易版spring antpath匹配
    if table_helper:is_antpath_include(request_uri, location["path_arr"]) then
        ngx.log(ngx.DEBUG, "request uri: ", request_uri, " matched site path: ", location["path"])
        if debug then
            debug_logger.log("request uri: " .. request_uri .. " matched site path: " .. location["path"])
        end
        --将站点所属应用appId放入head中 用于报错提示
        ngx.req.set_header("x-sal-site-appId", location["appId"])
        -- 将限流器放入nginx上下文中
        if location.limiter ~= nil then
            ngx.ctx.limiter = location.limiter
        end
        -- 按站点排序第一条匹配的生效
        local upstreams = location["upstreams"]
        if not upstreams then
            ngx.log(ngx.DEBUG, "site path: ", location["path"], " no upstreams.")
            if debug then
                debug_logger.log("site path: " .. location["path"] .. " no upstreams.")
            end
            return default
        end
        local proxy_timeout = location["timeout"]
        if not proxy_timeout then
            proxy_timeout = "60"
        elseif proxy_timeout > 0 then
            proxy_timeout = tostring(proxy_timeout)
        end
        ngx.ctx.proxy_timeout = proxy_timeout
        local connect_timeout = location["connectTimeout"]
        if not connect_timeout then
            connect_timeout = "60"
        elseif connect_timeout > 0 then
            connect_timeout = tostring(connect_timeout)
        end
        ngx.ctx.connect_timeout = connect_timeout

        -- 处理签名
        local sha256 = resty_sha256:new()
        local ts = tostring(time)
        local nonce = string.random_string(10)
        if app_info.app_id_token_mapping[tostring(location.appId)] == nil then
            --将站点所属应用appId放入head中 用于报错提示
            ngx.req.set_header("x-sal-site-appId", "error")
            debug_logger.log("站点所属应用的应用id不存在")
            return default
        end
        sha256:update(ts .. app_info.app_id_token_mapping[tostring(location.appId)] .. nonce .. ts)
        local signature = str.to_hex(sha256:final())
        ngx.req.set_header("x-sal-signature", signature)
        ngx.req.set_header("x-sal-timestamp", ts)
        ngx.req.set_header("x-sal-nonce", nonce)

        -- 处理负载
        local lb_type = location["lbType"] ~= nil and location["lbType"] or 1
        local cur_stream = default
        if lb_type == 2 then
            -- session sticky
            local sticky_found = false
            if session_id ~= nil then
                local last_sticky_stream = udb_share:get(session_id .. location["path"])
                ngx.log(ngx.DEBUG, "last session sticky stream ", last_sticky_stream)
                if last_sticky_stream ~= nil then
                    -- 校验sticky的upstream是否失效
                    if table_helper:is_include(last_sticky_stream, upstreams) then
                        sticky_found = true
                        cur_stream = last_sticky_stream
                    end
                end
            end
            if not sticky_found then
                ngx.log(ngx.WARN, "session sticky not found site upstream, will fallback to random.")
                cur_stream = upstreams[math.random(1, #upstreams)]
            end
        else
            -- 默认随机
            cur_stream = upstreams[math.random(1, #upstreams)]
        end
        if session_id ~= nil then
            udb_share:set(session_id .. location["path"], cur_stream, 3600)
        end
        if debug then
            debug_logger.log("choose upstream: " .. location["siteName"] .. "|" .. cur_stream)
        end
        local req_uri_and_param = string.split(request_uri, "?")
        -- 如果有uri参数，单独set到uri_arg里去，防止proxy的时候被encode
        if #req_uri_and_param > 1 then
            request_uri = req_uri_and_param[1]
            ngx.req.set_uri(request_uri)
            ngx.req.set_uri_args(req_uri_and_param[2])
            if debug then
                debug_logger.log("got pure req uri: " .. request_uri .. ", req uri args: " .. req_uri_and_param[2])
            end
        end
        local rewrite = location["rewrite"]
        if rewrite and #string.trim(rewrite) > 0 then
            ngx.log(ngx.DEBUG, "current site backend need rewrite url, original request_uri: " .. request_uri .. ", rewrite rule: " .. rewrite)
            if debug then
                debug_logger.log("process rewrite rule: " .. rewrite)
            end
            local rewrite_rule_arr = string.split(rewrite, "rewrite")
            local rewrite_rule = #rewrite_rule_arr == 1 and rewrite_rule_arr[1] or rewrite_rule_arr[2]
            local rewrite_parts = string.split(rewrite_rule, "%s+")
            if #rewrite_parts ~= 2 then
                ngx.log(ngx.WARN, "rewrite rule: " .. rewrite_rule .. " is invalid")
                if debug then
                    debug_logger.log("rewrite rule: " .. rewrite_rule .. " is invalid, ignore it.")
                end
            else
                local rewrite_pattern = rewrite_parts[1]
                local rewrite_target = rewrite_parts[2]
                local new_uri, n, err = ngx.re.sub(request_uri, rewrite_pattern, rewrite_target)
                if not err then
                    ngx.log(ngx.DEBUG, "request uri: ", request_uri, " changed to ", new_uri, " after rewrite rule: ", rewrite_rule)
                    ngx.req.set_header("x-sal-before", request_uri)
                    if debug then
                        debug_logger.log("request uri: " .. request_uri .. " changed to " .. new_uri .. " after rewrite rule: " .. rewrite_rule)
                    end
                    ngx.req.set_uri(new_uri)
                else
                    ngx.log(ngx.WARN, "rewrite rule: ", rewrite_rule, " process failed, ", err)
                    if debug then
                        debug_logger.log("rewrite rule: " .. rewrite_rule .. " process failed, " .. err)
                    end
                end
            end
        end
        ngx.log(ngx.DEBUG, "current site backend peer ", cur_stream)
        return cur_stream
    else
        ngx.log(ngx.DEBUG, "request uri: ", request_uri, " don't match site path: ", location["path"])
        --             if debug then
        --                 debug_logger.log("request uri: " .. request_uri .. " don't match site path: " .. location["path"])
        --             end
    end
end
ngx.req.set_header("x-sal-err-code", 404)
ngx.log(ngx.WARN, "request uri: ", request_uri, " has no matched site location, return default thus 404")
if debug then
    debug_logger.log("请求地址:" .. request_uri .. " 没有匹配到任何站点配置！")
end
return default
