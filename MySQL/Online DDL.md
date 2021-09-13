作为一名DBA，对数据库进行DDL操作非常多，如添加索引，添加字段等等。对于MySQL数据库，DDL支持的并不是很好，一不留心就导致了全表被锁，经常搞得刚入门小伙伴很郁闷又无辜，不是说MySQL支持Online DDL么，不是说不会锁表的么？是的，令人高兴的是从MySQL5.6开始就支持部分DDL Online操作了，**但并不是全部喔**，今天这里就对我们常用的DDL进行总结和说明，让操作DDL的小伙伴从此做到心中有数，得心应手，让老板们再也不用担心我们做DDL咯。

我自己遵守的一条黄金准则：**DDL永远不要在业务高峰期间执行**。

环境说明：本次的测试服务器配置如下

```
      CPU:32 cores
      MEM：128G
      DISK: SSD（固态硬盘）
      MySQL版本：5.6.27以上
```

**一、MySQL执行DDL原理**

   MySQL各版本，对于DDL的处理方式是不同的，主要有三种：

- **Copy Table方式：** 这是InnoDB最早支持的方式。顾名思义，通过临时表拷贝的方式实现的。新建一个带有新结构的临时表，将原表数据全部拷贝到临时表，然后Rename，完成创建操作。这个方式过程中，原表是可读的，不可写。但是会消耗一倍的存储空间。
- **Inplace方式：**这是原生MySQL 5.5，以及innodb_plugin中提供的方式。所谓Inplace，也就是在原表上直接进行，不会拷贝临时表。相对于Copy Table方式，这比较高效率。原表同样可读的，但是不可写。

- **Online方式：**这是MySQL 5.6以上版本中提供的方式，也是今天我们重点说明的方式。无论是Copy Table方式，还是Inplace方式，原表只能允许读取，不可写。对应用有较大的限制，因此MySQL最新版本中，InnoDB支持了所谓的Online方式DDL。与以上两种方式相比，online方式支持DDL时不仅可以读，还可以写，对于dba来说，这是一个非常棒的改进。

**二、常用DDL执行方式总结**

| **操作**                          | **支持方式**            | **Allow R/W**              | **说明**                                                     |
| --------------------------------- | ----------------------- | -------------------------- | ------------------------------------------------------------ |
| add/create index                  | online                  | 允许读写                   | `当表上有FULLTEXT索引除外，需要锁表，阻塞写`                 |
| `add fulltext index`              | in-place（5.6以上版本） | 仅支持读，阻塞写           | 创建表上第一个fulltext index用copy table方式，除非表上`有``FTS_DOC_ID`列。之后创建fulltext index用in-place方式，**经过测试验证，第一次时5.6 innodb****会隐含自动添加`FTS_DOC_ID`列，也就是5.6都是in-place方式** |
| `drop index`                      | online                  | 允许读写                   | 操作元数据，不涉及表数据。所以很快，可以放心操作             |
| optimize table                    | online                  | 允许读写                   | 当带有fulltext index的表用copy table方式并且阻塞写           |
| alter table...engine=innodb       | online                  | 允许读写                   | 当带有fulltext index的表用copy table方式并且阻塞写           |
| add column                        | online                  | 允许读写，(增加自增列除外) | 1、添加auto_increment列或者修改当前列为自增列都要锁表，阻塞写;2、虽采用online方式，但是表数据需要重新组织，所以增加列依然是昂贵的操作，小伙伴尤其注意啦 |
| drop column                       | online                  | 允许读写(增加自增列除外)   | 同add column，重新组织表数据，，昂贵的操作                   |
| Rename a column                   | online                  | 允许读写                   | 操作元数据;不能改列的类型，否则就锁表（已验证）              |
| Reorder columns                   | online                  | 允许读写                   | 重新组织表数据，昂贵的操作                                   |
| Make column `NOT NULL`            | online                  | 允许读写                   | 重新组织表数据，昂贵的操作                                   |
| Change data type of column        | copy table              | 仅支持读，阻塞写           | 创建临时表，复制表数据，昂贵的操作（已验证）                 |
| Set default value for a column    | online                  | 允许读写                   | 操作元数据，因为default value存储在frm文件中，不涉及表数据。所以很快，可以放心操作 |
| alter table xxx auto_increment=xx | online                  | 允许读写                   | 操作元数据，不涉及表数据。所以很快，可以放心操作             |
| Add primary key                   | online                  | 允许读写                   | 昂贵的操作（已验证）                                         |
| Convert character set             | copy table              | 仅支持读，阻塞写           | 如果新字符集不同，需要重建表，昂贵的操作                     |

 **【注】：红色部分都需要注意的操作，会影响线上数据库性能**

 

**二、测试常用DDL执行方式**

- **测试用表：表大小70M,行数13659**
- **初始表结构：**

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
CREATE TABLE `t_mysql` (
  `checksum` bigint(20) unsigned NOT NULL,
  `sample` text NOT NULL，
  `content` text ，
  `content1` text ，
  `content2` text ，
) ENGINE=InnoDB DEFAULT CHARSET=utf8 
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

- **测试机器开启profiling：**

```
root:test> set profiling=1;
Query OK, 0 rows affected, 1 warning (0.00 sec)
```

 

**1、`add fulltext index`**

**1) 用例1：该语句执行期间是否锁表？**

开两个session。session 1：创建fulltext index

```
dbadmin:test> alter table t_mysql add fulltext index idx_1(sample);
执行中.......
```

session 2:进行insert数据，会一直等待中，阻塞写了

![img](https://images2015.cnblogs.com/blog/818283/201612/818283-20161219112044807-600882250.png)

**【结论1】：创建全文索引时，仅支持读，阻塞写；dba小伙伴加索引时要注意啦，而且执行时间会很长，在执行ddl时，尽量不要手动kill，可能会导致异常，[这里有个知识点](http://www.cnblogs.com/cchust/p/4639397.html)。**

**2) 用例2：创建表上第一个fulltext index用copy table方式，除非表上`有``FTS_DOC_ID`列。之后创建fulltext index用in-place方式？**

- 创建第一个全文索引：

```
root:test> alter table t_mysql add fulltext index idx_1(sample);
Query OK, 0 rows affected, 1 warning (15.21 sec)
Records: 0  Duplicates: 0  Warnings: 1
```

这个时候发现**0 rows affected**，也就是说没有用copy table方式。这是为什么，官方文档上说第一个全文索引采用copy table方式的？再看下执行过程：

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
root:test> show profile for query 10;
+--------------------------------+-----------+
| Status                         | Duration  |
+--------------------------------+-----------+
| starting                       |  0.000378 |
| checking permissions           |  0.000038 |
| checking permissions           |  0.000035 |
| init                           |  0.000032 |
| Opening tables                 |  0.000101 |
| setup                          |  0.000079 |
| creating table                 |  0.001043 |
| After create                   |  0.000217 |
| System lock                    |  0.000031 |
| preparing for alter table      |  0.023248 |
| altering table                 | 15.164399 |
| committing alter table to stor |  0.016108 |
| end                            |  0.000043 |
| query end                      |  0.000327 |
| closing tables                 |  0.000021 |
| freeing items                  |  0.000081 |
| logging slow query             |  0.000121 |
| cleaning up                    |  0.000060 |
+--------------------------------+-----------+
18 rows in set, 1 warning (0.00 sec)
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

在这上面也没有发现**copy tmp table**字样，说明确实没有进行表copy。在上面执行建全文索引时，有一个warning，看下这个warning：

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
root:test> show warnings;
+---------+------+--------------------------------------------------+
| Level   | Code | Message                                          |
+---------+------+--------------------------------------------------+
| Warning |  124 | InnoDB rebuilding table to add column FTS_DOC_ID |
+---------+------+--------------------------------------------------+
1 row in set (0.00 sec)
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

到这里就明白了，原来当我们建第一个全文索引时，5.6以上版本innodb会默认的为我们自动添加FTS_DOC_ID，这样就避免了copy table了，所以相对会快些。

**【结论2】：5.6以上版本innodb会默认的为我们自动添加FTS_DOC_ID，所以第一次创建全文索引时避免了copy table。我们可以自此认为5.6以上版本创建全文索引都是in-place方式。**

**2、`optimize table & alter table...engine=innodb`**

注：测试前清除上面创建的全文索引，恢复表为初始

**1) 用例：该语句执行期间是否锁表**

1.1)不存在全文索引：

session1执行：

```
root:test> alter table t_mysql engine=innodb;
Query OK, 0 rows affected (1.38 sec) #没有数据受影响
Records: 0  Duplicates: 0  Warnings: 0
```

session2同时执行：

```
dbadmin:test> insert into t_mysql values(0113,'测试全文索引','darrenllllllllllllll');
Query OK, 1 row affected (0.14 sec)
```

当表上不存在全文索引时，optimize table 或者 alter table t_mysql engine=innodb 很快执行完成，并且不阻塞写；

1.2）存在全文索引时：

 步骤一：添加全文索引

```
CREATE TABLE `t_mysql` (
  `checksum` bigint(20) unsigned NOT NULL,
  `sample` text NOT NULL,
  `content` text,
  FULLTEXT KEY `idx_1` (`sample`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 |
```

步骤二：session1：执行optimize table或者alter table ... engine=innodb

```
root:test> alter table t_mysql engine=innodb;
执行中.......

Query OK, 13661 rows affected (42.13 sec)   #说明进行copy table数据了
Records: 13661  Duplicates: 0  Warnings: 0
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
root:test> show profile for query 14;
+----------------------+-----------+
| Status               | Duration  |
+----------------------+-----------+
| starting             |  0.000355 |
| checking permissions |  0.000071 |
| Opening tables       |  0.000151 |
| System lock          |  0.000188 |
| init                 |  0.000027 |
| Opening tables       |  0.000958 |
| setup                |  0.000062 |
| creating table       |  0.001235 |
| After create         |  0.000127 |
| System lock          |  0.045863 |
| copy to tmp table    | 43.937449 |
| rename result table  |  0.529001 |
| end                  |  0.000172 |
| Opening tables       |  0.000759 |
| System lock          |  0.002615 |
| query end            |  0.000402 |
| closing tables       |  0.000011 |
| freeing items        |  0.000022 |
| cleaning up          |  0.000033 |
+----------------------+-----------+
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

session 2：模拟插入数据：

```
dbadmin:test> insert into t_mysql values(0113,'测试全文索引','darrenllllllllllllll'); 

等待中.......
```

当表上存在全文索引时，我们执行optimize table 或者 alter table t_mysql engine=innodb 采用copy table方式，而且锁全表，阻塞写；

 **【结论1】：当表上不存在全文索引时，optimize table 或者 alter table t_mysql engine=innodb 采用in-place方式，并且不阻塞写；**

​         **当表上存在全文索引时，我们执行optimize table 或者 alter table t_mysql engine=innodb 采用copy table方式，而且锁全表，阻塞写；**

 **3、add column**

 **1）用例1：添加auto_increment列要锁表，阻塞写？**

 session 1 ：

```
root:test> alter table t_mysql add column id int not null primary key auto_increment;
Query OK, 0 rows affected (1.41 sec)
```

session 2：

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
dbadmin:test> insert into t_mysql(checksum,sample,content) values(0113,'测试全文索引','darrenllllllllllllll');

waitting......
......
......
......
......
......
Query OK, 1 row affected (0.97 sec)
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

当添加自增列时，会阻塞写。

 **2）用例2：添加普通列，online？**

**session 1：
**

```
root:test> alter table t_mysql add column content1 text;
Query OK, 0 rows affected (1.36 sec)  #in-place方式
Records: 0  Duplicates: 0  Warnings: 0
```

**session 2：**

```
dbadmin:test> insert into t_mysql(checksum,sample,content) values(0113,'测试全文索引','darrenllllllllllllll');
Query OK, 1 row affected (0.01 sec)
```

当添加一个普通列时，是online的，不阻塞写入。

**4、change column type
**

session 1：

```
root:test> alter table t_mysql change content1 content1 longtext;  
Query OK, 13674 rows affected (1.37 sec)  # copy table
Records: 13674  Duplicates: 0  Warnings: 0
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
root:test> show profile;
+----------------------+----------+
| Status               | Duration |
+----------------------+----------+
| starting             | 0.000302 |
| checking permissions | 0.000027 |
| checking permissions | 0.000045 |
| init                 | 0.000024 |
| Opening tables       | 0.000097 |
| setup                | 0.000067 |
| creating table       | 0.001379 |
| After create         | 0.000165 |
| System lock          | 0.004105 |
| copy to tmp table    | 1.327642 |  #copy table
| rename result table  | 0.034565 |
| end                  | 0.000473 |
| query end            | 0.001067 |
| closing tables       | 0.000263 |
| freeing items        | 0.000414 |
| logging slow query   | 0.000478 |
| cleaning up          | 0.001074 |
+----------------------+----------+
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

session 2：并发DML

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
dbadmin:test> insert into t_mysql(checksum,sample,content1) values(0113,'测试全文索引','darrenllllllllllllll');

WAITTING.......
.......
.......
.......
.......
.......
Query OK, 1 row affected (0.95 sec)
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

**【结论】：修改列类型DDL采用copy table方式并且阻塞写入，在线上操作必须谨慎再谨慎！**

 

以上就是我经常进行线上的DDL操作了，如果还有其他DDL请查看下面的官方链接。从此，DBA小伙伴进行DDL操作不再侥幸也不再盲目，做到心中有杆秤。

另外，我的一些建议：

 **1、尽量不要在业务高峰期间进行DDL，即使是online DDL;**

 **2、对于大表（G级别）DDL，最好在测试库上做一遍，预估下时间，不至于到线上执行时心慌手乱；（线上和测试环境数据量差不多）**