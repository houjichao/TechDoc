### 1 Java Flight Recorder是啥

### 1.1 简介

Java Flight Recorder简称JFR，OpenJDK从11版本开始支持。它是一个低开销的数据收集框架，可用于在生产环境中分析Java应用和JVM运行状况及性能问题。

### 1.2 JFR的背景

故障诊断、监控和profile收集分析是开发周期中不可缺少的一部分。但是很多问题都只会在高负载的生产环境中产生。此时就需要一个可以在生产环境中使用的监控工具，JFR由此而生。

JFR会从应用程序中记录运行时事件，同时也会记录JVM和OS的。记录的结果会存在一个单独的文件中，此文件可供开发工程师分析bug和性能问题。

同时JDK中也提供了可视化工具来分析这类文件。

### 1.3 详述

JFR在JEP：167的Event-based JVM Tracing的基础上做了扩展。JEP167只将event简单的输出到stdout，而JFR提供了更高性能的基于二进制格式的event输出。

JFR在JDK中相关的模块如下：

```text
jdk.jfr 
    * API and internals
    * Requires only java.base (suitable for resource constrained devices)

jdk.management.jfr
    * JMX capabilities
    * Requires jdk.jfr and jdk.management
```

JFR有如下两种启动方式

*增加JVM参数：-XX:StartFlightRecording*

通过jcmd工具使用，用例如下：

\* jcmd JFR.start ：开始记录

\* jcmd JFR.dump filename=recording.jfr ：将记录文件dump下来

\* jcmd JFR.stop ：停止

dump下来的jfr文件可以通过jmc来分析。

### 1.4 通过jcmd转储JFR文件



![img](https://pic3.zhimg.com/80/v2-5714af11859c6b5737edf382a7155caa_720w.jpg)



就是下面这个文件了

![img](https://pic1.zhimg.com/80/v2-22020eb793d902e7cca7a07a78993990_720w.png)



### 2 通过jmc分析jfr

JDK11中已经移除了jmc工具包，从JDK11的what's new可以看出：



![img](https://pic2.zhimg.com/80/v2-820f8793551bfd2fcbd244cf2187b1e1_720w.png)



但是，跑在JDK11上的应用程序，dump出来的jfr用jmc6及以前的版本都是打不开的，需要最新的jcm7才能打开：



![img](https://pic4.zhimg.com/80/v2-8d70007c6e4a5469de1616368295f0db_720w.jpg)



经过各种google，最终发现，目前还无法直接下载jmc7的二进制版，但可以自行build。build方式如下：

> [https://github.com/JDKMissionControl/jmc](https://link.zhihu.com/?target=https%3A//github.com/JDKMissionControl/jmc)

编译完成后，打开jmc，加载jfr文件，就可以看到下面的界面了。

![img](https://pic4.zhimg.com/80/v2-8906b7dfc357f7b434425f5e3afca12b_720w.jpg)



### 3 参考

- [JDK Documents - JEP 328: Flight Recorder](https://link.zhihu.com/?target=https%3A//openjdk.java.net/jeps/328)
- [JDK11 - Introduction to JDK Flight Recorder（Video）](https://link.zhihu.com/?target=https%3A//www.youtube.com/watch%3Fv%3D_69wTZR6lis)
- [Java Mission Control - Now serving OpenJDK binaries too!](https://link.zhihu.com/?target=https%3A//blogs.oracle.com/java-platform-group/java-mission-control-now-serving-openjdk-binaries-too)
- [JMC 7 Early-Access Builds](https://link.zhihu.com/?target=https%3A//jdk.java.net/jmc/)
- [GitHub: JDKMissionControl/jmc](https://link.zhihu.com/?target=https%3A//github.com/JDKMissionControl/jmc)
- [OpenJDK Wiki: jmc main](https://link.zhihu.com/?target=https%3A//wiki.openjdk.java.net/display/jmc/Main)
- [jmc7 log](https://link.zhihu.com/?target=http%3A//hg.openjdk.java.net/jmc/jmc7/)
- [Fetching and Building OpenJDK Mission Control](https://link.zhihu.com/?target=http%3A//hirt.se/blog/%3Fp%3D947)