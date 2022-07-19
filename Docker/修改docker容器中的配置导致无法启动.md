### 问题

我在windows系统中编写了my.cnf，然后通过xftp上传到Linux服务器，接着把这个配置文件挂载到docker中，mysql就是一直Restarting，也就是启动不成功。无法进入进入容器。之前弄不明白，没办法只能删除容器。
现在经过一定的积累，知道怎么去解决问题了。
首先，问题的细节在于：windows平台下和linux平台下文件内容格式不同。windows下的配置文件不能直接上传到linux系统上，否则不成功。

### 解决办法：

在Linux中执行.sh脚本，异常/bin/sh^M: bad interpreter: No such file or directory。

分析：这是不同系统编码格式引起的：在windows系统中编辑的.sh文件可能有不可见字符，所以在Linux系统下执行会报以上异常信息。

解决：1）在windows下转换：
如果是 Notepad++ 则是在： 编辑 -> EOL Conversion -> 转换为 UNIX 格式 中。

然后将配置文件拷贝到容器中，或者直接挂载：

```
Docker 在容器内修改配置文件后，重启后，使用ps查看却没有起来。
查看错误信息发现是刚刚修改的配置文件出错，但是想通过exec 命令 却进入不了容器。
这时候就用到了 container cp 命令
使用 docker start -i 【容器】，获得出错信息，找到错误文件位置
使用 docker container cp 容器名:容器内修改的文件路径（中间冒号必须） 本地路径 。将文件拷贝到本地（此命令需要高权）。拷贝到本地后，把配置文件修改成为正确的。
使用docker container cp 本地路径 容器名:容器内修改的文件路径（中间冒号必须）。这条命令将修改好的文件覆盖到容器内。
重新docker start 容器，容器成功运行
```