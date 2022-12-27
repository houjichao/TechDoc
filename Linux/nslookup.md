nslookup简介
nslookup命令用于查询DNS的记录，从而得到该域名的IP地址和其他信息。

nslookup常用命令

#### 1.直接查询（查询一个域名的A记录）

nslookup domain [dns-server]

如果没有指定dns-server，会使用系统默认的dns服务器，举个例子：
```
[root@ /]# nslookup baidu.com          
Server:         10.28.15.254
Address:        10.28.15.254#53

Non-authoritative answer:
Name:   baidu.com
Address: 110.242.68.66
Name:   baidu.com
Address: 39.156.66.10
```

#### 2.查询其他记录

直接查询返回的是A记录，我们可以指定参数，查询其他记录，比如 C name、MX、PTR等

nslookup -qt = type domain  [dns-server]

常用的记录类型如下

A地址记录
AAAA地址记录
C name 别名记录
PTR 反向记录
MX 邮件服务器记录
NS名字服务器记录
TXT 域名对应的文本信息

```
nslookup -qt=MX baidu.com  
*** Invalid option: qt=MX
Server:         10.28.15.254
Address:        10.28.15.254#53

Non-authoritative answer:
Name:   baidu.com
Address: 110.242.68.66
Name:   baidu.com
Address: 39.156.66.10
```

#### **3.指定域名服务器**

在需要查询的域名后面跟上域名服务器的地址

nslookup www.baidu.com 8.8.8.8

