-- 定时拉取应用配置信息

local constants = require "constants"
local http = require "lualib.resty.http"
local cjson = require "cjson"
local limit_req = require "lualib.resty.limit.req"
local reflection_util = require "util.reflection_util"
local safe_util = require "util.safe_util"

local _M = {}
local mt = { __index = _M }

_M._VERSION = "1.0.0"

local acc_backends = constants.ACC_BACKENDS

function _M:handler(premature)
    ngx.log(ngx.ERR, "start refresh app config...")
    local cur_acc_backend = acc_backends[math.random(1, #acc_backends)]
    local httpc = http.new()
    local resp, err = httpc:request_uri("http://" .. cur_acc_backend["host"] .. ":" .. cur_acc_backend["port"] .. constants.GET_APP_URI, {
        method = "POST"
    })
    httpc:close()
    if err then
        ngx.log(ngx.ERR, "failed to query app info api: ", err)
        --return
    else
        app_info = safe_util.safe_json_decode(resp.body)
        if not app_info or app_info.data == nil then
            ngx.log(ngx.ERR, "failed to query app info api: payload data is nil.")
            --return
        else
            -- 有效config
            app_info.time = os.time()
            local paas_id_token_mapping = {}
            local app_id_token_mapping = {}
            -- reflection_util:log_obj(app_info.data,ngx.ERR)
            for _, v in ipairs(app_info.data) do
                -- reflection_util:log_obj(v,ngx.ERR)
                local token = v["paasToken"]~=nil and v["paasToken"] or "1"
                paas_id_token_mapping[v["passId"]] = token
                app_id_token_mapping[tostring(v["applicationId"])] = token
            end
            app_info.paas_id_token_mapping = paas_id_token_mapping
            app_info.app_id_token_mapping = app_id_token_mapping
            ngx.log(ngx.ERR, "finish refresh app info...")
        end
    end
    local ok, err = ngx.timer.at(constants.APP_REFRESH_INTERVAL, _M.handler)
    if not ok then
        ngx.log(ngx.CRIT, "failed to re create the timer: ", err)
        return
    end
end

return _M