--- 反射工具，用于调试时打印对象

local _M = {}
local mt = { __index = _M }

_M._VERSION = "1.0.0"

function _M:log_obj(obj,log_level)
    for key,value in pairs(obj) do
        ngx.log(log_level, key.."=>"..tostring(value));
    end
end

return _M

