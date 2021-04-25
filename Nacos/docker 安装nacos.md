### 1 docker命令安装单机版Nacos

1. 下载镜像

   ```
   docker search nacos
   
   docker pull nacos/nacos-server
   ```

2. 创建配置文件和日志文件目录

   ```
   mkdir -p /Users/houjichao/Work/Application/nacos/init.d
   mkdir -p /Users/houjichao/Work/Application/nacos/logs
   cd /Users/houjichao/Work/Application/nacos/init.d
   touch custom.properties
   ```

3. 添加配置,暴露metrics数据

   ```
   management.endpoints.web.exposure.include=*
   ```

4. 创建并启动容器（单机模式）,使用默认的Derby数据库

   ```
   docker run -d -p 8848:8848 -e MODE=standalone \
   -v /Users/houjichao/Work/Application/nacos/init.d/custom.properties:/home/nacos/init.d/custom.properties \
   -v /Users/houjichao/Work/Application/nacos/logs/:/home/nacos/logs \
   --restart always \
   --name my-nacos nacos/nacos-server:latest
   ```

5. 访问Nacos控制台

   | 名称   | 值                       |
   | ------ | ------------------------ |
   | 地址   | http://宿主ip:8848/nacos |
   | 用户名 | nacos                    |
   | 密码   | nacos                    |

   

