# 编写初衷

当我们在代码中看到如下几种硬编码形式的业务逻辑选择时，我知道你的内心是拒绝的。

```javascript
if (业务类型1==req.getBusinessType) {
	//业务类型1特定逻辑
} else if (业务类型2==req.getBusinessType) {
	//业务类型2特定逻辑
} else {
	//其他逻辑
} 
```

然后你像我一样去google了一下，如何去除if else 的硬编码，你就会找到策略模式（手动护住狗头?） 策略模式UML类图如下： 

![image-20211129215441853](/Users/houjichao/Library/Application Support/typora-user-images/image-20211129215441853.png)

 但是我们真的去除了if else 吗？让我们来看看客户端的调用方式：

```javascript
    //客户端调用
    public class Client
    {
        public void Main(string param)
        {
            Context context;
            if (param == "A")
            {
                context = new Context(new ConcreteStrategyA());
            }
            else if(param == "B")
            {
                context = new Context(new ConcreteStrategyB());
            }
            else if(param == "C")
            {
                context = new Context(new ConcreteStrategyC());
            }
            else
            {
                throw new Exception("没有可用的策略");
            }
            context.ContextFunc();
        }
    }
```

或许有些人就说了，这么多Strategy怎么能直接new呢？当然是用工厂模式啦。 但是不管是抽象工厂还是工厂方法模式，都是存在if else 的，此处使用工厂模式并没有消除if else ,只是把条件判断藏的更深了。 那么就没有解决方法了吗？ **当然是有哒，duang~** 

# 痛点问题阐述

1. 拒绝繁复的if else
2. 无法新开接口，又需根据不同渠道请求做差异化处理
3. 灵活复用模块能力

# 框架介绍

本框架通过将接口与业务能力解耦的方式，便捷复用现有功能模块，实现了相较于Spring Cloud等微服务概念更细粒度的微模块编排与组合。

## 原理简介

本框架主要通过自定义注解，通过AOP对自定义注解进行拦截，并根据接口上的@Adapter注解业务配置，从redis中选取相应被@Module所注解的微模块列表，并依次执行。

## 微模块

通过@Module自定义注解标定微模块，通过type类型以区分该业务模块是普通处理器（AdapterConfig.MODULE_HANDLE）还是结果处理器（AdapterConfig.MODULE_OUTPUT）

```javascript
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface Module {
    /**
     * 模块类型
     * handle 处理器 AdapterConfig.MODULE_HANDLE
     * output 结果处理器 AdapterConfig.MODULE_OUTPUT
     * @return
     */
    String type();
}
```

这里举三个栗子?，后面会用到

```javascript
@Service
@Module(type = AdapterConfig.MODULE_HANDLE)
@Slf4j
public class FirstDemoProcessor {

    @Properties
    public <T1,T2> void properties(T1 requestDTO,T2 requestBO){
        //入参转换，预处理
        log.info("FirstDemoProcessor.properties...");
    }

    @Proceser
    public <T2> void process(T2 requestBO){
        //业务处理
        log.info("FirstDemoProcessor.process...");
    }
}
@Service
@Module(type = AdapterConfig.MODULE_HANDLE)
@Slf4j
public class SecondDemoProcessor {

    @Proceser
    public <T2> void process(T2 requestBO){
        //业务处理
         log.info("SecondDemoProcessor.process...");
    }
}
@Service
@Module(type = AdapterConfig.MODULE_OUTPUT)
@Slf4j
public class ResultDemoProcessor <T2,S>{

    @Proceser
    public Result<S> void process(T2 requestBO){
        //结果业务处理
        log.info("ResultDemoProcessor.process...");
    }
}
```

## 业务适配器

通过在服务接口中使用@Adapter注解，并配置注解属性以实现**两种**不同形式的服务配置

```javascript
/**
 * Description:业务适配器注解
 * Create by amgji
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface Adapter {

    /**
     * 业务类型适配
     * @return
     */
    Class<? extends BusinessAdapter> type() default BusinessAdapter.class;

    /**
     * 业务名称适配
     * @return
     */
    String name() default "";

    /**
     * 业务类型
     * @return
     */
    String businessType() default "";

}
```

### SelfControl模式

SelfControl模式主要是由**服务提供方确认**该服务接口所需绑定的业务流程，即通过将@Adapter name 属性绑定至redis中已有业务流程的key,以实现接口与服务能力的解耦。

**适用场景：**

- **接口对所有调用方提供的能力相同**

举个栗子?

```javascript
@Service
public class DemoService<T,S> {

    @Adapter(name = "ORDER")
    public Result<S> demoMethod(T request) {
        return null;
    }
}
```

同时在redis中配置业务流程

```javascript
ORDER:["firstDemoProcessor","secondDemoProcessor","resultDemoProcessor"]
```

### VerifyControl模式

VerifyControl模式主要通过查询**接口入参**中**businessType+@Adapter**与**注解中businessType属性**的**联合key**是否存在，其主要通过入参中businessType控制业务逻辑选择

**适用场景：**

- **所有服务调用方需调用同一接口，但处理逻辑有所差异**

举个栗子?

```javascript
@Service
public class DemoService<T,S> {

    @Adapter(type = StandardBusinessAdapter.class, businessType = "ORDER")
    public Result<S> demoMethod(T request) {
        return null;
    }
}
```

同时在redis中配置业务流程

```javascript
businessType_ORDER:["firstDemoProcessor","secondDemoProcessor","resultDemoProcessor"]
```

## Requirements

- 配置好你的redis
- **然后什么都不需要了！！！**

## 运行结果

```javascript
FirstDemoProcessor.properties...
FirstDemoProcessor.process...
SecondDemoProcessor.process...
ResultDemoProcessor.process...
```