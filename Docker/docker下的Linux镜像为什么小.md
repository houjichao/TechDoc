首先要明白，典型的Linux文件系统由**bootfs**和**rootfs**两部分组成
1. **bootfs**(boot file system)主要包含 bootloader（引导加载程序）和kernel（内核空间），bootloader主要是引导加载kernel，kernel被加载到内存中后 bootfs就被umount了
2. **rootfs** (root file system) :root文件系统，包含的就是典型的Linux系统中的/dev, /proc, /bin, /etc等标准目录和文件

3.不同的Linux发行版本，bootfs基本一样，而rootfs不同，如Ubuntu，centos等

内核空间是kernel,Linux刚启动时会加载bootfs文件系统，之后bootf会被卸载掉，
用户空间的文件系统是rootfs,包含常见的目录，如/dev、/proc、/bin、/etc等等
不同的Linux发行版本(红帽，centos，ubuntu等)主要的区别是rootfs, 多个Linux发行版本的kernel差别不大。
因此通过docker pull centos命令下载镜像，实质上下载centos操作系统的rootfs，所以docker下载的镜像大小只有200M。

### Docker镜像原理

（1）Docker镜像是由系统的文件系统叠加而成。

（2）最低端是bootfs，并使用宿主机的bootfs，docker中操作系统启动几秒钟，而实际安装一个操作系统需要几十分钟，原因就是，通过docker镜像启动的操作系统，底层使用的是docker宿主机的bootfs不需要重新加载bootfs。

（3）第二层是root文件系统rootfs称为base image。

（4）然后可以再往上叠加其它镜像文件，docker镜像分层构建的好处是：已经下载过的镜像文件可以被后面需要下载的镜像复用，e.g.比如已下载完成Tomcat镜像如下图，在在下载NGINX镜像的时候，基础镜像已经存在不需要再下载。

（5）统一文件系统（Union File System）技术能够将不同的层整合成一个文件系统，为这些层提供了统一的视角，这样就隐藏了多层的存在在用户的角度来看，只存在一个文件系统。

（6）一个镜像可以放在另一个镜像的上面。位于下面的镜像称为父镜像，最底部的镜像称为基础镜像。

（7）当从一个镜像启动容器时，docker会在最顶层加载一个读写文件系统作为容器，下图中的只读镜像不支持修改，如果用户想修改一个镜像的话，可以通过可读写的容器构建一个镜像。

![img](https://img-blog.csdnimg.cn/20200621231743148.jpeg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQwNjAxNjAz,size_16,color_FFFFFF,t_70)

![img](https://img-blog.csdnimg.cn/20200621231743150.jpeg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQwNjAxNjAz,size_16,color_FFFFFF,t_70)

Docker容器是建立在Aufs基础上的，Aufs（以前称之为Another Union FS，后来绝不不够高大上，更名为Advanced Union FS）是一种Union FS， 简单来说就是支持将不同的目录挂载到同一个虚拟文件系统下，并实现一种layer的概念。Aufs将挂载到同一虚拟文件系统下的多个目录分别设置成read-only，read-write以及whiteout-able权限，对read-only目录只能读，而写操作只能实施在read-write目录中。重点在于，写操作是在read-only上的一种增量操作，不影响read-only目录。当挂载目录的时候要严格按照各目录之间的这种增量关系，将被增量操作的目录优先于在它基础上增量操作的目录挂载，待所有目录挂载结束了，继续挂载一个read-write目录，如此便形成了一种层次结构。





alpine