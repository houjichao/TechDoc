## [什么是 IPC](https://wiki.swoole.com/#/learn?id=什么是ipc)

同一台主机上两个进程间通信 (简称 IPC) 的方式有很多种，在 Swoole 下使用了 2 种方式 `Unix Socket` 和 `sysvmsg`，下面分别介绍：

- **Unix Socket**

  全名 UNIX Domain Socket, 简称 `UDS`, 使用套接字的 API (socket，bind，listen，connect，read，write，close 等)，和 TCP/IP 不同的是不需要指定 ip 和 port，而是通过一个文件名来表示 (例如 FPM 和 Nginx 之间的 `/tmp/php-fcgi.sock`)，UDS 是 Linux 内核实现的全内存通信，无任何 `IO` 消耗。在 `1` 进程 `write`，`1` 进程 `read`，每次读写 `1024` 字节数据的测试中，`100` 万次通信仅需 `1.02` 秒，而且功能非常的强大，`Swoole` 下默认用的就是这种 IPC 方式。

  - **`SOCK_STREAM` 和 `SOCK_DGRAM`**

    - `Swoole` 下面使用 `UDS` 通讯有两种类型，`SOCK_STREAM` 和 `SOCK_DGRAM`，可以简单的理解为 TCP 和 UDP 的区别，当使用 `SOCK_STREAM` 类型的时候同样需要考虑 [TCP 数据包边界问题](https://wiki.swoole.com/#/learn?id=tcp数据包边界问题)。
    - 当使用 `SOCK_DGRAM` 类型的时候不需要考虑 TCP 数据包边界问题，每个 `send()` 的数据都是有边界的，发送多大的数据接收的时候就收到多大的数据，没有传输过程中的丢包、乱序问题，`send` 写入和 `recv` 读取的顺序是完全一致的。`send` 返回成功后一定是可以 `recv` 到。

    在 IPC 传输的数据比较小时非常适合用 `SOCK_DGRAM` 这种方式，**由于 `IP` 包每个最大有 64k 的限制，所以用 `SOCK_DGRAM` 进行 IPC 时候单次发送数据不能大于 64k，同时要注意收包速度太慢操作系统缓冲区满了会丢弃包，因为 UDP 是允许丢包的，可以适当调大缓冲区**。

- **sysvmsg**

  即 Linux 提供的`消息队列`，这种 `IPC` 方式通过一个文件名来作为 `key` 进行通讯，这种方式非常的不灵活，实际项目使用的并不多，不做过多介绍。

  - **此种 IPC 方式只有两个场景下有用:**
    - 防止丢数据，如果整个服务都挂掉，再次启动队列中的消息也在，可以继续消费，**但同样有脏数据的问题**。
    - 可以外部投递数据，比如 Swoole 下的 `Worker进程`通过消息队列给 `Task进程`投递任务，第三方的进程也可以投递任务到队列里面让 Task 消费，甚至可以在命令行手动添加消息到队列。

IPC（Inter-Process Communication，进程间通信）是指在不同进程之间进行数据交换和通信的机制。常见的 IPC 方式包括：

1. 管道（Pipe）：一种半双工的通信方式，父子进程可以通过共享文件描述符进行通信。

2. 消息队列（Message Queue）：一种消息传递方式，将消息放到一个队列中，接收方从队列中读取数据。

3. 共享内存（Shared Memory）：多个进程可以访问同一块物理内存，在访问时需要加锁以避免竞争条件。

4. 套接字（Socket）：一种网络通信方式，提供面向连接或无连接的数据传输服务。

5. 信号量（Semaphore）：用于控制对共享资源的访问，实现多个进程间的同步操作。

6. 命名管道（Named Pipe）：类似于管道，但可以由不相关的进程使用，并且具有持久性和路径名称。

7. RPC（Remote Procedure Call）：远程过程调用，允许一个程序在另一个地址空间上执行过程并返回结果。

8. RMI （Remote Method Invocation) ： 远程方法调用 ，与 RPC 类似 ， 但针对对象而非函数 。