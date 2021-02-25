-- lua学习
-- Lua 中有 8 个基本类型分别为：nil、boolean、number、string、userdata、function、thread 和 table。


-- nil
print(a)
print(type(a))

-- nil删除作用
tab1 = { key1 = "val1", key2 = "val2", "val3" }
print("nil删除作用前")
for k, v in pairs(tab1) do
    print(k .. " - " .. v)
end
 
tab1.key1 = nil
print("nil删除作用后")
for k, v in pairs(tab1) do
    print(k .. " - " .. v)
end

-- nil 作比较时应该加上双引号 ""
print(type(X)==nil)
print(type(X)=="nil")


-- boolean: 只有两个可选值：true（真） 和 false（假），Lua 把 false 和 nil 看作是 false，其他的都为 true，数字 0 也是 true
print("boolean开始")
print(type(true))
print(type(false))
print(type(nil))
 
if false or nil then
    print("至少有一个是 true")
else
    print("false 和 nil 都为 false")
end

if 0 then
    print("数字 0 是 true")
else
    print("数字 0 为 false")
end
print("boolean结束")

-- number:Lua 默认只有一种 number 类型 -- double（双精度）类型（默认类型可以修改 luaconf.h 里的定义），以下几种写法都被看作是 number 类型：
print("number类型开始：")
print(type(2))
print(type(2.2))
print(type(0.2))
print(type(2e+1))
print(type(0.2e-1))
print(type(7.8263692594256e-06))
print("number类型结束")


-- string: 
-- 字符串由一对双引号或单引号来表示。
string1 = "this is string1"
string2 = 'this is string2'
print(string1)
print(string2)
-- 也可以用 2 个方括号 "[[]]" 来表示"一块"字符串。
html = [[
<html>
<head></head>
<body>
    <a href="http://www.runoob.com/">菜鸟教程</a>
</body>
</html>
]]
print(html)

-- 在对一个数字字符串上进行算术操作时，Lua 会尝试将这个数字字符串转成一个数字:

print("2" + 6)
print("2" + "6")
print("2 + 6")
print("-2e2" * "6")
-- print("error" + 1) 此行会报错

--字符串连接使用的是 .. ，如：
print("a" .. 'b')
print(157 .. 428)


-- 使用 # 来计算字符串的长度，放在字符串前面，如下实例：
len = "houjichao"
print(#len)

