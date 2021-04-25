**Redis的设计与实现**

其实 [Redis](http://mp.weixin.qq.com/s?__biz=MzI3ODcxMzQzMw==&mid=2247493806&idx=1&sn=c4988a38efd6555338615d932ce7522e&chksm=eb506d98dc27e48eab55be68da483102bc828704485a5740785afdf7bec525acbafc4697a4a8&scene=21#wechat_redirect) 主要是通过三个方面来满足这样高效吞吐量的性能需求

- 高效的数据结构
- 多路复用 IO 模型
- 事件机制

#### **1、高效的数据结构**

[Redis](http://mp.weixin.qq.com/s?__biz=MzI3ODcxMzQzMw==&mid=2247493806&idx=1&sn=c4988a38efd6555338615d932ce7522e&chksm=eb506d98dc27e48eab55be68da483102bc828704485a5740785afdf7bec525acbafc4697a4a8&scene=21#wechat_redirect) 支持的几种高效的数据结构 string（字符串）、hash（哈希）、list（列表）、set（集合）、zset（有序集合）

以上几种对外暴露的数据结构它们的底层编码方式都是做了不同的优化的，不细说了，不是本文重点。

#### **2、多路复用 IO 模型**

假设某一时刻与 [Redis](http://mp.weixin.qq.com/s?__biz=MzI3ODcxMzQzMw==&mid=2247493806&idx=1&sn=c4988a38efd6555338615d932ce7522e&chksm=eb506d98dc27e48eab55be68da483102bc828704485a5740785afdf7bec525acbafc4697a4a8&scene=21#wechat_redirect) 服务器建立了 1 万个长连接，对于阻塞式 IO 的做法就是，对每一条连接都建立一个线程来处理，那么就需要 1万个线程，同时根据我们的经验对于 IO 密集型的操作我们一般设置，线程数 = 2 * CPU 数量 + 1，对于 CPU 密集型的操作一般设置线程 = CPU 数量 + 1。

当然各种书籍或者网上也有一个详细的计算公式可以算出更加合适准确的线程数量，但是得到的结果往往是一个比较小的值，像阻塞式 IO 这也动则创建成千上万的线程，系统是无法承载这样的负荷的更加弹不上高效的吞吐量和服务了。

而多路复用 IO 模型的做法是，用一个线程将这一万个建立成功的链接陆续的放入 event_poll，event_poll 会为这一万个长连接注册回调函数，当某一个长连接准备就绪后（建立建立成功、数据读取完成等），就会通过回调函数写入到 event_poll 的就绪队列 rdlist 中，这样这个单线程就可以通过读取 rdlist 获取到需要的数据。

需要注意的是，除了异步 IO 外，其它的 I/O 模型其实都可以归类为阻塞式 I/O 模型，不同的是像阻塞式 I/O 模型在第一阶段读取数据的时候，如果此时数据未准备就绪需要阻塞，在第二阶段数据准备就绪后需要将数据从内核态复制到用户态这一步也是阻塞的。而多路复用 IO 模型在第一阶段是不阻塞的，只会在第二阶段阻塞。

通过这种方式，就可以用 1 个或者几个线程来处理大量的连接了，极大的提升了吐吞量

![img](https://img2020.cnblogs.com/other/1218593/202006/1218593-20200622151400164-1783867940.jpg)

**3、事件机制**

[Redis](http://mp.weixin.qq.com/s?__biz=MzI3ODcxMzQzMw==&mid=2247493806&idx=1&sn=c4988a38efd6555338615d932ce7522e&chksm=eb506d98dc27e48eab55be68da483102bc828704485a5740785afdf7bec525acbafc4697a4a8&scene=21#wechat_redirect) 客户端与 [Redis](http://mp.weixin.qq.com/s?__biz=MzI3ODcxMzQzMw==&mid=2247493806&idx=1&sn=c4988a38efd6555338615d932ce7522e&chksm=eb506d98dc27e48eab55be68da483102bc828704485a5740785afdf7bec525acbafc4697a4a8&scene=21#wechat_redirect) 服务端建立连接，发送命令，[Redis](http://mp.weixin.qq.com/s?__biz=MzI3ODcxMzQzMw==&mid=2247493806&idx=1&sn=c4988a38efd6555338615d932ce7522e&chksm=eb506d98dc27e48eab55be68da483102bc828704485a5740785afdf7bec525acbafc4697a4a8&scene=21#wechat_redirect) 服务器响应命令都是需要通过事件机制来做的，如下图

![img](https://img2020.cnblogs.com/other/1218593/202006/1218593-20200622151401508-1134467469.png)

- 首先 redis 服务器运行，监听套接字的 AE_READABLE 事件处于监听的状态下，此时**连接应答处理器**工作
- 客户端与 [Redis](http://mp.weixin.qq.com/s?__biz=MzI3ODcxMzQzMw==&mid=2247493806&idx=1&sn=c4988a38efd6555338615d932ce7522e&chksm=eb506d98dc27e48eab55be68da483102bc828704485a5740785afdf7bec525acbafc4697a4a8&scene=21#wechat_redirect) 服务器发起建立连接，监听套接字产生 AE_READABLE 事件，当 IO 多路复用程序监听到其准备就绪后，将该事件压入队列中，由文件事件分派器获取队列中的事件交于**连接应答处理器**工作处理，应答客户端建立连接成功，同时将客户端 socket 的 AE_READABLE 事件压入队列由文件事件分派器获取队列中的事件交**命令请求处理器关联**
- 客户端发送 set key value 请求，客户端 socket 的 AE_READABLE 事件，当 IO 多路复用程序监听到其准备就绪后，将该事件压入队列中，由文件事件分派器获取队列中的事件交于**命令请求处理器关联**处理
- **命令请求处理器关联**处理完成后，需要响应客户端操作完成，此时将产生 socket 的 AE_WRITEABLE 事件压入队列，由文件事件分派器获取队列中的事件交于**命令恢复处理器**处理，返回操作结果，完成后将解除 AE_WRITEABLE 事件与**命令恢复处理器**的关联

**reactor模式**

大体上可以说 [Redis](http://mp.weixin.qq.com/s?__biz=MzI3ODcxMzQzMw==&mid=2247493806&idx=1&sn=c4988a38efd6555338615d932ce7522e&chksm=eb506d98dc27e48eab55be68da483102bc828704485a5740785afdf7bec525acbafc4697a4a8&scene=21#wechat_redirect) 的工作模式是，reactor 模式配合一个队列，用一个 serverAccept 线程来处理建立请求的链接，并且通过 IO 多路复用模型，让内核来监听这些 socket，一旦某些 socket 的读写事件准备就绪后就对应的事件压入队列中，然后 worker 工作，由文件事件分派器从中获取事件交于对应的处理器去执行，当某个事件执行完成后文件事件分派器才会从队列中获取下一个事件进行处理。

可以类比在 netty 中，我们一般会设置 bossGroup 和 workerGroup 默认情况下 bossGroup 为 1，workerGroup = 2 * cpu 数量，这样可以由多个线程来处理读写就绪的事件，但是其中不能有比较耗时的操作如果有的话需要将其放入线程池中，不然会降低其吐吞量。在 [Redis](http://mp.weixin.qq.com/s?__biz=MzI3ODcxMzQzMw==&mid=2247493806&idx=1&sn=c4988a38efd6555338615d932ce7522e&chksm=eb506d98dc27e48eab55be68da483102bc828704485a5740785afdf7bec525acbafc4697a4a8&scene=21#wechat_redirect) 中我们可以看做这二者的值都是 1。

**为什么说存储的值不宜过大**

比如一个 string key = a，存储了 500MB，首先读取事件压入队列中，文件事件分派器从中获取到后，交于命令请求处理器处理，此处就涉及到从磁盘中加载 500MB。

比如是普通的 SSD 硬盘，读取速度 200MB/S，那么需要 2.5S 的读取时间，在内存中读取数据比较快比如 DDR4 中 50G/秒，读取 500MB 需要 100 毫秒左右。

线程的库一般默认 10 毫秒就算慢查询了，大部分的指令执行时间都是微秒级别，此时其它 socket 所有的请求都将处于等待过程中，就会导致阻塞了 100 毫秒，同时又会占用较大的带宽导致吞吐量进一步下降。