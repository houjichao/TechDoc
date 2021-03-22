-- api网关过滤

local constants = require "constants"
local page_alert = require "util.page_alert"
local cjson = require "cjson"
local table_helper = require "util.table_helper"
local auth_info = require "auth.auth_info"
local debug_logger = require "util.debug_logger"
local table_helper = require "util.table_helper"
local resty_sha256 = require "resty.sha256"
local api_service = require "api_service"
local limit_req = require "lualib.resty.limit.req"
require "util.string_helper"
local str = require "resty.string"
local reflection_util = require "util.reflection_util"

local debug = false
local waf_on = false --waf默认关闭

local request_uri = ngx.var.request_uri
if not string.startWith(request_uri, "/ebus/") then
    ngx.exit(404)
    return
end

-- 检查平台配置信息
if not config_info then
    page_alert:alert("请求中断，cause:接入层配置信息为空！")
    return
end
local time = os.time()
if not config_info.time or time - config_info.time > constants.CONFIG_EXPIRE then
    page_alert:alert("请求中断，cause:接入层配置已过期！" .. tostring(time - config_info.time))
    return
end


-- 检查平台应用信息
if not app_info then
    page_alert:alert("请求中断，cause:接入层app信息为空！")
    return
end
if not app_info.time or time - app_info.time > constants.CONFIG_EXPIRE then
    page_alert:alert("请求中断，cause:接入层app信息已过期！" .. tostring(time - app_info.time))
    return
end

-- 是否开启waf
waf_on = config_info["wafOn"] ~= nil and config_info["wafOn"] or false
if waf_on == true or waf_on == "true" then
    -- 首先执行waf
    local simple_waf = require "waf"
    simple_waf.check()
    ngx.log(ngx.DEBUG, "waf检查通过")
else
    ngx.log(ngx.DEBUG, "waf检查关闭")
end

-- 校验签名
-- 兼容rio的签名方式
-- sig = sha256(ts+paastoken+nonce+ts)
local paas_id_token_mapping = app_info.paas_id_token_mapping
local headers = ngx.req.get_headers()
local paas_id = headers["x-sal-paasid"] ~= nil and headers["x-sal-paasid"] or headers["x-rio-paasid"]
if not paas_id or string.len(paas_id) < 1 or paas_id_token_mapping[paas_id] == nil then
    --paasid为空
    page_alert:alert("{\"errcode\":400000400, \"errmsg\":\"unknown paas info.\"}")
    return
end
local paas_token = paas_id_token_mapping[paas_id]
ngx.ctx.paas_token = paas_token
local ts = headers["x-sal-timestamp"] ~= nil and headers["x-sal-timestamp"] or headers["x-rio-timestamp"]
local signature = headers["x-sal-signature"] ~= nil and headers["x-sal-signature"] or headers["x-rio-signature"]
local nonce = headers["x-sal-nonce"] ~= nil and headers["x-sal-nonce"] or headers["x-rio-nonce"]

if ts == nil or string.len(ts) < 1 or signature == nil or string.len(signature) < 1 or nonce == nil or string.len(nonce) < 1 then
    page_alert:alert("{\"errcode\":400000400, \"errmsg\":\"missing headers.\"}")
    return
end

local tts = tonumber(ts)
if tts == nil or tts <= 0 then
    page_alert:alert("{\"errcode\":400000400, \"errmsg\":\"invalid timestamp.\"}")
    return
end

if time - tts < -1 or time - tts >= 180 then
    page_alert:alert("{\"errcode\":400000400, \"errmsg\":\"timestamp is out of date.\"}")
    return
end

if string.len(nonce) < 10 or string.len(nonce) > 20 then
    page_alert:alert("{\"errcode\":400000400, \"errmsg\":\"invalid nonce.\"}")
    return
end

local sha256 = resty_sha256:new()
sha256:update(ts .. paas_token .. nonce .. ts)
local signature_again = str.to_hex(sha256:final())

if signature ~= signature_again then
    page_alert:alert("{\"errcode\":400000401, \"errmsg\":\"bad signature.\"}")
    return
end

ngx.log(ngx.DEBUG, "receive ebus request, ", request_uri)
local api = api_service:get_api(request_uri)
-- reflection_util:log_obj(api, ngx.DEBUG)
if not api then
    page_alert:alert("{\"errcode\":400000404, \"errmsg\":\"api not found.\"}")
    return
end

--api, err = cjson.decode(api)

if not api or not api.networkDomain then
    page_alert:alert("{\"errcode\":400000404, \"errmsg\":\"api info is invalid.\"}")
    return
end

-- api ip白名单校验
local api_ip_white_list = api.ipWhiteList
if api_ip_white_list then
    --todo ip白名单校验
end

-- api ip黑名单校验
local api_ip_block_list = api.ipBlockList
if api_ip_block_list then
    --todo ip黑名单校验
end

local api_allowed_paas_id_list = api.allowedPaasIdList
if api_allowed_paas_id_list then
    -- 检查源paasid是否允许请求当前api
    -- reflection_util:log_obj(api_allowed_paas_id_list, ngx.ERR)
    if not table_helper:is_include(paas_id, api_allowed_paas_id_list) then
        page_alert:alert("{\"errcode\":400000403, \"errmsg\":\"you are not allowed to access this api.\"}")
        return
    end
else
    page_alert:alert("{\"errcode\":400000403, \"errmsg\":\"you are not allowed to access this api.\"}")
end

-- 限流检查
-- 总限流检查
-- todo 单paasid限流检查
if api.limiter ~= nil then
    ngx.log(ngx.DEBUG, "限流检查开启")
    -- local key = ngx.var.binary_remote_addr
    local delay, err = api.limiter:incoming("key", true)
    if not delay then
        if err == "rejected" then
            page_alert:alert("{\"errcode\":400000429, \"errmsg\":\"too many requests.\"}")
            return
        end
        ngx.log(ngx.ERR, "failed to limit api req: ", err)
        page_alert:alert("{\"errcode\":400000529, \"errmsg\":\"internal error.\"}")
        return
    end
    if delay >= 0.001 then
        ngx.sleep(delay)
    end
    ngx.log(ngx.DEBUG, "限流检查通过")
else
    ngx.log(ngx.DEBUG, "限流检查未配置")
end
local network_domain = api.networkDomain
local original_path = api.globalOriginalPath
local cur_stream = network_domain[math.random(1, #network_domain)]
ngx.log(ngx.DEBUG, paas_id, " request api: ", request_uri, ", choose upstream: ", cur_stream)
ngx.var.backend = cur_stream
if original_path~=nil and #original_path>0 then
    ngx.req.set_uri(original_path)
end

