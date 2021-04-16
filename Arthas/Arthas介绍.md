### 定位

`Arthas` 是Alibaba开源的Java诊断工具

### Arthas解决的问题

1. 这个类从哪个 jar 包加载的？为什么会报各种类相关的 Exception？
2. 我改的代码为什么没有执行到？难道是我没 commit？分支搞错了？
3. 遇到问题无法在线上 debug，难道只能通过加日志再重新发布吗？
4. 线上遇到某个用户的数据处理有问题，但线上同样无法 debug，线下无法重现！
5. 是否有一个全局视角来查看系统的运行状况？
6. 有什么办法可以监控到JVM的实时运行状态？
7. 怎么快速定位应用的热点，生成火焰图？

`Arthas`支持JDK 6+，支持Linux/Mac/Windows，采用命令行交互模式，同时提供丰富的 `Tab` 自动补全功能，进一步方便进行问题的定位和诊断。



## 快速安装

### 使用`arthas-boot`（推荐）

下载`arthas-boot.jar`，然后用`java -jar`的方式启动：

```
curl -O https://arthas.aliyun.com/arthas-boot.jar
java -jar arthas-boot.jar
```

```
[root@snpt-meta-display-5cc47bff7b-zp64x app]# java -jar arthas-boot.jar
Picked up JAVA_TOOL_OPTIONS:  -Xloggc:/data/tsf_apm/monitor/jvm-metrics/gclog.log 
[INFO] arthas-boot version: 3.5.0
[INFO] Found existing java process, please choose one and input the serial number of the process, eg : 1. Then hit ENTER.
* [1]: 1 snpt-meta_1.0.0-RELEASE.jar
1

输入1，进入java进程
```

