在 ELK Stack 中，日志数据采集有单独的工具，就是 Logstash 和 Beats。

- **Logstash** 主要是用来日志的搜集、分析、过滤日志的工具，支持大量的数据获取方式。一般工作方式为 c/s 架构，client 端安装在需要收集日志的主机上，server 端负责将收到的各节点日志进行过滤、修改等操作在一并发往 Elasticsearch 上去。
- **Beats** 在这里是一个轻量级日志采集器，其实 Beats 家族有 6 个成员，早期的 ELK 架构中使用 Logstash 收集、解析日志，但是 Logstash 对内存、cpu、io 等资源消耗比较高。相比 Logstash，Beats 所占系统的 CPU 和内存几乎可以忽略不计。

目前 Beats 包含六种工具：

- **Packetbeat**： 网络数据（收集网络流量数据）
- **Metricbeat**： 指标（收集系统、进程和文件系统级别的 CPU 和内存使用情况等数据）
- **Filebeat**： 日志文件（收集文件数据）
- **Winlogbeat**： windows 事件日志（收集 Windows 事件日志数据）
- **Auditbeat**：审计数据（收集审计日志）
- **Heartbeat**：运行时间监控（收集系统运行时的数据）

几种部署方式：

- **1. Logstash 日志数据采集，Elasticsearch 存储，Kibana 展示**
- **2. Filebeat 日志数据采集，Elasticsearch 存储，Kibana 展示**
- **3. Filebeat 日志数据采集，Logstash 过滤，Elasticsearch 存储，Kibana 展示**

第三种方案的实现架构图：

![https://img3.sycdn.imooc.com/5afc1f4800018b1211190591.jpg](https://img3.sycdn.imooc.com/5afc1f4800018b1211190591.jpg)



## ELK搭建

使用外国大佬的开源项目，基本不要改什么就可快速搭建一套单机版ELK用于练手。
 **注意**：logstash已被我改造，如果以该项目构建ELK记得更改logstash.conf。
 ELK项目github链接： https://github.com/deviantony/docker-elk

这里对es不做过多描述，主要针对filebeat和logstash讲解。

## 什么是Filebeat

Filebeat是一个轻量级的托运人，用于转发和集中日志数据。Filebeat作为代理安装在服务器上，监视您指定的日志文件或位置，收集日志事件，并将它们转发到Elasticsearch或 Logstash进行索引。
 Filebeat的工作原理：启动Filebeat时，它会启动一个或多个输入，这些输入将查找您为日志数据指定的位置。对于Filebeat找到的每个日志，Filebeat启动一个收集器。每个收集器为新内容读取单个日志，并将新日志数据发送到libbeat，libbeat聚合事件并将聚合数据发送到您为Filebeat配置的输出。
 官方流程图如下:

![img](https://upload-images.jianshu.io/upload_images/15392486-a66fe0b09efa6d13.jpg?imageMogr2/auto-orient/strip|imageView2/2/w/940/format/webp)

## 什么是Logstash

Logstash是一个具有实时流水线功能的开源数据收集引擎。Logstash可以动态统一来自不同来源的数据，并将数据标准化为您选择的目的地。为各种高级下游分析和可视化用例清理和民主化所有数据。
 Logstash的优势：

- Elasticsearch的摄取主力
   水平可扩展的数据处理管道，具有强大的Elasticsearch和Kibana协同作用
- 可插拔管道架构
   混合，匹配和编排不同的输入，过滤器和输出，以便在管道协调中发挥作用
- 社区可扩展和开发人员友好的插件生态系统
   提供超过200个插件，以及创建和贡献自己的灵活性

