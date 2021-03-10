### 总述

这三个命令属于研发类必须关注的，用来做线上热更调试，因为发版本往往成本都会比较高，所以如果定位出具体问题，而且修改又少，就可以通过一台机器做热更，达到灰度对比的效果。

### jad

jad在使用之前，都建议先用sc

#### sc

> 查看JVM已加载的类信息

“Search-Class” 的简写，这个命令能搜索出所有已经加载到 JVM 中的 Class 信息

| 参数名称              | 参数说明                                                     |
| --------------------- | ------------------------------------------------------------ |
| *class-pattern*       | 类名表达式匹配                                               |
| *method-pattern*      | 方法名表达式匹配                                             |
| [d]                   | 输出当前类的详细信息，包括这个类所加载的原始文件来源、类的声明、加载的ClassLoader等详细信息。 如果一个类被多个ClassLoader所加载，则会出现多次 |
| [E]                   | 开启正则表达式匹配，默认为通配符匹配                         |
| [f]                   | 输出当前类的成员变量信息（需要配合参数-d一起使用）           |
| [x:]                  | 指定输出静态变量时属性的遍历深度，默认为 0，即直接使用 `toString` 输出 |
| `[c:]`                | 指定class的 ClassLoader 的 hashcode                          |
| `[classLoaderClass:]` | 指定执行表达式的 ClassLoader 的 class name                   |
| `[n:]`                | 具有详细信息的匹配类的最大数量（默认为100）                  |

> class-pattern支持全限定名，如com.taobao.test.AAA，也支持com/taobao/test/AAA这样的格式，这样，我们从异常堆栈里面把类名拷贝过来的时候，不需要在手动把`/`替换为`.`啦。

> sc 默认开启了子类匹配功能，也就是说所有当前类的子类也会被搜索出来，想要精确的匹配，请打开`options disable-sub-class true`开关

```
[arthas@87878]$ sc -d   com.hjc.learn.controller.WebFluxController
 class-info        com.hjc.learn.controller.WebFluxController
 code-source       /Users/houjichao/Work/Java/hjc/spring-boot-learn/target/classes/
 name              com.hjc.learn.controller.WebFluxController
 isInterface       false
 isAnnotation      false
 isEnum            false
 isAnonymousClass  false
 isArray           false
 isLocalClass      false
 isMemberClass     false
 isPrimitive       false
 isSynthetic       false
 simple-name       WebFluxController
 modifier          public
 annotation        org.springframework.web.bind.annotation.RestController,org.springframework.web.bind.annotation.RequestMapping,io.swagger.annotations.Api
 interfaces
 super-class       +-java.lang.Object
 class-loader      +-sun.misc.Launcher$AppClassLoader@18b4aac2
                     +-sun.misc.Launcher$ExtClassLoader@67b92f0a
 classLoaderHash   18b4aac2  --这个

Affect(row-cnt:1) cost in 89 ms.
```



核心是要拿到这个hash值，因为有时候编译跟热更代码不生效，那很大可能是你用的classloader不对。

然后运行 jad --source-only  类全路径 > /保存目录/文件名.java

### mc

> Memory Compiler/内存编译器，编译`.java`文件生成`.class`。

mc /保存目录/文件名.java -d /保存目录  （注意这里可能需要指定-c classloader的hash值,另外生成出来的类是自带全路径目录的）

可以通过`-c`参数指定classloader：

```
mc -c 327a647b /tmp/Test.java
```

也可以通过`--classLoaderClass`参数指定ClassLoader：

```
$ mc --classLoaderClass org.springframework.boot.loader.LaunchedURLClassLoader /tmp/UserController.java -d /tmp
Memory compiler output:
/tmp/com/example/demo/arthas/user/UserController.class
Affect(row-cnt:1) cost in 346 ms
```

可以通过`-d`命令指定输出目录：

```
mc -d /tmp/output /tmp/ClassA.java /tmp/ClassB.java
```

编译生成`.class`文件之后，可以结合[retransform](https://arthas.gitee.io/retransform.html)命令实现热更新代码。

```
mc -d /Users/houjichao/Work/Java/hjc/TechDoc -c 18b4aac2 /Users/houjichao/Work/Java/hjc/spring-boot-learn/src/main/java/com/hjc/learn/controller/WebFluxController.java
```

### retransform

加载外部的`.class`文件，retransform jvm已加载的类。

```
retransform -c 18b4aac2 /Users/houjichao/Work/Java/hjc/TechDoc/com/hjc/learn/controller/WebFluxController.class
```

