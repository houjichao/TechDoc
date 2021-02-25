-- for循环学习

-- 数值for循环
-- 语法
--[=[

for var=exp1,exp2,exp3 do  
    <执行体>  
end
var 从 exp1 变化到 exp2，每次变化以 exp3 为步长递增 var，并执行一次 "执行体"。exp3 是可选的，如果不指定，默认为1。

for i=1,f(x) do
    print(i)
end

]=]

print("数值for循环")
-- for的三个表达式在循环开始前一次性求值，以后不再进行求值。比如上面的f(x)只会在循环开始前执行一次，其结果用在后面的循环中。
function f(x)  
    print("function")  
    return x*2  
end  
for i=1,f(5),2 do print(i)  
end

-- 步长为-1
print("步长为-1")
for i=10,1,-1 do
    print(i)
end

