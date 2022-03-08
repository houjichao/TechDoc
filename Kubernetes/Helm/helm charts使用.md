### 背景：

k8s 部署服务可以采用两种方式
1. 自己编写对应的资源控制yaml ，kubectl apply -f XX .yml部署
2. 使用helm charts的方式部署

### Helm 是什么？

Helm 是 Deis 开发的一个用于 Kubernetes 应用的包管理工具，主要用来管理 Charts。有点类似于 Ubuntu 中的 APT 或 CentOS 中的 YUM。
Helm Chart 是用来封装 Kubernetes 原生应用程序的一系列 YAML 文件。可以在你部署应用的时候自定义应用程序的一些 Metadata，以便于应用程序的分发。
对于应用发布者而言，可以通过 Helm 打包应用、管理应用依赖关系、管理应用版本并发布应用到软件仓库。
对于使用者而言，使用 Helm 后不用需要编写复杂的应用部署文件，可以以简单的方式在 Kubernetes 上查找、安装、升级、回滚、卸载应用程序。

### Helm 组件及相关术语

#### Helm

Helm 是一个命令行下的客户端工具。主要用于 Kubernetes 应用程序 Chart 的创建、打包、发布以及创建和管理本地和远程的 Chart 仓库。

#### Tiller

Tiller 是 Helm 的服务端，部署在 Kubernetes 集群中。Tiller 用于接收 Helm 的请求，并根据 Chart 生成 Kubernetes 的部署文件（ Helm 称为 Release ），然后提交给 Kubernetes 创建应用。Tiller 还提供了 Release 的升级、删除、回滚等一系列功能。

#### Chart

Helm 的软件包，采用 TAR 格式。类似于 APT 的 DEB 包或者 YUM 的 RPM 包，其包含了一组定义 Kubernetes 资源相关的 YAML 文件。

#### Repoistory

Helm 的软件仓库，Repository 本质上是一个 Web 服务器，该服务器保存了一系列的 Chart 软件包以供用户下载，并且提供了一个该 Repository 的 Chart 包的清单文件以供查询。Helm 可以同时管理多个不同的 Repository。

#### Release

使用 helm install 命令在 Kubernetes 集群中部署的 Chart 称为 Release。

### Helm 工作原理

![在这里插入图片描述](https://img-blog.csdnimg.cn/20190905145646376.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3RleHRkZW1vMTIz,size_16,color_FFFFFF,t_70)

Chart Install 过程
Helm 从指定的目录或者 TAR 文件中解析出 Chart 结构信息。
Helm 将指定的 Chart 结构和 Values 信息通过 gRPC 传递给 Tiller。
Tiller 根据 Chart 和 Values 生成一个 Release。
Tiller 将 Release 发送给 Kubernetes 用于生成 Release。
Chart Update 过程
Helm 从指定的目录或者 TAR 文件中解析出 Chart 结构信息。
Helm 将需要更新的 Release 的名称、Chart 结构和 Values 信息传递给 Tiller。
Tiller 生成 Release 并更新指定名称的 Release 的 History。
Tiller 将 Release 发送给 Kubernetes 用于更新 Release。
Chart Rollback 过程
Helm 将要回滚的 Release 的名称传递给 Tiller。
Tiller 根据 Release 的名称查找 History。
Tiller 从 History 中获取上一个 Release。
Tiller 将上一个 Release 发送给 Kubernetes 用于替换当前 Release。
helm使用

#### 1.创建一个空charts

helm create test

![在这里插入图片描述](https://img-blog.csdnimg.cn/20190905150001615.png)

#### 2.编辑charts文件

目录结构如图

![在这里插入图片描述](https://img-blog.csdnimg.cn/20190905150236534.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3RleHRkZW1vMTIz,size_16,color_FFFFFF,t_70)

charts 目录用于存放应用依赖的其他服务，比如DB
Charts.yml 用于编写版本信息
templates 目录是实际的 k8s资源控制部署文件 ，需要注意的是deployment.yaml 文件，需要根据实际情况修改 container的端口, 根据服务性质，比如nginx的80 ，tomcat的8080

![在这里插入图片描述](https://img-blog.csdnimg.cn/20190905150741500.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3RleHRkZW1vMTIz,size_16,color_FFFFFF,t_70)

values.yaml 用于编写整个charts应用的 参数信息 ，比如 image ， service-type ，等可变信息

![在这里插入图片描述](https://img-blog.csdnimg.cn/20190905150955438.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3RleHRkZW1vMTIz,size_16,color_FFFFFF,t_70)

#### 3.测试charts 文件是否正确

![在这里插入图片描述](https://img-blog.csdnimg.cn/2019090515111932.png)

如图就是文件编写正常，可执行下一步

#### 4.打包

![在这里插入图片描述](https://img-blog.csdnimg.cn/20190905151224720.png)

#### 5.推送charts指仓库

推送之前先看一下自己的repo地址，准备往哪个仓库推送

```
helm repo list
```



![在这里插入图片描述](https://img-blog.csdnimg.cn/20190905151320242.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3RleHRkZW1vMTIz,size_16,color_FFFFFF,t_70)

我们当前使用的是本地的harbor ，作为仓库 ，当前推送到library

![在这里插入图片描述](https://img-blog.csdnimg.cn/20190905151532803.png)

#### 6.去harbor上检查

我们发现刚才的test charts已经推送了上来

#### 7.可以使用kubeapps 容器商店 部署，或者可以直接在命令行部署

我们在容器应用商店上查看，已经看到推送过来的charts

#### 8.点击部署即可自动化部署

如果采用命令行如下即可

![在这里插入图片描述](https://img-blog.csdnimg.cn/20190905152004927.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3RleHRkZW1vMTIz,size_16,color_FFFFFF,t_70)

### 总结

helm charts管理使得部署文件版本化管理成为了可能， 方便版本维护，环境升级回退，降低了环境部署的复杂性。