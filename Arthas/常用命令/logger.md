# logger

> 查看logger信息，更新logger level

### 查看指定classloader的logger信息

注意hashcode是变化的，需要先查看当前的ClassLoader信息，提取对应ClassLoader的hashcode。

如果你使用`-c`，你需要手动输入hashcode：`-c <hashcode>`

对于只有唯一实例的ClassLoader可以通过`--classLoaderClass`指定class name，使用起来更加方便：

```
logger --classLoaderClass sun.misc.Launcher$AppClassLoader
```

- 注: 这里classLoaderClass 在 java 8 是 sun.misc.Launcher$AppClassLoader，而java 11的classloader是jdk.internal.loader.ClassLoaders$AppClassLoader。

`--classLoaderClass` 的值是ClassLoader的类名，只有匹配到唯一的ClassLoader实例时才能工作，目的是方便输入通用命令，而`-c <hashcode>`是动态变化的。

### 更新logger level

```
[arthas@2062]$ logger --name ROOT --level debug
update logger level success.
```

### 指定classloader更新 logger level

默认情况下，logger命令会在SystemClassloader下执行，如果应用是传统的`war`应用，或者spring boot fat jar启动的应用，那么需要指定classloader。

可以先用 `sc -d yourClassName` 来查看具体的 classloader hashcode，然后在更新level时指定classloader：

```
[arthas@2062]$ logger -c 2a139a55 --name ROOT --level debug
```

### 查看没有appender的logger的信息

默认情况下，`logger`命令只打印有appender的logger的信息。如果想查看没有`appender`的logger的信息，可以加上参数`--include-no-appender`。

注意，通常输出结果会很长。