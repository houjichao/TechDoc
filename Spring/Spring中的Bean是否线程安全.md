其实，Spring中的Bean是否线程安全，其实跟Spring容器本身无关。Spring框架中没有提供线程安全的策略，因此，Spring容器中在的Bean本身也不具备线程安全的特性。咱们要透彻理解这个结论，我们首先要知道Spring中的Bean是从哪里来的。

1、Spring中Bean从哪里来的？
在Spring容器中，除了很多Spring内置的Bean以外，其他的Bean都是我们自己通过Spring配置来声明的，然后，由Spring容器统一加载。我们在Spring声明配置中通常会配置以下内容，如：class（全类名）、id（也就是Bean的唯一标识）、 scope（作用域）以及lazy-init（是否延时加载）等。之后，Spring容器根据配置内容使用对应的策略来创建Bean的实例。因此，Spring容器中的Bean其实都是根据我们自己写的类来创建的实例。因此，Spring中的Bean是否线程安全，跟Spring容器无关，只是交由Spring容器托管而已。
那么，在Spring容器中，什么样的Bean会存在线程安全问题呢？回答，这个问题之前我们得先回顾一下Spring Bean的作用域。在Spring定义的作用域中，其中有 prototype（ 多例Bean ）和 singleton （ 单例Bean）。那么，定义为 prototype 的Bean，是在每次 getBean 的时候都会创建一个新的对象。定义为 singleton 的Bean，在Spring容器中只会存在一个全局共享的实例。基于对以上Spring Bean作用域的理解，下面，我们来分析一下在Spring容器中，什么样的Bean会存在线程安全问题。

2、Spring中什么样的Bean存在线程安全问题？
我们已经知道，多例Bean每次都会新创建新实例，也就是说线程之间不存在Bean共享的问题。因此，多例Bean是不存在线程安全问题的。
而单例Bean是所有线程共享一个实例，因此，就可能会存在线程安全问题。但是单例Bean又分为无状态Bean和有状态Bean。在多线程操作中只会对Bean的成员变量进行查询操作，不会修改成员变量的值，这样的Bean称之为无状态Bean。所以，可想而知，无状态的单例Bean是不存在线程安全问题的。但是，在多线程操作中如果需要对Bean中的成员变量进行数据更新操作，这样的Bean称之为有状态Bean，所以，有状态的单例Bean就可能存在线程安全问题。
所以，最终我们得出结论，在Spring中，只有有状态的单例Bean才会存在线程安全问题。我们在使用Spring的过程中，经常会使用到有状态的单例Bean，如果真正遇到了线程安全问题，我们又该如何处理呢？

3、如何处理Spring Bean的线程安全问题？
处理有状态单例Bean的线程安全问题有以下三种方法：
1、将Bean的作用域由 “singleton” 单例 改为 “prototype” 多例。
2、在Bean对象中避免定义可变的成员变量，当然，这样做不太现实，就当我没说。
3、在类中定义 ThreadLocal 的成员变量，并将需要的可变成员变量保存在 ThreadLocal 中，ThreadLocal 本身就具备线程隔离的特性，这就相当于为每个线程提供了一个独立的变量副本，每个线程只需要操作自己的线程副本变量，从而解决线程安全问题。
都已经看到这里了， 相信大家应该已经知道了 Spring中的Bean是否线程安全以及如何处理Bean的线程安全问题。



**结论：不是线程安全的**

Spring容器中的Bean是否线程安全，容器本身并没有提供Bean的线程安全策略，因此可以说Spring容器中的Bean本身不具备线程安全的特性，但是具体还是要结合具体scope的Bean去研究。

Spring 的 bean 作用域（scope）类型

singleton:单例，默认作用域。prototype:原型，每次创建一个新对象。request:请求，每次Http请求创建一个新对象，适用于WebApplicationContext环境下。session:会话，同一个会话共享一个实例，不同会话使用不用的实例。global-session:全局会话，所有会话共享一个实例。**线程安全这个问题，要从单例与原型Bean分别进行说明。**

**原型Bean**

对于原型Bean,每次创建一个新对象，也就是线程之间并不存在Bean共享，自然是不会有线程安全的问题。

**单例Bean**

对于单例Bean,所有线程都共享一个单例实例Bean,因此是存在资源的竞争。

如果单例Bean,是一个无状态Bean，也就是线程中的操作不会对Bean的成员执行查询以外的操作，那么这个单例Bean是线程安全的。比如Spring mvc 的 Controller、Service、Dao等，这些Bean大多是无状态的，只关注于方法本身。

**spring单例，为什么controller、service和dao确能保证线程安全？**

Spring中的Bean默认是单例模式的，框架并没有对bean进行多线程的封装处理。

实际上大部分时间Bean是无状态的（比如Dao） 所以说在某种程度上来说Bean其实是安全的。

但是如果Bean是有状态的 那就需要开发人员自己来进行线程安全的保证，最简单的办法就是改变bean的作用域 把 "singleton"改为’‘protopyte’ 这样每次请求Bean就相当于是 new Bean() 这样就可以保证线程的安全了。

有状态就是有数据存储功能无状态就是不会保存数据 controller、service和dao层本身并不是线程安全的，只是如果只是调用里面的方法，而且多线程调用一个实例的方法，会在内存中复制变量，这是自己的线程的工作内存，是安全的。

Java虚拟机栈是线程私有的，它的生命周期与线程相同。虚拟机栈描述的是Java方法执行的内存模型：每个方法在执行的同时都会创建一个栈帧用于存储局部变量表、操作数栈、动态链接、方法出口等信息。

局部变量的固有属性之一就是封闭在执行线程中。它们位于执行线程的栈中，其他线程无法访问这个栈。

所以其实任何无状态单例都是线程安全的。

Spring的根本就是通过大量这种单例构建起系统，以事务脚本的方式提供服务。

**首先问@Controller @Service是不是线程安全的？**

答：默认配置下不是的。为啥呢？因为默认情况下@Controller没有加上@Scope，没有加@Scope就是默认值singleton，单例的。意思就是系统只会初始化一次Controller容器，所以每次请求的都是同一个Controller容器，当然是非线程安全的。举个栗子：

![img](https://pics6.baidu.com/feed/d439b6003af33a8715f3e310c0c0953f5243b546.png?token=ca7fbfcfc52d8621a60ac854e3303ac4)

在postman里面发三次请求，结果如下：

![img](https://pics2.baidu.com/feed/adaf2edda3cc7cd9d5a697693f9da438b90e911e.png?token=94c2fcff103c6b868071f84109eae0e4)

说明他不是线程安全的。怎么办呢？可以给他加上上面说的@Scope注解，如下：

![img](https://pics4.baidu.com/feed/a686c9177f3e670937ac44b13d5b1a3af9dc5577.png?token=c5fe64deb14efe9c065fa7bdf18ff074)

这样一来，每个请求都单独创建一个Controller容器，所以各个请求之间是线程安全的，三次请求结果：

![img](https://pics7.baidu.com/feed/09fa513d269759eeab5b47d4b467c6116c22dfcd.png?token=72db9c7637c3cbd47f9c5c4f32ccf20c)

加了@Scope注解多的实例prototype是不是一定就是线程安全的呢？

![img](https://pics2.baidu.com/feed/a71ea8d3fd1f41340acabced238310cdd3c85ec3.png?token=862e37f844bddcef6393973ff2bfa1fb)

看三次请求结果：

![img](https://pics0.baidu.com/feed/5bafa40f4bfbfbede74f1e577d6c7231afc31f22.jpeg?token=63683ba154aa8f1b655906ba4a7bf0b2)

虽然每次都是单独创建一个Controller但是扛不住他变量本身是static的呀，所以说呢，即便是加上@Scope注解也不一定能保证Controller 100%的线程安全。所以是否线程安全在于怎样去定义变量以及Controller的配置。

所以来个全乎一点的实验，代码如下：

![img](https://pics3.baidu.com/feed/728da9773912b31be2dcd3468184b37ddbb4e154.jpeg?token=10d954dca2a0ead59731604eed9028a8)

补充Controller以外的代码：

config里面自己定义的Bean:User

![img](https://pics0.baidu.com/feed/3b87e950352ac65cdbf95fadff6e371691138a97.jpeg?token=598ced8df46633fcc29ba4af0ee67496)

我暂时能想到的定义变量的方法就这么多了，三次http请求结果如下：

![img](https://pics4.baidu.com/feed/35a85edf8db1cb134bca1ac4d8c8d34990584bec.jpeg?token=6f2f0df98dd794cfdb35e85780baf31a)

可以看到，在单例模式下Controller中只有用ThreadLocal封装的变量是线程安全的。为什么这样说呢？我们可以看到3次请求结果里面只有ThreadLocal变量值每次都是从0+1=1的，其他的几个都是累加的，而user对象呢，默认值是0，第二交取值的时候就已经是1了，关键他的hashCode是一样的，说明每次请求调用的都是同一个user对象。

下面将TestController 上的@Scope注解的属性改一下改成多实例的：@Scope(value = "prototype")，其他都不变，再次请求，结果如下：

![img](https://pics1.baidu.com/feed/b8389b504fc2d562a9352a12e18d15e877c66cb7.jpeg?token=387c8de25e7c5baa7b0ab62050c59e4a)

分析这个结果发现，多实例模式下普通变量，取配置的变量还有ThreadLocal变量都是线程安全的，而静态变量和user（看他的hashCode都是一样的）对象中的变量都是非线程安全的。

也就是说尽管TestController 是每次请求的时候都初始化了一个对象，但是静态变量始终是只有一份的，而且这个注入的user对象也是只有一份的。静态变量只有一份这是当然的咯，那么有没有办法让user对象可以每次都new一个新的呢？当然可以：

![img](https://pics4.baidu.com/feed/0ff41bd5ad6eddc4e934159e3f4733fa53663323.jpeg?token=b3ca9d779e0da11ae90058f6623b10bb)

在config里面给这个注入的Bean加上一个相同的注解@Scope(value = "prototype")就可以了，再来请求一下看看：

![img](https://pics2.baidu.com/feed/023b5bb5c9ea15cea453efbab19cbff43b87b263.jpeg?token=0c8d2859c61d370195cd72eae6271aba)

可以看到每次请求的user对象的hashCode都不是一样的，每次赋值前取user中的变量值也都是默认值0。

下面总结一下：

1、在@Controller/@Service等容器中，默认情况下，scope值是单例-singleton的，也是线程不安全的。

2、尽量不要在@Controller/@Service等容器中定义静态变量，不论是单例(singleton)还是多实例(prototype)他都是线程不安全的。

3、默认注入的Bean对象，在不设置scope的时候他也是线程不安全的。

4、一定要定义变量的话，用ThreadLocal来封装，这个是线程安全的