### watch

> 方法执行数据观测

让你能方便的观察到指定方法的调用情况。能观察到的范围为：`返回值`、`抛出异常`、`入参`，通过编写 OGNL 表达式进行对应变量的查看。

## 参数说明

watch 的参数比较多，主要是因为它能在 4 个不同的场景观察对象

| 参数名称            | 参数说明                                   |
| ------------------- | ------------------------------------------ |
| *class-pattern*     | 类名表达式匹配                             |
| *method-pattern*    | 方法名表达式匹配                           |
| *express*           | 观察表达式                                 |
| *condition-express* | 条件表达式                                 |
| [b]                 | 在**方法调用之前**观察                     |
| [e]                 | 在**方法异常之后**观察                     |
| [s]                 | 在**方法返回之后**观察                     |
| [f]                 | 在**方法结束之后**(正常返回和异常返回)观察 |
| [E]                 | 开启正则表达式匹配，默认为通配符匹配       |
| [x:]                | 指定输出结果的属性遍历深度，默认为 1       |

这里重点要说明的是观察表达式，观察表达式的构成主要由 ognl 表达式组成，所以你可以这样写`"{params,returnObj}"`，只要是一个合法的 ognl 表达式，都能被正常支持。

```
watch org.jeecg.modules.profession.mapper.HouseHoldResidentLongProfessionTbaseMapper search '{params}' -x 3 '#cost > 1000'
```

```
[arthas@87878]$ watch  com.hjc.learn.controller.WebFluxController commonHandle '{params,returnObj}' -x 3
Press Q or Ctrl+C to abort.
Affect(class count: 1 , method count: 1) cost in 418 ms, listenerId: 10
method=com.hjc.learn.controller.WebFluxController.commonHandle location=AtExit
ts=2021-03-10 20:03:14; [cost=12284.616291ms] result=@ArrayList[
    @Object[][isEmpty=true;size=0],
    @String[common handler],
]
```

