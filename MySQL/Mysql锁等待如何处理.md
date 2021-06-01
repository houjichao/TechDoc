这个问题我相信大家对它并不陌生，但是有很多人对它产生的原因以及处理吃的不是特别透，很多情况都是交给DBA去定位和处理问题，接下来我们就针对这个问题来展开讨论。

Mysql造成锁的情况有很多，下面我们就列举一些情况：

1. 执行DML操作没有commit，再执行删除操作就会锁表。

2. 在同一事务内先后对同一条数据进行插入和更新操作。

3. 表索引设计不当，导致数据库出现死锁。

4. 长事物，阻塞DDL，继而阻塞所有同表的后续操作。

但是要区分的是Lock wait timeout exceeded与Dead Lock是不一样。

* Lock wait timeout exceeded：后提交的事务等待前面处理的事务释放锁，但是在等待的时候超过了mysql的锁等待时间，就会引发这个异常。

* Dead Lock：两个事务互相等待对方释放相同资源的锁，从而造成的死循环，就会引发这个异常。

还有一个要注意的是innodb_lock_wait_timeout与lock_wait_timeout也是不一样的。

* innodb_lock_wait_timeout：innodb的dml操作的行级锁的等待时间

* lock_wait_timeout：数据结构ddl操作的锁的等待时间

如何查看innodb_lock_wait_timeout的具体值？

```
SHOW VARIABLES LIKE 'innodb_lock_wait_timeout'
```

如何修改innode lock wait timeout的值？

参数修改的范围有Session和Global，并且支持动态修改，可以有两种方法修改：

方法一：

通过下面语句修改

```
set innodb_lock_wait_timeout=100;
set global innodb_lock_wait_timeout=100;
```

ps. 注意global的修改对当前线程是不生效的，只有建立新的连接才生效。

方法二：

修改参数文件/etc/my.cnf innodb_lock_wait_timeout = 50

ps. innodb_lock_wait_timeout指的是事务等待获取资源等待的最长时间，超过这个时间还未分配到资源则会返回应用失败；当锁等待超过设置时间的时候，就会报如下的错误；ERROR 1205 (HY000): Lock wait timeout exceeded; try restarting transaction。其参数的时间单位是秒，最小可设置为1s(一般不会设置得这么小)，最大可设置1073741824秒，默认安装时这个值是50s(默认参数设置)。

下面介绍在遇到这类问题该如何处理

### 问题现象

* 数据更新或新增后数据经常自动回滚。

* 表操作总报 Lock wait timeout exceeded 并长时间无反应

### 解决方法

* 应急方法：show full processlist; kill掉出现问题的进程。ps.有的时候通过processlist是看不出哪里有锁等待的，当两个事务都在commit阶段是无法体现在processlist上

* 根治方法：select * from innodb_trx;查看有是哪些事务占据了表资源。ps.通过这个办法就需要对innodb有一些了解才好处理

说起来很简单找到它杀掉它就搞定了，但是实际上并没有想象的这么简单，当问题出现要分析问题的原因，通过原因定位业务代码可能某些地方实现的有问题，从而来避免今后遇到同样的问题。


