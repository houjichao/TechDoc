## 概述

flink的sink是flink三大逻辑结构之一（source，transform，sink）,**功能就是负责把flink处理后的数据输出到外部系统中**，flink 的sink和source的代码结构类似。

在编写代码的过程中，我们可以使用flink已经提供的sink，如kafka，jdbc,es等，当然我们也可以通过自定义的方式，来实现我们自己的sink。下面说明核心类