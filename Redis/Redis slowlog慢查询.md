### redis slow log概述

redis的slow log记录了那些执行时间超过规定时长的请求。执行时间不包括I/O操作（比如与客户端进行网络通信等），只是命令的实际执行时间（期间线程会被阻塞，无法服务于其它请求）。 
有两个参数用于配置slow log： 

* slowlog-log-slower-than：设定执行时间，单位是微秒，执行时长超过该时间的命令将会被记入log。-1表示不记录slow log; 0强制记录所有命令。 slowlog-log-slower-than 的默认值为 10000 （10毫秒，1秒 = 1,000毫秒 = 1,000,000微秒）。
* slowlog-max-len：slow log的长度。最小值为0。如果日志队列已超出最大长度，则最早的记录会被从队列中清除。 
  可以通过编辑redis.conf文件配置以上两个参数。对运行中的redis, 可以通过config get, config set命令动态改变上述两个参数

### 查看、修改配置

slowlog 保存在内存里面，读写速度非常快，因此我们可以放心地使用它，不必担心因为开启 slowlog 而损害 Redis 的速度。

slowlog 有两个重要的配置，我们先通过 CONFIG GET slowlog-* 命令来查看现有的配置。

config set slowlog-log-slower-than 10000



#### 读取slow log

slow log是记录在内存中的，所以即使你记录所有的命令（将slowlog-log-slower-than设为0），对性能的影响也很小。 
slowlog get: 列出所有slow log 
slowlog get N:列出最近N条slow log

### 输出格式

```
 1) 1) (integer) 797
    2) (integer) 1615115430
    3) (integer) 10237
    4) 1) "DEL"
       2) "access_route"
    5) "10.197.162.61:50298"
    6) ""
```

### 输出详解

1唯一性(unique)的日志标识符
2unix时间戳
3命令执行时间（微秒）
4执行的命令
5客户端ip端口
6客户端名称

### 获取当前slowlog长度

slowlog len

### 重置slowlog

可以使用slowlog reset重置slow log。日志一旦被删除，将无法恢复。