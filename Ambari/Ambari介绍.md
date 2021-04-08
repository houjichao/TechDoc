# Ambari简介

## Ambari概述

Apache Ambari是一种基于Web的工具，支持Apache Hadoop集群的创建、管理和监控。Ambari已支持大多数Hadoop组件，包括HDFS、MapReduce、Hive、Pig、 Hbase、Zookeeper、Sqoop和Hcatalog等；除此之外，Ambari还支持Spark、Storm等计算框架及资源调度平台YARN。

Apache Ambari 从集群节点和服务收集大量信息，并把它们表现为容易使用的，集中化的接口：Ambari Web.

Ambari Web显示诸如服务特定的摘要、图表以及警报信息。可通过Ambari Web对Hadoop集群进行创建、管理、监视、添加主机、更新服务配置等；也可以利用Ambari Web执行集群管理任务，例如启用 Kerberos 安全以及执行Stack升级。任何用户都可以查看Ambari Web特性。拥有administrator-level 角色的用户可以访问比 operator-level 或 view-only 的用户能访问的更多选项。例如，Ambari administrator 可以管理集群安全，一个 operator 用户可以监控集群，而 view-only 用户只能访问系统管理员授予他的必要的权限。

# Ambari体系结构

Ambari 自身也是一个分布式架构的软件，主要由两部分组成：Ambari Server 和 Ambari Agent。简单来说，用户通过Ambari Server通知 Ambari Agent 安装对应的软件；Agent 会定时地发送各个机器每个软件模块的状态给 Ambari Server，最终这些状态信息会呈现在 Ambari 的 GUI，方便用户了解到集群的各种状态，并进行相应的维护。

Ambari Server 从整个集群上收集信息。每个主机上都有 Ambari Agent, Ambari Server 通过 Ambari Agent 控制每部主机。

