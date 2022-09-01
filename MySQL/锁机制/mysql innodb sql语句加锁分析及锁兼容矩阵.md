### 官方文档中对于sql语句的加锁描述

SLELCT … FROM

* 前三种级别不加锁，SERIALIZABLE级别下，会对SELECT 默认带上LOCK IN SHARE MODE，S锁

SELECT…FOR UPDATE / SELECT … LOCK IN SHARE MODE

* 扫描到的行都会加上锁（不符合where子句条件的记录锁会被释放）

SELECT … LOCK IN SHARE MODE

* 在搜索遇到的所有索引记录上加 next-key lock（S）。对于使用唯一索引搜索唯一行的语句，只需在对应的索引上加锁（行锁S）

SELECT … FOR UPDATE

* 在搜索遇到的所有索引记录上加 next-key lock (X)。对于使用唯一索引搜索唯一行的语句，只需在对应的索引上加锁（行锁X）。

UPDATE … WHERE

* 在搜索遇到的所有索引记录上加 next-key lock (X)。对于使用唯一索引搜索唯一行的语句，只需在对应的索引上加锁（行锁X）。
  当UPDATE修改聚集索引记录时，对受影响的辅助索引记录进行隐式锁定。在插入新的二级索引记录之前执行 duplicate check扫描时，以及在插入新的二级索引记录时，UPDATE操作还会在受影响的二级索引记录上获得共享锁。

DELETE FROM … WHERE …

* 在搜索遇到的所有索引记录上加 next-key lock (X)。对于使用唯一索引搜索唯一行的语句，只需在对应的索引上加锁（行锁X）。

INSERT

* 在插入的行上设置行锁（X）。
  在插入之前，会先设置一个gap锁，称为insert intention gap lock。（insert intention gap lock和insert intention gap lock是兼容的，例如现在有索引4，7；事务A,B分别要插入5，6；事务A，B在获取X锁之前，会获取这个i gap，锁定4和7的间隙，A,B彼此不会阻塞，因为行没有冲突。）
  如果insert 的事务出现了duplicate-key error ，事务会对duplicate index record加共享锁。这个共享锁在并发的情况下是会产生死锁的。

|       **session A**       |             **session B**             |             **session C**             |
| :-----------------------: | :-----------------------------------: | :-----------------------------------: |
|    START TRANSACTION;     |                                       |                                       |
| INSERT INTO t1 VALUES(1); |                                       |                                       |
|     insert成功，并X锁     |          START TRANSACTION;           |                                       |
|             ·             |       INSERT INTO t1 VALUES(1);       |          START TRANSACTION;           |
|             ·             |                 wait                  |       INSERT INTO t1 VALUES(1);       |
|             ·             |                                       |                 wait                  |
|     rollback, 释放X锁     |                                       |                                       |
|             `             |                获取S锁                |                获取S锁                |
|             `             | 获取X锁没有成功，等待session C释放S锁 | 获取X锁没有成功，等待session B释放S锁 |

INSERT … ON DUPLICATE KEY UPDATE

* 和INSERT的区别是，在发生duplicate key error 时，加的是X锁，而不是S锁。
  主键冲突时，加的行锁（X）；唯一键冲突时，加的是next-key lock（X）。【前面描述出自官方文档，但是有网上有博客说官方文档有bug，主键冲突也加的是next-key lock】

REPLACE …

* replace into 跟 insert 功能类似，不同点在于：replace into 首先尝试插入数据到表中， 1. 如果发现表中已经有此行数据（根据主键或者唯一索引判断）则先删除此行数据，然后插入新的数据。 2. 否则，直接插入新数据。

如果插入没有冲突，和insert一样，否则，加next-key lock (X)


### 锁的兼容矩阵

|                  | Gap  | Insert Intention | Record | Next-Key |
| ---------------- | ---- | ---------------- | ------ | -------- |
| Gap              | 兼容 | 兼容             | 兼容   | 兼容     |
| Insert Intention | 冲突 | 兼容             | 兼容   | 冲突     |
| Record           | 兼容 | 兼容             | 冲突   | 冲突     |
| Next-Key         | 兼容 | 兼容             | 冲突   | 冲突     |

注：横向是已经持有的锁，纵向是正在请求的锁

| type | IS     | IX     | S      | X      |
| ---- | ------ | ------ | ------ | ------ |
| IS   | 兼容   | 兼容   | 兼容   | 不兼容 |
| IX   | 兼容   | 兼容   | 不兼容 | 不兼容 |
| S    | 兼容   | 不兼容 | 兼容   | 不兼容 |
| X    | 不兼容 | 不兼容 | 不兼容 | 不兼容 |

------

参考：
[1] mysql官方文档 https://dev.mysql.com/doc/refman/5.7/en/innodb-locks-set.html
[2] MySQL技术内幕:InnoDB存储引擎
[3] http://m.elecfans.com/article/872770.html
[4] https://www.jianshu.com/p/7004f7571427