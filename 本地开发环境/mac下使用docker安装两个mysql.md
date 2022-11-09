```
docker search mysql

mysql 的官网仓库为：https://hub.docker.com/_/mysql?tab=tags

docker pull mysql:latest
(如果要拉取其他版本的，可以在官放hub查看版本)


docker run -p 3306:3306 --name mysql8.0 -e MYSQL_ROOT_PASSWORD=1234 -d mysql

指令参数说明：

run：启动docker。
-p 3306:3306：设置操作系统与docker的端口对接，第一个3306是操作系统的端口，用于对完使用；第二个是docker运行MySQL的服务端口3306。
–name mysql8.0：是启动这个docker的容器名字，可以自行命名。
-e MYSQL_ROOT_PASSWORD=1234是设置docker的MySQL的root用户密码。
-d mysql：是镜像名称，如果没有规定MySQL版本，使用mysql默认安装最新版本，如果规定mysql版本，可以加上版本信息，如-d mysql5.7。
如果直接启动docker，而本地还没下载MySQL镜像，docker会默认自动下载MySQL镜像。指令执行完成后，分别输入指令查看当前docker和镜像信息：

docker ps -a
docker images
```

## 修改MySQL加密方式

由于最新版MySQL的加密方式改变了，如果使用Navicat Premium 15等工具连接可能无法连接成功，我们需要对docker里面的MySQL进行修改。
输入`docker exec -it mysql8.0 bash`进入当前docker，其中mysql8.0是这个docker的容器名字，如图所示：

```
mysql -uroot -p1234
use mysql;
alter user 'root'@'%' identified with mysql_native_password by '1234';
select host,user,plugin,authentication_string from mysql.user;
```

最后分别输入两次`exit`退出MySQL和docker。

## 安装第二个MySQL

如果要在同一个操作系统运行多个docker的MySQL，只需在run指令设置参数 - -p 的对完端口即可，比如启动第二个MySQL服务，可执行下面指令：

```
docker run -p 3307:3306 --name mysql8.1 -e MYSQL_ROOT_PASSWORD=1234 -d mysql
```

上述指令参数说明

- -p第一个参数是3307，代表centos8的3307端口，因为3306端口已被第一个docker占用了；第二个参数3306是docker里面MySQL的运行端口，由于每个docker都是独立运行的，因此两个docker都能使用3306。
- 参数–name必须与第一个docker的命名不能相同，否则会有冲突。

启动docker之后，剩下的操作就是修改MySQL的用户密码加密方式，这个操作在上述已有讲述。