硬件资源是服务的基础，我们带代码需要部署在vm（openstack集群、ECS、aws或者google cloud），这类资源需要集中管理，是属于我们的资源和哪资产。同时需要支持跨平台，比如阿里云、腾讯云、aws等。

基础设施即代码，这个在2014年就提出来了，这个概念不单单是自动化，自动化方面我们已经有了Salt，Puppet等，但这些还不够。



```csharp
As a best practice, infrastructure-as-code mandates that whatever work is needed to provision computing resources it must be done via code only.
作为最佳实践，基础设施及代码授权所有准备计算资源所需要做的工作都可以通过代码来完成
```

计算资源包括计算、存储、网络、数据库等等，这意味着我们不需要点击去做部署，而是通过如下方式：

1. 通过特定的格式，json或者其他编排语言来定义所需的资源
2. 存储在代码控制系统
3. pull，测试
4. 执行代码来部署

这类的平台比较多，比如Terraform，Chef，Puppet Ansible，CloudFormation，Salt等等。Terraform是目前比较受欢迎的，支持跨平台，当然选择其他也是可以的。

传统的想法是，Terraform或者cloudFormation等平台提供物理资源，然后使用ansible或者saltstack来配置和部署。但是实际上并不需要如此，ansilbe能做的，terraform也能做。

#### 不可逆的部署

当前我们的做法是服务器和代码分开部署，但是现在的趋势是代码和vm绑定在一起，或者容器中都已经包含了代码，是当做一个整体部署下去，这样就不会有环境的问题。

如果需要修改参数，并不需要在原有vm或docker修改，而是修改配置包，然后直接部署新的vm或docker。

这样做的收益是只需要一份配置，不需要测试环境部署一套，开发环境配置一次，线上环境又是一种，节约人力。

如果要查看log，当然不需要登录服务器去查看，在服务器上可以配置响应的日志组件，将日志上传到集中的日志中心，统一管理，方便之后用elk等分析处理。[aws elk部署参考](https://links.jianshu.com/go?to=https%3A%2F%2Fmedium.com%2F%40devfire%2Fdeploying-the-elk-stack-on-amazon-ecs-dd97d671df06)

心得：学习到了新的概念，下一步则是上手实践下。

