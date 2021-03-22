--- 接入层认证信息 载体类

local redis_util = require "util.redis_util"
local constants = require "constants"

local _M = {}

_M._VERSION = "1.0.0"

local mt = { __index = _M }

function _M.new(auth_type, session_id, token)
    local o = { auth_type = nil, session_id = nil, token = nil, auth_info = {} }

    -- 验证用户
    o.validate = function(self)
        local red = redis_util:get_conn()
        if "jwt" == self.auth_type then
            if red:ttl(constants.TOKEN_KEY .. self.token) > -2 then
                ngx.log(ngx.DEBUG, self.token, ' is valid.')
                redis_util:back_to_pool(red, 10000, 30)
                return true
            end
            ngx.log(ngx.DEBUG, self.token, ' is invalid.')
            redis_util:back_to_pool(red, 10000, 30)
            return false
        else
            if red:ttl(constants.SESSION_KEY .. self.session_id) > -2 then
                ngx.log(ngx.DEBUG, self.session_id, ' is valid.')
                redis_util:back_to_pool(red, 10000, 30)
                return true
            end
            redis_util:back_to_pool(red, 10000, 30)
            ngx.log(ngx.DEBUG, self.session_id, ' is invalid.')
            return false
        end
    end

    -- 获取验证信息
    o.get_auth_info = function(self)
        return self.auth_info
    end

    o.auth_type = auth_type
    o.session_id = session_id
    o.token = token

    return o
end

return _M