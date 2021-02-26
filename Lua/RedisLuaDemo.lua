-- Redis和Lua的结合使用

local key = KEYS[1]
local val = redis.call("GET", key);

if val == ARGV[1]
then
        redis.call('SET', KEYS[1], ARGV[2])
        return 1
else
        return 0
end
