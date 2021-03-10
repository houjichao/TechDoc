### monitor

> 方法执行监控

对匹配 `class-pattern`／`method-pattern`／`condition-express`的类、方法的调用进行监控。

`monitor` 命令是一个非实时返回命令.

实时返回命令是输入之后立即返回，而非实时返回的命令，则是不断的等待目标 Java 进程返回信息，直到用户输入 `Ctrl+C` 为止。

## 监控的维度说明

| 监控项    | 说明                       |
| --------- | -------------------------- |
| timestamp | 时间戳                     |
| class     | Java类                     |
| method    | 方法（构造方法、普通方法） |
| total     | 调用次数                   |
| success   | 成功次数                   |
| fail      | 失败次数                   |
| rt        | 平均RT                     |
| fail-rate | 失败率                     |

## 参数说明

方法拥有一个命名参数 `[c:]`，意思是统计周期（cycle of output），拥有一个整型的参数值

| 参数名称            | 参数说明                                |
| ------------------- | --------------------------------------- |
| *class-pattern*     | 类名表达式匹配                          |
| *method-pattern*    | 方法名表达式匹配                        |
| *condition-express* | 条件表达式                              |
| [E]                 | 开启正则表达式匹配，默认为通配符匹配    |
| `[c:]`              | 统计周期，默认值为120秒                 |
| [b]                 | 在**方法调用之前**计算condition-express |

使用

```
[arthas@87878]$ monitor -c 5 com.hjc.learn.controller.WebFluxController commonHandle
Press Q or Ctrl+C to abort.
Affect(class count: 1 , method count: 1) cost in 314 ms, listenerId: 12
 timestamp                              class                                                      method                                                    total               success            fail                avg-rt(ms)         fail-rate
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2021-03-10 20:32:22                    com.hjc.learn.controller.WebFluxController                 commonHandle                                              1                   1                  0                   12240.87           0.00%

 timestamp                              class                                                      method                                                    total               success            fail                avg-rt(ms)         fail-rate
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2021-03-10 20:32:27                    com.hjc.learn.controller.WebFluxController                 commonHandle                                              0                   0                  0                   0.00               0.00%

 timestamp                              class                                                      method                                                    total               success            fail                avg-rt(ms)         fail-rate
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2021-03-10 20:32:32                    com.hjc.learn.controller.WebFluxController                 commonHandle                                              0                   0                  0                   0.00               0.00%

 timestamp                              class                                                      method                                                    total               success            fail                avg-rt(ms)         fail-rate
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2021-03-10 20:32:37                    com.hjc.learn.controller.WebFluxController                 commonHandle                                              0                   0                  0                   0.00               0.00%

 timestamp                              class                                                      method                                                    total               success            fail                avg-rt(ms)         fail-rate
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
```



### 计算条件表达式过滤统计结果(方法执行完毕之后)

```
monitor -c 5 com.hjc.learn.controller.WebFluxController commonHandle "params[0] <= 2"
```

### 计算条件表达式过滤统计结果(方法执行完毕之前)

```
monitor -b -c 5 com.test.testes.MathGame primeFactors "params[0] <= 2"
```

