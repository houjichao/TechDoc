# 通过源码理解Spring中@Scheduled的实现原理并且实现调度任务动态装载

## 前提

最近的新项目和数据同步相关，有定时调度的需求。之前一直有使用过`Quartz`、`XXL-Job`、`Easy Scheduler`等调度框架，后来越发觉得这些框架太重量级了，于是想到了`Spring`内置的`Scheduling`模块。而原生的`Scheduling`模块只是内存态的调度模块，不支持任务的持久化或者配置（配置任务通过`@Scheduled`注解进行硬编码，不能抽离到类之外），因此考虑理解`Scheduling`模块的底层原理，并且基于此造一个简单的轮子，使之支持调度任务配置：通过配置文件或者`JDBC`数据源。

## Scheduling模块

`Scheduling`模块是`spring-context`依赖下的一个包`org.springframework.scheduling`：

[![img](https://throwable-blog-1256189093.cos.ap-guangzhou.myqcloud.com/202004/s-b-s-f-1.png)](https://throwable-blog-1256189093.cos.ap-guangzhou.myqcloud.com/202004/s-b-s-f-1.png)

这个模块的类并不多，有四个子包：

- 顶层包的定义了一些通用接口和异常。
- `org.springframework.scheduling.annotation`：定义了调度、异步任务相关的注解和解析类，常用的注解如`@Async`、`@EnableAsync`、`@EnableScheduling`和`@Scheduled`。
- `org.springframework.scheduling.concurrent`：定义了调度任务执行器和相对应的`FactoryBean`。
- `org.springframework.scheduling.config`：定义了配置解析、任务具体实现类、调度任务`XML`配置文件解析相关的解析类。
- `org.springframework.scheduling.support`：定义了反射支持类、`Cron`表达式解析器等工具类。

如果想单独使用`Scheduling`，只需要引入`spring-context`这个依赖。但是现在流行使用`SpringBoot`，引入`spring-boot-starter-web`已经集成了`spring-context`，可以直接使用`Scheduling`模块，笔者编写本文的时候（`2020-03-14`）`SpringBoot`的最新版本为`2.2.5.RELEASE`，可以选用此版本进行源码分析或者生产应用：

```xml
<properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <maven.compiler.source>1.8</maven.compiler.source>
    <maven.compiler.target>1.8</maven.compiler.target>
    <spring.boot.version>2.2.5.RELEASE</spring.boot.version>
</properties>
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-dependencies</artifactId>
            <version>${spring.boot.version}</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
</dependencies>
```

开启`Scheduling`模块支持只需要在某一个配置类中添加`@EnableScheduling`注解即可，一般为了明确模块的引入，建议在启动类中使用此注解，如：

```java
@EnableScheduling
@SpringBootApplication
public class App {

    public static void main(String[] args) {
        SpringApplication.run(App.class, args);
    }
}
```

## Scheduling模块的工作流程[#](https://www.cnblogs.com/throwable/p/12616945.html#scheduling模块的工作流程)

[![img](https://throwable-blog-1256189093.cos.ap-guangzhou.myqcloud.com/202004/s-b-s-f-2.png)](https://throwable-blog-1256189093.cos.ap-guangzhou.myqcloud.com/202004/s-b-s-f-2.png)

这个图描述了`Scheduling`模块的工作流程，这里分析一下非`XML`配置下的流程（右边的分支）：

- 通过注解`@EnableScheduling`中的`@Import`引入了`SchedulingConfiguration`，而`SchedulingConfiguration`中配置了一个类型为`ScheduledAnnotationBeanPostProcessor`名称为`org.springframework.context.annotation.internalScheduledAnnotationProcessor`的`Bean`，这里有个常见的技巧，`Spring`内部加载的`Bean`一般会定义名称为`internalXXX`，`Bean`的`role`会定义为`ROLE_INFRASTRUCTURE = 2`。
- `Bean`后置处理器`ScheduledAnnotationBeanPostProcessor`会解析和处理每一个符合特定类型的`Bean`中的`@Scheduled`注解（注意`@Scheduled`只能使用在方法或者注解上），并且把解析完成的方法封装为不同类型的`Task`实例，缓存在`ScheduledTaskRegistrar`中的。
- `ScheduledAnnotationBeanPostProcessor`中的钩子接口方法`afterSingletonsInstantiated()`在所有单例初始化完成之后回调触发，在此方法中设置了`ScheduledTaskRegistrar`中的任务调度器（`TaskScheduler`或者`ScheduledExecutorService`类型）实例，并且调用`ScheduledTaskRegistrar#afterPropertiesSet()`方法添加所有缓存的`Task`实例到任务调度器中执行。

### 任务调度器[#](https://www.cnblogs.com/throwable/p/12616945.html#任务调度器)

`Scheduling`模块支持`TaskScheduler`或者`ScheduledExecutorService`类型的任务调度器，而`ScheduledExecutorService`其实是`JDK`并发包`java.util.concurrent`的接口，一般实现类就是调度线程池`ScheduledThreadPoolExecutor`。实际上，`ScheduledExecutorService`类型的实例最终会通过**适配器模式**转变为`ConcurrentTaskScheduler`，所以这里只需要分析`TaskScheduler`类型的执行器。

- `ThreadPoolTaskScheduler`：基于线程池实现的任务执行器，这个是最常用的实现，底层依赖于`ScheduledThreadPoolExecutor`实现。
- `ConcurrentTaskScheduler`：`TaskScheduler`接口和`ScheduledExecutorService`接口的适配器，如果自定义一个`ScheduledThreadPoolExecutor`类型的`Bean`，那么任务执行器就会适配为`ConcurrentTaskScheduler`。
- `DefaultManagedTaskScheduler`：`JDK7`引入的`JSR-236`的支持，可以通过`JNDI`配置此调度执行器，一般很少用到，底层也是依赖于`ScheduledThreadPoolExecutor`实现。

也就是说，内置的三个调度器类型底层都依赖于`JUC`调度线程池`ScheduledThreadPoolExecutor`。这里分析一下顶层接口`org.springframework.scheduling.TaskScheduler`提供的功能（笔者已经把功能一致的`default`方法暂时移除）：

```java
// 省略一些功能一致的default方法
public interface TaskScheduler {
     
     // 调度一个任务，通过触发器实例指定触发时间周期
     ScheduledFuture<?> schedule(Runnable task, Trigger trigger);
     
     // 指定起始时间调度一个任务 - 单次执行
     ScheduledFuture<?> schedule(Runnable task, Date startTime);

     // 指定固定频率调度一个任务，period的单位是毫秒
     ScheduledFuture<?> scheduleAtFixedRate(Runnable task, long period);
     
     // 指定起始时间和固定频率调度一个任务，period的单位是毫秒
     ScheduledFuture<?> scheduleAtFixedRate(Runnable task, Date startTime, long period);

     // 指定固定延迟间隔调度一个任务，delay的单位是毫秒
     ScheduledFuture<?> scheduleWithFixedDelay(Runnable task, long delay);

    // 指定起始时间和固定延迟间隔调度一个任务，delay的单位是毫秒
     ScheduledFuture<?> scheduleWithFixedDelay(Runnable task, Date startTime, long delay);
}
```

### Task的分类[#](https://www.cnblogs.com/throwable/p/12616945.html#task的分类)

`Scheduling`模块中支持不同类型的任务，主要包括下面的3种（解析的优先顺序也是如下）：

1. `Cron`表达式任务，支持通过`Cron`表达式配置执行的周期，对应的任务类型为`org.springframework.scheduling.config.CronTask`。
2. 固定延迟间隔任务，也就是上一轮执行完毕后间隔固定周期再执行本轮，依次类推，对应的的任务类型为`org.springframework.scheduling.config.FixedDelayTask`。
3. 固定频率任务，基于固定的间隔时间执行，**不会理会上一轮是否执行完毕本轮会照样执行**，对应的的任务类型为`org.springframework.scheduling.config.FixedRateTask`。

关于这几类`Task`，举几个简单的例子。`CronTask`是通过`cron`表达式指定执行周期的，并且**不支持延迟执行**，可以使用特殊字符`-`禁用任务执行：

```java
// 注解声明式使用 - 每五秒执行一次，不支持initialDelay
@Scheduled(cron = "*/5 * * * * ?")
public void processTask(){

}

// 注解声明式使用 - 禁止任务执行
@Scheduled(cron = "-")
public void processTask(){

}

// 编程式使用
public class Tasks {

    static DateTimeFormatter F = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    public static void main(String[] args) throws Exception {
        ThreadPoolTaskScheduler taskScheduler = new ThreadPoolTaskScheduler();
        taskScheduler.setPoolSize(10);
        taskScheduler.initialize();
        CronTask cronTask = new CronTask(() -> {
            System.out.println(String.format("[%s] - CronTask触发...", F.format(LocalDateTime.now())));
        }, "*/5 * * * * ?");
        taskScheduler.schedule(cronTask.getRunnable(),cronTask.getTrigger());
        Thread.sleep(Integer.MAX_VALUE);
    }
}
// 某次执行输出结果
[2020-03-16 01:07:00] - CronTask触发...
[2020-03-16 01:07:05] - CronTask触发...
......
```

`FixedDelayTask`需要配置延迟间隔值（`fixedDelay`或者`fixedDelayString`）和可选的起始延迟执行时间（`initialDelay`或者`initialDelayString`），这里注意一点是`fixedDelayString`和`initialDelayString`都支持从`EmbeddedValueResolver`（简单理解为配置文件的属性处理器）读取和`Duration`（例如`P2D`就是`parses as 2 days`，表示86400秒）支持格式的解析：

```java
// 注解声明式使用 - 延迟一秒开始执行，延迟间隔为5秒
@Scheduled(fixedDelay = 5000, initialDelay = 1000)
public void process(){
        
}

// 注解声明式使用 - spring-boot配置文件中process.task.fixedDelay=5000  process.task.initialDelay=1000
@Scheduled(fixedDelayString = "${process.task.fixedDelay}", initialDelayString = "${process.task.initialDelay}")
public void process(){
        
}

// 编程式使用
public class Tasks {

    static DateTimeFormatter F = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    public static void main(String[] args) throws Exception {
        ThreadPoolTaskScheduler taskScheduler = new ThreadPoolTaskScheduler();
        taskScheduler.setPoolSize(10);
        taskScheduler.initialize();
        FixedDelayTask fixedDelayTask = new FixedDelayTask(() -> {
            System.out.println(String.format("[%s] - FixedDelayTask触发...", F.format(LocalDateTime.now())));
        }, 5000, 1000);
        Date startTime = new Date(System.currentTimeMillis() + fixedDelayTask.getInitialDelay());
        taskScheduler.scheduleWithFixedDelay(fixedDelayTask.getRunnable(), startTime, fixedDelayTask.getInterval());
        Thread.sleep(Integer.MAX_VALUE);
    }
}
// 某次执行输出结果
[2020-03-16 01:06:12] - FixedDelayTask触发...
[2020-03-16 01:06:17] - FixedDelayTask触发...
......
```

`FixedRateTask`需要配置固定间隔值（`fixedRate`或者`fixedRateString`）和可选的起始延迟执行时间（`initialDelay`或者`initialDelayString`），这里注意一点是`fixedRateString`和`initialDelayString`都支持从`EmbeddedValueResolver`（简单理解为配置文件的属性处理器）读取和`Duration`（例如`P2D`就是`parses as 2 days`，表示86400秒）支持格式的解析：

```java
// 注解声明式使用 - 延迟一秒开始执行，每隔5秒执行一次
@Scheduled(fixedRate = 5000, initialDelay = 1000)
public void processTask(){

}

// 注解声明式使用 - spring-boot配置文件中process.task.fixedRate=5000  process.task.initialDelay=1000
@Scheduled(fixedRateString = "${process.task.fixedRate}", initialDelayString = "${process.task.initialDelay}")
public void process(){
        
}

// 编程式使用
public class Tasks {

    static DateTimeFormatter F = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    public static void main(String[] args) throws Exception {
        ThreadPoolTaskScheduler taskScheduler = new ThreadPoolTaskScheduler();
        taskScheduler.setPoolSize(10);
        taskScheduler.initialize();
        FixedRateTask fixedRateTask = new FixedRateTask(() -> {
            System.out.println(String.format("[%s] - FixedRateTask触发...", F.format(LocalDateTime.now())));
        }, 5000, 1000);
        Date startTime = new Date(System.currentTimeMillis() + fixedRateTask.getInitialDelay());
        taskScheduler.scheduleAtFixedRate(fixedRateTask.getRunnable(), startTime, fixedRateTask.getInterval());
        Thread.sleep(Integer.MAX_VALUE);
    }
}
// 某次执行输出结果
[2020-03-16 23:58:25] - FixedRateTask触发...
[2020-03-16 23:58:30] - FixedRateTask触发...
......
```

### 简单分析核心流程的源代码[#](https://www.cnblogs.com/throwable/p/12616945.html#简单分析核心流程的源代码)

在`SpringBoot`注解体系下，`Scheduling`模块的所有逻辑基本在`ScheduledAnnotationBeanPostProcessor`和`ScheduledTaskRegistrar`中。一般来说，一个类实现的接口代表了它能提供的功能，先看`ScheduledAnnotationBeanPostProcessor`实现的接口：

- `ScheduledTaskHolder`接口：返回`Set<ScheduledTask>`，表示持有的所有任务实例。
- `MergedBeanDefinitionPostProcessor`接口：`Bean`定义合并时回调，预留空实现，暂时不做任何处理。
- `BeanPostProcessor`接口：也就是`MergedBeanDefinitionPostProcessor`的父接口，`Bean`实例初始化前后分别回调，其中，后回调的`postProcessAfterInitialization()`方法就是用于解析`@Scheduled`和装载`ScheduledTask`，需要重点关注此方法的逻辑。
- `DestructionAwareBeanPostProcessor`接口：具体的`Bean`实例销毁的时候回调，用于`Bean`实例销毁的时候移除和取消对应的任务实例。
- `Ordered`接口：用于`Bean`加载时候的排序，主要是改变`ScheduledAnnotationBeanPostProcessor`在`BeanPostProcessor`执行链中的顺序。
- `EmbeddedValueResolverAware`接口：回调`StringValueResolver`实例，用于解析带占位符的环境变量属性值。
- `BeanNameAware`接口：回调`BeanName`。
- `BeanFactoryAware`接口：回调`BeanFactory`实例，具体是`DefaultListableBeanFactory`，也就是熟知的`IOC`容器。
- `ApplicationContextAware`接口：回调`ApplicationContext`实例，也就是熟知的`Spring`上下文，它是`IOC`容器的门面，同时是事件广播器、资源加载器的实现等等。
- `SmartInitializingSingleton`接口：所有单例实例化完毕之后回调，作用是在持有的`applicationContext`为`NULL`的时候开始调度所有加载完成的任务，这个钩子接口十分有用，笔者常用它做一些资源初始化工作。
- `ApplicationListener`接口：监听`Spring`应用的事件，具体是`ApplicationListener<ContextRefreshedEvent>`，监听上下文刷新的事件，如果事件中携带的`ApplicationContext`实例和`ApplicationContextAware`回调的`ApplicationContext`实例一致，那么在此监听回调方法中开始调度所有加载完成的任务，也就是在`ScheduledAnnotationBeanPostProcessor`这个类中，`SmartInitializingSingleton`接口的实现和`ApplicationListener`接口的实现逻辑是**互斥**的。
- `DisposableBean`接口：当前`Bean`实例销毁时候回调，也就是`ScheduledAnnotationBeanPostProcessor`自身被销毁的时候回调，用于取消和清理所有的`ScheduledTask`。

**上面分析的钩子接口在SpringBoot体系中可以按需使用，了解回调不同钩子接口的回调时机，可以在特定时机完成达到理想的效果。**

`@Scheduled`注解的解析集中在`postProcessAfterInitialization()`方法：

```java
public Object postProcessAfterInitialization(Object bean, String beanName) {
    // 忽略AopInfrastructureBean、TaskScheduler和ScheduledExecutorService三种类型的Bean
    if (bean instanceof AopInfrastructureBean || bean instanceof TaskScheduler ||
            bean instanceof ScheduledExecutorService) {
        // Ignore AOP infrastructure such as scoped proxies.
        return bean;
    }
    // 获取Bean的用户态类型，例如Bean有可能被CGLIB增强，这个时候要取其父类
    Class<?> targetClass = AopProxyUtils.ultimateTargetClass(bean);
    // nonAnnotatedClasses存放着不存在@Scheduled注解的类型，缓存起来避免重复判断它是否携带@Scheduled注解的方法
    if (!this.nonAnnotatedClasses.contains(targetClass) &&
            AnnotationUtils.isCandidateClass(targetClass, Arrays.asList(Scheduled.class, Schedules.class))) {
        // 因为JDK8之后支持重复注解，因此获取具体类型中Method -> @Scheduled的集合，也就是有可能一个方法使用多个@Scheduled注解，最终会封装为多个Task
        Map<Method, Set<Scheduled>> annotatedMethods = MethodIntrospector.selectMethods(targetClass,
                (MethodIntrospector.MetadataLookup<Set<Scheduled>>) method -> {
                    Set<Scheduled> scheduledMethods = AnnotatedElementUtils.getMergedRepeatableAnnotations(
                            method, Scheduled.class, Schedules.class);
                    return (!scheduledMethods.isEmpty() ? scheduledMethods : null);
                });
        // 解析到类型中不存在@Scheduled注解的方法添加到nonAnnotatedClasses缓存
        if (annotatedMethods.isEmpty()) {
            this.nonAnnotatedClasses.add(targetClass);
            if (logger.isTraceEnabled()) {
                logger.trace("No @Scheduled annotations found on bean class: " + targetClass);
            }
        }
        else {
            // Method -> @Scheduled的集合遍历processScheduled()方法进行登记
            annotatedMethods.forEach((method, scheduledMethods) ->
                    scheduledMethods.forEach(scheduled -> processScheduled(scheduled, method, bean)));
            if (logger.isTraceEnabled()) {
                logger.trace(annotatedMethods.size() + " @Scheduled methods processed on bean '" + beanName +
                        "': " + annotatedMethods);
            }
        }
    }
    return bean;
}
```

`processScheduled(Scheduled scheduled, Method method, Object bean)`就是具体的注解解析和`Task`封装的方法：

```java
// Runnable适配器 - 用于反射调用具体的方法，触发任务方法执行
public class ScheduledMethodRunnable implements Runnable {

	private final Object target;

	private final Method method;

	public ScheduledMethodRunnable(Object target, Method method) {
		this.target = target;
		this.method = method;
	}
        ....// 省略无关代码

        // 这个就是最终的任务方法执行的核心方法，抑制修饰符，然后反射调用
	@Override
	public void run() {
		try {
			ReflectionUtils.makeAccessible(this.method);
			this.method.invoke(this.target);
		}
		catch (InvocationTargetException ex) {
			ReflectionUtils.rethrowRuntimeException(ex.getTargetException());
		}
		catch (IllegalAccessException ex) {
			throw new UndeclaredThrowableException(ex);
		}
	}    
}

// 通过方法所在Bean实例和方法封装Runnable适配器ScheduledMethodRunnable实例
protected Runnable createRunnable(Object target, Method method) {
	Assert.isTrue(method.getParameterCount() == 0, "Only no-arg methods may be annotated with @Scheduled");
	Method invocableMethod = AopUtils.selectInvocableMethod(method, target.getClass());
	return new ScheduledMethodRunnable(target, invocableMethod);
}


// 这个方法十分长，不过逻辑并不复杂，它只做了四件事
// 0. 解析@Scheduled中的initialDelay、initialDelayString属性，适用于FixedDelayTask或者FixedRateTask的延迟执行
// 1. 优先解析@Scheduled中的cron属性，封装为CronTask，通过ScheduledTaskRegistrar进行缓存
// 2. 解析@Scheduled中的fixedDelay、fixedDelayString属性，封装为FixedDelayTask，通过ScheduledTaskRegistrar进行缓存
// 3. 解析@Scheduled中的fixedRate、fixedRateString属性，封装为FixedRateTask，通过ScheduledTaskRegistrar进行缓存
protected void processScheduled(Scheduled scheduled, Method method, Object bean) {
    try {
        // 通过方法宿主Bean和目标方法封装Runnable适配器ScheduledMethodRunnable实例
        Runnable runnable = createRunnable(bean, method);
        boolean processedSchedule = false;
        String errorMessage =
                "Exactly one of the 'cron', 'fixedDelay(String)', or 'fixedRate(String)' attributes is required";
        
        // 缓存已经装载的任务
        Set<ScheduledTask> tasks = new LinkedHashSet<>(4);

        // Determine initial delay
        // 解析初始化延迟执行时间，initialDelayString支持占位符配置，如果initialDelayString配置了，会覆盖initialDelay的值
        long initialDelay = scheduled.initialDelay();
        String initialDelayString = scheduled.initialDelayString();
        if (StringUtils.hasText(initialDelayString)) {
            Assert.isTrue(initialDelay < 0, "Specify 'initialDelay' or 'initialDelayString', not both");
            if (this.embeddedValueResolver != null) {
                initialDelayString = this.embeddedValueResolver.resolveStringValue(initialDelayString);
            }
            if (StringUtils.hasLength(initialDelayString)) {
                try {
                    initialDelay = parseDelayAsLong(initialDelayString);
                }
                catch (RuntimeException ex) {
                    throw new IllegalArgumentException(
                            "Invalid initialDelayString value \"" + initialDelayString + "\" - cannot parse into long");
                }
            }
        }

        // Check cron expression
        // 解析时区zone的值，支持支持占位符配置，判断cron是否存在，存在则装载为CronTask
        String cron = scheduled.cron();
        if (StringUtils.hasText(cron)) {
            String zone = scheduled.zone();
            if (this.embeddedValueResolver != null) {
                cron = this.embeddedValueResolver.resolveStringValue(cron);
                zone = this.embeddedValueResolver.resolveStringValue(zone);
            }
            if (StringUtils.hasLength(cron)) {
                Assert.isTrue(initialDelay == -1, "'initialDelay' not supported for cron triggers");
                processedSchedule = true;
                if (!Scheduled.CRON_DISABLED.equals(cron)) {
                    TimeZone timeZone;
                    if (StringUtils.hasText(zone)) {
                        timeZone = StringUtils.parseTimeZoneString(zone);
                    }
                    else {
                        timeZone = TimeZone.getDefault();
                    }
                    // 此方法虽然表面上是调度CronTask，实际上由于ScheduledTaskRegistrar不持有TaskScheduler，只是把任务添加到它的缓存中
                    // 返回的任务实例添加到宿主Bean的缓存中，然后最后会放入宿主Bean -> List<ScheduledTask>映射中
                    tasks.add(this.registrar.scheduleCronTask(new CronTask(runnable, new CronTrigger(cron, timeZone))));
                }
            }
        }

        // At this point we don't need to differentiate between initial delay set or not anymore
        // 修正小于0的初始化延迟执行时间值为0
        if (initialDelay < 0) {
            initialDelay = 0;
        }

        // 解析fixedDelay和fixedDelayString，如果同时配置，fixedDelayString最终解析出来的整数值会覆盖fixedDelay，封装为FixedDelayTask
        long fixedDelay = scheduled.fixedDelay();
        if (fixedDelay >= 0) {
            Assert.isTrue(!processedSchedule, errorMessage);
            processedSchedule = true;
            tasks.add(this.registrar.scheduleFixedDelayTask(new FixedDelayTask(runnable, fixedDelay, initialDelay)));
        }
        String fixedDelayString = scheduled.fixedDelayString();
        if (StringUtils.hasText(fixedDelayString)) {
            if (this.embeddedValueResolver != null) {
                fixedDelayString = this.embeddedValueResolver.resolveStringValue(fixedDelayString);
            }
            if (StringUtils.hasLength(fixedDelayString)) {
                Assert.isTrue(!processedSchedule, errorMessage);
                processedSchedule = true;
                try {
                    fixedDelay = parseDelayAsLong(fixedDelayString);
                }
                catch (RuntimeException ex) {
                    throw new IllegalArgumentException(
                            "Invalid fixedDelayString value \"" + fixedDelayString + "\" - cannot parse into long");
                }
                // 此方法虽然表面上是调度FixedDelayTask，实际上由于ScheduledTaskRegistrar不持有TaskScheduler，只是把任务添加到它的缓存中
                // 返回的任务实例添加到宿主Bean的缓存中，然后最后会放入宿主Bean -> List<ScheduledTask>映射中
                tasks.add(this.registrar.scheduleFixedDelayTask(new FixedDelayTask(runnable, fixedDelay, initialDelay)));
            }
        }

        // 解析fixedRate和fixedRateString，如果同时配置，fixedRateString最终解析出来的整数值会覆盖fixedRate，封装为FixedRateTask
        long fixedRate = scheduled.fixedRate();
        if (fixedRate >= 0) {
            Assert.isTrue(!processedSchedule, errorMessage);
            processedSchedule = true;
            tasks.add(this.registrar.scheduleFixedRateTask(new FixedRateTask(runnable, fixedRate, initialDelay)));
        }
        String fixedRateString = scheduled.fixedRateString();
        if (StringUtils.hasText(fixedRateString)) {
            if (this.embeddedValueResolver != null) {
                fixedRateString = this.embeddedValueResolver.resolveStringValue(fixedRateString);
            }
            if (StringUtils.hasLength(fixedRateString)) {
                Assert.isTrue(!processedSchedule, errorMessage);
                processedSchedule = true;
                try {
                    fixedRate = parseDelayAsLong(fixedRateString);
                }
                catch (RuntimeException ex) {
                    throw new IllegalArgumentException(
                            "Invalid fixedRateString value \"" + fixedRateString + "\" - cannot parse into long");
                }
                 // 此方法虽然表面上是调度FixedRateTask，实际上由于ScheduledTaskRegistrar不持有TaskScheduler，只是把任务添加到它的缓存中
                // 返回的任务实例添加到宿主Bean的缓存中，然后最后会放入宿主Bean -> List<ScheduledTask>映射中
                tasks.add(this.registrar.scheduleFixedRateTask(new FixedRateTask(runnable, fixedRate, initialDelay)));
            }
        }

        // Check whether we had any attribute set
        Assert.isTrue(processedSchedule, errorMessage);

        // Finally register the scheduled tasks
        synchronized (this.scheduledTasks) {
            // 注册所有任务实例，这个映射Key为宿主Bean实例，Value为List<ScheduledTask>，后面用于调度所有注册完成的任务
            Set<ScheduledTask> regTasks = this.scheduledTasks.computeIfAbsent(bean, key -> new LinkedHashSet<>(4));
            regTasks.addAll(tasks);
        }
    }
    catch (IllegalArgumentException ex) {
        throw new IllegalStateException(
                "Encountered invalid @Scheduled method '" + method.getName() + "': " + ex.getMessage());
    }
}
```

总的来说，这个方法做了四件事：

- 解析`@Scheduled`中的`initialDelay`、`initialDelayString`属性，适用于`FixedDelayTask`或者`FixedRateTask`的延迟执行。
- 优先解析`@Scheduled`中的`cron`属性，封装为`CronTask`，通过`ScheduledTaskRegistrar`进行缓存。
- 解析`@Scheduled`中的`fixedDelay`、`fixedDelayString`属性，封装为`FixedDelayTask`，通过`ScheduledTaskRegistrar`进行缓存。
- 解析`@Scheduled`中的`fixedRate`、`fixedRateString`属性，封装为`FixedRateTask`，通过`ScheduledTaskRegistrar`进行缓存。

`@Scheduled`修饰的某个方法如果同时配置了`cron`、`fixedDelay|fixedDelayString`和`fixedRate|fixedRateString`属性，意味着此方法同时封装为三种任务`CronTask`、`FixedDelayTask`和`FixedRateTask`。解析`xxString`值的使用，用到了`EmbeddedValueResolver`解析字符串的值，支持占位符，这样可以直接获取环境配置中的占位符属性（基于`SPEL`的特性，甚至可以支持嵌套占位符）。解析成功的所有任务实例存放在`ScheduledAnnotationBeanPostProcessor`的一个映射`scheduledTasks`中：

```java
// 宿主Bean实例 -> 解析完成的任务实例Set
private final Map<Object, Set<ScheduledTask>> scheduledTasks = new IdentityHashMap<>(16);
```

解析和缓存工作完成之后，接着分析最终激活所有调度任务的逻辑，见互斥方法`afterSingletonsInstantiated()`和`onApplicationEvent()`，两者中**一定只有一个方法**能够调用`finishRegistration()`：

```java
// 所有单例实例化完毕之后回调
public void afterSingletonsInstantiated() {
    // Remove resolved singleton classes from cache
    this.nonAnnotatedClasses.clear();

    if (this.applicationContext == null) {
        // Not running in an ApplicationContext -> register tasks early...
        finishRegistration();
    }
}

// 上下文刷新完成之后回调
@Override
public void onApplicationEvent(ContextRefreshedEvent event) {
    if (event.getApplicationContext() == this.applicationContext) {
        // Running in an ApplicationContext -> register tasks this late...
        // giving other ContextRefreshedEvent listeners a chance to perform
        // their work at the same time (e.g. Spring Batch's job registration).
        finishRegistration();
    }
}

// 
private void finishRegistration() {
    // 如果持有的scheduler对象不为null则设置ScheduledTaskRegistrar中的任务调度器
    if (this.scheduler != null) {
        this.registrar.setScheduler(this.scheduler);
    }
    // 这个判断一般会成立，得到的BeanFactory就是DefaultListableBeanFactory
    if (this.beanFactory instanceof ListableBeanFactory) {
        // 获取所有的调度配置器SchedulingConfigurer实例，并且都回调configureTasks()方法，这个很重要，它是用户动态装载调取任务的扩展钩子接口
        Map<String, SchedulingConfigurer> beans = ((ListableBeanFactory) this.beanFactory).getBeansOfType(SchedulingConfigurer.class);
        List<SchedulingConfigurer> configurers = new ArrayList<>(beans.values());
        // SchedulingConfigurer实例列表排序
        AnnotationAwareOrderComparator.sort(configurers);
        for (SchedulingConfigurer configurer : configurers) {
            configurer.configureTasks(this.registrar);
        }
    }
    // 下面这一大段逻辑都是为了从BeanFactory取出任务调度器实例，主要判断TaskScheduler或者ScheduledExecutorService类型的Bean，包括尝试通过类型或者名字获取
    // 获取成功后设置到ScheduledTaskRegistrar中
    if (this.registrar.hasTasks() && this.registrar.getScheduler() == null) {
        Assert.state(this.beanFactory != null, "BeanFactory must be set to find scheduler by type");
        try {
            // Search for TaskScheduler bean...
            this.registrar.setTaskScheduler(resolveSchedulerBean(this.beanFactory, TaskScheduler.class, false));
        }
        catch (NoUniqueBeanDefinitionException ex) {
            logger.trace("Could not find unique TaskScheduler bean", ex);
            try {
                this.registrar.setTaskScheduler(resolveSchedulerBean(this.beanFactory, TaskScheduler.class, true));
            }
            catch (NoSuchBeanDefinitionException ex2) {
                if (logger.isInfoEnabled()) {
                    logger.info("More than one TaskScheduler bean exists within the context, and " +
                            "none is named 'taskScheduler'. Mark one of them as primary or name it 'taskScheduler' " +
                            "(possibly as an alias); or implement the SchedulingConfigurer interface and call " +
                            "ScheduledTaskRegistrar#setScheduler explicitly within the configureTasks() callback: " +
                            ex.getBeanNamesFound());
                }
            }
        }
        catch (NoSuchBeanDefinitionException ex) {
            logger.trace("Could not find default TaskScheduler bean", ex);
            // Search for ScheduledExecutorService bean next...
            try {
                this.registrar.setScheduler(resolveSchedulerBean(this.beanFactory, ScheduledExecutorService.class, false));
            }
            catch (NoUniqueBeanDefinitionException ex2) {
                logger.trace("Could not find unique ScheduledExecutorService bean", ex2);
                try {
                    this.registrar.setScheduler(resolveSchedulerBean(this.beanFactory, ScheduledExecutorService.class, true));
                }
                catch (NoSuchBeanDefinitionException ex3) {
                    if (logger.isInfoEnabled()) {
                        logger.info("More than one ScheduledExecutorService bean exists within the context, and " +
                                "none is named 'taskScheduler'. Mark one of them as primary or name it 'taskScheduler' " +
                                "(possibly as an alias); or implement the SchedulingConfigurer interface and call " +
                                "ScheduledTaskRegistrar#setScheduler explicitly within the configureTasks() callback: " +
                                ex2.getBeanNamesFound());
                    }
                }
            }
            catch (NoSuchBeanDefinitionException ex2) {
                logger.trace("Could not find default ScheduledExecutorService bean", ex2);
                // Giving up -> falling back to default scheduler within the registrar...
                logger.info("No TaskScheduler/ScheduledExecutorService bean found for scheduled processing");
            }
        }
    }
    // 调用ScheduledTaskRegistrar的afterPropertiesSet()方法，装载所有的调度任务
    this.registrar.afterPropertiesSet();
}

public class ScheduledTaskRegistrar implements ScheduledTaskHolder, InitializingBean, DisposableBean {

    // 省略其他代码.........

    @Override
    public void afterPropertiesSet() {
        scheduleTasks();
    }

    // 装载所有调度任务
    @SuppressWarnings("deprecation")
    protected void scheduleTasks() {
        // 这里注意一点，如果找不到任务调度器实例，那么会用单个线程调度所有任务
        if (this.taskScheduler == null) {
            this.localExecutor = Executors.newSingleThreadScheduledExecutor();
            this.taskScheduler = new ConcurrentTaskScheduler(this.localExecutor);
        }
        // 调度所有装载完毕的自定义触发器的任务实例
        if (this.triggerTasks != null) {
            for (TriggerTask task : this.triggerTasks) {
                addScheduledTask(scheduleTriggerTask(task));
            }
        }
        // 调度所有装载完毕的CronTask
        if (this.cronTasks != null) {
            for (CronTask task : this.cronTasks) {
                addScheduledTask(scheduleCronTask(task));
            }
        }
        // 调度所有装载完毕的FixedRateTask
        if (this.fixedRateTasks != null) {
            for (IntervalTask task : this.fixedRateTasks) {
                addScheduledTask(scheduleFixedRateTask(task));
            }
        }
        // 调度所有装载完毕的FixedDelayTask
        if (this.fixedDelayTasks != null) {
            for (IntervalTask task : this.fixedDelayTasks) {
                addScheduledTask(scheduleFixedDelayTask(task));
            }
        }
    }   

    // 省略其他代码......... 
}
```

注意两个个问题：

- 如果没有配置`TaskScheduler`或者`ScheduledExecutorService`类型的`Bean`，那么调度模块**只会创建一个线程**去调度所有装载完毕的任务，如果任务比较多，执行密度比较大，很有可能会造成大量任务饥饿，表现为存在部分任务不会触发调度的场景（这个是调度模块生产中经常遇到的故障，需要重点排查是否没有设置`TaskScheduler`或者`ScheduledExecutorService`）。
- `SchedulingConfigurer`是调度模块提供给使用的进行扩展的钩子接口，用于在激活所有调度任务之前回调`ScheduledTaskRegistrar`实例，只要拿到`ScheduledTaskRegistrar`实例，我们就可以使用它注册和装载新的`Task`。

## 调度任务动态装载[#](https://www.cnblogs.com/throwable/p/12616945.html#调度任务动态装载)

`Scheduling`模块本身已经支持基于`NamespaceHandler`支持通过`XML`文件配置调度任务，但是笔者一直认为`XML`给人的感觉太"重"，使用起来显得太笨重，这里打算扩展出`JSON`文件配置和基于`JDBC`数据源配置（也就是持久化任务，这里选用`MySQL`）。根据前文的源码分析，需要用到`SchedulingConfigurer`接口的实现，用于在所有调度任务触发之前从外部添加自定义的调度任务。先定义调度任务的一些配置属性类：

```java
// 调度任务类型枚举
@Getter
@RequiredArgsConstructor
public enum  ScheduleTaskType {

    CRON("CRON"),

    FIXED_DELAY("FIXED_DELAY"),

    FIXED_RATE("FIXED_RATE"),

    ;

    private final String type;
}

// 调度任务配置,enable属性为全局开关
@Data
public class ScheduleTaskProperties {

    private Long version;
    private Boolean enable;
    private List<ScheduleTasks> tasks;
}

// 调度任务集合,笔者设计的时候采用一个宿主类中每个独立方法都是一个任务实例的模式
@Data
public class ScheduleTasks {
    
    // 这里故意叫Klass代表Class,避免关键字冲突
    private String taskHostKlass;
    private Boolean enable;
    private List<ScheduleTaskMethod> taskMethods;
}

// 调度任务方法 - enable为任务开关，没有配置会被ScheduleTaskProperties或者ScheduleTasks中的enable覆盖
@Data
public class ScheduleTaskMethod {

    private Boolean enable;
    private String taskDescription;
    private String taskMethod;
    // 时区,cron的计算需要用到
    private String timeZone;
    private String cronExpression;
    private String intervalMilliseconds;
    private String initialDelayMilliseconds;
}
```

设计的时候，考虑到多个任务执行方法可以放在同一个宿主类，这样可以方便同一种类的任务进行统一管理，如：

```java
public class TaskHostClass {

    public void task1() {

    }

    public void task2() {
        
    }

    ......

    public void taskN() {
        
    }
}
```

细节方面，`intervalMilliseconds`和`initialDelayMilliseconds`的单位设计为毫秒，使用字符串形式，方便可以基于`StringValueResolver`解析配置文件中的属性配置。添加一个抽象的`SchedulingConfigurer`：

```java
@Slf4j
public abstract class AbstractSchedulingConfigurer implements SchedulingConfigurer, InitializingBean, BeanFactoryAware,
        EmbeddedValueResolverAware {

    @Getter
    private StringValueResolver embeddedValueResolver;

    private ConfigurableBeanFactory configurableBeanFactory;

    private final List<InternalTaskProperties> internalTasks = Lists.newLinkedList();

    private final Set<String> tasksLoaded = Sets.newHashSet();

    @Override
    public void setBeanFactory(BeanFactory beanFactory) throws BeansException {
        configurableBeanFactory = (ConfigurableBeanFactory) beanFactory;
    }

    @Override
    public void afterPropertiesSet() throws Exception {
        internalTasks.clear();
        internalTasks.addAll(loadTaskProperties());
    }

    @Override
    public void setEmbeddedValueResolver(StringValueResolver resolver) {
        embeddedValueResolver = resolver;
    }

    @Override
    public void configureTasks(ScheduledTaskRegistrar taskRegistrar) {
        for (InternalTaskProperties task : internalTasks) {
            try {
                synchronized (tasksLoaded) {
                    String key = task.taskHostKlass() + "#" + task.taskMethod();
                    // 避免重复加载
                    if (!tasksLoaded.contains(key)) {
                        if (task instanceof CronTaskProperties) {
                            loadCronTask((CronTaskProperties) task, taskRegistrar);
                        }
                        if (task instanceof FixedDelayTaskProperties) {
                            loadFixedDelayTask((FixedDelayTaskProperties) task, taskRegistrar);
                        }
                        if (task instanceof FixedRateTaskProperties) {
                            loadFixedRateTask((FixedRateTaskProperties) task, taskRegistrar);
                        }
                        tasksLoaded.add(key);
                    } else {
                        log.info("调度任务已经装载,任务宿主类:{},任务执行方法:{}", task.taskHostKlass(), task.taskMethod());
                    }
                }
            } catch (Exception e) {
                throw new IllegalStateException(String.format("加载调度任务异常,任务宿主类:%s,任务执行方法:%s",
                        task.taskHostKlass(), task.taskMethod()), e);
            }
        }
    }

    private ScheduledMethodRunnable loadScheduledMethodRunnable(String taskHostKlass, String taskMethod) throws Exception {
        Class<?> klass = ClassUtils.forName(taskHostKlass, null);
        Object target = configurableBeanFactory.getBean(klass);
        Method method = ReflectionUtils.findMethod(klass, taskMethod);
        if (null == method) {
            throw new IllegalArgumentException(String.format("找不到目标方法,任务宿主类:%s,任务执行方法:%s", taskHostKlass, taskMethod));
        }
        Method invocableMethod = AopUtils.selectInvocableMethod(method, target.getClass());
        return new ScheduledMethodRunnable(target, invocableMethod);
    }

    private void loadCronTask(CronTaskProperties pops, ScheduledTaskRegistrar taskRegistrar) throws Exception {
        ScheduledMethodRunnable runnable = loadScheduledMethodRunnable(pops.taskHostKlass(), pops.taskMethod());
        String cronExpression = embeddedValueResolver.resolveStringValue(pops.cronExpression());
        if (null != cronExpression) {
            String timeZoneString = embeddedValueResolver.resolveStringValue(pops.timeZone());
            TimeZone timeZone;
            if (null != timeZoneString) {
                timeZone = TimeZone.getTimeZone(timeZoneString);
            } else {
                timeZone = TimeZone.getDefault();
            }
            CronTask cronTask = new CronTask(runnable, new CronTrigger(cronExpression, timeZone));
            taskRegistrar.addCronTask(cronTask);
            log.info("装载CronTask[{}#{}()]成功,cron表达式:{},任务描述:{}", cronExpression, pops.taskMethod(),
                    pops.cronExpression(), pops.taskDescription());
        }
    }

    private void loadFixedDelayTask(FixedDelayTaskProperties pops, ScheduledTaskRegistrar taskRegistrar) throws Exception {
        ScheduledMethodRunnable runnable = loadScheduledMethodRunnable(pops.taskHostKlass(), pops.taskMethod());
        long fixedDelayMilliseconds = parseDelayAsLong(embeddedValueResolver.resolveStringValue(pops.intervalMilliseconds()));
        long initialDelayMilliseconds = parseDelayAsLong(embeddedValueResolver.resolveStringValue(pops.initialDelayMilliseconds()));
        FixedDelayTask fixedDelayTask = new FixedDelayTask(runnable, fixedDelayMilliseconds, initialDelayMilliseconds);
        taskRegistrar.addFixedDelayTask(fixedDelayTask);
        log.info("装载FixedDelayTask[{}#{}()]成功,固定延迟间隔:{} ms,初始延迟执行时间:{} ms,任务描述:{}", pops.taskHostKlass(),
                pops.taskMethod(), fixedDelayMilliseconds, initialDelayMilliseconds, pops.taskDescription());
    }

    private void loadFixedRateTask(FixedRateTaskProperties pops, ScheduledTaskRegistrar taskRegistrar) throws Exception {
        ScheduledMethodRunnable runnable = loadScheduledMethodRunnable(pops.taskHostKlass(), pops.taskMethod());
        long fixedRateMilliseconds = parseDelayAsLong(embeddedValueResolver.resolveStringValue(pops.intervalMilliseconds()));
        long initialDelayMilliseconds = parseDelayAsLong(embeddedValueResolver.resolveStringValue(pops.initialDelayMilliseconds()));
        FixedRateTask fixedRateTask = new FixedRateTask(runnable, fixedRateMilliseconds, initialDelayMilliseconds);
        taskRegistrar.addFixedRateTask(fixedRateTask);
        log.info("装载FixedRateTask[{}#{}()]成功,固定执行频率:{} ms,初始延迟执行时间:{} ms,任务描述:{}", pops.taskHostKlass(),
                pops.taskMethod(), fixedRateMilliseconds, initialDelayMilliseconds, pops.taskDescription());
    }

    private long parseDelayAsLong(String value) {
        if (null == value) {
            return 0L;
        }
        if (value.length() > 1 && (isP(value.charAt(0)) || isP(value.charAt(1)))) {
            return Duration.parse(value).toMillis();
        }
        return Long.parseLong(value);
    }

    private boolean isP(char ch) {
        return (ch == 'P' || ch == 'p');
    }

    /**
     * 加载任务配置,预留给子类实现
     */
    protected abstract List<InternalTaskProperties> loadTaskProperties() throws Exception;

    interface InternalTaskProperties {

        String taskHostKlass();

        String taskMethod();

        String taskDescription();
    }

    @Builder
    protected static class CronTaskProperties implements InternalTaskProperties {

        private String taskHostKlass;
        private String taskMethod;
        private String cronExpression;
        private String taskDescription;
        private String timeZone;

        @Override
        public String taskDescription() {
            return taskDescription;
        }

        public String cronExpression() {
            return cronExpression;
        }

        public String timeZone() {
            return timeZone;
        }

        @Override
        public String taskHostKlass() {
            return taskHostKlass;
        }

        @Override
        public String taskMethod() {
            return taskMethod;
        }
    }

    @Builder
    protected static class FixedDelayTaskProperties implements InternalTaskProperties {

        private String taskHostKlass;
        private String taskMethod;
        private String intervalMilliseconds;
        private String initialDelayMilliseconds;
        private String taskDescription;

        @Override
        public String taskDescription() {
            return taskDescription;
        }

        public String initialDelayMilliseconds() {
            return initialDelayMilliseconds;
        }

        public String intervalMilliseconds() {
            return intervalMilliseconds;
        }

        @Override
        public String taskHostKlass() {
            return taskHostKlass;
        }

        @Override
        public String taskMethod() {
            return taskMethod;
        }
    }

    @Builder
    protected static class FixedRateTaskProperties implements InternalTaskProperties {

        private String taskHostKlass;
        private String taskMethod;
        private String intervalMilliseconds;
        private String initialDelayMilliseconds;
        private String taskDescription;

        @Override
        public String taskDescription() {
            return taskDescription;
        }

        public String initialDelayMilliseconds() {
            return initialDelayMilliseconds;
        }

        public String intervalMilliseconds() {
            return intervalMilliseconds;
        }

        @Override
        public String taskHostKlass() {
            return taskHostKlass;
        }

        @Override
        public String taskMethod() {
            return taskMethod;
        }
    }
}
```

`loadTaskProperties()`方法用于加载任务配置，留给子类实现。

### JSON配置[#](https://www.cnblogs.com/throwable/p/12616945.html#json配置)

`JSON`配置文件的格式如下（类路径下的`scheduling/tasks.json`文件）：

```json
{
  "version": 1,
  "tasks": [
    {
      "taskKlass": "club.throwable.schedule.Tasks",
      "taskMethods": [
        {
          "taskType": "FIXED_DELAY",
          "taskDescription": "processTask1任务",
          "taskMethod": "processTask1",
          "intervalMilliseconds": "5000"
        }
      ]
    }
  ]
}
```

每个层级都有一个`enable`属性，默认为`true`，只有强制指定为`false`的时候才不会装载对应的任务调度方法。这里就是简单继承`AbstractSchedulingConfigurer`，实现从类路径加载配置的逻辑，定义`JsonSchedulingConfigurer`：

```java
public class JsonSchedulingConfigurer extends AbstractSchedulingConfigurer {
    
    // 这里把默认的任务配置JSON文件放在CLASSPATH下的scheduling/tasks.json,可以通过配置项scheduling.json.config.location进行覆盖
    @Value("${scheduling.json.config.location:scheduling/tasks.json}")
    private String location;

    @Autowired
    private ObjectMapper objectMapper;

    @Override
    protected List<InternalTaskProperties> loadTaskProperties() throws Exception {
        ClassPathResource resource = new ClassPathResource(location);
        String content = StreamUtils.copyToString(resource.getInputStream(), StandardCharsets.UTF_8);
        ScheduleTaskProperties properties = objectMapper.readValue(content, ScheduleTaskProperties.class);
        if (Boolean.FALSE.equals(properties.getEnable()) || null == properties.getTasks()) {
            return Lists.newArrayList();
        }
        List<InternalTaskProperties> target = Lists.newArrayList();
        for (ScheduleTasks tasks : properties.getTasks()) {
            if (null != tasks) {
                List<ScheduleTaskMethod> taskMethods = tasks.getTaskMethods();
                if (null != taskMethods) {
                    for (ScheduleTaskMethod taskMethod : taskMethods) {
                        if (!Boolean.FALSE.equals(taskMethod.getEnable())) {
                            if (ScheduleTaskType.CRON == taskMethod.getTaskType()) {
                                target.add(CronTaskProperties.builder()
                                        .taskMethod(taskMethod.getTaskMethod())
                                        .cronExpression(taskMethod.getCronExpression())
                                        .timeZone(taskMethod.getTimeZone())
                                        .taskDescription(taskMethod.getTaskDescription())
                                        .taskHostKlass(tasks.getTaskKlass())
                                        .build());
                            }
                            if (ScheduleTaskType.FIXED_DELAY == taskMethod.getTaskType()) {
                                target.add(FixedDelayTaskProperties.builder()
                                        .taskMethod(taskMethod.getTaskMethod())
                                        .intervalMilliseconds(taskMethod.getIntervalMilliseconds())
                                        .initialDelayMilliseconds(taskMethod.getInitialDelayMilliseconds())
                                        .taskDescription(taskMethod.getTaskDescription())
                                        .taskHostKlass(tasks.getTaskKlass())
                                        .build());
                            }
                            if (ScheduleTaskType.FIXED_RATE == taskMethod.getTaskType()) {
                                target.add(FixedRateTaskProperties.builder()
                                        .taskMethod(taskMethod.getTaskMethod())
                                        .intervalMilliseconds(taskMethod.getIntervalMilliseconds())
                                        .initialDelayMilliseconds(taskMethod.getInitialDelayMilliseconds())
                                        .taskDescription(taskMethod.getTaskDescription())
                                        .taskHostKlass(tasks.getTaskKlass())
                                        .build());
                            }
                        }
                    }
                }
            }
        }
        return target;
    }
}
```

添加一个配置类和任务类：

```java
@Configuration
public class SchedulingAutoConfiguration {

    @Bean
    public JsonSchedulingConfigurer jsonSchedulingConfigurer(){
        return new JsonSchedulingConfigurer();
    }
}

// club.throwable.schedule.Tasks
@Slf4j
@Component
public class Tasks {

    public void processTask1() {
        log.info("processTask1触发..........");
    }
}
```

启动`SpringBoot`应用，某次执行的部分日志如下：

```shell
2020-03-22 16:24:17.248  INFO 22836 --- [           main] c.t.s.AbstractSchedulingConfigurer       : 装载FixedDelayTask[club.throwable.schedule.Tasks#processTask1()]成功,固定延迟间隔:5000 ms,初始延迟执行时间:0 ms,任务描述:processTask1任务
2020-03-22 16:24:22.275  INFO 22836 --- [pool-1-thread-1] club.throwable.schedule.Tasks            : processTask1触发..........
2020-03-22 16:24:27.277  INFO 22836 --- [pool-1-thread-1] club.throwable.schedule.Tasks            : processTask1触发..........
2020-03-22 16:24:32.279  INFO 22836 --- [pool-1-thread-1] club.throwable.schedule.Tasks            : processTask1触发..........
......
```

这里有些细节没有完善，例如配置文件参数的一些非空判断、配置值是否合法等等校验逻辑没有做，如果要设计成一个工业级的类库，这些方面必须要考虑。

### JDBC数据源配置[#](https://www.cnblogs.com/throwable/p/12616945.html#jdbc数据源配置)

`JDBC`数据源这里用`MySQL`举例说明，先建一个调度任务配置表`schedule_task`：

```java
CREATE TABLE `schedule_task`
(
    id                         BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT '主键',
    edit_time                  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    create_time                DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    editor                     VARCHAR(32)     NOT NULL DEFAULT 'admin' COMMENT '修改者',
    creator                    VARCHAR(32)     NOT NULL DEFAULT 'admin' COMMENT '创建者',
    deleted                    BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '软删除标识',
    task_host_class            VARCHAR(256)    NOT NULL COMMENT '任务宿主类全类名',
    task_method                VARCHAR(128)    NOT NULL COMMENT '任务执行方法名',
    task_type                  VARCHAR(16)     NOT NULL COMMENT '任务类型',
    task_description           VARCHAR(64)     NOT NULL COMMENT '任务描述',
    cron_expression            VARCHAR(128) COMMENT 'cron表达式',
    time_zone                  VARCHAR(32) COMMENT '时区',
    interval_milliseconds      BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '执行间隔时间',
    initial_delay_milliseconds BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '初始延迟执行时间',
    UNIQUE uniq_class_method (task_host_class, task_method)
) COMMENT '调度任务配置表';
```

其实具体的做法和`JSON`配置差不多，先引入`spring-boot-starter-jdbc`，接着编写`MysqlSchedulingConfigurer`：

```java
// DAO
@RequiredArgsConstructor
public class MysqlScheduleTaskDao {

    private final JdbcTemplate jdbcTemplate;

    private static final ResultSetExtractor<List<ScheduleTask>> MULTI = r -> {
        List<ScheduleTask> tasks = Lists.newArrayList();
        while (r.next()) {
            ScheduleTask task = new ScheduleTask();
            tasks.add(task);
            task.setId(r.getLong("id"));
            task.setCronExpression(r.getString("cron_expression"));
            task.setInitialDelayMilliseconds(r.getLong("initial_delay_milliseconds"));
            task.setIntervalMilliseconds(r.getLong("interval_milliseconds"));
            task.setTimeZone(r.getString("time_zone"));
            task.setTaskDescription(r.getString("task_description"));
            task.setTaskHostClass(r.getString("task_host_class"));
            task.setTaskMethod(r.getString("task_method"));
            task.setTaskType(r.getString("task_type"));
        }
        return tasks;
    };

    public List<ScheduleTask> selectAllTasks() {
        return jdbcTemplate.query("SELECT * FROM schedule_task WHERE deleted = 0", MULTI);
    }
}

// MysqlSchedulingConfigurer
@RequiredArgsConstructor
public class MysqlSchedulingConfigurer extends AbstractSchedulingConfigurer {

    private final MysqlScheduleTaskDao mysqlScheduleTaskDao;

    @Override
    protected List<InternalTaskProperties> loadTaskProperties() throws Exception {
        List<InternalTaskProperties> target = Lists.newArrayList();
        List<ScheduleTask> tasks = mysqlScheduleTaskDao.selectAllTasks();
        if (!tasks.isEmpty()) {
            for (ScheduleTask task : tasks) {
                ScheduleTaskType scheduleTaskType = ScheduleTaskType.fromType(task.getTaskType());
                if (ScheduleTaskType.CRON == scheduleTaskType) {
                    target.add(CronTaskProperties.builder()
                            .taskMethod(task.getTaskMethod())
                            .cronExpression(task.getCronExpression())
                            .timeZone(task.getTimeZone())
                            .taskDescription(task.getTaskDescription())
                            .taskHostKlass(task.getTaskHostClass())
                            .build());
                }
                if (ScheduleTaskType.FIXED_DELAY == scheduleTaskType) {
                    target.add(FixedDelayTaskProperties.builder()
                            .taskMethod(task.getTaskMethod())
                            .intervalMilliseconds(String.valueOf(task.getIntervalMilliseconds()))
                            .initialDelayMilliseconds(String.valueOf(task.getInitialDelayMilliseconds()))
                            .taskDescription(task.getTaskDescription())
                            .taskHostKlass(task.getTaskHostClass())
                            .build());
                }
                if (ScheduleTaskType.FIXED_RATE == scheduleTaskType) {
                    target.add(FixedRateTaskProperties.builder()
                            .taskMethod(task.getTaskMethod())
                            .intervalMilliseconds(String.valueOf(task.getIntervalMilliseconds()))
                            .initialDelayMilliseconds(String.valueOf(task.getInitialDelayMilliseconds()))
                            .taskDescription(task.getTaskDescription())
                            .taskHostKlass(task.getTaskHostClass())
                            .build());
                }
            }
        }
        return target;
    }
}
```

记得引入`spring-boot-starter-jdbc`和`mysql-connector-java`并且激活`MysqlSchedulingConfigurer`配置。插入一条记录：

```sql
INSERT INTO `schedule_task`(`id`, `edit_time`, `create_time`, `editor`, `creator`, `deleted`, `task_host_class`, `task_method`, `task_type`, `task_description`, `cron_expression`, `time_zone`, `interval_milliseconds`, `initial_delay_milliseconds`) VALUES (1, '2020-03-30 23:46:10', '2020-03-30 23:46:10', 'admin', 'admin', 0, 'club.throwable.schedule.Tasks', 'processTask1', 'FIXED_DELAY', '测试任务', NULL, NULL, 10000, 5000);
```

然后启动服务，某次执行的输出：

```shell
2020-03-30 23:47:27.376  INFO 53120 --- [pool-1-thread-1] club.throwable.schedule.Tasks            : processTask1触发..........
2020-03-30 23:47:37.378  INFO 53120 --- [pool-1-thread-1] club.throwable.schedule.Tasks            : processTask1触发..........
....
```

### 混合配置[#](https://www.cnblogs.com/throwable/p/12616945.html#混合配置)

有些时候我们希望可以`JSON`配置和`JDBC`数据源配置进行混合配置，或者动态二选一以便灵活应对多环境的场景（例如要在开发环境使用`JSON`配置而测试和生产环境使用`JDBC`数据源配置，甚至可以将`JDBC`数据源配置覆盖`JSON`配置，这样能保证总是倾向于使用`JDBC`数据源配置），这样需要对前面两小节的实现加多一层抽象。这里的设计可以参考`SpringMVC`中的控制器参数解析器的设计，具体是`HandlerMethodArgumentResolverComposite`，其实道理是相同的。

## 其他注意事项[#](https://www.cnblogs.com/throwable/p/12616945.html#其他注意事项)

在生产实践中，暂时不考虑生成任务执行日志和细粒度的监控，着重做了两件事：

- 并发控制，（多服务节点下）禁止任务并发执行。
- 跟踪任务的日志轨迹。

### 解决并发执行问题[#](https://www.cnblogs.com/throwable/p/12616945.html#解决并发执行问题)

一般情况下，我们需要禁止任务并发执行，考虑引入`Redisson`提供的分布式锁：

```java
// 引入依赖
<dependency>
    <groupId>org.redisson</groupId>
    <artifactId>redisson</artifactId>
    <version>最新版本</version>
</dependency>

// 配置类
@Configuration
@AutoConfigureAfter(RedisAutoConfiguration.class)
public class RedissonAutoConfiguration {

    @Autowired
    private RedisProperties redisProperties;

    @Bean(destroyMethod = "shutdown")
    public RedissonClient redissonClient() {
        Config config = new Config();
        SingleServerConfig singleServerConfig = config.useSingleServer();
        singleServerConfig.setAddress(String.format("redis://%s:%d", redisProperties.getHost(), redisProperties.getPort()));
        if (redisProperties.getDatabase() > 0) {
            singleServerConfig.setDatabase(redisProperties.getDatabase());
        }
        if (null != redisProperties.getPassword()) {
            singleServerConfig.setPassword(redisProperties.getPassword());
        }
        return Redisson.create(config);
    }
}

// 分布式锁工厂
@Component
public class DistributedLockFactory {

    private static final String DISTRIBUTED_LOCK_PATH_PREFIX = "dl:";

    @Autowired
    private RedissonClient redissonClient;

    public DistributedLock provideDistributedLock(String lockKey) {
        String lockPath = DISTRIBUTED_LOCK_PATH_PREFIX + lockKey;
        return new RedissonDistributedLock(redissonClient, lockPath);
    }
}
```

这里考虑到项目依赖了`spring-boot-starter-redis`，直接复用了它的配置属性类（`RedissonDistributedLock`是`RLock`的轻量级封装，见附录）。使用方式如下：

```java
@Autowired
private DistributedLockFactory distributedLockFactory;

public void task1() {
    DistributedLock lock = distributedLockFactory.provideDistributedLock(lockKey);
    // 等待时间为20秒,持有锁的最大时间为60秒
    boolean tryLock = lock.tryLock(20L, 60, TimeUnit.SECONDS);
    if (tryLock) {
         try {
            // 业务逻辑
         }finally {
            lock.unlock();
        }
    }
}
```

### 引入MDC跟踪任务的Trace[#](https://www.cnblogs.com/throwable/p/12616945.html#引入mdc跟踪任务的trace)

`MDC`其实是`Mapped Diagnostic Context`的缩写，也就是映射诊断上下文，一般用于日志框架里面同一个线程执行过程的跟踪（例如一个线程跑过了多个方法，各个方法里面都打印了日志，那么通过`MDC`可以对整个调用链通过一个唯一标识关联起来），例如这里选用`slf4j`提供的`org.slf4j.MDC`：

```java
@Component
public class MappedDiagnosticContextAssistant {

    /**
     * 在MDC中执行
     *
     * @param runnable runnable
     */
    public void processInMappedDiagnosticContext(Runnable runnable) {
        String uuid = UUID.randomUUID().toString();
        MDC.put("TRACE_ID", uuid);
        try {
            runnable.run();
        } finally {
            MDC.remove("TRACE_ID");
        }
    }
}
```

任务执行的时候需要包裹成一个`Runnale`实例：

```java
public void task1() {
    mappedDiagnosticContextAssistant.processInMappedDiagnosticContext(() -> {
        StopWatch watch = new StopWatch();
        watch.start();
        log.info("开始执行......");
        // 业务逻辑
        watch.stop();
        log.info("执行完毕,耗时:{} ms......", watch.getTotalTimeMillis());
    });
}
```

结合前面一节提到的并发控制，那么最终执行的任务方法如下：

```java
public void task1() {
    mappedDiagnosticContextAssistant.processInMappedDiagnosticContext(() -> {
        StopWatch watch = new StopWatch();
        watch.start();
        log.info("开始执行......");
        scheduleTaskAssistant.executeInDistributedLock("任务分布式锁KEY", () -> {
            // 真实的业务逻辑
        });
        watch.stop();
        log.info("执行完毕,耗时:{} ms......", watch.getTotalTimeMillis());
    });
}
```

这里的方法看起来比较别扭，其实可以直接在任务装载的时候基于分布式锁和`MDC`进行封装，方式类似于`ScheduledMethodRunnable`，这里不做展开，因为要详细展开篇幅可能比较大（`ScheduleTaskAssistant`见附录）。

## 小结[#](https://www.cnblogs.com/throwable/p/12616945.html#小结)

其实`spring-context`整个调度模块完全依赖于`TaskScheduler`实现，更底层的是`JUC`调度线程池`ScheduledThreadPoolExecutor`。如果想要从底层原理理解整个调度模块的运行原理，那么就一定要分析`ScheduledThreadPoolExecutor`的实现。整篇文章大致介绍了`spring-context`调度模块的加载调度任务的流程，并且基于扩展接口`SchedulingConfigurer`扩展出多种自定义配置调度任务的方式，但是考虑到需要在生产环境中运行，那么免不了需要考虑监控、并发控制、日志跟踪等等的功能，但是这样就会使得整个调度模块变重，慢慢地就会发现，这个轮子越造越大，越有主流调度框架`Quartz`或者`Easy Scheduler`的影子。笔者认为，软件工程，有些时候要权衡取舍，该抛弃的就应该果断抛弃，否则总是负重而行，还能走多远？

参考资料：

- `SpringBoot`源码

## 附录[#](https://www.cnblogs.com/throwable/p/12616945.html#附录)

`ScheduleTaskAssistant`：

```java
@RequiredArgsConstructor
@Component
public class ScheduleTaskAssistant {

    /**
     * 5秒
     */
    public static final long DEFAULT_WAIT_TIME = 5L;

    /**
     * 30秒
     */
    public static final long DEFAULT_LEAVE_TIME = 30L;

    private final DistributedLockFactory distributedLockFactory;

    /**
     * 在分布式锁中执行
     *
     * @param waitTime  锁等着时间
     * @param leaveTime 锁持有时间
     * @param timeUnit  时间单位
     * @param lockKey   锁的key
     * @param task      任务对象
     */
    public void executeInDistributedLock(long waitTime, long leaveTime, TimeUnit timeUnit, String lockKey, Runnable task) {
        DistributedLock lock = distributedLockFactory.dl(lockKey);
        boolean tryLock = lock.tryLock(waitTime, leaveTime, timeUnit);
        if (tryLock) {
            try {
                long waitTimeMillis = timeUnit.toMillis(waitTime);
                long start = System.currentTimeMillis();
                task.run();
                long end = System.currentTimeMillis();
                long cost = end - start;
                // 预防锁过早释放
                if (cost < waitTimeMillis) {
                    Sleeper.X.sleep(waitTimeMillis - cost);
                }
            } finally {
                lock.unlock();
            }
        }
    }

    /**
     * 在分布式锁中执行 - 使用默认时间
     *
     * @param lockKey 锁的key
     * @param task    任务对象
     */
    public void executeInDistributedLock(String lockKey, Runnable task) {
        executeInDistributedLock(DEFAULT_WAIT_TIME, DEFAULT_LEAVE_TIME, TimeUnit.SECONDS, lockKey, task);
    }
}
```

`RedissonDistributedLock`：

```java
@Slf4j
public class RedissonDistributedLock implements DistributedLock {

    private final RedissonClient redissonClient;
    private final String lockPath;
    private final RLock internalLock;

    RedissonDistributedLock(RedissonClient redissonClient, String lockPath) {
        this.redissonClient = redissonClient;
        this.lockPath = lockPath;
        this.internalLock = initInternalLock();
    }

    private RLock initInternalLock() {
        return redissonClient.getLock(lockPath);
    }

    @Override
    public boolean isLock() {
        return internalLock.isLocked();
    }

    @Override
    public boolean isHeldByCurrentThread() {
        return internalLock.isHeldByCurrentThread();
    }

    @Override
    public void lock(long leaseTime, TimeUnit unit) {
        internalLock.lock(leaseTime, unit);
    }

    @Override
    public boolean tryLock(long waitTime, long leaseTime, TimeUnit unit) {
        try {
            return internalLock.tryLock(waitTime, leaseTime, unit);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException(String.format("Acquire lock fail by thread interrupted,path:%s", lockPath), e);
        }
    }

    @Override
    public void unlock() {
        try {
            internalLock.unlock();
        } catch (IllegalMonitorStateException ex) {
            log.warn("Unlock path:{} error for thread status change in concurrency", lockPath, ex);
        }
    }
}
```