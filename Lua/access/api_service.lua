-- api服务

local redis_util = require "util.redis_util"
local cjson = require "cjson"
local constants = require "constants"
local refrection_util = require "util.reflection_util"
local limit_req = require "lualib.resty.limit.req"
local safe_util = require "util.safe_util"

local _M = {}

_M._VERSION = "1.0.0"

local mt = { __index = _M }

function _M:get_api(api_path)
    local api = ngx_lru_cache:get(api_path)
    if api ~= nil then
        return api
    end
    local red = redis_util:get_conn()
    local res, err = red:hget(constants.SAL_API_KEY, api_path)
    redis_util:back_to_pool(red, 10000, 30)
    if res == nil or res == ngx.null then
        ngx.log(ngx.ERR, "no api for ", api_path, err)
        return nil
    end
    api = safe_util.safe_json_decode(res)
    if api == nil then
        ngx.log(ngx.ERR, "bad record for api ", api_path, res, err)
        return nil
    end
    local rate_limit = api.rateLimit
    if rate_limit ~= nil and rate_limit > 0 then
        local rate_limit_start = math.max(1, math.floor(rate_limit / 3))
        local rate_limit_end = math.max(rate_limit_start, rate_limit - rate_limit_start)
        local lim, err = limit_req.new("sal_limit_req_store", rate_limit_end, rate_limit_start)
        if not lim then
            ngx.log(ngx.ERR, "failed to instantiate a limiter for api: ", location["path"], err)
        else
            ngx.log(ngx.ERR, "apply rate limit ", rate_limit_end, "/", rate_limit_start, "/s to api ", api["path"])
            api.limiter = lim
        end
    end
    ngx_lru_cache:set(api_path, api, 15)
    return api
end

return _M

