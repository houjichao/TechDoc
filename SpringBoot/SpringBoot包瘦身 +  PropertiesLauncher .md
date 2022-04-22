### 背景

现在微服务架构越来越流行，一个项目10多个基于spring boot的服务模块很常见。假设一个服务模块打成jar包是100M，那么一次全量发布可能就需要上传1G的文件。在网络情况好的时候可能还没多大感觉，但如果是代码需要拷贝到内网发布，或者上传到某些国外服务器上, 将严重影响工作效率。

那么，有没有什么办法给我们打的spring boot的jar包瘦瘦身呢？
答案是有，通过相关配置使spring boot打包的时候只加载一些经常会变化的依赖包，比如项目通用的common模块，一些调用feign接口的API模块，而那些固定的依赖包则直接上传到服务器的指定目录下，在项目启动的时候通过命令指定lib包加载的目录就可以了。这样，我们打出来的jar包最多几M不到，极大的缩小了spring boot项目jar包的体积，提高了发布上线的效率。

**补充：**
**fat jar：** 即胖jar，打出的jar包包含所有的依赖包。
好处是可以直接运行，不需要添加其他命令，坏处是体积太大，传输困难。

**thin jar：**即瘦包，打出的jar包只包含一些经常变换的依赖包，一般为项目中的公共模块或一些API接口依赖模块。
好处是体积小，有利于提高项目发布效率；
坏处是依赖包外置可能存在安全遗患，如果项目的maven依赖变动频繁，维护服务器上的lib目录就比较麻烦，也不利于问题定位。

### 瘦身运动

**1、修改maven打包参数**

```
<build>
    <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
            <configuration>
                <layout>ZIP</layout>
                <includes>
                    <include>
                        <groupId>nothing</groupId>
                        <artifactId>nothing</artifactId>
                    </include>
                    <include>
                        <groupId>com.hjc.tax.rpc</groupId>
                        <artifactId>common</artifactId>
                    </include>
                </includes>
            </configuration>
        </plugin>
    </plugins>
</build>
```

**说明：**

**layout**
用来配置可执行jar包中Main-Class的类型，这里一定要设置为 ZIP，使打的jar包中的**Main-Class为PropertiesLauncher** 。

**includes**
将需要保留的jar包，按照groupId和artifactId（注意两个都是必填项）include进来。
nothing 代表不存在的依赖包，意思就是什么依赖包都不引入
common是引入的公共服务模块。

**2、执行maven打包**
先执行mvn clean，然后执行mvn package

通过压解工具查看tax-ws-thin-zip.jar里面META-INF目录下的MANIFEST.MF文件：

发现Main-Class的值确实变为了PropertiesLauncher ，说明我们的配置成功。
（至于为什么一定要将Main-Class配置为PropertiesLauncher 后面再介绍）

**3、比较FatJar和ThinJar的体积：**

可以发现，tax-ws-thin.jar这个瘦包的体积比胖包的体积小了非常多。

**4、从fatJar包中拷贝中lib包到D:\web目录下**

**5、通过命令启动jar包**

```
D:\web>java -Dloader.path="D:\web\lib"  -jar tax-ws-thin.jar
```

通过启动参数loader.path配置外置依赖包的加载路径。

项目成功启动，说明我们配置的外包依赖包加载生效。

### 原理探究

为什么将可执行jar包的Main-Class设置为PropertiesLauncher就可以通过配置启动参数loader.path指定依赖包的加载路径呢？
首先我们对spring boot可执行jar包实现原理中的启动器Launcher有所了解。

**以下摘自spring boot官网：**
org.springframework.boot.loader.Launcher类是特殊的引导程序类，用作可执行jar的主要入口点。它是jar文件中的实际Main-Class，用于设置适当的URLClassLoader并最终调用main（）方法。

有三个启动器子类（**JarLauncher，WarLauncher和PropertiesLauncher**）。它们的目的是从目录中的嵌套jar文件或war文件（而不是在类路径中显式的文件）加载资源（.class文件等）。对于JarLauncher和WarLauncher，嵌套路径是固定的。 JarLauncher位于BOOT-INF / lib /中，而WarLauncher位于WEB-INF / lib /和WEB-INF / lib-provided /中。如果需要，可以在这些位置添加额外的罐子。默认情况下，PropertiesLauncher在您的应用程序存档中的BOOT-INF / lib /中查找。您可以通过在loader.properties（这是目录，归档文件或归档文件中的目录的逗号分隔列表）中设置一个称为LOADER_PATH或loader.path的环境变量来添加其他位置。
————————————————

也就是说启动器Launcher是为了项目启动加载依赖资源的，共有3个启动器（**JarLauncher，WarLauncher和PropertiesLauncher**），其中JarLauncher和WarLauncher加载资源的路径是固定的，而PropertiesLauncher可以通过环境变量loader.path来指定加载资源的位置。
![在这里插入图片描述](https://i2.wp.com/img-blog.csdnimg.cn/20200531001157375.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3cxMDE0MDc0Nzk0,size_16,color_FFFFFF,t_70)

**layout属性值说明：**

JAR，即通常的可执行jar
Main-Class: org.springframework.boot.loader.JarLauncher

WAR，即通常的可执行war，需要的servlet容器依赖位于
Main-Class: org.springframework.boot.loader.warLauncher

**ZIP**，即DIR，类似于JAR
Main-Class: org.springframework.boot.loader.PropertiesLauncher
（记住这个就好，其他的应用场景比较少）

**PropertiesLauncher属性配置**

PropertiesLauncher具有一些可以通过外部属性（系统属性，环境变量，清单条目或loader.properties）启用的特殊功能。 下表描述了这些属性：

| Key                | 目的                                                         |
| :----------------- | :----------------------------------------------------------- |
| loader.path        | lib包加载路径                                                |
| loader.home        | 用于解析loader.path中的相对路径。 例如，给定loader.path = lib，则$ {loader.home} / lib是类路径位置（以及该目录中的所有jar文件）。 此属性还用于查找loader.properties文件，如以下示例/ opt / app所示。它默认为$ {user.dir}。 |
| loader.args        | main方法的默认参数（以空格分隔）。                           |
| loader.main        | 要启动的主类的名称（例如com.app.Application）                |
| loader.config.name | 属性文件的路径（例如，classpath：loader.properties）。 默认为loader.properties。 |
| loader.system      | 布尔值标志，指示应将所有属性添加到系统属性。 默认为false。   |

更过资料可以查看官网的关于spring boot可执行jar包的说明文档：The Executable Jar Format

### 陷阱纠正

之前在网上看到过一种没有配置layout=ZIP的方式，而是直接打成瘦包后，在启动命令中通过-Djava.ext.dirs来指定外置依赖包的加载路径。

```
D:\web>java -Djava.ext.dirs="D:\web\lib"  -jar tax-ws-thin.jar
```

**原理解析：**
-Djava.ext.dirs会覆盖Java本身的ext设置，java.ext.dirs指定的目录由ExtClassLoader加载器加载，如果您的程序没有指定该系统属性，那么该加载器默认加载$JAVA_HOME/jre/lib/ext目录下的所有jar文件。但如果你手动指定系统属性且忘了把$JAVA_HOME/jre/lib/ext路径给加上，那么ExtClassLoader不会去加载$JAVA_HOME/lib/ext下面的jar文件，这意味着你将失去一些功能，例如java自带的加解密算法实现。

所以，通过这种写法，直接强行修改java默认扩展类加载器的加载路径，很容易导致一些问题。最好不要随便使用。

### 找不到Oracle驱动包的问题

在使用-Djava.ext.dirs配置外置依赖包加载路径的时候，出现了加载不到Oracle的驱动包的问题，这个时候需要添加
-Doracle.jdbc.thinLogonCapability=o3，配置oracle的登录兼容性

#### 扩展：双亲委派机制

这里展开来讲就涉及到了java的双亲委派加载机制。
![在这里插入图片描述](https://i2.wp.com/img-blog.csdnimg.cn/20200531002923598.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3cxMDE0MDc0Nzk0,size_16,color_FFFFFF,t_70)

1、BootStrapClassLoader：启动类加载器，该ClassLoader是在启动时候创建的，是写在JVM内核里的，它不是一个字节码文件，是由c++编写的二进制代码，所以开发者无法获取到该启动类的引用，也就不能通过引用来进行操作。这个加载器是加载$JAVA_HOME/jre/lib下面的类库（或者通过参数-Xbootclasspath指定）。

2、EXTClassLoader：扩展类加载器，ExtClassLoader会加载 $JAVA_HOME/jre/lib/ext下的类库（或者通过参数-Djava.ext.dirs指定）。

3、AppClassLoader:应用程序加载器，会加载java环境变量CLASSPATH所指定的路径下的类库，而CLASSPATH所指定的路径可以通过Systemn.getProperty(“java.class.path”)获取，该变量可以覆盖。

4、CustomClassLoader：自定义加载器，就是用户自己定义的CLassLoader，比如tomcat的standardClassLoader属于这一类。

**ClassLoader双亲委派机制：**
1、当APPClassLoader加载一个class时，它首先不会自己去加载这个类，而是把类加载请求委派给父类加载器EXTClassloader去完成。

2、当EXTClassLoader加载一个class时，它首先不会去尝试加载这个类，而是把类加载请求委派给BootStrapClassLoader去完成。

3、如果BottStrapClassLoader加载失败，会使用EXTClassLoader去尝试加载。

4、若EXTClassLoader也加载失败，则会使用APPClassLoader来加载，如果APPClassLoader也加载失败，则会报出异常ClassNotFundException.

### 总结

1、为什么要给spring boot工程打的可执行jar包瘦身
2、spring boot的三种启动器说明
3、如何配置PropertiesLauncher启动器实现外部依赖包的加载
4、指出了通过指定-Djava.ext.dirs参数实现外部依赖包加载的问题
5、扩展说明了java的双亲委派加载机制
6、外部依赖包加载不到Oracle驱动包的解决办法