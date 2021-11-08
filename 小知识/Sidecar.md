### Sidecar 是什么

将本将属于应用程序的功能拆分成单独的进程，这个进程可以被理解为Sidecar。在微服务体系内，将集成在应用内的微服务功能剥离到了sidecar内，sidecar提供了微服务发现、注册，服务调用，应用认证，限速等功能。



Sidecar 模式是 Service Mesh 中习惯采用的模式

将*应用程序的功能*划分为单独的进程可以被视为 **Sidecar 模式**。如图所示，Sidecar 模式允许您在应用程序旁边添加更多功能，而无需额外第三方组件配置或修改应用程序代码。

![img](https://mosn.io/docs/concept/sidecar-pattern/sidecar-pattern.jpg)



#### 特点:

1. Sidecar为独立部署的进程。
2. sidecar降低应用程序代码和底层代码的耦合度，帮助异构服务通过sidecar快速接入微服务体系。
   

### Sidecar 如何工作

接下来以异构服务为基础介绍sidecar如何工作。

#### Sidecar 代理服务注册发现

下图为异构服务通过sidecar接入注册中心。异构服务本身可能为非Java或传统应用，接入困难。

异构服务本身不会和注册中心有请求调用，而是通过sidecar代理注册接入注册中心，获得服务注册、发现等功能。

![服务注册发现](https://img-blog.csdnimg.cn/20210124202649646.jpg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3N3ZWF0T3R0,size_16,color_FFFFFF,t_70)

#### Sidecar 代理异构服务发起服务调用

异构服务本身不和注册中心有直接联系，所以异构服务的调用也需要走sidecar，通过sidecar进行服务发现调用，sidecar收到异构服务的请求后通过服务发现和负载均衡选中目标服务实例，转发请求至目标服务。

![调用](https://img-blog.csdnimg.cn/20210124202649586.jpg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3N3ZWF0T3R0,size_16,color_FFFFFF,t_70)

#### 异构服务如何被调用

如果异构服务为服务提供方（会被其它服务调用），服务发起方会先注册中心发现sidecar代理注册的实例信息，将请求发送到Sidecar，Sidecar将请求转发给异构服务完成调用请求。

![被调用](https://img-blog.csdnimg.cn/20210124202649553.jpg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3N3ZWF0T3R0,size_16,color_FFFFFF,t_70)