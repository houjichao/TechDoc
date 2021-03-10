### thread

thread命令最主要是用来给我们去排查生产环境的阻塞问题。

```
thread //当前正在运行线程列表
thread -n x//选取最忙的topn
thread -b //找出当前阻塞其他线程的线程
thread -具体的tid //输出线程堆栈
thread -[i <value>]	指定cpu使用率统计的采样间隔，单位为毫秒，默认值为200
thread --state RUNNABLE //过滤部分线程状态
thread [--all]	显示所有匹配的线程
```

一般情况下我们会采用一个采样周期。譬如持续一秒(如果不指定的话就是200ms)的采样，如下：

```
[arthas@74929]$ thread -n 3 -i 1000
"C1 CompilerThread3" [Internal] cpuUsage=0.51% deltaTime=5ms time=6288ms


"arthas-command-execute" Id=413 cpuUsage=0.08% deltaTime=0ms time=1285ms RUNNABLE
    at sun.management.ThreadImpl.dumpThreads0(Native Method)
    at sun.management.ThreadImpl.getThreadInfo(ThreadImpl.java:448)
    at com.taobao.arthas.core.command.monitor200.ThreadCommand.processTopBusyThreads(ThreadCommand.java:199)
    at com.taobao.arthas.core.command.monitor200.ThreadCommand.process(ThreadCommand.java:122)
    at com.taobao.arthas.core.shell.command.impl.AnnotatedCommandImpl.process(AnnotatedCommandImpl.java:82)
    at com.taobao.arthas.core.shell.command.impl.AnnotatedCommandImpl.access$100(AnnotatedCommandImpl.java:18)
    at com.taobao.arthas.core.shell.command.impl.AnnotatedCommandImpl$ProcessHandler.handle(AnnotatedCommandImpl.java:111)
    at com.taobao.arthas.core.shell.command.impl.AnnotatedCommandImpl$ProcessHandler.handle(AnnotatedCommandImpl.java:108)
    at com.taobao.arthas.core.shell.system.impl.ProcessImpl$CommandProcessTask.run(ProcessImpl.java:385)
    at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:511)
    at java.util.concurrent.FutureTask.run$$$capture(FutureTask.java:266)
    at java.util.concurrent.FutureTask.run(FutureTask.java)
    at java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.access$201(ScheduledThreadPoolExecutor.java:180)
    at java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.run(ScheduledThreadPoolExecutor.java:293)
    at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
    at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
    at java.lang.Thread.run(Thread.java:748)


"VM Periodic Task Thread" [Internal] cpuUsage=0.03% deltaTime=0ms time=3092ms
```

关注cpuUsage采样时间内cpu使用率\deltaTime采样时间内cpu时间\time总运行时间

**值得一提，thread -b是用来寻找阻塞线程的利器**

可以很清晰看到阻塞的线程，阻塞的代码位置及lock的对象/类。

**注意，在做压测的时候，有时候锁的粒度会很小，但是依然存在，特别是synchronized锁着的代码执行很快，在压测的时候会表现为吞吐到达一定上不去，但是thread -b由于阻塞的时间短，所以一次抓取不一定能定位到问题，这需要多执行几次看看**

