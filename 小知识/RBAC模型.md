RBAC是什么？

[RBAC ](http://www.sojson.com/tag_rbac.html)是基于角色的访问控制（`Role-Based Access Control` ）在[ RBAC ](http://www.sojson.com/tag_rbac.html)中，权限与角色相关联，用户通过成为适当角色的成员而得到这些角色的权限。这就极大地简化了权限的管理。这样管理都是层级相互依赖的，权限赋予给角色，而把角色又赋予用户，这样的权限设计很清楚，管理起来很方便。

# RBAC介绍。

[RBAC ](http://www.sojson.com/tag_rbac.html)认为授权实际上是`Who` 、`What` 、`How` 三元组之间的关系，也就是`Who` 对`What` 进行`How` 的操作，也就是“主体”对“客体”的操作。

**Who：是权限的拥有者或主体（如：User，Role）。**

**What：是操作或对象（operation，object）。**

**How：具体的权限（Privilege,正向授权与负向授权）。**

然后[ RBAC ](http://www.sojson.com/tag_rbac.html)又分为`RBAC0、RBAC1、RBAC2、RBAC3` ，如果你不知道他们有什么区别，你可以百度百科：[百度百科-RBAC](http://baike.baidu.com/link?url=Tg3nxejvD2QVLLkjKa_4XaQoOWSPAVpR1FgHAG_gANcamtN2cYIm1r1irNw9VZ816FBrMEvdoYqwzixqdHd5e_) 估计你看不懂。还是看看我的简单介绍。

我这里结合我的见解，简单的描述下（去掉那么多的废话）。

# RBAC0、RBAC1、RBAC2、RBAC3简单介绍。

- **RBAC0：是RBAC的核心思想。**
- **RBAC1：是把RBAC的角色分层模型。**
- **RBAC2：增加了RBAC的约束模型。**
- **RBAC3：其实是RBAC2 + RBAC1。**

 

# RBAC0，RBAC的核心。

![img](https://cdn.www.sojson.com/file/16-06-16-14-20-00/doc/4401651529)

# RBAC1，基于角色的分层模型

![img](https://cdn.www.sojson.com/file/16-06-16-14-21-23/doc/7029750528)

# RBAC2、是RBAC的约束模型。

![img](https://cdn.www.sojson.com/file/16-06-16-14-22-14/doc/8236905173)

# RBAC3、就是RBAC1+RBAC2

![img](https://cdn.www.sojson.com/file/16-06-16-14-23-00/doc/3299798382)

**估计看完图后，应该稍微清楚一点。**

下面来看个Demo。员工权限设计的模型图，以及对应关系。

![img](https://cdn.www.sojson.com/file/16-06-16-14-25-54/doc/5627410676)

关系图，以及实体设计。

![img](https://cdn.www.sojson.com/file/16-06-16-14-50-29/doc/2800632674)

表设计

![img](https://cdn.www.sojson.com/file/16-06-16-14-48-35/doc/5015616817)

在我们平常的权限系统中，想完全遵循 [RBAC](http://www.sojson.com/tag_rbac.html) 模型是很难的，因为难免系统业务上有一些差异化的业务考量，所以在设计之初，不要太理想，太追求严格的 [RBAC](http://www.sojson.com/tag_rbac.html) 模型设计，因为这样会使得你的系统处处鸡肋，无法拓展。

所以在这里要说明一下， [RBAC](http://www.sojson.com/tag_rbac.html) 是一种模型，是一种思想，是一种核心思想，但是就思想而言，不是要你完全参照，而是你在这个基础之上，融入你自己的思想，赋予你的业务之上，达到适用你的业务。所以要批评一下那些说：“`RBAC`模型是垃圾，按照它思路去执行，结果无法拓展。”之类话语的人。那是你自己不会变通。

言归正传。

背景需求：

需要在`“权限”=>“角色”=>“用户”`之间，在赋予一个特殊的角色“客服”，这个需求比较常见，我一个用户想把我的权限分配到“客服”角色上，然后由几个“客服”去操作对应的业务流程。比如我们的天猫，淘宝商家后天就是如此，当店铺开到一定的规模，那么就会有分工。

A客服：负责打单填写发货单。

B~E客服：负责每天对我们说“亲，您好。祝亲生活愉快！”，也就是和我们沟通交流的客服。

F~H：负责售后。

... ...

那么这些客服也是归属到这个商家下面去。而且每个商家可能都有类似的客服，分工完全靠商家自己去分配管理。

![img](https://cdn.www.sojson.com/file/doc/1454549883)

这样的系统，融合我们的权限控制，关键要看“客服”用户的添加是在哪添加，如果是由客服直接添加，不走我们的统一注册流程，那建议不要融合到上面这一套 权限、角色、用户之间去，而是给用户再多一个绑定，把多个用户绑定到客服下，并且给客服赋予对应的权限。

### 1、权限赋予：

权限赋予是把当前用户的权限拉出来，然后分配的客服可以小于等于当前用户的权限。

### 2、权限加载：

正常的加载权限，当用户登录后，并且第一次使用权限判断的时候， [Shiro](http://www.sojson.com/tag_shiro.html) 会去加载权限。

### 3、权限判断：

走正常用户权限判断，但是数据操作需要判断是不是当前归属的用户的数据，其实这个是属于业务层，就算你不是客服，也是需要判断。

### 4、禁用|启用：

禁用启用，也是正常的用户流程，添加到禁用列表里，如果被禁用，就无法操作任何内容。

 

总之：不要让框框架架来限制你的业务，也不要让你的业务局限于框框架架。但是也不推荐你去改动框框架架，而是基于框框架架做业务封装。