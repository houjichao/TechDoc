### 1. 你的 SQL 语句为什么变“慢”了

当内存数据页跟磁盘数据页内容不一致的时候，我们称这个内存页为“脏页”。内存数据写入到磁盘后，内存和磁盘上的数据页的内容就一致了，称为“干净页”。

什么情况会引发数据库的 flush 过程呢？

1. 对应的就是 InnoDB 的 redo log 写满了。这时候系统会停止所有更新操作，把 checkpoint 往前推进，redo log 留出空间可以继续写。
2. 对应的就是系统内存不足。当需要新的内存页，而内存不够用的时候，就要淘汰一些数据页，空出内存给别的数据页使用。如果淘汰的是“脏页”，就要先将脏页写到磁盘。
3. 对应的就是 MySQL 认为系统“空闲”的时候
4. 对应的就是 MySQL 正常关闭的情况

InnoDB 用缓冲池（buffer pool）管理内存，缓冲池中的内存页有三种状态：

1. 第一种是，还没有使用的；

2. 第二种是，使用了并且是干净页；

3. 第三种是，使用了并且是脏页。

刷脏页虽然是常态，但是出现以下这两种情况，都是会明显影响性能的：

1. 一个查询要淘汰的脏页个数太多，会导致查询的响应时间明显变长；

2. 日志写满，更新全部堵住，写性能跌为 0，这种情况对敏感业务来说，是不能接受的。

### 2. InnoDB 刷脏页的控制策略

首先，你要正确地告诉 InnoDB 所在主机的 IO 能力，这样 InnoDB 才能知道需要全力刷脏页的时候，可以刷多快。

这就要用到 innodb_io_capacity 这个参数了，它会告诉 InnoDB 你的磁盘能力。这个值我建议你设置成磁盘的 IOPS。磁盘的 IOPS 可以通过 fio 这个工具来测试，下面的语句是我用来测试磁盘随机读写的命令：

```
fio -filename=$filename -direct=1 -iodepth 1 -thread -rw=randrw -ioengine=psync -bs=16k -size=500M -numjobs=10 -runtime=10 -group_reporting -name=mytest 
```

```
wget https://github.com/axboe/fio/archive/refs/tags/fio-3.14.tar.gz
tar -zxvf fio-3.14.tar.gz
cd /configure
./configure
make
make install
```

```
[root@VM-0-5-centos fio-fio-3.14]# fio -filename=test.txt -direct=1 -iodepth 1 -thread -rw=randrw -ioengine=psync -bs=16k -size=500M -numjobs=10 -runtime=10 -group_reporting -name=mytest 
mytest: (g=0): rw=randrw, bs=(R) 16.0KiB-16.0KiB, (W) 16.0KiB-16.0KiB, (T) 16.0KiB-16.0KiB, ioengine=psync, iodepth=1
...
fio-3.14
Starting 10 threads
mytest: Laying out IO file (1 file / 500MiB)
Jobs: 10 (f=10): [m(10)][100.0%][r=70.5MiB/s,w=70.1MiB/s][r=4510,w=4488 IOPS][eta 00m:00s]
mytest: (groupid=0, jobs=10): err= 0: pid=3283234: Thu Sep  8 15:09:21 2022
  read: IOPS=4591, BW=71.7MiB/s (75.2MB/s)(718MiB/10004msec)
    clat (usec): min=310, max=10225, avg=672.55, stdev=546.12
     lat (usec): min=310, max=10226, avg=672.74, stdev=546.18
    clat percentiles (usec):
     |  1.00th=[  388],  5.00th=[  424], 10.00th=[  449], 20.00th=[  482],
     | 30.00th=[  506], 40.00th=[  529], 50.00th=[  553], 60.00th=[  586],
     | 70.00th=[  619], 80.00th=[  676], 90.00th=[  848], 95.00th=[ 1205],
     | 99.00th=[ 3490], 99.50th=[ 4752], 99.90th=[ 6849], 99.95th=[ 7177],
     | 99.99th=[ 8586]
   bw (  KiB/s): min=60000, max=85482, per=100.00%, avg=73508.87, stdev=685.11, samples=198
   iops        : min= 3750, max= 5340, avg=4594.01, stdev=42.78, samples=198
  write: IOPS=4640, BW=72.5MiB/s (76.0MB/s)(725MiB/10004msec); 0 zone resets
    clat (usec): min=599, max=19814, avg=1484.99, stdev=1367.40
     lat (usec): min=599, max=19814, avg=1485.34, stdev=1367.41
    clat percentiles (usec):
     |  1.00th=[  742],  5.00th=[  807], 10.00th=[  848], 20.00th=[  898],
     | 30.00th=[  938], 40.00th=[  979], 50.00th=[ 1029], 60.00th=[ 1106],
     | 70.00th=[ 1205], 80.00th=[ 1434], 90.00th=[ 2442], 95.00th=[ 4555],
     | 99.00th=[ 7635], 99.50th=[ 8455], 99.90th=[10945], 99.95th=[12256],
     | 99.99th=[15926]
   bw (  KiB/s): min=61024, max=87356, per=100.00%, avg=74407.13, stdev=621.96, samples=198
   iops        : min= 3814, max= 5458, avg=4650.06, stdev=38.82, samples=198
  lat (usec)   : 500=13.71%, 750=29.72%, 1000=24.83%
  lat (msec)   : 2=24.45%, 4=3.91%, 10=3.29%, 20=0.09%
  cpu          : usr=0.53%, sys=2.08%, ctx=92644, majf=0, minf=2
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=45937,46422,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
   READ: bw=71.7MiB/s (75.2MB/s), 71.7MiB/s-71.7MiB/s (75.2MB/s-75.2MB/s), io=718MiB (753MB), run=10004-10004msec
  WRITE: bw=72.5MiB/s (76.0MB/s), 72.5MiB/s-72.5MiB/s (76.0MB/s-76.0MB/s), io=725MiB (761MB), run=10004-10004msec

Disk stats (read/write):
  vda: ios=45804/46224, merge=46/14, ticks=30385/67539, in_queue=46706, util=99.17%
```

InnoDB 的刷盘速度就是要参考这两个因素：一个是脏页比例，一个是 redo log 写盘速度。

现在你知道了，InnoDB 会在后台刷脏页，而刷脏页的过程是要将内存页写入磁盘。所以，无论是你的查询语句在需要内存的时候可能要求淘汰一个脏页，还是由于刷脏页的逻辑会占用 IO 资源并可能影响到了你的更新语句，都可能是造成你从业务端感知到 MySQL“抖”了一下的原因。

要尽量避免这种情况，你就要合理地设置 innodb_io_capacity 的值，并且平时要多关注脏页比例，不要让它经常接近 75%。

其中，脏页比例是通过 Innodb_buffer_pool_pages_dirty/Innodb_buffer_pool_pages_total 得到的，具体的命令参考下面的代码：

```sql
如果有information_schema.global_status feature is disabled报错，执行下面两条语句
show variables like '%show_compatibility_56%';
set global show_compatibility_56=ON;


select VARIABLE_VALUE into @a from information_schema.global_status where VARIABLE_NAME = 'Innodb_buffer_pool_pages_dirty';
select VARIABLE_VALUE into @b from information_schema.global_status where VARIABLE_NAME = 'Innodb_buffer_pool_pages_total';
select @a/@b;
```

一旦一个查询请求需要在执行过程中先 flush 掉一个脏页时，这个查询就可能要比平时慢了。而 MySQL 中的一个机制，可能让你的查询会更慢：在准备刷一个脏页的时候，如果这个数据页旁边的数据页刚好是脏页，就会把这个“邻居”也带着一起刷掉；而且这个把“邻居”拖下水的逻辑还可以继续蔓延，也就是对于每个邻居数据页，如果跟它相邻的数据页也还是脏页的话，也会被放到一起刷。

在 InnoDB 中，innodb_flush_neighbors 参数就是用来控制这个行为的，值为 1 的时候会有上述的“连坐”机制，值为 0 时表示不找邻居，自己刷自己的。

找“邻居”这个优化在机械硬盘时代是很有意义的，可以减少很多随机 IO。机械硬盘的随机 IOPS 一般只有几百，相同的逻辑操作减少随机 IO 就意味着系统性能的大幅度提升。

而如果使用的是 SSD 这类 IOPS 比较高的设备的话，我就建议你把 innodb_flush_neighbors 的值设置成 0。因为这时候 IOPS 往往不是瓶颈，而“只刷自己”，就能更快地执行完必要的刷脏页操作，减少 SQL 语句响应时间。

在 MySQL 8.0 中，innodb_flush_neighbors 参数的默认值已经是 0 了。

### 3. 小结

利用 WAL (Write-Ahead  Logging)技术，数据库将随机写转换成了顺序写，大大提升了数据库的性能。

但是，由此也带来了内存脏页的问题。脏页会被后台线程自动 flush，也会由于数据页淘汰而触发 flush，而刷脏页的过程由于会占用资源，可能会让你的更新和查询语句的响应时间长一些。在文章里，我也给你介绍了控制刷脏页的方法和对应的监控方式。