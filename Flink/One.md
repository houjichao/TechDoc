nc -lk 9999

socket的并行度只能是1

state

两种state 一种operator state 针对task级别 一种keyed state 针对key级别

valueState



正常提供三种存储地方 内存 文件系统 flink自带rocksdb



flink和hive、spark有什么区别呢：

hive底层基于MapReduce 和磁盘交互多,主要做离线,spark基于内存,可以做实时离线.但是容易内存溢出.flink很好的解决了前面的问题 ,可以做实时离线,擅长实时

