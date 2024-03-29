# Linux nc命令

Linux nc命令用于设置路由器。

执行本指令可设置路由器的相关参数。

### nc命令的作用

- 实现任意TCP/UDP端口的侦听，nc可以作为server以TCP或UDP方式侦听指定端口
- 端口的扫描，nc可以作为client发起TCP或UDP连接
- 机器之间传输文件
- 机器之间网络测速

### nc命令的安装

```
yum -y install nmap-ncat
```

### 语法

```
nc [-hlnruz][-g<网关...>][-G<指向器数目>][-i<延迟秒数>][-o<输出文件>][-p<通信端口>][-s<来源位址>][-v...][-w<超时秒数>][主机名称][通信端口...]
```

**参数说明**：

- -g<网关> 设置路由器跃程通信网关，最多可设置8个。
- -G<指向器数目> 设置来源路由指向器，其数值为4的倍数。
- -h 在线帮助。
- -i<延迟秒数> 设置时间间隔，以便传送信息及扫描通信端口。
- -l 使用监听模式，管控传入的资料。用于指定nc将处于侦听模式。指定该参数，则意味着nc被当作server，侦听并接受连接，而非向其它地址发起连接。
- -n 直接使用IP地址，而不通过域名服务器。
- -o<输出文件> 指定文件名称，把往来传输的数据以16进制字码倾倒成该文件保存。
- -p<通信端口> 设置本地主机使用的通信端口。
- -r 乱数指定本地与远端主机的通信端口。
- -s<来源位址> 设置本地主机送出数据包的IP地址。
- -u 使用UDP传输协议，默认是TCP
- -v 显示指令执行过程。输出交互或出错信息，新手调试时尤为有用
- -w<超时秒数> 设置等待连线的时间。
- -z 使用0输入/输出模式，只在扫描通信端口时使用。
- -k<通信端口>  强制 nc 待命链接.当客户端从服务端断开连接后，过一段时间服务端也会停止监听。 但通过选项 -k 我们可以强制服务器保持连接并继续监听端口。

### 实例

TCP端口扫描

```
# nc -v -z -w2 192.168.0.3 1-100 
192.168.0.3: inverse host lookup failed: Unknown host
(UNKNOWN) [192.168.0.3] 80 (http) open
(UNKNOWN) [192.168.0.3] 23 (telnet) open
(UNKNOWN) [192.168.0.3] 22 (ssh) open
```

扫描192.168.0.3 的端口 范围是 1-100

扫描UDP端口

```
# nc -u -z -w2 192.168.0.1 1-1000 //扫描192.168.0.3 的端口 范围是 1-1000
```

扫描指定端口

```
# nc -nvv 192.168.0.1 80 //扫描 80端口
(UNKNOWN) [192.168.0.1] 80 (?) open
y  //用户输入
```

常用命令

```
sh-4.2# nc -l 9999                        # 开启一个本地9999的TCP协议端口，由客户端主动发起连接，一旦连接必须由服务端发起关闭
sh-4.2# nc -vw 2 192.168.21.248 11111     # 通过nc去访问192.168.21.248主机的11111端口，确认是否存活；可不加参数
sh-4.2# nc -ul 9999                       # 开启一个本地9999的UDP协议端口，客户端不需要由服务端主动发起关闭
sh-4.2# nc 192.168.21.248 9999 < test     # 通过192.168.21.248的9999TCP端口发送数据文件
sh-4.2# nc -l 9999 > zabbix.file          # 开启一个本地9999的TCP端口，用来接收文件内容

# 测试网速
A机器操作如下：
sh-4.2# yum install -y dstat      　　　　 # A机器安装dstat命令
sh-4.2# nc -l 9999 > /dev/null

# B机器开启数据传输
nc 10.0.1.161 9999 </dev/zero

# A机器进行网络监控
sh-4.2# dstat

nc -lk 9999 
模拟socket通信
```

