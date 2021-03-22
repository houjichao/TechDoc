-- 简单的antpath lua匹配办法, 没有完全支持antstyle，仅用于此项目
-- 因为spring gateway中用antstyle的通配符，所以openresty里也简单的沿用，而没有用正则

require "util.string_helper"



-- 辅助：统计/字符数
local function count_slash(s)
    local cnt = 0;
    for c in s:gmatch"." do
        cnt = cnt+ (c=='/' and 1 or 0)
    end
    return cnt
end
function string.ant_match(s, ant_pattern)
    local slash_count = count_slash(s)
    -- 替换lua正则中和antstyle通配符的混淆问题
    ant_pattern = string.gsub(ant_pattern, "%.", "%%.")
    ant_pattern = string.gsub(ant_pattern, "%?", ".")
    ant_pattern = string.gsub(ant_pattern, "%-", "%%-")
    -- 仅支持××在开头或者结尾 够用
    if string.find(ant_pattern, "%*%*") ~= nil then
        if string.startWith(ant_pattern,"/**") and ant_pattern~="/**" then
            local arr = string.split(ant_pattern, "/**")
            ant_pattern = arr[#arr]
            ant_pattern = string.gsub(ant_pattern, "%*", "[^/]*")
            if string.match(s, "^"..ant_pattern.."/?$") ~=nil then
                return true
             end
            for i = 1, slash_count, 1 do
                ant_pattern = "/[a-zA-Z%.0-9%-_~&=@%?%%%+:!,%[%]%(%)%$%*%^{}]+" .. ant_pattern
                if string.match(s, "^" .. ant_pattern .. "/?$") ~= nil then
                    return true
                end
            end
            return false
        elseif string.endWith(ant_pattern,"/**") then
            ant_pattern = string.split(ant_pattern, "/**")[1]
            ant_pattern = string.gsub(ant_pattern, "%*", "[^/]*")
            if string.match(s, "^"..ant_pattern.."/?$") ~=nil then

             return true
            end
            for i = 1, slash_count, 1 do
                ant_pattern = ant_pattern .. "/[a-zA-Z%.0-9%-_~&=@%?%%%+:!,%[%]%(%)%$%*%^{}]+"
                if string.match(s, "^" .. ant_pattern .. "/?$") ~= nil then
                    return true
                end
            end
            return false
        else
            return false
        end
    else
        ant_pattern = string.gsub(ant_pattern, "%*", "[^/]*")
        return string.match(string.split(s,"?")[1], "^" .. ant_pattern .. "/?$") ~= nil
    end
end