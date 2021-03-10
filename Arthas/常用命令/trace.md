### trace

**trace是整个arthas最核心的命令，trace用的好的话基本可以解决80%的链路问题**

简单的命令：

trace 全路径类名 方法名 参数 正则

常用命令：

trace  *ClassName method '#cost>xxxx'  -n 10  含义是只过滤出耗时大于xxxx毫秒的方法调用，只取前10个

### 参数说明

| 参数名称            | 参数说明                             |
| ------------------- | ------------------------------------ |
| *class-pattern*     | 类名表达式匹配                       |
| *method-pattern*    | 方法名表达式匹配                     |
| *condition-express* | 条件表达式                           |
| [E]                 | 开启正则表达式匹配，默认为通配符匹配 |
| `[n:]`              | 命令执行次数                         |
| `#cost`             | 方法执行耗时                         |

这里重点要说明的是观察表达式，观察表达式的构成主要由 ognl 表达式组成，所以你可以这样写`"{params,returnObj}"`，只要是一个合法的 ognl 表达式，都能被正常支持。

### 注意事项

- `trace` 能方便的帮助你定位和发现因 RT 高而导致的性能问题缺陷，但其每次只能跟踪一级方法的调用链路。

  参考：[Trace命令的实现原理](https://github.com/alibaba/arthas/issues/597)

- 3.3.0 版本后，可以使用动态Trace功能，不断增加新的匹配类，参考下面的示例。

- 目前不支持 `trace java.lang.Thread getName`，参考issue: [#1610](https://github.com/alibaba/arthas/issues/1610) ，考虑到不是非常必要场景，且修复有一定难度，因此当前暂不修复

  

  这里给几个trace跟踪问题的常规图跟说明

  ![image.png](https://cdn.nlark.com/yuque/0/2021/png/264028/1610196934462-6647efb5-1c6e-4d39-b26e-4b5f0f3995fa.png?x-oss-process=image%2Fresize%2Cw_1500)

  这个是最简单的图。根据树形展开，我们只需要整体最长耗时的地方即可

  实际上在实践过程中，除了上面那种简单的链路以外，还会遇到以下几种典型的链路，分别对应几种方法

  ![image.png](https://cdn.nlark.com/yuque/0/2021/png/264028/1610198335402-9624cf8d-da5f-4008-933a-9e97e759dd70.png?x-oss-process=image%2Fresize%2Cw_746)



像上面这种树状图，可以看到耗时莫名在顶层链路增加，一般这种情况，要看下上下文堆栈，常见的有两种原因可能导致：

1、用了aop的方式，中间拦截对类做了增强，这时候要通过代码找到对应增强类

2、像jdk本身的代码，输出是会自动过滤的，这时候要通过  --skipJDKMethod false 的参数把jdk输出打开，举个例子：

```
public void echo() throws InterruptedException {
        Long time = System.currentTimeMillis();
        for (int i=0;i<1_000_0; i++) {
            Thread.sleep(1L);
            log.info("abcd-----------------------");
        }
        System.out.println(System.currentTimeMillis()-time);
    }
```

像这个代码。正常输出：

```
[arthas@87318]$ trace  com.hjc.learn.controller.WebFluxController commonHandle  '#cost>100'
Press Q or Ctrl+C to abort.
Affect(class count: 1 , method count: 1) cost in 74 ms, listenerId: 6
```



如果加上--skipJDKMethod false

```
[arthas@87878]$ trace --skipJDKMethod false  com.hjc.learn.controller.WebFluxController commonHandle  '#cost>100'
Press Q or Ctrl+C to abort.
Affect(class count: 1 , method count: 1) cost in 71 ms, listenerId: 9
`---ts=2021-03-10 19:49:20;thread_name=http-nio-9100-exec-5;id=164;is_daemon=true;priority=5;TCCL=org.springframework.boot.web.embedded.tomcat.TomcatEmbeddedWebappClassLoader@69b3886f
    `---[12018.641214ms] com.hjc.learn.controller.WebFluxController:commonHandle()
        +---[0.019811ms] java.lang.System:currentTimeMillis() #26
        +---[min=0.067352ms,max=0.220145ms,total=0.287497ms,count=2] org.slf4j.Logger:info() #57
        +---[12018.109059ms] com.hjc.learn.controller.WebFluxController:doThing() #28
        `---[0.012281ms] java.lang.System:currentTimeMillis() #29
```

能够把整体耗时都打印出来

***trace因为本身成本比较高，所以不支持连续的下钻功能，如果需要的话可以通过正则匹配达到这个效果 -E 类1|类2；另外就是通过telnet arthas进程，通过相同的listenerId 进行join下钻。

