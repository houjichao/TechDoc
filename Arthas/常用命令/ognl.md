## ognl

ognl是一块大头，上面的命令掌握了只代表你掌握了arthas的基本入门，掌握ognl是arthas进阶必备的一块。

#### 我们能用ognl结合arthas做什么呢？

> 执行ognl表达式

| 参数名称              | 参数说明                                                     |
| --------------------- | ------------------------------------------------------------ |
| *express*             | 执行的表达式                                                 |
| `[c:]`                | 执行表达式的 ClassLoader 的 hashcode，默认值是SystemClassLoader |
| `[classLoaderClass:]` | 指定执行表达式的 ClassLoader 的 class name                   |
| [x]                   | 结果对象的展开层次，默认值1                                  |

### 调用静态函数：

```
ognl '@java.lang.System@out.println("hello")'
```

### 获取静态类的静态字段

```
ognl '@全路径类目@静态属性名'
ognl '@java.lang.Integer@MIN_VALUE'

非静态字段执行报错：
[arthas@59567]$ ognl '@com.hjc.learn.model.Movie@name'
Failed to execute ognl, exception message: ognl.OgnlException: Field name of class com.hjc.learn.model.Movie is not static, please check $HOME/logs/arthas/arthas.log for more details.

非字段报错：
[arthas@59567]$ ognl '@com.hjc.learn.util.GuavaRangeUtil@inTheInterval'
Failed to execute ognl, exception message: ognl.OgnlException: Could not get static field inTheInterval from class com.hjc.learn.util.GuavaRangeUtil [java.lang.NoSuchFieldException: inTheInterval], please check $HOME/logs/arthas/arthas.log for more details
```

### 调用静态方法

```
ognl '@全路径类目@静态方法名("参数")'

[arthas@62942]$ ognl '@com.hjc.learn.test.ArthasStaticDemo@getMovie("tangtan","chensicheng")' -x 1
@Movie[
    name=@String[tangtan],
    director=@String[chensicheng],
]
```



### 通过hashcode指定ClassLoader：

classloader -t

```
[arthas@59567]$ classloader -t
+-BootstrapClassLoader
+-sun.misc.Launcher$ExtClassLoader@67b92f0a
  +-com.taobao.arthas.agent.attach.AttachArthasClassloader@7227926b
  +-sun.misc.Launcher$AppClassLoader@18b4aac2
Affect(row-cnt:4) cost in 443 ms.
[arthas@59567]$ ognl -c 7f9a81e8 @org.springframework.boot.SpringApplication@logger
Can not find classloader with hashCode: 7f9a81e8.
[arthas@59567]$ ognl -c 18b4aac2  @org.springframework.boot.SpringApplication@logger
@Slf4jLocationAwareLog[
    FQCN=@String[org.apache.commons.logging.LogAdapter$Slf4jLocationAwareLog],
    name=@String[org.springframework.boot.SpringApplication],
    logger=@Logger[Logger[org.springframework.boot.SpringApplication]],
]
[arthas@59567]$
```

注意hashcode是变化的，需要先查看当前的ClassLoader信息，提取对应ClassLoader的hashcode。

对于只有唯一实例的ClassLoader可以通过class name指定，使用起来更加方便：

```
[arthas@59567]$ ognl --classLoaderClass org.springframework.boot.loader.LaunchedURLClassLoader  @org.springframework.boot.SpringApplication@logger
Can not find classloader by class name: org.springframework.boot.loader.LaunchedURLClassLoader.
[arthas@59567]$ ognl --classLoaderClass sun.misc.Launcher$AppClassLoader  @org.springframework.boot.SpringApplication@logger
@Slf4jLocationAwareLog[
    FQCN=@String[org.apache.commons.logging.LogAdapter$Slf4jLocationAwareLog],
    name=@String[org.springframework.boot.SpringApplication],
    logger=@Logger[Logger[org.springframework.boot.SpringApplication]],
]
```

### 执行多行表达式，赋值给临时变量，返回一个List：

```
[arthas@59567]$ ognl '#value1=@System@getProperty("java.home"), #value2=@System@getProperty("java.runtime.name"), {#value1, #value2}'
@ArrayList[
    @String[/Library/Java/JavaVirtualMachines/jdk1.8.0_241.jdk/Contents/Home/jre],
    @String[Java(TM) SE Runtime Environment],
]
```

### 返回对象中包含的对象和List

```
[arthas@64894]$ ognl '@com.hjc.learn.test.ArthasStaticDemo@getPerson("houjichao",27,2)' -x 1
@Person[
    name=@String[houjichao],
    age=@Integer[27],
    child=@Child[Person.Child(sex=girl, childAge=10)],
    childList=@ArrayList[isEmpty=false;size=2],
]

```

-x 1 中的x是小写; 上面可以看到 child对象和childs列表都没有打印出来
试试 `-x 2` 和 `-x 3`

```
[arthas@64894]$ ognl '@com.hjc.learn.test.ArthasStaticDemo@getPerson("houjichao",27,2)' -x 2
@Person[
    name=@String[houjichao],
    age=@Integer[27],
    child=@Child[
        sex=@String[girl],
        childAge=@Integer[10],
    ],
    childList=@ArrayList[
        @Child[Person.Child(sex=boy, childAge=978821522)],
        @Child[Person.Child(sex=boy, childAge=-447765283)],
    ],
]
[arthas@64894]$ ognl '@com.hjc.learn.test.ArthasStaticDemo@getPerson("houjichao",27,2)' -x 3
@Person[
    name=@String[houjichao],
    age=@Integer[27],
    child=@Child[
        sex=@String[girl],
        childAge=@Integer[10],
    ],
    childList=@ArrayList[
        @Child[
            sex=@String[boy],
            childAge=@Integer[-81686174],
        ],
        @Child[
            sex=@String[boy],
            childAge=@Integer[1682744182],
        ],
    ],
]
```

**-x 2 的时候对象属性有展开,但是列表没有, -x 3 才把列表展开了**

### 方法A的返回值当做方法B的入参

```
[arthas@66289]$ ognl '#value1=@com.hjc.learn.test.ArthasStaticDemo@getPerson("src",18), #value2=@com.hjc.learn.test.ArthasStaticDemo@setPerson(#value1) ,{#value1,#value2}' -x 2
@ArrayList[
    @Person[
        name=@String[src],
        age=@Integer[18],
        child=null,
        childList=null,
    ],
    @Person[
        name=@String[src],
        age=@Integer[18],
        child=null,
        childList=null,
    ],
]
```

### 方法入参是一个复杂对象

```
先用构造函数构造一个对象
ognl 'new com.shirc.arthasexample.ognl.Shirc("jjdlmn",true)'
然后把这个对象当做入参传入；所以最终可以这么写
ognl '#obj=new com.shirc.arthasexample.ognl.Shirc("jjdlmn",true),@com.shirc.arthasexample.ognl.OgnlTest@inputObj(#obj)' -x 2


[arthas@68142]$ ognl '#obj=new com.hjc.learn.model.Movie("jjdlmn","true"),@com.hjc.learn.test.ArthasStaticDemo@setMovie(#obj)' -x 2
Failed to execute ognl, exception message: ognl.MethodFailedException: Method "new" failed for object com.hjc.learn.model.Movie [java.lang.NoSuchMethodException], please check $HOME/logs/arthas/arthas.log for more details.
```

**经过测试，以上的方式是无法构造一个复杂对象的，可以用以下方式代替**

```
[arthas@89686]$ ognl '#obj=new com.hjc.learn.model.Movie(),#obj.setName("2222"), #obj.setDirector("1111"),@com.hjc.learn.test.ArthasStaticDemo@setMovie(#obj)' -x 2
@Movie[
    name=@String[2222],
    director=@String[1111],
]
```



### 方法入参是一个map

```
先构造一个Map对象可以这样
ognl '#{ "foo" : "foo value", "bar" : "bar value" }'
然后把这个对象赋值给一个变量; 最后把这个变量当做入参传入;
然后把这个对象当做入参传入；所以最终可以这么写

[arthas@68392]$ ognl '#inputmap=#{ "foo" : "foo value", "bar" : "bar value" }, @com.hjc.learn.test.ArthasStaticDemo@mapTest(#inputmap)' -x 2
@LinkedHashMap[
    @String[foo]:@String[foo value],
    @String[bar]:@String[bar value],
]
```

### 读取不同类型的值

**示例一：访问复杂对象属性**

```
ognl '@com.shirc.arthasexample.ognl.OgnlTest@getPerson("src",18).name' -x 4
```

**示例二、访问List或者数组类型**

```
ognl '@com.shirc.arthasexample.ognl.OgnlTest@getChilds({"jinjidelaomanong","jjdlmn"})[0]' -x 2
```

##### 示例三: 访问Map对象

```
ognl '@com.shirc.arthasexample.ognl.OgnlTest@getMap()["shirc"]' -x 2

ognl '@com.shirc.arthasexample.ognl.OgnlTest@getMap()["shirc"].sex' -x 2
shirc: 是map的key; 记得要用双引号"" 引起来
```

