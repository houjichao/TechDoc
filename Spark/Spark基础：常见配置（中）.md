## 应用相关属性

```text
[重要] spark.app.name 
默认值，无
应用的名字，在spark ui或者日志里都会用到

[重要] spark.driver.cores
默认值，1
driver程序在cluster模式下使用的核数

spark.driver.maxResultSize
默认值，1g
限制 spark action操作获取的结果大小，至少1M，如果配置为0则代表无限制。当任务获取数据到达该限制时会停止。如果配置的过大，可能会造成jvm的oom。

[重要] spark.driver.memory
默认值，1g
driver进程使用的内存大小，当sparkContext初始化时，会基于改配置格式化。如果是client模式，这个配置仅能通过 SparkConfig 在代码中指定，因为JVM此时已经启动了。或者使用 --driver-memory 在程序提交时配置。

spark.driver.memoryOverhead 
默认值，driver内存*0.1
driver使用的堆外内存大小，如果没有单位则默认为MB。

[重要] spark.executor.memory
默认值，1g
executor进程的内存大小

spark.executor.pyspark.memory
默认值，无
Pyspark每个executor的内存，如果没有配置Spark不会限制python内存的使用。

spark.executor.memoryOverhead
默认值，executor内存*0.1
executor分配的对外内存

[重要] spark.extraListeners
默认值，无
SparkListener实现类，多个用逗号拼接。当执行初始化时，会通过这个接口进行特定的触发操作。如果类由单个参数如SparkConf的构造器，则默认优先使用；否则默认调用无参的构造方法。如果没有找到合适的构造方法，会直接抛出异常。

[重要] spark.local.dir
默认值，/tmp
Spark的应用执行目录，里面会包含RDD的相关信息。这部分的数据应该存放在更快的本地磁盘，可以通过逗号拼接配置到多个磁盘中。在Spark1.0之后在集群模式下会被一下参数覆盖：standalone 下的 SPARK_LOCAL_DIRS，mesos 下的 MESOS_SANDBOX，yarn 下的 LOCAL_DIRS。

spark.logConf
默认值，false
当SparkContext启动时，在日志中输出当前有效的SparkConf配置

[重要] spark.master
默认值，无
本地模式如 local, local[*]，Standalone如 spark://HOST:PORT，mesos如 mesos://HOST/PORT，yarn如 yarn-cluster， k8s如 k9s://HOST:PORT

[重要] spark.submit.deployMode
默认值，无
应用部署的模式，如client和cluster

spark.log.callerContext
默认值，无
应用信息记录到yarn rs日志 或 hdfs audit log中，长度依赖于hadoop中的配置， hadoop.caller.context.max.size

spark.driver.supervise
默认值，false
如果为true， 当driver失败时会自动进行重启。仅对 standalone 或 mesos的cluster模式有影响。
```

## 运行时属性

```text
spark.driver.extraClassPath
默认值，无
其他的类加载路径，在client模式下需要在SparkConf中配置，因为driver启动的时候JVM已经启动了。或者在启动的时候配置 --driver-class-path 属性

spark.driver.extraJavaOptions
默认值，无
driver程序的JVM配置。比如GC配置或者日志配置等。不支持-Xmx这种配置，因为堆内存大小在cluster模式下可以通过 spark.driver.memory 属性配置，或者在client模式下，通过 --driver-memory 属性配置。

spark.driver.extraLibraryPath
默认值，无
driver启动的资源路径。

spark.driver.userClassPathFirst
默认值，false
试验特性，配置是否用户定义的jar比默认的jar优先加载。这个特性可以帮助解决Spark的依赖冲突。该参数仅在 cluster 模式下支持。

spark.executor.extraClassPath
默认值，无，executor的类加载目录

spark.executor.extraJavaOptions
默认值，无

spark.executor.extraLibraryPath
默认值，无

spark.executor.logs.rolling.maxRetainedFiles
默认值，无，保留的日志文件数量

spark.executor.logs.rolling.enableCompression
默认值，false，开启日志压缩

spark.executor.logs.rolling.maxSize
默认值，无，日志轮转的大小

spark.executor.logs.rolling.strategy
默认值，无，日志轮转的策略，如time时间轮转、size大小轮转

spark.executor.logs.rolling.time.interval
默认值，daily
如果是时间轮转间隔。可用值 daily, hourly, minutely 或者 任意秒钟。

spark.executor.userClassPathFirst
默认值，false
配置executor类加载顺序

spark.executorEnv.[EnvironmentVariableName]
默认值，无
为Executor进程添加环境变量。

spark.redaction.regex
默认值，secret 或 password
配置文件中哪些为敏感信息

spark.python.profile
默认值，false
开启python优化。

spark.python.profile.dump
spark.python.worker.memory
spark.python.worker.reuse


spark.files
逗号拼接，上传到executor的文件

spark.submit.pyFiles

[重要] spark.jars
driver和executor使用的jar

spark.jars.packages
maven中依赖的jar包，格式如 groupId:artifactId:version。

spark.jars.excludes
排除的依赖jar，格式如 groupId:artifactId

spark.jars.ivy
定义Ivy的用户目录

spark.jars.ivySettings

spark.jars.repositories
maven仓库

spark.pyspark.driver.python
driver的python可执行环境

spark.pyspark.python
execturo的python可执行环境
```

## Shuffle属性

```text
spark.reducer.maxSizeInFlight
默认值，48m
在reduce任务中，map输出的大小，如果没有特殊指定单位为MB。由于每个输出都需要创建buffer接收他们，因此需要为每个任务配置一个上限，避免占用太多内存。

spark.reducer.maxReqsInFlight
默认值，Int.MaxValue
限制远程拉取数据的请求数量。随着集群中主机的增加，可能会导致某个节点有大量的连接。

spark.reducer.maxBlocksInFlightPerAddress
默认值，Int.MaxValue
限制单个主机的连接数。

spark.maxRemoteBlockSizeFetchToMem
默认值，Int.MaxValue - 512
远程block拉取数据的时候如果超过一定的大小则刷写到磁盘。

spark.shuffle.compress
默认值，true
shuffle的文件，是否启用压缩，压缩格式为 spark.io.compression.codec

spark.shuffle.file.buffer
默认值，32k
shuffle输出的文件大小。

spark.shuffle.io.maxRetries
默认值，3
Netty模式下，如果是IO相关的异常，进行的重启次数。适合由于超大shuffle导致长时间GC停顿或者网络暂时失联的问题。

spark.shuffle.io.numConnectionsPerPeer
默认值，1
Netty模式下，针对每个主机连接的数量，如果为1可以保证主机之间的重用。如果主机数量比较少，会导致并发不够充分，可以适当调大。

spark.shuffle.io.preferDirectBufs
默认值，true
Netty模式下，使用堆外内存进行数据缓存，避免垃圾回收。

spark.shuffle.io.retryWait
默认值，5s
Netty模式下，重试拉取数据的间隔。

spark.shuffle.service.enabled
默认值，false
开启外部shuffle服务，需要在spark应用中配置 spark.dynamicAllocation.enabled 为true.

spark.shuffle.service.port
默认值，7337

spark.shuffle.service.index.cache.size
默认值，100m

spark.shuffle.maxChunksBeingTransferred
默认值，Long.MAX_VALUE
同时shuffle的chunk数量。

spark.shuffle.sort.bypassMergeThreshold 
默认值，200
在sort-base shuffle manager中，避免没有map-side聚合时，分区数量过多

spark.shuffle.spill.compress
默认值，true
在shuffle的时候开启压缩

spark.shuffle.accurateBlockThreshold
默认值，100 * 1024 * 1024   
统计阈值，HighlyCompressedMapStatus（不太了解）

spark.shuffle.registration.timeout
默认值，5000
外部shuffle服务注册的超时时间

spark.shuffle.registration.maxAttempts
默认值，3
外部shuffle服务，注册重试次数
```

## Spark UI属性

```text
spark.eventLog.logBlockUpdates.enabled
默认值，false
是否为更新的日志创建独立的block

spark.eventLog.longForm.enabled
默认值，false
如果配置为true，会使用长表格来显示日志

[重要] spark.eventLog.compress
默认值,false
日志是否启用压缩

[重要] spark.eventLog.dir
Spark记录日志的目录，子目录为appid，用户可以通过配置这个选项把日志搜集汇总到hfds，从而使用history server统一监控

[重要] spark.eventLog.enabled
默认值，false
是否开启spark的日志记录，有助于应用结束后重新spark ui

spark.eventLog.overwrite
默认值，false
是否覆盖现有的文件

spark.eventLog.buffer.kb
默认值，100k
输出流的buffer大小

spark.ui.dagGraph.retainedRootRDDs
默认值，Int.MaxValue
垃圾回收前，记录的DAG节点状态数量

spark.ui.enabled
默认值，true
是否开启spark ui

spark.ui.killEnabled
默认值，true
在ui中允许kill job和stage

spark.ui.liveUpdate.period
默认值，100ms
更新存活记录的时间，-1为永不更新

spark.ui.liveUpdate.minFlushPeriod
默认值，1s
spark ui刷新的时间间隔

spark.ui.port
默认值，4040

spark.ui.retainedJobs
默认值，1000
spark ui垃圾回收前保留的任务数量。

spark.ui.retainedStages
默认值，1000

spark.ui.retainedTasks
默认值，100000

spark.ui.reverseProxy
默认值，false
使用代理访问ui

spark.ui.reverseProxyUrl
代替url

spark.ui.showConsoleProgress
默认值，false
在控制台显示进度

spark.worker.ui.retainedExecutors
默认值，1000

spark.worker.ui.retainedDrivers
默认值，1000

spark.sql.ui.retainedExecutions
默认值，1000

spark.streaming.ui.retainedBatches
默认值，1000

spark.ui.retainedDeadExecutors
默认值，100

spark.ui.filters
进入spark ui时使用的 servlet filter，比如 
spark.ui.filters=com.test.filter1
spark.com.test.filter1.param.name1=foo
spark.com.test.filter1.param.name2=bar

spark.ui.requestHeaderSize
默认值，8k
允许的Http头大小
```

## 压缩和序列化

```text
[重要] spark.broadcast.compress
默认值，true
广播的时候启用压缩，压缩格式为 spark.io.compression.codec

[重要] spark.checkpoint.compress
默认值，false
是否针对RDD检查点使用压缩。

[重要] spark.io.compression.codec
默认值，lz4
spark内部使用的压缩格式，包括RDD分区、事件日志、广播变量、shuffle输出等。默认Spark提供了，lz4, lzf, snappy, zstd等，也可以使用对应的全名：
org.apache.spark.io.LZ4CompressionCodec
org.apache.spark.io.LZFCompressionCodec
org.apache.spark.io.SnappyCompressionCodec
org.apache.spark.io.ZStdCompressionCodec

spark.io.compression.lz4.blockSize
默认值，32k

spark.io.compression.snappy.blockSize
默认值，32k

spark.io.compression.zstd.level
默认值，1

spark.io.compression.zstd.bufferSize
默认值，32k

spark.kryo.classesToRegister

spark.kryo.referenceTracking
默认值，true

spark.kryo.registrationRequired
默认值，false

spark.kryo.registrator

spark.kryo.unsafe
默认值，false

spark.kryoserializer.buffer.max
默认值，64m

spark.kryoserializer.buffer
默认值，64k

[重要] spark.rdd.compress
默认值，false
是否针对RDD分区进行压缩

[重要] spark.serializer
默认值，org.apache.spark.serializer.JavaSerializer
网络传输或缓存时的序列化的方式

spark.serializer.objectStreamReset
默认值，100
使用JavaSerializer序列化对象时，缓存对象的数量。
```

## 执行属性

```text
spark.broadcast.blockSize
默认值，4m
TorrentBroadcastFactory中block的大小。太大的值会导致广播的时候并行度低，如果太小BlockManager可能会遇到瓶颈。

spark.broadcast.checksum
默认值，true
是否针对广播开启checksum，开启后可以帮助检测数据的完整性，但是传输数据的时候会消耗一部分计算和传输资源。如果网络传输有其他的可靠机制，那么可以关闭该选项。

[重要] spark.executor.cores
默认值，在yarn模式下为1，其他的资源调度系统取决于机器的核数。这个核数是针对每个executor来说的。

[重要] spark.default.parallelism
对于分布式的shuffle操作，如reduceByKey和join，控制对应的最大分区数。对于parallelize操作，则取决于资源调度系统。对于Local模式，取决于本地的核数；对于mesos默认是8；对于其他的调度框架是executor的核数或2。

spark.executor.heartbeatInterval
默认值，10s
executor跟driver之间的心跳间隔，心跳可以保证driver知道executor是否还在存活，并更新对应的task信息。这个参数需要低于 spark.network.timeout 参数。

spark.files.fetchTimeout
默认值，60s
当时driver程序使用SparkContext.addFile()获取文件时的超时时间

spark.files.useFetchCache
默认值，true
如果开启配置，拉取文件的时候将会使用本地缓存，这在相同的应用由多个executor运行在相同的主机时会提高性能。如果设置为false，缓存优化会被关闭，所有的executor都会通过复制文件来进行文件拉取。这个配置在NFS文件系统时需要禁用。

spark.files.overwrite
默认值，false
在使用SparkContext.addFile时，当目标文件已经存在是否直接覆盖。

spark.files.maxPartitionBytes
默认值，128MB
单个分区读取的最大字节数。

spark.files.openCostInBytes
默认值，4MB
小于这个大小的文件会合并到一个分区，避免碎片任务

spark.hadoop.cloneConf
默认值，false
开启后会为每个Task克隆一个新的hadoop Configuration对象，这样可以解决线程安全问题。为了避免额外的性能开销，默认是关闭的。

spark.hadoop.validateOutputSpecs
默认值，true
开启后，会校验输出规范，检查输出目录是否存在，使用saveAsHadoopFile。当在预创建输出目录时，可以关闭该选项。一般建议用户如果不是为了保证兼容性，不要关闭这个配置。这个配置在Spark Streaming中会被忽略，因为数据会通过检查点进行恢复。

spark.storage.memoryMapThreshold
默认值，2m
Spark memory maps从磁盘读取的大小，这样避免Spark读取太多碎片文件。

spark.hadoop.mapreduce.fileoutputcommitter.algorithm.version
默认值，1
文件输出提交的算法，可以是1或2。当为2时，有更高的性能，但是版本1可能会有更好的容错。
```

## 网络

```text
spark.rpc.message.maxSize
默认值，128
executor和driver之间发送消息的大小。

spark.blockManager.port
随机
blockManager监听的地址

spark.driver.blockManager.port
driver监听的block manager端口

spark.driver.bindAddress
driver主机，这个配置会覆盖 SPARK_LOCAL_IP 环境变量。

spark.driver.host 主机名
spark.driver.port

spark.network.timeout
默认值，120s
默认网络交互超时时间，下面的配置如果没有配，都会使用这个时间。
spark.core.connection.ack.wait.timeout, 
spark.storage.blockManagerSlaveTimeoutMs, 
spark.shuffle.io.connectionTimeout,
spark.rpc.askTimeout or spark.rpc.lookupTimeout

spark.port.maxRetries
默认值，16
绑定端口时最大重试次数，如果配置为0，每次端口占用的时候都会自增加1.

spark.rpc.numRetries
默认值，3
Rpc重试次数

spark.rpc.retry.wait
默认值，3s
重试间隔时间

spark.rpc.askTimeout
默认值，spark.network.timeout
请求操作超时时间

spark.rpc.lookupTimeout
默认值，120s
远程查找超时时间

spark.core.connection.ack.wait.timeout  
默认值，spark.network.timeout
连接超时时间，避免因为长时间GC导致超时。
```