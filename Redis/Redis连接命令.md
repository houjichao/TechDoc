### Select 

Redis Select 命令用于切换到指定的数据库，数据库索引号 index 用数字值指定，以 0 作为起始索引值。

```
redis 127.0.0.1:6379> SET db_number 0         # 默认使用 0 号数据库
OK

redis 127.0.0.1:6379> SELECT 1                # 使用 1 号数据库
OK

redis 127.0.0.1:6379[1]> GET db_number        # 已经切换到 1 号数据库，注意 Redis 现在的命令提示符多了个 [1]
(nil)

redis 127.0.0.1:6379[1]> SET db_number 1
OK

redis 127.0.0.1:6379[1]> GET db_number
"1"

redis 127.0.0.1:6379[1]> SELECT 3             # 再切换到 3 号数据库
OK

redis 127.0.0.1:6379[3]>                      # 提示符从 [1] 改变成了 [3]
```

| 序号 | 命令及描述                      |
| :--- | :------------------------------ |
| 1    | AUTH password 验证密码是否正确  |
| 2    | ECHO message 打印字符串         |
| 3    | PING 查看服务是否运行           |
| 4    | QUIT 关闭当前连接               |
| 5    | SELECT index 切换到指定的数据库 |

Redis有时会有中文乱码

要在 redis-cli 后面加上 --raw，就可以避免中文乱码了。

```
redis-cli --raw
```

