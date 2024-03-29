JVM内存模型
JVM内存模型分为堆（heap）、元空间、栈、本地方法栈、程序计数器。
JDK8的内存模型如下图：

       堆和元空间是线程共享的，在Java虚拟机中只有一个堆、一个元空间，并在JVM启动的时候就创建，JVM停止才销毁。
       栈、本地方法栈、程序计数器是每个线程私有的，随着线程的创建而创建，随着线程的结束而死亡。


1. 本地方法栈
提供虚拟机使用到的本地Native方法服务。

2. 程序计数器(Program Counter Register)
       每个线程在创建后，都会产生自己的程序计数器和栈。程序计数器是一块较小的内存空间。由于CPU时间片轮限制，众多线程在并发执行过程中，处理器只会执行某个线程中的一条指令，这样必然涉及线程的切换。
       程序计数器用来存放下一个执行指令的行号。线程恢复要依赖程序计数器。此区域不会发生内存溢出异常。

3. 线程栈（Stack）
       JVM中的线程栈是描述Java方法执行的内存区域，它是线程私有的。每一个方法被调用直至执行完成的过程，就对应着一个栈帧在虚拟机栈中从入栈到出栈的过程。

栈帧存储着局部变量、操作数栈、动态链接、方法出口等信息，局部变量存储方法内的局部变量，操作数栈用来计算时临时存放变量，动态链接存放方法的元信息等，方法出口记录如哪个方法的本方法等。通过javap -c XX.class查看字节码文件。

       如果线程请求的栈深度大于虚拟机所允许的深度，将会抛出stackoverflowError通常出现在递归方法中；
       如果虚拟机可以动态扩展，但是无法申请到足够的内存时，就会抛出outOfMemoryError异常。

4. 方法区（Method Area）
       方法区中存放已经被虚拟机加载的类信息、常量、静态变量、即时编译器编译后的代码等数据。是JDK7之前存在的一个概念，这里仅做简单回顾，模型图如下：


       方法区与堆（Java Heap）一样，是各个线程共享的内存区域。

运行时常量池
       运行时常量池是方法区的一部分，存放着class文件元信息描述，编译后的代码数据，引用类型数据，类文件常量池。
       JDK1.7之前运行时常量池是方法区的一部分，JDK1.7及之后版本已经将运行时常量池从方法区中移了出来，开辟了一块区域Metaspace（元空间）存放运行时常量池，注意字符串常量池移至堆中。

PermGen（永久代）
       绝大部分 Java 程序员应该都见过 “java.lang.OutOfMemoryError: PermGen space “这个异常。这里的 “PermGen space”其实指的就是方法区。不过方法区和“PermGen space”又有着本质的区别，前者是 JVM 内存回收的规范，而后者则是 JVM 规范的一种实现，使用永久代来实现方法区而已。这样HotSpot的垃圾收集器就能像管理Java堆一样管理这部分内存。简单点说就是HotSpot虚拟机中内存模型的分代，其中新生代和老生代在堆中，永久代使用方法区实现。
       类及方法的信息等比较难确定其大小，因此对于永久代的大小指定比较困难，太小容易出现永久代溢出，太大则容易导致老年代溢出。由于方法区主要存储类的相关信息，所以对于动态生成类的情况比较容易出现永久代的内存溢出，容易产生Perm区的OOM。比如某个实际Web工程中，因为功能点比较多，在运行过程中，要不断动态加载很多的类，经常出现致命错误:Exception in thread ‘dubbo client x.x connector' java.lang.OutOfMemoryError: PermGenspac，为解决该问题，需要设定运行参数-XX:MaxPermSize= l280m，如果部署到新机器上，往往会因为JVM参数没有修改导致故障再现。不熟悉此应用的人排查问题时往往苦不堪言。除此之外，永久代会为 GC 带来不必要的复杂度，并且回收效率偏低；字符串存在永久代中，容易出现性能问题和内存溢出。

5. 元空间（Metaspace）
       JDK8使用元空间替换永久代，元空间的本质和永久代类似，都是对JVM规范中方法区的实现。之前永久代的内容：类元信息、字段、静态属性、方法、常量，还有运行时常量池等都移动至元空间，但是字符串常量移至堆内存。
       元空间在本地内存中分配，它并不是虚拟机运行时数据区的一部分，也不是Java虚拟机规范中定义的内存区域，它直接从操作系统中分配，因此不受Java堆大小的限制，但是会受到本机总内存的大小及处理器寻址空间的限制，因此它也可能导致OutOfMemoryError异常出现。“元空间”的大小可以动态调整，通过以下参数来指定元空间大小：
   -XX:MetaspaceSize，初始空间大小，达到该值就会触发垃圾收集进行类型卸载，同时GC会对该值进行调整：如果释放了大量的空间，就适当降低该值；如果释放了很少的空间，那么在不超过MaxMetaspaceSize时，适当提高该值
   -XX:MaxMetaspaceSize，最大空间，默认是没有限制的
   -XX:MinMetaspaceFreeRatio，在GC之后，最小的Metaspace剩余空间容量的百分比，减少为分配空间所导致的垃圾收集
   -XX:MaxMetaspaceFreeRatio，在GC之后，最大的Metaspace剩余空间容量的百分比，减少为释放空间所导致的垃圾收集
   元空间详解

6. 堆
       Heap存储着几乎所有的对象及数组，JVM8中把静态变量（字符串常量池）也移到堆区进行存储。

       堆是OOM故障最主要的发源地，也是是垃圾回收的主要区域,所以也被称为GC堆。通常情况下，它占用的空间是所有内存区域中最大的，但如果无节制地创建大量对象，也容易消耗完所有的空间。堆的内存空间既可以固定大小，也可运行时动态地调整，通过如下参数设定初始值和最大值，比如-Xms256M. -Xmx1024M。其中-X表示它是JVM运行参数，ms是memorystart初始堆容量的简称 ，mx是memory max最大堆容量的简称。但是在通常情况下，服务器在运行过程中，堆空间不断地扩容与回缩，势必形成不必要的系统压力，所以在线上生产环境中，JVM的Xms和Xmx设置成一样大小，避免在GC后调整堆大小时带来的额外压力。
       
       堆分成两大块:新生代和老年代，对象产生之初在新生代，步入暮年时进入老年代。
       新生代又分为1个Eden区+ 2个Survivor区，8:1:1的比例。
       绝大部分对象在Eden（意为伊甸园）区生成，当Eden区装填满的时候，会触发Young GC。垃圾回收的时候，在Eden区实现清除策略，没有被引用的对象则直接回收。依然存活的对象会被移送到Survivor（幸存者）区，这个区真是名副其实的存在。Survivor 区分为S0和S1两块内存空间，送到哪块空间呢?每次Young GC的时候，将存活的对象复制到未使用的那块空间，然后将当前正在使用的空间完全清除，交换两块空间的使用状态。
       如果Young GC要移送的对象大于Survivor区容量上限，或者超大对象的阈值超过eden分配担保设置值的上限，则直接移交给老年代.如果老年代也无法放下，则会触发Full Garbage Collection(Full GC)，如果依然无法放下，则抛OOM.。
       假如一些没有进取心的对象以为可以一直在新生代的Survivor区交换来交换去，那就错了。每个对象都有一个计数器，每次Young GC都会加1。-XX:MaxTenuringThreshold参数能配置计数器的值到达某个阈值的时候，对象从新生代晋升至老年代。默认值是15，可以在Survivor 区交换14次之后，晋升至老年代。



       堆出现OOM的概率是所有内存耗尽异常中最高的。出错时的堆内信息对解决问题非常有帮助，所以给JVM设置运行参数-XX:+HeapDumpOnOutOfMemoryError，让JVM遇到OOM异常时能输出堆内信息，使用-XX:HeapDumpPath参数指定dump路径。利用JVM参数-XX:OnOutOfMemoryError可以在发生OOM异常时，运行一个本机的脚本或指令。

jVM内存模型
内存回收
