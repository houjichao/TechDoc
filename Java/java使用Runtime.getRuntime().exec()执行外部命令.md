最近需要用java程序做一个linux命令定时执行工具，看来看去java能运行外部linux命令的就只有Runtime.getRuntime().exec()了，只是《深入理解java虚拟机》中138也提道此命令运行过程如下

> 首先克隆一个和当前虚拟机拥有一样的环境变量的进程，再利用这个新的进程去执行外部命令，最后再推出这个进程，如果频繁执行这个操作，系统消耗会很大，不仅是cpu，内存负担也很重

下面是我自己写的springboot程序做的性能测试



```java
    @Bean
    public ThreadPoolExecutor threadPoolTaskScheduler() {
        return new ThreadPoolExecutor(50, 50, 60, TimeUnit.SECONDS, new LinkedBlockingQueue<Runnable>(1000));
    }
```

LinuxApplication启动类加入一个线程池bean，创建了一个核心线程数为50的线程池，用来执行线程



```java
    @Scheduled(cron = "0 * * * * ?")
    public void pingStart() {
        try {
            for (int i = 0; i < 100; i++) {
                threadPoolExecutor.execute(new Runnable() {
                    @Override
                    public void run() {
                        //String[] command = {"ping 192.168.150.144"};//windows测试命令
                        String[] command = {"ping -c 5 -i 0.5 192.168.150.144"};//linux测试命令
                        String result = LinuxExecuteUtils.execute(command);//内部封装Runtime.getRuntime().exec()
                        log.info(result);
                    }
                });
            }
        } catch (Exception e) {
            log.error("主机拨测异常", e);
        }
    }
```

定时任务为一分钟一次，每次往线程池加入100个线程，每个线程执行一样的ping命令，我自己把Runtime.getRuntime().exec()封装在了LinuxExecuteUtils里面，具体代码就不贴了。

首先在windows上测试，程序运行前进程数为77

修改线程池



```java
    @Bean
    public ThreadPoolExecutor threadPoolTaskScheduler() {
        return new ThreadPoolExecutor(5, 5, 60, TimeUnit.SECONDS, new LinkedBlockingQueue<Runnable>(1000));
    }
```

接下来科普一下windows和linux之间的区别

> windows：进程和线程的概念明确，进程对应于运行实例，线程则是程序代码执行的最小单元
>  linux：只有进程而没有线程，利用fork()和exec函数族来操作多线程



那么仅仅因为linux只有进程就能的出结论Runtime.getRuntime().exec()在linux上并不太消耗性能吗？我上文也只是说了好像，程序测试也不是很完美，进程创建总的来说是一件很耗资源的事，能不用就尽量不用，能少用就尽量少用。

最后对于真的要使用Runtime.getRuntime().exec()的可以去[http://commons.apache.org/proper/commons-exec/index.html](https://links.jianshu.com/go?to=http%3A%2F%2Fcommons.apache.org%2Fproper%2Fcommons-exec%2Findex.html)看看，开源社区做了jar包封装了这个命令，做了优化。