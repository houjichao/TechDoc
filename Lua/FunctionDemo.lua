-- Lua数据类型 function

--[[
在 Lua 中，函数是被看作是"第一类值（First-Class Value）"，函数可以存在变量里:
--]]

-- demo
function function1(n)
    if n == 0 then
        return 1
    else 
        return n * function1(n-1)
    end
end
--相当于5的阶乘
print(function1(5))
function2=function1
print(function2(5))

-- function 可以以匿名函数（anonymous function）的方式通过参数传递:

function testFun(tab,fun)
    for k,v in pairs (tab) do
        print(fun(k,v))
    end
end

tab={key1="val1",key2="val2"};

testFun(tab,
function(key,val) -- 匿名函数
     return key.."="..val
end
)
