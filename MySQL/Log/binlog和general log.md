```javascript
log_bin=ON  
log_bin_basename=/var/lib/mysql/mysql-bin   
log_bin_index=/var/lib/mysql/mysql-bin.index  
```

## General_log 详解

### **1、介绍**

● 开启 general log 将所有到达MySQL Server的[SQL语句](https://so.csdn.net/so/search?q=SQL语句&spm=1001.2101.3001.7020)记录下来。
● 一般不会开启开功能，因为log的量会非常庞大。但个别情况下可能会临时的开一会儿general log以供排障使用。 
● 相关参数一共有3：general_log、log_output、general_log_file

```sql
show variables like 'general_log';  -- 查看日志是否开启
set global general_log=on; -- 开启日志功能
show variables like 'general_log_file';  -- 看看日志文件保存位置
set global general_log_file='tmp/general.lg'; -- 设置日志文件保存位置
show variables like 'log_output';  -- 看看日志输出类型  table或file
set global log_output='table'; -- 设置输出类型为 table
set global log_output='file';   -- 设置输出类型为file
```

![è¿éåå¾çæè¿°](https://img-blog.csdn.net/2018041512315761?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L0FieXNzY2Fycnk=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

log_output=’FILE’ 表示将日志存入文件,默认值是FILE　 
log_output=’TABLE’表示将日志存入数据库,这样日志信息就会被写入到mysql.slow_log表中. 

mysql数据库支持同时两种日志存储方式,配置的时候以逗号隔开即可,如:log_output=‘FILE,TABLE‘.日志记录到系统专用日志表中,要比记录到文件耗费更多的系统资源,因此对于需要启用慢查日志,又需要比够获得更高的系统性能,那么建议优先记录到文件.

### 2、开启数据库general_log步骤

先执行sql指令：show variables like ‘%log%’; 

![è¿éåå¾çæè¿°](https://img-blog.csdn.net/20180327143515275?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L0FieXNzY2Fycnk=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

可以看到默认general_log是OFF的，我们直接开启：set global general_log = ON;（永久修改需要在my.cnf的【mysqld】中添加：general_log = 1）

 ![è¿éåå¾çæè¿°](https://img-blog.csdn.net/20180327144211645?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L0FieXNzY2Fycnk=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

OK，现在mysql就会在general_log_file显示的路径文件里记录general日志了！（从现在开始记录）我默认的路径是 /usr/local/mysql/data/VM_0_17_redhat.log

# Binlog 详解

## 1、介绍

MySQL的二进制日志可以说是MySQL最重要的日志了，它记录了所有的DDL和DML(除了数据查询语句)语句（记录mysql内部**增删改**等对mysql数据库有更新的内容的记录（对数据库的改动），**对数据库的查询select或show等不会被binlog日志记录**），以事件形式记录，还包含语句所执行的消耗的时间，MySQL的二进制日志是事务安全型的。

一般来说开启二进制日志大概会有**1%的性能损耗。**

**两个最重要的使用场景：**
其一：MySQL Replication在Master端开启binlog，Mster把它的二进制日志传递给slaves来达到master-slave数据一致的目的。 
其二：自然就是数据恢复了，通过使用mysqlbinlog工具来使恢复数据。

**二进制日志包括两类文件：** 
二进制日志索引文件（文件名后缀为.index）用于记录所有的二进制文件； 
二进制日志文件（文件名后缀为.00000*）记录数据库所有的DDL和DML(除了数据查询语句)语句事件。

## 2、开启binlog日志

查看binlog开启状态：

```sql
mysql> show variables like 'log_bin';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| log_bin       | OFF   |
+---------------+-------+
1 row in set (0.01 sec)
```

vim编辑打开mysql配置文件my.cnf：

```python
vim /etc/my.cnf
在【mysqld】中添加：
log-bin=/home/data/mysql-log/mysql-bin
server-id=12345
```

网上很多教程都只是添加log-bin一行就行了，此处我们为什么要加 server-id？ 
因为我们用的是5.7及以上版本的话，不加server-id重启mysql服务会报错，5.7以下版本就不用加了。 

![è¿éåå¾çæè¿°](https://img-blog.csdn.net/20180415143425322?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L0FieXNzY2Fycnk=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

所以必须添加server-id这个参数！随机指定一个不能和其他集群中机器重名的字符串，如果只有一台机器，那就可以随便指定了。 
注意！修改配置文件后重启报错最好定位到mysql的errlog，查看具体错误，我出现过一个错误就是用root自定义创建bin-log所在的目录，没给mysql用户权限。

还有一种配置方式（指定三个参数）：

第一个参数是打开binlog日志 
第二个参数是binlog日志的基本文件名，后面会追加标识来表示每一个文件 
第三个参数指定的是binlog文件的索引文件，这个文件管理了所有的binlog文件的目录

**重启后查看：** 

 ![è¿éåå¾çæè¿°](https://img-blog.csdn.net/20180415143337296?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L0FieXNzY2Fycnk=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

![è¿éåå¾çæè¿°](https://img-blog.csdn.net/20180415143729642?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L0FieXNzY2Fycnk=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70) 

## 3、常用binlog日志操作命令

1、查看所有binlog日志列表

```sql
mysql> show master logs;
```

 2、查看master状态，即最后(最新)一个binlog日志的编号名称，及其最后一个操作事件pos结束点(Position)值

```sql
mysql> show master status;
```

3、刷新log日志，自此刻开始产生一个新编号的binlog日志文件

```lua
mysql> flush logs;
```

注：每当mysqld服务重启时，会自动执行此命令，刷新binlog日志；在mysqldump备份数据时加 -F 选项也会刷新binlog日志；

4、重置(清空)所有binlog日志

```perl
mysql> reset master;
```

5、查看binlog日志内容（以表格形式）

```sql
mysql>  show binlog events in 'mysql-bin.000002';
```

## 4、mysqlbinlog命令使用

　　mysqlbinlog功能是将mysql的binlog日志转换成Mysql语句，默认情况下binlog日志是二进制文件，无法直接查看。我们直接在mysql目录的bin目录下启动该命令。（在MySQL5.5以下版本使用mysqlbinlog命令时如果报错，就加上 “–no-defaults”选项） 
　　 
mysqlbinlog命令部分参数：

```javascript
-d  //指定库的binlog
-r  //相当于重定向到指定文件
--start-position--stop-position //按照指定位置精确解析binlog日志（精确），如不接--stop-positiion则一直到binlog日志结尾
--start-datetime--stop-datetime //按照指定时间解析binlog日志（模糊，不准确），如不接--stop-datetime则一直到binlog日志结尾
```

备注：myslqlbinlog分库导出binlog，如使用-d参数，更新数据时必须使用use database。 
例：解析yj-test数据库的binlog日志并写入my.sql文件

```haskell
./mysqlbinlog -d yj-test /home/data/mysql-log/mysql-bin.000003 -r my.sql
//使用位置精确解析binlog日志
./mysqlbinlog mysql-bin.000003 --start-position=100  --stop-position=200 -r my.sql
```

可以直接查看所有binlog信息：

```sql
mysql> show master logs;
+------------------+-----------+
| Log_name         | File_size |
+------------------+-----------+
| mysql-bin.000001 |       177 |
| mysql-bin.000002 |       154 |
+------------------+-----------+
2 rows in set (0.00 sec)
```

## 5、binlog的三种工作模式

查看binlog日志格式：

```sql
show variables like "binlog_format";
```

注：我的默认为 ROW 模式，和网上说的默认不一样（Statement）

**（1）Row level** 
　　ROW是基于行级别的,他会记录每一行记录的变化,就是将每一行的修改都记录到binlog里面,记录的非常详细，但sql语句并没有在binlog里。 
　　日志中会记录每一行数据被修改的情况，然后在slave端对相同的数据进行修改。在replication里面也不会因为存储过程触发器等造成Master-Slave数据不一致的问题,但是有个致命的缺点日志量比较大.由于要记录每一行的数据变化,当执行update语句后面不加where条件的时候或alter table的时候,产生的日志量是相当的大。 
　　 
**（2）Statement level（默认）** 
　　每一条被修改数据的sql都会记录到master的bin-log中，slave在复制的时候sql进程会解析成和原来master端执行过的相同的sql再次执行 
　　优点：解决了 Row level下的缺点，不需要记录每一行的数据变化，减少bin-log日志量，节约磁盘IO，提高新能

**（3）Mixed（混合模式）** 
　　结合了Row level和Statement level的优点。 
　　在默认情况下是statement,但是在某些情况下会切换到row状态，如当一个DML更新一个ndb引擎表，或者是与时间用户相关的函数等。在主从的情况下，在主机上如果是STATEMENT模式，那么binlog就是直接写now()，然而如果这样的话，那么从机进行操作的时间，也执行now()，但明显这两个时间不会是一样的，所以对于这种情况就必须把STATEMENT模式更改为ROW模式，因为ROW模式会直接写值而不是写语句（该案例是错误的，即使是STATEMENT模式也可以使用now()函数，具体原因以后再分析）。同样ROW模式还可以减少从机的相关计算，如在主机中存在统计写入等操作时，从机就可以免掉该计算把值直接写入从机。

一般企业binlog模式的选择： 
互联网公司使用MySQL的功能较少（不用存储过程、触发器、函数），选择默认的Statement level； 
用到MySQL的特殊功能（存储过程、触发器、函数）则选择Mixed模式； 
用到MySQL的特殊功能（存储过程、触发器、函数），又希望数据最大化一直则选择Row模式；

MySql中查询日志相关：

show variables like 'log_bin'; 
show variables like '%general_log%'; 
show variables like '%log_%'; 