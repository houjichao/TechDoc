#### Redis中使用Lua脚本的好处

* 减少网络开销。可以将多个请求通过脚本的形式一次发送，减少网络时延。
* 原子操作。Redis会将整个脚本作为一个整体执行，中间不会被其他请求插入。因此在脚本运行过程中无需担心会出现竞态条件，无需使用事务。
* 复用。客户端发送的脚本会永久存在redis中，这样其他客户端可以复用这一脚本，而不需要使用代码完成相同的逻辑。



#### Redis中Lua的常用命令

* EVAL

*  EVALSHA

*  SCRIPT LOAD - SCRIPT EXISTS

*  SCRIPT FLUSH

*  SCRIPT KILL

  

##### Eval命令

命令格式：`EVAL script numkeys key [key …] arg [arg …]`
\- `script`参数是一段 Lua5.1 脚本程序。脚本不必(也不应该[^1])定义为一个 Lua 函数
\- `numkeys`指定后续参数有几个key，即：key [key …]中key的个数。如没有key，则为0
\- `key [key …]` 从 EVAL 的第三个参数开始算起，表示在脚本中所用到的那些 Redis 键(key)。在Lua脚本中通过KEYS[1], KEYS[2]获取。
\- `arg [arg …]` 附加参数。在Lua脚本中通过ARGV[1],ARGV[2]获取。

**注意： EVAL命令依据参数numkeys来将其后面的所有参数分别存入脚本中KEYS和ARGV两个table类型的全局变量。当脚本不需要任何参数时，也不能省略这个参数(设为0)**

```sh
// 例1：numkeys=1，keys数组只有1个元素key1，arg数组无元素
127.0.0.1:6379> EVAL "return KEYS[1]" 1 key1
"key1"

// 例2：numkeys=0，keys数组无元素，arg数组元素中有1个元素value1
127.0.0.1:6379> EVAL "return ARGV[1]" 0 value1
"value1"

// 例3：numkeys=2，keys数组有两个元素key1和key2，arg数组元素中有两个元素first和second 
//      其实{KEYS[1],KEYS[2],ARGV[1],ARGV[2]}表示的是Lua语法中“使用默认索引”的table表，
//      相当于java中的map中存放四条数据。Key分别为：1、2、3、4，而对应的value才是：KEYS[1]、KEYS[2]、ARGV[1]、ARGV[2]
//      举此例子仅为说明eval命令中参数的如何使用。项目中编写Lua脚本最好遵从key、arg的规范。
127.0.0.1:6379> eval "return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}" 2 key1 key2 first second 
1) "key1"
2) "key2"
3) "first"
4) "second"


// 例4：使用了redis为lua内置的redis.call函数
//      脚本内容为：先执行SET命令，在执行EXPIRE命令
//      numkeys=1，keys数组有一个元素userAge（代表redis的key）
//      arg数组元素中有两个元素：10（代表userAge对应的value）和60（代表redis的存活时间）
127.0.0.1:6379> EVAL "redis.call('SET', KEYS[1], ARGV[1]);redis.call('EXPIRE', KEYS[1], ARGV[2]); return 1;" 1 userAge 10 60
(integer) 1
127.0.0.1:6379> get userAge
"10"
127.0.0.1:6379> ttl userAge
(integer) 44
```



通过上面的例4，我们可以发现，脚本中使用redis.call()去调用redis的命令。
在 Lua 脚本中，可以使用两个不同函数来执行 Redis 命令，它们分别是： `redis.call() 和 redis.pcall()`
这两个函数的唯一区别在于它们使用不同的方式处理执行命令所产生的错误，差别如下：

**错误处理**
当 redis.call() 在执行命令的过程中发生错误时，脚本会停止执行，并返回一个脚本错误，错误的输出信息会说明错误造成的原因：

```sh
127.0.0.1:6379> lpush foo a
(integer) 1

127.0.0.1:6379> eval "return redis.call('get', 'foo')" 0
(error) ERR Error running script (call to f_282297a0228f48cd3fc6a55de6316f31422f5d17): ERR Operation against a key holding the wrong kind of value
```

和 redis.call() 不同， redis.pcall() 出错时并不引发(raise)错误，而是返回一个带 err 域的 Lua 表(table)，用于表示错误：

```sh
127.0.0.1:6379> EVAL "return redis.pcall('get', 'foo')" 0
(error) ERR Operation against a key holding the wrong kind of value
```





##### SCRIPT LOAD命令 和 EVALSHA命令

SCRIPT LOAD命令格式：`SCRIPT LOAD script`
EVALSHA命令格式：`EVALSHA sha1 numkeys key [key …] arg [arg …]`

这两个命令放在一起讲的原因是：`EVALSHA` 命令中的sha1参数，就是`SCRIPT LOAD` 命令执行的结果。

`SCRIPT LOAD` 将脚本 script 添加到Redis服务器的脚本缓存中，并不立即执行这个脚本，而是会立即对输入的脚本进行求值。并返回给定脚本的 SHA1 校验和。如果给定的脚本已经在缓存里面了，那么不执行任何操作。

在脚本被加入到缓存之后，在任何客户端通过`EVALSHA`命令，可以使用脚本的 SHA1 校验和来调用这个脚本。脚本可以在缓存中保留无限长的时间，直到执行`SCRIPT FLUSH`为止。



```sh
## SCRIPT LOAD加载脚本，并得到sha1值
127.0.0.1:6379> SCRIPT LOAD "redis.call('SET', KEYS[1], ARGV[1]);redis.call('EXPIRE', KEYS[1], ARGV[2]); return 1;"
"6aeea4b3e96171ef835a78178fceadf1a5dbe345"

## EVALSHA使用sha1值，并拼装和EVAL类似的numkeys和key数组、arg数组，调用脚本。
127.0.0.1:6379> EVALSHA 6aeea4b3e96171ef835a78178fceadf1a5dbe345 1 userAge 10 60
(integer) 1
127.0.0.1:6379> get userAge
"10"
127.0.0.1:6379> ttl userAge
(integer) 43
```





