-- Lua中没有continue语法 使用这几种方式实现

-- Demo1
for i = 10, 1, -1 do
  repeat
    if i == 5 then
      print("continue code here")
      break
    end
    print(i, "loop code here")
  until true
end

-- Demo2

for i=1, 3 do
    if i <= 2 then
        print(i, "yes continue")
        goto continue
    end
    print(i, " no continue")
    ::continue::
    print([[i'm end]])
end
