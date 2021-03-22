-- table操作辅助函数

require "util.string_helper"
require "util.simple_antpath_matcher"

local _M = {}
local mt = {__index = _M}

_M._VERSION = "1.0.0"

function _M:is_include(value, tab)
    for k, v in ipairs(tab) do
        if v == value then
            return true
        end
    end
    return false
end

function _M:is_v_include(value, tab, key)
    for k, v in ipairs(tab) do
            if v[key] == value then
                return true
            end
        end
        return false
end

function _M:is_startwith_include(value, tab)
  for k, v in ipairs(tab) do
        if string.startWith(value,v) then
            return true
        end
    end
    return false
end

function _M:is_antpath_include(value, tab)
    for k, v in ipairs(tab) do
        if string.ant_match(value,v) then
            ngx.log(ngx.DEBUG, value .. " matched rule: "..v)
            return true
        end
    end
    return false
end


return _M
