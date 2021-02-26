-- Lua函数
--[[
Lua 提供了许多的内建函数，你可以很方便的在程序中调用它们，如print()函数可以将传入的参数打印在控制台上。

Lua 函数主要有两种用途：

1.完成指定的任务，这种情况下函数作为调用语句使用；
2.计算并返回值，这种情况下函数作为赋值语句的表达式使用。

--]]

--[=[
Lua 编程语言函数定义格式如下：

optional_function_scope function function_name( argument1, argument2, argument3..., argumentn)
    function_body
    return result_params_comma_separated
end
解析：

optional_function_scope: 该参数是可选的制定函数是全局函数还是局部函数，未设置该参数默认为全局函数，如果你需要设置函数为局部函数需要使用关键字 local。

function_name: 指定函数名称。

argument1, argument2, argument3..., argumentn: 函数参数，多个参数以逗号隔开，函数也可以不带参数。

function_body: 函数体，函数中需要执行的代码语句块。

result_params_comma_separated: 函数返回值，Lua语言函数可以返回多个值，每个值以逗号隔开。
]=]

-- demo max
function max(num1,num2)
    if (num1 > num2) then 
        result = num1;
    else 
        result = num2;
    end 
    
    return result;
end 
print("两值比较最大值为 ",max(10,4))
print("两值比较最大值为 ",max(5,6))

--Lua 中我们可以将函数作为参数传递给函数，如下实例：
myprint = function(param)
   print("这是打印函数 -   ##",param,"##")
end

function add(num1,num2,functionPrint)
   result = num1 + num2
   -- 调用传递的函数参数
   functionPrint(result)
end
myprint(10)
-- myprint 函数作为参数传递
add(2,5,myprint)

--funciton 可以多返回值
--Lua函数可以返回多个结果值，比如string.find，其返回匹配串"开始和结束的下标"（如果不存在匹配串返回nil）。
function maximum (a)
    local mi = 1             -- 最大值索引
    local m = a[mi]          -- 最大值
    for i,val in ipairs(a) do
       if val > m then
           mi = i
           m = val
       end
    end
    return m, mi
end

print(maximum({8,10,23,12,5})) 







