-- lua中变量的定义和使用
-- 全局变量
a = 5 

-- 局部变量
local b = 5

-- 函数
function var()
    a = 10
    c = 5 -- 全局变量
    local d = 6 -- 局部变量
    print("c = " .. c)
    print("d = " .. d)
end

var()
print("--------")
print("a = " .. a)
print("b = " .. b)
print("c = " .. c)
-- print("d = " .. d) -- 报错d找不到，不能拼接一个变量与nil
