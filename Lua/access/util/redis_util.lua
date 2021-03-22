---
--- 简单操作redis的工具，接入服务nginx这层的redis要求和gateway一层公用一个
---
local constants = require "constants"
local redis = require "resty.redis"

local _M = {}
local mt = { __index = _M }

_M._VERSION = "1.0.0"

--- 获得redis连接
--
function _M:get_conn()
    local red = redis:new()
    red:set_timeouts(1000, 1000, 1000)
    local ok, err = red:connect(constants.REDIS_HOST, constants.REDIS_PORT)
    if not ok then
        ngx.log(ngx.ERR, "failed to redis connect: ", err)
        return
    end
    if constants.REDIS_AUTH~=nil and #constants.REDIS_AUTH>0 then
        local res, err = red:auth(constants.REDIS_AUTH)
        if not res then
            ngx.log(ngx.ERR, "failed to redis authenticate: ", err)
            return
        end
    end
    return red
end

--- 返回连接到pool
--
function _M:back_to_pool(red, timeout, pool_size)
    local ok, err = red:set_keepalive(timeout, pool_size)
    if not ok then
        ngx.log(ngx.ERR, "failed to redis set keepalive: ", err)
        return
    end
end


return _M


