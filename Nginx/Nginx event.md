**events模块中包含nginx中所有处理连接的设置.**

常用配置项如下:

```
events{
    use epoll;
    worker_connections 20000;
    client_header_buffer_size 4k;
    open_file_cache max=2000 inactive=60s;
    open_file_cache_valid 60s;
    open_file_cache_min_uses 1;
｝
```

下面为详细说明

#### use epoll;

#使用epoll的I/O 模型(值得注意的是如果你不知道Nginx该使用哪种轮询方法的话，它会选择一个最适合你操作系统的)

补充说明:

与apache相类，nginx针对不同的操作系统，有不同的事件模型
    A）标准事件模型
    Select、poll属于标准事件模型，如果当前系统不存在更有效的方法，nginx会选择select或poll
    B）高效事件模型
    Kqueue：使用于FreeBSD 4.1+, OpenBSD 2.9+, NetBSD 2.0 和 MacOS X.使用双处理器的MacOS X系统使用kqueue可能会造成内核崩溃。
    Epoll:使用于Linux内核2.6版本及以后的系统。
    /dev/poll：使用于Solaris 7 11/99+, HP/UX 11.22+ (eventport), IRIX 6.5.15+ 和 Tru64 UNIX 5.1A+。
    Eventport：使用于Solaris 10. 为了防止出现内核崩溃的问题， 有必要安装安全补丁

查看linux版本号可以使用 cat /proc/version命令

```
cat /proc/version
```

输出如下

```php
Linux version 2.6.32-504.23.4.el6.x86_64 (mockbuild@c6b9.bsys.dev.centos.org) 
(gcc version 4.4.7 20120313 (Red Hat 4.4.7-11) (GCC) ) 
```

#### **worker_connections 2000;**

\#工作进程的最大连接数量 理论上每台nginx服务器的最大连接数为worker_processes*worker_connections worker_processes为我们再main中开启的进程数

#### keepalive_timeout 60;

#keepalive超时时间。 这里指的是http层面的keep-alive 并非tcp的keepalive  如果想了解详情 请戳这里 http://www.bubuko.com/infodetail-260176.html
里面写的很详细 有兴趣的可以去看一下

#### client_header_buffer_size 4k;

客户端请求头部的缓冲区大小，这个可以根据你的系统分页大小来设置，一般一个请求头的大小不会超过1k，不过由于一般系统分页都要大于1k，所以这里设置为系统分页大小。查看系统分页可以使用 getconf PAGESIZE命令

```
getconf PAGESIZE
```

输出如下：

```
[root@master ~]# getconf PAGESIZE
4096
```

#### open_file_cache max=2000 inactive=60s;

为打开文件指定缓存，默认是没有启用的，max指定缓存最大数量，建议和打开文件数一致，inactive是指经过多长时间文件没被请求后删除缓存 打开文件最大数量为我们再main配置的worker_rlimit_nofile参数

#### **open_file_cache_valid 60s;**

这个是指多长时间检查一次缓存的有效信息。如果有一个文件在inactive时间内一次没被使用，它将被移除

#### **open_file_cache_min_uses 1;**

open_file_cache指令中的inactive参数时间内文件的最少使用次数，如果超过这个数字，文件描述符一直是在缓存中打开的，如果有一个文件在inactive时间内一次没被使用，它将被移除。