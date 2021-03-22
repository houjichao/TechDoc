-- 定时更新认证信息载体的布隆过滤器

local constants = require "constants"
local http = require "lualib.resty.http"
local cjson = require "cjson"
local limit_req = require "lualib.resty.limit.req"
local reflection_util = require "util.reflection_util"
local redis_util = require "util.redis_util"

local _M = {}
local mt = { __index = _M }

_M._VERSION = "1.0.0"

local acc_backends = constants.ACC_BACKENDS

function _M:handler(premature)
    ngx.log(ngx.ERR, "start to refresh auth info bloom filter.")
    ngx.log(ngx.ERR, "finish refreshing auth info bloom filter.")
end

return _M
