-- lua学习 repeta...until循环

--[[
Lua 编程语言中 repeat...until 循环语句不同于 for 和 while循环，for 和 while 循环的条件语句在当前循环执行开始时判断，而 repeat...until 循环的条件语句在当前循环结束后判断。
--]]

--[=[
Lua 编程语言中 repeat...until 循环语法格式:
repeat
   statements
until( condition )

循环条件判断语句（condition）在循环体末尾部分，所以在条件进行判断前循环体都会执行一次。
如果条件判断语句（condition）为 false，循环会重新开始执行，直到条件判断语句（condition）为 true 才会停止执行。
]=]

-- demo

--[ 变量定义 --]
a = 10 
--[ 执行循环 --]
repeat 
  print("a的值为：",a)
  a = a + 1
until(a > 20)
