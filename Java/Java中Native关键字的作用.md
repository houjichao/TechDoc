初次遇见 native是在 java.lang.Object 源码中的一个hashCode方法：

```
public native int hashCode();
```

为什么有个native呢？这是我所要学习的地方。所以下面想要总结下native。

[回到顶部](http://www.cnblogs.com/Qian123/p/5702574.html#_labelTop)

## 一、认识 native 即 JNI,Java Native Interface

凡是一种语言，都希望是纯。比如解决某一个方案都喜欢就单单这个语言来写即可。Java平台有个用户和本地C代码进行互操作的API，称为Java Native Interface (Java本地接口)。



 

[回到顶部](http://www.cnblogs.com/Qian123/p/5702574.html#_labelTop)

## 二、用 Java 调用 C 的“Hello，JNI”

我们需要按照下班方便的步骤进行：

**1、创建一个Java类**，里面包含着一个 native 的方法和加载库的方法 loadLibrary。HelloNative.java 代码如下：

```
public class HelloNative
{
    static
    {
        System.loadLibrary("HelloNative");
    }
     
    public static native void sayHello();
     
    @SuppressWarnings("static-access")
    public static void main(String[] args)
    {
        new HelloNative().sayHello();
    }
}
```

首先让大家注意的是native方法，那个加载库的到后面也起作用。native 关键字告诉编译器（其实是JVM）调用的是该方法在外部定义，这里指的是C。如果大家直接运行这个代码， JVM会告之：“A Java Exception has occurred.”控制台输出如下：

```
Exception in thread "main" java.lang.UnsatisfiedLinkError: no HelloNative in java.library.path
    at java.lang.ClassLoader.loadLibrary(Unknown Source)
    at java.lang.Runtime.loadLibrary0(Unknown Source)
    at java.lang.System.loadLibrary(Unknown Source)
    at HelloNative.<clinit>(HelloNative.java:5)
```

这是程序使用它的时候，虚拟机说不知道如何找到sayHello，手动写，不多赘述