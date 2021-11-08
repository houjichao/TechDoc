### 1.什么是serialVersionUID

​        serialVersionUID用作Serializable类中的版本控件。如果您没有显式声明serialVersionUID，JVM将根据您的Serializable类的各个方面自动为您执行此操作，如Java（TM）对象序列化规范中所述。
​        序列化运行时将每个可序列化类与版本号相关联，称为serialVersionUID，在反序列化期间使用该版本号来验证序列化对象的发送方和接收方是否已加载与该序列化兼容的该对象的类。如果接收者为具有与相应发送者类的serialVersionUID不同的对象加载了一个类，则反序列化将导致InvalidClassException。
​        通俗理解就是serialVersionUID是适用于Java的序列化机制，Java的序列化机制是通过判断类的serialVersionUID来验证版本一致性的。在进行反序列化时，JVM会把传来的字节流中的serialVersionUID与本地相应实体类的serialVersionUID进行比较，如果相同就认为是一致的，可以进行反序列化，否则就会出现序列化版本不一致的异常，即是java.io.InvalidClassException。
**serialVersionUID两种生成方式：**
a.显式声明，该字段必须是static，final和long类型：
private static final long serialVersionUID = 1L;
b.如果没有显式声明serialVersionUID，JVM将使用自己的算法生成默认SerialVersionUID。

### 2.java.io.InvalidClassException产生原因？

– Client is using SUN’s JVM in Windows.
– Server is using JRockit in Linux.
The client sends a serializable class with default generated
serialVersionUID (e.g 123L) to the server over socket, the server may
generate a different serialVersionUID (e.g 124L) during deserialization
process, and raises an unexpected InvalidClassExceptions.
（译文如下）

客户端在Windows中使用SUN的JVM。
服务器在Linux中使用JRockit。
客户端通过套接字向服务器发送带有默认生成的serialVersionUID（例如123L）的可序列化类，服务器可以在反序列化过程中生成不同的serialVersionUID（例如124L），并引发意外的InvalidClassExceptions。

### 3.java.io.InvalidClassException解决方案

It is strongly recommended that all serializable classes explicitly declare serialVersionUID values, since the default serialVersionUID computation is highly sensitive to class details that may vary depending on compiler implementations, and can thus result in unexpected InvalidClassExceptions during deserialization. Therefore, to guarantee a consistent serialVersionUID value across different java compiler implementations, a serializable class must declare an explicit serialVersionUID value.
（译文如下）
        强烈建议所有可序列化类显式声明serialVersionUID值，因为默认的serialVersionUID计算对类细节高度敏感，这些细节可能因编译器实现而异，因此在反序列化期间可能导致意外的InvalidClassExceptions。因此，为了保证跨不同java编译器实现的一致的serialVersionUID值，可序列化类必须声明显式的serialVersionUID值。

### 4.idea推荐插件

idea推荐安装使用GenerateSerialVersionUID插件
可参考：https://blog.csdn.net/csdn565973850/article/details/88852454