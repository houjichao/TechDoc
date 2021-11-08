### 一、 Instrumentation 与 attach 机制

Arthas 热更新功能看起来很神奇，实际上离不开 JDK 一些 API，分别为 instrument API 与 attach API。

#### 1.1 Instrumentation

Java Instrumentation 是 JDK5 之后提供接口。使用这组接口，我们可以获取到正在运行 JVM 相关信息，使用这些信息我们构建相关监控程序检测 JVM。另外， 最重要我们可以**替换**和**修改**类的，这样就实现了热更新。

Instrumentation 存在两种使用方式，一种为 pre-main 方式，这种方式需要在虚拟机参数指定 Instrumentation 程序，然后程序启动之前将会完成修改或替换类。使用方式如下:

```
java -javaagent:jar Instrumentation_jar -jar xxx.jar
```

有没有觉得这种启动方式很熟悉，仔细观察一下 IDEA 运行输出窗口。

另外很多应用监控工具，如：zipkin、pinpoint、skywalking。

这种方式只能在应用启动之前生效，存在一定的局限性。

JDK6 针对这种情况作出了改进，增加 ***agent-main***方式。我们可以在应用启动之后，再运行**Instrumentation**程序。启动之后，只有连接上相应的应用，我们才能做出相应改动，这里我们就需要使用 Java 提供 attach API。

#### 2.2 Attach API

Attach API 位于 tools.jar 包，可以用来连接目标 JVM。Attach API 非常简单，内部只有两个主要的类，VirtualMachine 与 VirtualMachineDescriptor。

VirtualMachine 代表一个 JVM 实例， 使用它提供 attach 方法，我们就可以连接上目标 JVM。

```
 VirtualMachine vm = VirtualMachine.attach(pid);
```

VirtualMachineDescriptor 则是一个描述虚拟机的容器类，通过该实例我们可以获取到 JVM PID(进程 ID),该实例主要通过 VirtualMachine#list 方法获取。

    for (VirtualMachineDescriptor descriptor : VirtualMachine.list()){
       System.out.println(descriptor.id());
    }
介绍完热更新涉及的相关原理，接下去使用上面 API 实现热更新功能。

### 二、实现热更新功能

这里我们使用 Instrumentation `agent-main` 方式。

#### 2.1、实现 agent-main

首先需要编写一个类，包含以下两个方法：

```
public static void agentmain (String agentArgs, Instrumentation inst);          [1]
public static void agentmain (String agentArgs);            [2]
```

> 上面的方法只需要实现一个即可。若两个都实现， [1] 优先级大于 [2]，将会被优先执行。

接着读取外部传入 class 文件，调用 `Instrumentation#redefineClasses`，这个方法将会使用新 class 替换当前正在运行的 class，这样我们就完成了类的修改。

```
public class AgentMain {
    /**
     *
     * @param agentArgs 外部传入的参数，类似于 main 函数 args
     * @param inst
     */
    public static void agentmain(String agentArgs, Instrumentation inst) {
        // 从 agentArgs 获取外部参数
        System.out.println("开始热更新代码");
        // 这里将会传入 class 文件路径
        String path = agentArgs;
        try {
            // 读取 class 文件字节码
            RandomAccessFile f = new RandomAccessFile(path, "r");
            final byte[] bytes = new byte[(int) f.length()];
            f.readFully(bytes);
            // 使用 asm 框架获取类名
            final String clazzName = readClassName(bytes);

            // inst.getAllLoadedClasses 方法将会获取所有已加载的 class
            for (Class clazz : inst.getAllLoadedClasses()) {
                // 匹配需要替换 class
                if (clazz.getName().equals(clazzName)) {
                    ClassDefinition definition = new ClassDefinition(clazz, bytes);
                    // 使用指定的 class 替换当前系统正在使用 class
                    inst.redefineClasses(definition);
                }
            }

        } catch (UnmodifiableClassException | IOException | ClassNotFoundException e) {
            System.out.println("热更新数据失败");
        }


    }

    /**
     * 使用 asm 读取类名
     *
     * @param bytes
     * @return
     */
    private static String readClassName(final byte[] bytes) {
        return new ClassReader(bytes).getClassName().replace("/", ".");
    }
}
```

完成代码之后，我们还需要往 jar 包 manifest 写入以下属性。

```
## 指定 agent-main 全名
Agent-Class: com.andyxh.AgentMain
## 设置权限，默认为 false，没有权限替换 class
Can-Redefine-Classes: true
```

我们使用 `maven-assembly-plugin`，将上面的属性写入文件中。

```
<plugin>
    <artifactId>maven-assembly-plugin</artifactId>
    <version>3.1.0</version>
    <configuration>
        <!--指定最后产生 jar 名字-->
        <finalName>hotswap-jdk</finalName>
        <appendAssemblyId>false</appendAssemblyId>
        <descriptorRefs>
            <!--将工程依赖 jar 一块打包-->
            <descriptorRef>jar-with-dependencies</descriptorRef>
        </descriptorRefs>
        <archive>
            <manifestEntries>
                <!--指定 class 名字-->
                <Agent-Class>
                    com.andyxh.AgentMain
                </Agent-Class>
                <Can-Redefine-Classes>
                    true
                </Can-Redefine-Classes>
            </manifestEntries>
            <manifest>
                <!--指定 mian 类名字，下面将会使用到-->
                <mainClass>com.andyxh.JvmAttachMain</mainClass>
            </manifest>
        </archive>
    </configuration>
    <executions>
        <execution>
            <id>make-assembly</id> <!-- this is used for inheritance merges -->
            <phase>package</phase> <!-- bind to the packaging phase -->
            <goals>
                <goal>single</goal>
            </goals>
        </execution>
    </executions>
</plugin>

```

到这里我们就完成热更新主要代码，接着使用 Attach API，连接目标虚拟机，触发热更新的代码。

```
public class JvmAttachMain {
    public static void main(String[] args) throws IOException, AttachNotSupportedException, AgentLoadException, AgentInitializationException {
        // 输入参数，第一个参数为需要 Attach jvm pid 第二参数为 class 路径
        if(args==null||args.length<2){
            System.out.println("请输入必要参数，第一个参数为 pid，第二参数为 class 绝对路径");
            return;
        }
        String pid=args[0];
        String classPath=args[1];
        System.out.println("当前需要热更新 jvm pid 为 " pid);
        System.out.println("更换 class 绝对路径为 " classPath);
        // 获取当前 jar 路径
        URL jarUrl=JvmAttachMain.class.getProtectionDomain().getCodeSource().getLocation();
        String jarPath=jarUrl.getPath();

        System.out.println("当前热更新工具 jar 路径为 " jarPath);
        VirtualMachine vm = VirtualMachine.attach(pid);//7997是待绑定的jvm进程的pid号
        // 运行最终 AgentMain 中方法
        vm.loadAgent(jarPath, classPath);
    }
}
```

在这个启动类，我们最终调用 `VirtualMachine#loadAgent`，JVM 将会使用上面 AgentMain 方法使用传入 class 文件替换正在运行 class。

#### 2.2、运行

这里加入一个方法获取 JVM 运行进程 ID。

```
public class HelloService {

    public static void main(String[] args) throws InterruptedException {
        System.out.println(getPid());
        while (true){
            TimeUnit.SECONDS.sleep(1);
            hello();
        }
    }

    public static void hello(){
        System.out.println("hello world");
    }

    /**
     * 获取当前运行 JVM PID
     * @return
     */
    private static String getPid() {
        // get name representing the running Java virtual machine.
        String name = ManagementFactory.getRuntimeMXBean().getName();
        System.out.println(name);
        // get pid
        return name.split("@")[0];
    }

}
```

首先运行 `HelloService`，获取当前 PID,接着复制 `HelloService` 代码到另一个工程，修改 `hello` 方法输出 `hello agent`，重新编译生成新的 class 文件。

最后在命令行运行生成的 jar 包。

demo github:https://github.com/9526xu/hotswap-example