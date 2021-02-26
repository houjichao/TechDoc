--Lua 循环控制 break 语句

--[[
Lua 编程语言 break 语句插入在循环体中，用于退出当前循环或语句，并开始脚本执行紧接着的语句。

如果你使用循环嵌套，break语句将停止最内层循环的执行，并开始执行的外层的循环语句。
--]]
print("break语句")
a=10
while(a<20)
do 
  print("a的值为：",a)
  a=a+1
  if(a>15)
  then 
    --[ 使用break语句终止循环 --]
    break
  end
end


--Lua 循环控制 goto语句
--[[
Lua 语言中的 goto 语句允许将控制流程无条件地转到被标记的语句处。

语法
语法格式如下所示：

goto Label
Label 的格式为：

:: Label ::

--]]

--demo1
print("goto语句")
local a =1
::houjichao:: print("--- goto houjichao ---")

a=a+1
if a<3 then
    goto houjichao
end

-- demo3 利用goto实现continue的功能
for i=1, 3 do
    if i <= 2 then
        print(i, "yes continue")
        goto continue
    end
    print(i, " no continue")
    ::continue::
    print([[i'm end]])
end

--demo2 在label中设置多个语句
i = 0
::s1:: do 
  print(i)
  i = i + 1
end
if i>3 then
 os.exit()
end
goto s1 

-- demo3 利用goto实现continue的功能
for i=1, 3 do
    if i <= 2 then
        print(i, "yes continue")
        goto continue
    end
    print(i, " no continue")
    ::continue::
    print([[i'm end]])
end









