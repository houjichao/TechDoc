#### 编写Lua脚本文件

```lua
local key = KEYS[1]
local val = redis.call("GET", key);

if val == ARGV[1]
then
        redis.call('SET', KEYS[1], ARGV[2])
        return 1
else
        return 0
end
```



#### 执行Lua脚本文件

```sh
执行命令： redis-cli -a 密码 --eval Lua脚本路径 key [key …] ,  arg [arg …] 
如：redis-cli -a 123456 --eval ./Redis_CompareAndSet.lua userName , zhangsan lisi 
```



**此处敲黑板，注意啦！！！**
"--eval"而不是命令模式中的"eval"，一定要有前端的两个-
脚本路径后紧跟key [key …]，相比命令行模式，少了numkeys这个key数量值
key [key …] 和 arg [arg …] 之间的“ , ”，英文逗号前后必须有空格，否则死活都报错



语法：

```sh
redis-cli --eval path/to/redis.lua KEYS[1] KEYS[2] , ARGV[1] ARGV[2] ...
--eval，告诉redis-cli读取并运行后面的lua脚本
path/to/redis.lua，是lua脚本的位置
KEYS[1] KEYS[2]，是要操作的键，可以指定多个，在lua脚本中通过KEYS[1], KEYS[2]获取
ARGV[1] ARGV[2]，参数，在lua脚本中通过ARGV[1], ARGV[2]获取。



```

**注意： KEYS和ARGV中间的 ',' 两边的空格，不能省略。**



```sh
## Redis客户端执行
127.0.0.1:6379> set userName zhangsan 
OK
127.0.0.1:6379> get userName
"zhangsan"

## 将lua脚本拷贝到Redis docker容器
docker cp Redis_CompareAndSet.lua 7ed26093003c:/

## linux服务器执行
## 第一次执行：compareAndSet成功，返回1
## 第二次执行：compareAndSet失败，返回0
[root@vm01 learn_lua]# redis-cli -a 123456 --eval Redis_CompareAndSet.lua userName , zhangsan lisi
(integer) 1
[root@vm01 learn_lua]# redis-cli -a 123456 --eval Redis_CompareAndSet.lua userName , zhangsan lisi
(integer) 0
```



#### 实例：使用Lua控制IP访问频率

需求：实现一个访问频率控制，某个IP在短时间内频繁访问页面，需要记录并检测出来，就可以通过Lua脚本高效的实现。
小声说明：本实例针对固定窗口的访问频率，而动态的非滑动窗口。即：如果规定一分钟内访问10次，记为超限。在本实例中前一分钟的最后一秒访问9次，下一分钟的第1秒又访问9次，不计为超限。
脚本如下：

```lua
local visitNum = redis.call('incr', KEYS[1])

if visitNum == 1 then
        redis.call('expire', KEYS[1], ARGV[1])
end

if visitNum > tonumber(ARGV[2]) then
        return 0
end

return 1;
```



演示如下：

```sh
## LimitIP:127.0.0.1为key， 10 3表示：同一IP在10秒内最多访问三次
## 前三次返回1，代表未被限制；第四、五次返回0，代表127.0.0.1这个ip已被拦截
[root@vm01 learn_lua]# redis-cli -a 123456 --eval Redis_LimitIpVisit.lua LimitIP:127.0.0.1 , 10 3
 (integer) 1
[root@vm01 learn_lua]# redis-cli -a 123456 --eval Redis_LimitIpVisit.lua LimitIP:127.0.0.1 , 10 3
 (integer) 1
[root@vm01 learn_lua]# redis-cli -a 123456 --eval Redis_LimitIpVisit.lua LimitIP:127.0.0.1 , 10 3
 (integer) 1
[root@vm01 learn_lua]# redis-cli -a 123456 --eval Redis_LimitIpVisit.lua LimitIP:127.0.0.1 , 10 3
 (integer) 0
[root@vm01 learn_lua]# redis-cli -a 123456 --eval Redis_LimitIpVisit.lua LimitIP:127.0.0.1 , 10 3
 (integer) 0
```



#### 总结

1. 通过上面一系列的介绍，对Lua脚本、Lua基础语法有了一定了解，同时也学会在Redis中如何去使用Lua脚本去实现Redis命令无法实现的场景
2. 回头再思考文章开头提到的Redis使用Lua脚本的几个优点：**减少网络开销、原子性、复用**

本文已简单介绍了Redis中如何使用Lua脚本，以及几个小实例应用。 **在下一篇中会介绍真实项目中的“答题红包雨抢夺”的实例 和 项目中是如何使用Lua解决问题。敬请期待！！！**