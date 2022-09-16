概念和区别

SELECT … LOCK IN SHARE MODE走的是S锁(意向共享锁)，即在符合条件的rows上都加了共享锁，这样的话，**其他session可以读取这些记录，也可以继续添加S锁，但是无法修改这些记录直到你这个加锁的session执行完成(否则直接锁等待超时)。**

SELECT … FOR UPDATE 走的是X锁(意向排它锁)，即在符合条件的rows上都加了排它锁，其他session也就无法在这些记录上添加任何的S锁或X锁。如果不存在一致性非锁定读的话，那么其他session是无法读取和修改这些记录的，但是innodb有非锁定读(快照读并不需要加锁)，for update之后并不会阻塞其他session的快照读取操作，除了select …lock in share mode和select … for update这种显示加锁的查询操作。

通过对比，发现for update的加锁方式无非是比lock in share mode的方式了多阻塞，select…lock in share mode的查询方式，并不会阻塞快照读。

lock in share mode 只锁覆盖索引，但是如果是 for update 就不一样了。 执行 for update 时， 系统会认为你接下来要更新数据，因此会顺便给主键索引上满足条件的行加上行锁。 **锁是加在索引上的，如果你要用 lock in share mode 来 给行加读锁避免数据被更新的话，就必须得绕过覆盖索引的优化，在查询字段中加入索引中不存在 的字段**
