local socket=require("socket")
function test()
  local a = "aaaaaaaaa"
  local b = "bbbbbbbbb"
  local t1 =socket.gettime()
  for _ =1,10000 do
  local c = table.concat({a,b})
end
  print(socket.gettime()-t1)
end

function test1()
  local a = "aaaaaaaaa"
  local b = "bbbbbbbbb"
  local t1 =socket.gettime()
  for _ =1,10000 do
  local c = a..b
end
  print(socket.gettime()-t1)
end

test()
test1()