-- 包装异常安全操作，避免核心调度函数lua虚拟机报错导致不能正常运转

local _M = {}
local mt = { __index = _M }

_M._VERSION = "1.0.0"

function _M.safe_json_decode(str)
    local cjson = require "cjson"
    local json_value = nil
    pcall(function(str) json_value = cjson.decode(str) end, str)
    return json_value
end

return _M