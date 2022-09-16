##### binlog的格式

binlog 有三种格式：

* Statement（Statement-Based Replication,SBR）：每一条会修改数据的 SQL 都会记录在 binlog 中，减少了大量的IO操作，提升了系统的性能。但是，正是由于 Statement 模式只记录 SQL，而如果一些 SQL 中 包含了函数，那么可能会出现执行结果不一致的情况。比如说 uuid() 函数，每次执行的时候都会生成一个随机字符串，在 master 中记录了 uuid，当同步到 slave 之后，再次执行，就得到另外一个结果了。所以使用 Statement 格式会出现一些数据一致性问题。
* Row（Row-Based Replication,RBR）：不记录 SQL 语句上下文信息，仅保存哪条记录被修改。Row 格式的日志内容会非常清楚地记录下每一行数据修改的细节，这样就不会出现 Statement 中存在的那种数据无法被正常复制的情况。不过 Row 格式也有一个很大的问题，那就是日志量太大了，特别是批量 update、整表 delete、alter 表等操作，由于要记录每一行数据的变化，此时会产生大量的日志，大量的日志也会带来 IO 性能问题。

* Mixed（Mixed-Based Replication,MBR）：Statement 和 Row 的混合体。在 Mixed 模式下，系统会自动判断该用 Statement 还是 Row：一般的语句修改使用 Statement 格式保存 binlog；对于一些 Statement 无法准确完成主从复制的操作，则采用 Row 格式保存 binlog。Mixed 模式中，MySQL 会根据执行的每一条具体的 SQL 语句来区别对待记录的日志格式，也就是在 Statement 和 Row 之间选择一种。
  

##### 刷盘优化

innodb_flush_log_at_trx_commit：

innodb_flush_log_at_trx_commit=0，在提交事务时，InnoDB不会立即触发将缓存日志写到磁盘文件的操作，而是每秒触发一次缓存日志回写磁盘操作，并调用操作系统fsync刷新IO缓存。
innodb_flush_log_at_trx_commit=1，在每个事务提交时，InnoDB立即将缓存中的redo日志回写到日志文件，并调用操作系统fsync刷新IO缓存。
innodb_flush_log_at_trx_commit=2，在每个事务提交时，InnoDB立即将缓存中的redo日志回写到日志文件，但并不马上调用fsync来刷新IO缓存，而是每秒只做一次磁盘IO缓存刷新操作。

默认值1是为了保证完整的ACID。当然，你可以将这个配置项设置为1以外的值来换取更高的性能，但是在系统崩溃的时候，你将会丢失1秒的数据。设置为0的话，my[SQL](http://www.dataguru.cn/article-8711-1.html?union_site=innerlink)d进程崩溃的时候，就会丢失最后1秒的事务。设置为2的话，只有在操作系统崩溃或者断电的时候才会丢失最后1秒的数据。InnoDB在做恢复的时候会忽略这个值。

刷写其实是两个操作，刷（flush）和写（write），区分这两个概念（两个系统调用）是很重要的。在大多数的操作系统中，把Innodb的log buffer（内存）写入日志（调用系统调用write），只是简单的把数据移到操作系统缓存中，操作系统缓存同样指的是内存。并没有实际的持久化数据。

所以，通常设置为0和2的时候，在崩溃或断电的时候会丢失最后一秒的数据，因为这个时候数据只是存在于操作系统缓存。之所以说“通常”，可能会有丢失不只1秒的数据的情况，比如说执行flush操作的时候阻塞了。

设为1当然是最安全的，但性能也是最差的（相对其他两个参数而言，但不是不能接受）。如果对数据一致性和完整性要求不高，完全可以设为2，如果只要求性能，例如高并发写的日志服务器，设置为0来获得更高性能。



sync_binlog

MySQL提供一个sync_binlog参数来控制数据库的binlog刷到磁盘上去。

默认，sync_binlog=0，表示MySQL不控制binlog的刷新，由文件系统自己控制它的缓存的刷新。这时候的性能是最好的，但是风险也是最大的。因为一旦系统Crash，在binlog_cache中的所有binlog信息都会被丢失。

如果sync_binlog>0，表示每sync_binlog次事务提交，MySQL调用文件系统的刷新操作将缓存刷下去。最安全的就是sync_binlog=1了，表示每次事务提交，MySQL都会把binlog刷下去，是最安全但是性能损耗最大的设置。这样的话，在数据库所在的主机操作系统损坏或者突然掉电的情况下，系统才有可能丢失1个事务的数据。但是binlog虽然是顺序IO，但是设置sync_binlog=1，多个事务同时提交，同样很大的影响MySQL和IO性能。虽然可以通过group commit的补丁缓解，但是刷新的频率过高对IO的影响也非常大。对于高并发事务的系统来说，“sync_binlog”设置为0和设置为1的系统写入性能差距可能高达5倍甚至更多。

所以很多MySQL DBA设置的sync_binlog并不是最安全的1，而是100或者是0。这样牺牲一定的一致性，可以获得更高的并发和性能。



更新的时候也会写undo log，但是这里作者可能重点想表述一条更新语句的执行过程，重点不在回滚阶段，所以没有提到undo log

![img](https://img-blog.csdnimg.cn/b92eedf480014dc0a0c53ee7effd33b4.png)



RTO:恢复目标时间



WAL：Write-Ahead Logging 先写日志，再写磁盘