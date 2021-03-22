-- 定时拉取接入层配置信息

local constants = require "constants"
local http = require "lualib.resty.http"
local cjson = require "cjson"
local limit_req = require "lualib.resty.limit.req"
local safe_util = require "util.safe_util"
require "util.string_helper"

local _M = {}
local mt = { __index = _M }

_M._VERSION = "1.0.0"

local acc_backends = constants.ACC_BACKENDS

function _M:handler(premature)
    ngx.log(ngx.WARN, "start refresh access config...")
    local cur_acc_backend = acc_backends[math.random(1, #acc_backends)]
    local httpc = http.new()
    local resp, err = httpc:request_uri("http://" .. cur_acc_backend["host"] .. ":" .. cur_acc_backend["port"] .. constants.GET_CONFIG_URI, {
        method = "POST"
    })
    httpc:close()
    if err then
        ngx.log(ngx.ERR, "failed to query access config api: ", err)
        --return
    else
        config_info = safe_util.safe_json_decode(resp.body)
        if not config_info or config_info.data == nil then
            ngx.log(ngx.ERR, "failed to query access config api: payload data is nil.")
            --return
        else
            -- 有效config
            config_info = config_info.data
            -- 遍历站点信息 初始化限流器
            if config_info.locations then
                for _, location in pairs(config_info.locations) do
                    if location ~= nil then
                        location.path_arr = string.split(location.path, ",")
                        if location.rateLimit > 0 then
                            local rate_limit_start = math.max(1, math.floor(location.rateLimit / 3))
                            local rate_limit_end = math.max(rate_limit_start, location.rateLimit - rate_limit_start)
                            local lim, err = limit_req.new("sal_limit_req_store", rate_limit_end, rate_limit_start)
                            if not lim then
                                ngx.log(ngx.ERR, "failed to instantiate a limiter for location: ", location["path"], err)
                            else
                                ngx.log(ngx.ERR, "apply rate limit ", rate_limit_end, "/", rate_limit_start, "/s to location ", location["path"])
                                location.limiter = lim
                            end
                        end
                    end
                end
            end
            config_info.time = os.time()
            local udb_share = ngx.shared.udb_share
            -- udb_share:set(constants.CONFIG_SHARE_KEY, cjson.encode(config_info.data))
            udb_share:set("login-page", config_info["loginPage"])
            udb_share:set("return-url-name", config_info["returnUrlName"])
            ngx.log(ngx.WARN, "finish refresh access config...")
        end
    end
    local ok, err = ngx.timer.at(constants.CONFIG_REFRESH_INTERVAL, _M.handler)
    if not ok then
        ngx.log(ngx.CRIT, "failed to re create the timer: ", err)
        return
    end
end

return _M