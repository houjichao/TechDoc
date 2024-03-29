# 1、简介

​    RocksDB是FaceBook起初作为实验性质开发的一个高效数据库软件，旨在充分实现快存上存储数据的服务能力。RocksDB是一个c++库，可以用来存储keys和values，且keys和values可以是任意的字节流，支持原子的读和写。除此外，RocksDB深度支持各种配置，可以在不同的生产环境（纯内存、Flash、hard disks or HDFS）中调优，支持不同的数据压缩算法、和生产环境debug的完善工具。 RocksDB的主要设计点是在快存和高服务压力下性能表现优越，所以该db需要充分挖掘Flash和RAM的读写速率。RocksDB需要支持高效的point lookup和range scan操作，需要支持配置各种参数在高压力的随机读、随机写或者二者流量都很大时性能调优。

# 2、High Level Architecture

​    RocksDB是一个嵌入式的K-V（任意字节流）存储。所有的数据在引擎中是有序存储，可以支持Get(key)、Put（Key）、Delete（Key）和NewIterator()。RocksDB的基本组成是memtable、sstfile和logfile。memtable是一种内存数据结构，写请求会先将数据写到memtable中，然后可选地写入logfile。logfile是一个顺序写的文件。当内存表溢出的时候，数据会flush到sstfile中，然后这个memtable对应的logfile也会安全地被删除。sstfile中的数据也是有序存储以方便查找。

# 3、Features

### Column Families

   RocksDB支持将一个数据库实例分片为多个列族。每个DB新建时默认带一个名为"default"的列族，如果一个操作没有携带列族信息，则默认使用这个列族。如果WAL开启，当实例crash再恢复时，RocksDB可以保证用户一个一致性的视图。通过WriteBatch API，可以实现跨列族操作的原子性。

### Updates

   Put 接口可以把一对k-v数据写入DB，如果k已经存在的话，则已有的v会被新的v覆盖。Write接口可以实现将多个k-v对写入DB，RockdDB可以保证要么所有的k-v对都写入DB，要么一个都不写入。同理，不管哪个k在DB中已经存在，旧值都会被覆盖。

### Gets、Iterators、Snapshots

   RocksDB中的key和value完全是byte stream，key和value的大小没有任何限制。Get接口提供用户一种从DB中查询key对应value的方法，MultiGet提供批量查询功能。DB中的所有数据都是按照key有序存储，其中key的compare方法可以用户自定义。Iterator方法提供用户RangeScan功能，首先seek到一个特定的key，然后从这个点开始遍历。Iterator也可以实现RangeScan的逆序遍历，当执行Iterator时，用户看到的是一个时间点的一致性视图。Snapshot接口可以创建数据库在某一个时间点的快照。Get和Iterator接口也可以执行在某一个Snapshot上。某种意义上，Iterator和Snapshot提供了DB在某个时间点的一个一致性视图，但是其实现原理却不一样。快速短期/前台的scan操作比较适合用Iterator，长期/后台操作适合用Snapshot。当使用Iterator时，会对数据库相应时间点的所有底层文件增加引用计数，直到Iterator结束或者释放了引用计数后，这些文件才允许被删除。Snapshot不关注数据文件是否被删除的问题，Compation进程会感知Snapshot的存在，会保证对应视图的数据不会被删除。当实例重启时，Snapshot会丢失，这是因为RocksDB不会持久化Snapshot相关数据。

### Transations

  RocksDB提供了多个操作的事务性，支持悲观和乐观模式。

### Prefix Iterator

   大部分的LSM引擎都不支持高效的RangeScan操作，这是由于执行RangeScan操作时都要访问所有的数据文件导致。但是大部分用户并不仅仅是完全scan所有的数据，相反，很多情况下仅仅需要按照key的前缀字符串区遍历。RocksDB根据这些应用场景，优化了对应的底层实现。用户可以prefix_extractor来声明一个key_prefix，然后RocksDB为每一个key_prefix存储相应的blooms。配置了key_prefix的Iterator操作可以通过对应的bloom bits来避免检索不含有特定key prefix的数据文件，依次可以提高Iterator性能。

### Persistence

   RocksDB有事物日志，所有的写操作首先写入内存表内，然后可选地写入到事物日志中。当DB重启时会重新执行事物日志中的所有操作，然后恢复到特定的数据状态。事物日志数据可以与DB数据文件配置成不同的目录下，这种情况适用于将数据文件写到一致性、性能高的快存中，同时可以将事物日志保存在读写性能相对比较慢的持久化存储上来保证数据的安全性。当写数据时可以配置WriteOption,来支持是否将写操作记录在事物日志中或者当用户执行commit时是否需要执行事物日志记录的sync操作。

### Fault Torlerance

   RocksDB通过checksum来检测磁盘数据损坏。每个sst file的数据块（4k-128k）都有相应的checksum值。写入存储的数据块内容不允许被修改。

### Multi-Threaded Compactions

   当用户重复写入一个key时，在DB中会存在这个key的多个value，compaction操作就是来删除这个key的冗余数据。当一个key被删除时，compation也可以用来真正执行这个底层数据的删除工作，如果用户配置合适的话，compation操作可以多线程执行。DB的数据都存储在sstfile中，当内存表的数据满的时候，会将内存数据（去重、删除无效数据后）写入到L0 文件中。每隔一段时间小文件中的数据会重新merge到更大的文件中，这就是compation。LSM引擎的写吞吐直接依赖于compation的性能，特别是数据存储在SSD或者RAM的情况。RocksDB也支持多线程并行compaction。

### Avoiding Stalls

   后台的compaction线程用来将内存数据flush到存储，当所有的后台线程都正在执行compaction时，瞬时大量写操作会很快将内存表写满，这就会引起写停顿。可以配置少一些的线程用于执行数据flush操作，

### Full Backups, Incremental Backups and Replication

   RocksDB支持增量备份，增量复制需要能够查找到所有的DB修改记录。GetUpdatesSince接口可以提供tail DB transction log的功能。RocksDB的tranction log记录在数据库目录中，当日志文件不再需要时就会move到归档目录。归档目录之所以存在是因为数据复制流比较落后时有可能需要检索过去某一个时间点的日志。GetSortedWalFiles可以返回所有的transction log文件列表。

### Block Cache -- Compressed and Uncompressed Data

   RocksDB使用LRU cache提供block的读服务。block cache partition为两个独立的cache，其中一块可以cache未压缩RAM数据，另一块cache 压缩RAM数据。如果压缩cache配置打开的话，用户一般会开启direct io，以避免OS的也缓存重新cache相同的压缩数据。

### Table Cache

 Table cache缓存了所有已打开的文件句柄，这些文件都是sstfile。用户可以设置table cache的最大值。

### Merge Operator

 RocksDB原生地就支持三种记录类型，分别为Put、Delete和Merge。Merge可以合并多个Put和Merge记录为一个单独的记录。

本文先介绍了一下RocksDB的基本概念和知识。