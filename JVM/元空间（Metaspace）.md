#### 一、从方法区(PermGen)到元空间(Metaspace)

- **方法区(PermGen)**

1. JDK1.8以前的HotSpot JVM有**方法区**，也叫**永久代(permanent generation)**。
2. 方法区用于存放已被虚拟机加载的**类信息、常量、静态变量，即编译器编译后的代码**。
3. 方法区是一片**连续的堆空间**，通过**-XX:MaxPermSize**来设定永久代最大可分配空间，当JVM加载的类信息容量超过了这个值，会报**OOM:PermGen**错误。
4. 永久代的**GC**是和老年代(old generation)捆绑在一起的，无论谁满了，都会触发永久代和老年代的垃圾收集。
5. JDK1.7开始了方法区的部分移除：**符号引用(Symbols)**移至**native heap**，**字面量(interned strings)**和**静态变量(class statics)**移至**java heap。**

- **为什么要用Metaspace替代方法区**
   随着动态类加载的情况越来越多，这块内存变得不太可控，如果设置小了，系统运行过程中就容易出现内存溢出，设置大了又浪费内存。

#### 二、Metaspace的组成

Metaspace由两大部分组成：Klass Metaspace和NoKlass Metaspace。

- **Klass Metaspace**

1. Klass Metaspace就是用来存**klass**的，就是class文件在jvm里的运行时数据结构（不过我们看到的类似A.class其实是存在heap里的，是java.lang.Class的对象实例）。

2. 这部分默认放在

   Compressed Class Pointer Space

   中，是一块连续的内存区域，

   紧接着Heap，和之前的perm一样。通过-XX:CompressedClassSpaceSize来控制这块内存的大小，默认是1G。

   下图展示了对象的存储模型，_mark是对象的Mark Word，_klass是元数据指针

   ![img](https:////upload-images.jianshu.io/upload_images/9643870-2b4003d55470e200.jpg?imageMogr2/auto-orient/strip|imageView2/2/w/638/format/webp)

   has ccs.jpg

3. Compressed Class Pointer Space

   不是必须有的

   ，如果设置了

   -XX:-UseCompressedClassPointers

   ，或者

   -Xmx设置大于32G

   ，就不会有这块内存，这种情况下klass都会存在NoKlass Metaspace里。

   ![img](https:////upload-images.jianshu.io/upload_images/9643870-cc60edcdfa610703.jpg?imageMogr2/auto-orient/strip|imageView2/2/w/728/format/webp)

   no ccs.jpg

- **NoKlass Metaspace**

1. NoKlass Metaspace专门来存klass相关的其他的内容，比如method，constantPool等，可以由多块不连续的内存组成。
2. 这块内存是必须的，虽然叫做NoKlass Metaspace，但是也其实可以存klass的内容，上面已经提到了对应场景。
3. NoKlass Metaspace在本地内存中分配。

- **指针压缩**

1. 64位平台上默认打开
2. 设置-XX:+UseCompressedOops压缩对象指针， **oops**指的是普通对象指针(ordinary object pointers)， 会被压缩成32位。
3. 设置-XX:+UseCompressedClassPointers压缩类指针，会被压缩成32位。

#### 三、Metaspace内存管理

1. 在metaspace中，类和其元数据的生命周期与其对应的类加载器相同，只要类的类加载器是存活的，在Metaspace中的类元数据也是存活的，不能被回收。
2. 每个加载器有单独的存储空间。
3. 省掉了GC扫描及压缩的时间。
4. 当GC发现某个类加载器不再存活了，会把对应的空间整个回收。

Metaspace VM使用一个**块分配器(chunking allocator)**来管理Metaspace空间的内存分配。块的大小依赖于类加载器的类型。
 Metaspace VM中有一个全局的可使用的**块列表（a global free list of chunks）**。当类加载器需要一个块的时候，类加载器从全局块列表中取出一个块，添加到它自己维护的块列表中。当类加载器死亡，它的块将会被释放，归还给全局的块列表。
 块（chunk）会进一步被划分成blocks,每个block存储一个元数据单元(a unit of metadata)。Chunk中Blocks的是分配线性的（pointer bump）。这些chunks被分配在内存映射空间(memory mapped(mmapped) spaces)之外。在一个全局的虚拟内存映射空间（global virtual mmapped spaces）的链表，当任何虚拟空间变为空时，就将该虚拟空间归还回操作系统。

![img](https:////upload-images.jianshu.io/upload_images/9643870-6447c5018eae19d6.jpg?imageMogr2/auto-orient/strip|imageView2/2/w/600/format/webp)

metachunks.jpg


 上面这幅图展示了Metaspace使用metachunks在mmapeded virual spaces分配的情形。



#### 四、metaspace的主要参数

MetaspaceSize
 MaxMetaspaceSize
 CompressedClassSpaceSize
 MinMetaspaceExpansion
 MaxMetaspaceExpansion
 MinMetaspaceFreeRatio
 MaxMetaspaceFreeRatio
 UseLargePagesInMetaspace
 InitialBootClassLoaderMetaspaceSize

#### MetaspaceSize

metaspaceGC发生的初始阈值，也是最小阈值，默认20.8M左右，与之对比的主要是指Klass Metaspace与NoKlass Metaspace两块committed的内存和。

- 触发metaspaceGC的阈值是不断变化的：当metaspace使用的内存接近阈值时，会尝试增大阈值。metaspaceGC后也会调整阈值。

#### MaxMetaspaceSize

由于metaspace大部分在本地内存中分配，默认基本是无穷大，但仍然受本地内存大小的限制。为了防止metaspace被无止境使用，建议设置这个参数。

- 这个参数会限制metaspace(包括了Klass Metaspace以及NoKlass Metaspace)被committed的内存大小，会保证committed的内存不会超过这个值，一旦超过就会触发GC。
- 和MaxPermSize的区别，根据MaxMetaspaceSize，并不会在jvm启动的时候分配一块这么大的内存出来，而根据MaxPermSize分配的内存则是固定大小。

#### CompressedClassSpaceSize

Compressed Class Pointer Space区域的大小，默认1G。
 如果设置了-XX:-UseCompressedClassPointers，或者-Xmx设置大于32G，则这个参数不生效。

#### MinMetaspaceExpansion

MinMetaspaceExpansion和MaxMetaspaceExpansion这两个参数这两个参数和扩容其实并没有直接的关系，并不是为了增大committed的内存。
 主要是在比较特殊的场景下救急使用，增大触发metaspace GC的阈值，延迟GC的发生。
 默认332.8K，增大触发metaspace GC阈值的最小要求。
 如果需要分配的内存小于MinMetaspaceExpansion，则将metaspace GC的阈值提升MinMetaspaceExpansion。

#### MaxMetaspaceExpansion

默认5.2M，增大触发metaspace GC阈值的最大要求。
 如果需要分配的内存大于MinMetaspaceExpansion但是小于MaxMetaspaceExpansion，那增量就是MaxMetaspaceExpansion。
 如果需要分配的内存超过了MaxMetaspaceExpansion，那增量就是MinMetaspaceExpansion加上要分配的内存大小

注：每次分配只会给对应的线程一次扩展触发metaspace GC阈值的机会，如果扩展了，但是还不能分配，那就只能等着做GC了。

#### MinMetaspaceFreeRatio

MinMetaspaceFreeRatio和下面的MaxMetaspaceFreeRatio，主要是影响触发metaspaceGC的阈值。

默认40，表示每次GC完之后，如果metaspace内存的空闲比例小于MinMetaspaceFreeRatio%，那么将尝试做扩容，增大触发metaspaceGC的阈值。
 不过这个增量至少是MinMetaspaceExpansion才会做，不然不会增加这个阈值。
 这个参数主要是为了避免触发metaspaceGC的阈值和gc之后committed的内存的量比较接近，于是将这个阈值进行扩大。

注：这里不用gc之后used的量来算，主要是担心可能出现committed的量超过了触发metaspaceGC的阈值，这种情况一旦发生会很危险，会不断做gc，这应该是jdk8在某个版本之后才修复的bug

#### MaxMetaspaceFreeRatio

默认70，这个参数和上面的参数基本是相反的，是为了避免触发metaspaceGC的阈值过大，而想对这个值进行缩小。
 这个参数在gc之后committed的内存比较小的时候并且离触发metaspaceGC的阈值比较远的时候，调整会比较明显。

#### UseLargePagesInMetaspace

默认false，这个参数是说是否在metaspace里使用LargePage，一般情况下我们使用4KB的page size，这个参数依赖于UseLargePages这个参数开启，不过这个参数我们一般不开。

#### InitialBootClassLoaderMetaspaceSize

64位下默认4M，32位下默认2200K，metasapce前面已经提到主要分了两大块，Klass Metaspace以及NoKlass Metaspace，而NoKlass Metaspace是由一块块内存组合起来的，这个参数决定了NoKlass Metaspace的第一个内存Block的大小，即2*InitialBootClassLoaderMetaspaceSize，同时为bootstrapClassLoader的第一块内存chunk分配了InitialBootClassLoaderMetaspaceSize的大小

#### 五、jstat里的metaspace字段

我们看GC是否异常，除了通过GC日志来做分析之外，我们还可以通过jstat这样的工具展示的数据来分析，前面我公众号里有篇文章介绍了jstat这块的实现，有兴趣的可以到我的公众号你假笨里去翻阅下jstat的这篇文章。

我们通过jstat可以看到metaspace相关的这么一些指标，分别是**M，CCS，MC，MU，CCSC，CCSU，MCMN，MCMX，CCSMN，CCSMX**

#### MC & MU & CCSC & CCSU

- MC表示Klass Metaspace以及NoKlass Metaspace两者总共committed的内存大小，单位是KB，虽然从上面的定义里我们看到了是capacity，但是实质上计算的时候并不是capacity，而是committed，这个是要注意的
- MU这个无可厚非，说的就是Klass Metaspace以及NoKlass Metaspace两者已经使用了的内存大小
- CCSC表示的是Klass Metaspace的已经被commit的内存大小，单位也是KB
- CCSU表示Klass Metaspace的已经被使用的内存大小

#### M & CCS

- M表示的是Klass Metaspace以及NoKlass Metaspace两者总共的使用率，其实可以根据上面的四个指标算出来，即(CCSU+MU)/(CCSC+MC)
- CCS表示的是NoKlass Metaspace的使用率，也就是CCSU/CCSC算出来的

PS：所以我们有时候看到M的值达到了90%以上，其实这个并不一定说明metaspace用了很多了，因为内存是慢慢commit的，所以我们的分母是慢慢变大的，不过当我们committed到一定量的时候就不会再增长了

#### MCMN & MCMX & CCSMN & CCSMX

- MCMN和CCSMN这两个值可以忽略，一直都是0
- MCMX表示Klass Metaspace以及NoKlass Metaspace两者总共的reserved的内存大小，比如默认情况下Klass Metaspace是通过CompressedClassSpaceSize这个参数来reserved 1G的内存，NoKlass Metaspace默认reserved的内存大小是2* InitialBootClassLoaderMetaspaceSize
- CCSMX表示Klass Metaspace reserved的内存大小





### 回顾

根据JVM内存区域的划分，简单的画了下方的这个示意图。区域主要分为两大块，一块是堆区（Heap），我们所New出的对象都会在堆区进行分配，在C语言中的malloc所分配的方法就是从Heap区获取的。而垃圾回收器主要是对堆区的内存进行回收的。

而另一部分则是非堆区，非堆区主要包括用于编译和保存本地代码的“代码缓存区(Code Cache)”、保存JVM自己的静态数据的“永生代（Perm Gen）”、存放方法参数局部变量等引用以及记录方法调用顺序的“Java虚拟机栈（JVM Stack）”和“本地方法栈（Local Method Stack）”。

![img](https://img2018.cnblogs.com/blog/285763/201901/285763-20190108221653081-1421492645.png)

垃圾回收器主要回收的是堆区中未使用的内存区域，并对相应的区域进行整理。在堆区中，又根据对象内存的存活时间或者对象大小，分为“年轻代”和“年老代”。“年轻代”中的对象是不稳定的易产生垃圾，而“年老代”中的对象比较稳定，不易产生垃圾。之所以将其分开，是分而治之，根据不同区域的内存块的特点，采取不同的内存回收算法，从而提高堆区的垃圾回收的效率。

永久代存放JVM运行时使用的类。永久代同样包含了Java SE库的类和方法。永久代的对象在full GC时进行垃圾收集。

### 一、元空间替换持久代

#### 1.1、持久代

　　PermGen space的全称是Permanent Generation space,是指内存的永久保存区域，说说为什么会内存益出：这一部分用于存放Class和Meta的信息,Class在被 Load的时候被放入PermGen space区域，它和和存放Instance的Heap区域不同,所以如果你的APP会LOAD很多CLASS的话,就很可能出现PermGen space错误。这种错误常见在web服务器对JSP进行pre compile的时候。

　　JVM 种类有很多，比如 Oralce-Sun Hotspot, Oralce JRockit, IBM J9, Taobao JVM（淘宝好样的！）等等。当然武林盟主是Hotspot了，这个毫无争议。需要注意的是，PermGen space是Oracle-Sun Hotspot才有，JRockit以及J9是没有这个区域。

持久代中包含了虚拟机中所有可通过反射获取到的数据，比如Class和Method对象。不同的Java虚拟机之间可能会进行类共享，因此持久代又分为只读区和读写区。

JVM用于描述应用程序中用到的类和方法的元数据也存储在持久代中。JVM运行时会用到多少持久代的空间取决于应用程序用到了多少类。除此之外，Java SE库中的类和方法也都存储在这里。

如果JVM发现有的类已经不再需要了，它会去回收（卸载）这些类，将它们的空间释放出来给其它类使用。Full GC会进行持久代的回收。

- JVM中类的元数据在Java堆中的存储区域。
- Java类对应的HotSpot虚拟机中的内部表示也存储在这里。
- 类的层级信息，字段，名字。
- 方法的编译信息及字节码。
- 变量
- 常量池和符号解析

持久代的大小

- 它的上限是MaxPermSize，默认是64M
- Java堆中的连续区域 : 如果存储在非连续的堆空间中的话，要定位出持久代到新对象的引用非常复杂并且耗时。卡表（card table），是一种记忆集（Remembered Set），它用来记录某个内存代中普通对象指针（oops）的修改。
- 持久代用完后，会抛出OutOfMemoryError "PermGen space"异常。解决方案：应用程序清理引用来触发类卸载；增加MaxPermSize的大小。
- 需要多大的持久代空间取决于类的数量，方法的大小，以及常量池的大小。

#### 1.2、为什么移除持久代

- 它的大小是在启动时固定好的——很难进行调优。-XX:MaxPermSize，设置成多少好呢？
- HotSpot的内部类型也是Java对象：它可能会在Full GC中被移动，同时它对应用不透明，且是非强类型的，难以跟踪调试，还需要存储元数据的元数据信息（meta-metadata）。
- 简化Full GC：每一个回收器有专门的元数据迭代器。
- 可以在GC不进行暂停的情况下并发地释放类数据。
- 使得原来受限于持久代的一些改进未来有可能实现

根据上面的各种原因，永久代最终被移除，**方法区移至Metaspace，字符串常量移至Java Heap**。

#### 1.3、移除持久代后，PermGen空间的状况

- 这部分内存空间将全部移除。
- JVM的参数：PermSize 和 MaxPermSize 会被忽略并给出警告（如果在启用时设置了这两个参数）。

![img](https://img2018.cnblogs.com/blog/285763/201912/285763-20191205135008326-1042628756.png)

 

 

### 二、元空间

随着JDK8的到来，JVM不再有PermGen。但类的元数据信息（metadata）还在，只不过不再是存储在连续的堆空间上，而是移动到叫做“Metaspace”的本地内存（Native memory）中。

![img](https://img2018.cnblogs.com/blog/285763/201912/285763-20191205113339760-1181483685.png)

### 2.1、metaspace的组成

- **Klass Metaspace:**Klass Metaspace就是用来存klass的，klass是我们熟知的class文件在jvm里的运行时数据结构，不过有点要提的是我们看到的类似A.class其实是存在heap里的，是java.lang.Class的一个对象实例。这块内存是紧接着Heap的，和我们之前的perm一样，这块内存大小可通过-XX:CompressedClassSpaceSize参数来控制，这个参数前面提到了默认是1G，但是这块内存也可以没有，假如没有开启压缩指针就不会有这块内存，这种情况下klass都会存在NoKlass Metaspace里，另外如果我们把-Xmx设置大于32G的话，其实也是没有这块内存的，因为会这么大内存会关闭压缩指针开关。还有就是这块内存最多只会存在一块。
- **NoKlass Metaspace**:NoKlass Metaspace专门来存klass相关的其他的内容，比如method，constantPool等，这块内存是由多块内存组合起来的，所以可以认为是不连续的内存块组成的。这块内存是必须的，虽然叫做NoKlass Metaspace，但是也其实可以存klass的内容，上面已经提到了对应场景。

Klass Metaspace和NoKlass Mestaspace都是所有classloader共享的，所以类加载器们要分配内存，但是每个类加载器都有一个SpaceManager，来管理属于这个类加载的内存小块。如果Klass Metaspace用完了，那就会OOM了，不过一般情况下不会，NoKlass Mestaspace是由一块块内存慢慢组合起来的，在没有达到限制条件的情况下，会不断加长这条链，让它可以持续工作。

元空间的本质和永久代类似，都是对JVM规范中方法区的实现。**不过元空间与永久代之间最大的区别在于：元空间并不在虚拟机中，而是使用本地内存。**因此，默认情况下，元空间的大小仅受本地内存限制，但可以通过以下参数来指定元空间的大小： 
　　-XX:MetaspaceSize，初始空间大小，达到该值就会触发垃圾收集进行类型卸载，同时GC会对该值进行调整：如果释放了大量的空间，就适当降低该值；如果释放了很少的空间，那么在不超过MaxMetaspaceSize时，适当提高该值。 
　　-XX:MaxMetaspaceSize，最大空间，默认是没有限制的。 
　　除了上面两个指定大小的选项以外，还有两个与 GC 相关的属性： 
　　-XX:MinMetaspaceFreeRatio，在GC之后，最小的Metaspace剩余空间容量的百分比，减少为分配空间所导致的垃圾收集 
　　-XX:MaxMetaspaceFreeRatio，在GC之后，最大的Metaspace剩余空间容量的百分比，减少为释放空间所导致的垃圾收集

　　-verbose参数是为了获取类型加载和卸载的信息

#### 2.2、元空间的特点

- 充分利用了Java语言规范中的好处：类及相关的元数据的生命周期与类加载器的一致。
- 每个加载器有专门的存储空间
- 只进行线性分配
- 不会单独回收某个类
- 省掉了GC扫描及压缩的时间
- 元空间里的对象的位置是固定的
- 如果GC发现某个类加载器不再存活了，会把相关的空间整个回收掉

#### 2.3、元空间的内存分配模型

- 绝大多数的类元数据的空间都从本地内存中分配
- 用来描述类元数据的类(klasses)也被删除了
- 分元数据分配了多个虚拟内存空间
- 给每个类加载器分配一个内存块的列表。块的大小取决于类加载器的类型; sun/反射/代理对应的类加载器的块会小一些
- 归还内存块，释放内存块列表
- 一旦元空间的数据被清空了，虚拟内存的空间会被回收掉
- 减少碎片的策略

我们来看下JVM是如何给元数据分配虚拟内存的空间的 

![img](https://images2018.cnblogs.com/blog/285763/201803/285763-20180306171746876-1967632355.png)

你可以看到虚拟内存空间是如何分配的(vs1,vs2,vs3) ，以及类加载器的内存块是如何分配的。CL是Class Loader的缩写。

#### 理解_mark和_klass指针

要想理解下面这张图，你得搞清楚这些指针都是什么东西。

JVM中，每个对象都有一个指向它自身类的指针，不过这个指针只是指向具体的实现类，而不是接口或者抽象类。

对于32位的JVM:

_mark : 4字节常量

_klass: 指向类的4字节指针 对象的内存布局中的第二个字段( _klass，在32位JVM中，相对对象在内存中的位置的偏移量是4，64位的是8)指向的是内存中对象的类定义。

64位的JVM：

_mark : 8字节常量

_klass: 指向类的8字节的指针

开启了指针压缩的64位JVM： _mark : 8字节常量

_klass: 指向类的4字节的指针

#### Java对象的内存布局

![img](https://images2018.cnblogs.com/blog/285763/201803/285763-20180306173026502-1011531412.png)

类指针压缩空间（Compressed Class Pointer Space）

**只有是64位平台上启用了类指针压缩才会存在这个区域**。对于64位平台，为了压缩JVM对象中的_klass指针的大小，引入了类指针压缩空间（Compressed Class Pointer Space）。

![img](https://images2018.cnblogs.com/blog/285763/201803/285763-20180306173101905-670251391.png)

## CompressedClassSpace

- java8移除了permanent generation，然后class metadata存储在native memory中，其大小默认是不受限的，可以通过-XX:MaxMetaspaceSize来限制
- 如果开启了-XX:+UseCompressedOops及-XX:+UseCompressedClassesPointers(`默认是开启`)，则UseCompressedOops会使用32-bit的offset来代表java object的引用，而UseCompressedClassPointers则使用32-bit的offset来代表64-bit进程中的class pointer；可以使用CompressedClassSpaceSize来设置这块的空间大小
- 如果开启了指针压缩，则CompressedClassSpace分配在MaxMetaspaceSize里头，即MaxMetaspaceSize=Compressed Class Space Size + Metaspace area (excluding the Compressed Class Space) Size
- 查看CompressedClassSpace大小，见《[十二、jdk工具之jcmd介绍（堆转储、堆分析、获取系统信息、查看堆外内存）](https://www.cnblogs.com/duanxz/p/6115722.html)》

压缩指针后的内存布局

![img](https://images2018.cnblogs.com/blog/285763/201803/285763-20180306173134936-1569355422.png)

指针压缩概要

- 64位平台上默认打开
- 使用-XX:+UseCompressedOops压缩对象指针 "oops"指的是普通对象指针("ordinary" object pointers)。 Java堆中对象指针会被压缩成32位。 使用堆基地址（如果堆在低26G内存中的话，基地址为0）
- 使用-XX:+UseCompressedClassPointers选项来压缩类指针
- 对象中指向类元数据的指针会被压缩成32位
- 类指针压缩空间会有一个基地址

#### 元空间和类指针压缩空间的区别

- 类指针压缩空间只包含类的元数据，比如InstanceKlass, ArrayKlass 仅当打开了UseCompressedClassPointers选项才生效 为了提高性能，Java中的虚方法表也存放到这里 这里到底存放哪些元数据的类型，目前仍在减少
- 元空间包含类的其它比较大的元数据，比如方法，字节码，常量池等。

### 三、元空间内存管理

元空间的内存管理由元空间虚拟机来完成。先前，对于类的元数据我们需要不同的垃圾回收器进行处理，现在只需要执行元空间虚拟机的C++代码即可完成。在元空间中，类和其元数据的生命周期和其对应的类加载器是相同的。话句话说，只要类加载器存活，其加载的类的元数据也是存活的，因而不会被回收掉。 
准确的来说，每一个类加载器的存储区域都称作一个元空间，所有的元空间合在一起就是我们一直说的元空间。当一个类加载器被垃圾回收器标记为不再存活，其对应的元空间会被回收。在元空间的回收过程中没有重定位和压缩等操作。但是元空间内的元数据会进行扫描来确定Java引用。 
元空间虚拟机负责元空间的分配，其采用的形式为组块分配。组块的大小因类加载器的类型而异。在元空间虚拟机中存在一个全局的空闲组块列表。当一个类加载器需要组块时，它就会从这个全局的组块列表中获取并维持一个自己的组块列表。当一个类加载器不再存活，那么其持有的组块将会被释放，并返回给全局组块列表。类加载器持有的组块又会被分成多个块，每一个块存储一个单元的元信息。组块中的块是线性分配（指针碰撞分配形式）。组块分配自内存映射区域。这些全局的虚拟内存映射区域以链表形式连接，一旦某个虚拟内存映射区域清空，这部分内存就会返回给操作系统。

![img](https://images2018.cnblogs.com/blog/285763/201803/285763-20180306172133154-1878006260.png)

上图展示的是虚拟内存映射区域如何进行元组块的分配。类加载器1和3表明使用了反射或者为匿名类加载器，他们使用了特定大小组块。 而类加载器2和4根据其内部条目的数量使用小型或者中型的组块。

### 四、Metaspace调优

使用-XX:MaxMetaspaceSize参数可以设置元空间的最大值，默认是没有上限的，也就是说你的系统内存上限是多少它就是多少。-XX:MetaspaceSize选项指定的是元空间的初始大小，如果没有指定的话，元空间会根据应用程序运行时的需要动态地调整大小。

#### MaxMetaspaceSize的调优

- -XX:MaxMetaspaceSize={unlimited}
- 元空间的大小受限于你机器的内存
- 限制类的元数据使用的内存大小，以免出现虚拟内存切换以及本地内存分配失败。如果怀疑有类加载器出现泄露，应当使用这个参数；32位机器上，如果地址空间可能会被耗尽，也应当设置这个参数。
- **元空间的初始大小是21M**——这是GC的初始的高水位线，超过这个大小会进行Full GC来进行类的回收。
- 如果启动后GC过于频繁，请将该值设置得大一些
- 可以设置成和持久代一样的大小，以便推迟GC的执行时间

#### CompressedClassSpaceSize的调优

- 只有当-XX:+UseCompressedClassPointers开启了才有效
- -XX:CompressedClassSpaceSize=1G
- 由于这个大小在启动的时候就固定了的，因此最好设置得大点。
- 没有使用到的话不要进行设置
- JVM后续可能会让这个区可以动态的增长。不需要是连续的区域，只要从基地址可达就行；可能会将更多的类元信息放回到元空间中；未来会基于PredictedLoadedClassCount的值来自动的设置该空间的大小

正如前面提到了，Metaspace VM管理Metaspace空间的增长。但有时你会想通过在命令行显示的设置参数-XX:MaxMetaspaceSize来限制Metaspace空间的增长。默认情况下，-XX:MaxMetaspaceSize并没有限制，因此，在技术上，Metaspace的尺寸可以增长到交换空间，而你的本地内存分配将会失败。

每次垃圾收集之后，Metaspace VM会自动的调整high watermark，推迟下一次对Metaspace的垃圾收集。

这两个参数，-XX：MinMetaspaceFreeRatio和-XX：MaxMetaspaceFreeRatio,类似于GC的FreeRatio参数，可以放在命令行。

### 五、Metaspace可以使用的工具

针对Metaspace，JDK自带的一些工具做了修改来展示Metaspace的信息：

- **jmap -clstats** :打印类加载器的统计信息(取代了在JDK8之前打印类加载器信息的permstat)。
- **jstat -gc** :Metaspace的信息也会被打印出来。
- **jcmd GC.class_stats**:这是一个新的诊断命令，可以使用户连接到存活的JVM，转储Java类元数据的详细统计。

**示例1：jmap -clstats** 

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
[ciadmin@2-103test_app pos-gateway-cloud]$ jmap -clstats 26964
Attaching to process ID 26964, please wait...
Debugger attached successfully.
Server compiler detected.
JVM version is 25.131-b11
finding class loader instances ..done.
computing per loader stat ..done.
please wait.. computing liveness..................................................................................liveness analysis may be inaccurate ...
class_loader    classes    bytes    parent_loader    alive?    type

<bootstrap>    2699    4611703      null      live    <internal>
0x00000000a1013a00    1    880    0x00000000a001b938    dead    sun/reflect/DelegatingClassLoader@0x0000000100009df8
0x00000000a3e931e8    1    880      null      dead    sun/reflect/DelegatingClassLoader@0x0000000100009df8
0x00000000a083d280    1    1471    0x00000000a001b938    dead    sun/reflect/DelegatingClassLoader@0x0000000100009df8
0x00000000a1c057c8    1    880    0x00000000a001b938    dead    sun/reflect/DelegatingClassLoader@0x0000000100009df8
0x00000000a1013938    1    1474    0x00000000a001b938    dead    sun/reflect/DelegatingClassLoader@0x0000000100009df8
0x00000000a1013d38    1    1471    0x00000000a001b938    dead    sun/reflect/DelegatingClassLoader@0x0000000100009df8
0x00000000a141ae78    1    880    0x00000000a001b938    dead    sun/reflect/DelegatingClassLoader@0x0000000100009df8
0x00000000a083d1b8    1    1473    0x00000000a001b938    dead    sun/reflect/DelegatingClassLoader@0x0000000100009df8
0x00000000a163c658    1    880    0x00000000a001b938    dead    sun/reflect/DelegatingClassLoader@0x0000000100009df8
0x00000000a293afa8    1    1473    0x00000000a001b938    dead    sun/reflect/DelegatingClassLoader@0x0000000100009df8
0x00000000a19ec0a0    15    70893    0x00000000a001b938    live    com/aliyun/openservices/shade/com/alibaba/fastjson/util/ASMClassLoader@0x000000010066b7a0
0x00000000a2778848    1    1474    0x00000000a001b938    dead    sun/reflect/DelegatingClassLoader@0x0000000100009df8
0x00000000a141a900    1    880    0x00000000a001b938    dead    sun/reflect/DelegatingClassLoader@0x0000000100009df8
0x00000000a083d8c0    1    1473    0x00000000a001b938    dead    sun/reflect/DelegatingClassLoader@0x0000000100009df8
0x00000000a163c720    1    880    0x00000000a001b938    dead    sun/reflect/DelegatingClassLoader@0x0000000100009df8
...
0x00000000a094fe68    0    0    0x00000000a0007438    live    java/net/URLClassLoader@0x000000010000ecd0

total = 177    12836    20539140        N/A        alive=9, dead=168        N/A    
[ciadmin@2-103test_app pos-gateway-cloud]$ 
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

**示例二：jstat -gc 26964**

```
[ciadmin@2-103test_app pos-gateway-cloud]$ jstat -gc 26964
 S0C    S1C    S0U    S1U      EC       EU        OC         OU       MC     MU    CCSC   CCSU   YGC     YGCT    FGC    FGCT     GCT   
3072.0 3072.0 2384.8  0.0   62976.0   6699.1   445440.0   67911.5   69760.0 68124.8 8320.0 7929.0   3792   36.649  12      1.971   38.620
[ciadmin@2-103test_app pos-gateway-cloud]$ 
```

![img](https://images2018.cnblogs.com/blog/285763/201803/285763-20180306160630605-655433116.png)

**示例三：jcmd 5943 GC.class_stats**

```
[ciadmin@2-103test_app pos-gateway-cloud]$ jcmd 5943 GC.class_stats
5943:
GC.class_stats command requires -XX:+UnlockDiagnosticVMOptions
[ciadmin@2-103test_app pos-gateway-cloud]$ 
```

说是：应用程序启动时增加-XX:+UnlockDiagnosticVMOptions参数

加了上面的参数后，重新来一把如下：

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
D:\workspace\study\target\classes\com\dxz\jvm>jcmd 4332 GC.class_stats
4332:
Index Super  InstBytes KlassBytes annotations  CpAll MethodCount Bytecodes MethodAll  ROAll   RWAll   Total ClassName
    1    -1  258458040        480           0      0           0         0         0     24     584     608 [Ljava.lang.Object;
    2   368  217343856       1000           0   6864          51      3955     13744   8664   13888   22552 java.util.HashMap
    3   368  144895744       1432           0  15584          93      9536     37136  19104   37048   56152 java.util.concurrent.ConcurrentHashMap
    4   363   99615560        928           0   8232          24      1719      6040   4392   11304   15696 java.net.URLClassLoader
    5    -1   90560256        480           0      0           0         0         0     32     584     616 [Ljava.util.concurrent.ConcurrentHashMap$Node;
    6    -1   90559840        480           0      0           0         0         0     32     584     616 [Ljava.util.WeakHashMap$Entry;
    7   367   72447872       1384           0   5288          59      2245     13544   7080   14016   21096 java.util.Vector
    8   367   54335928       1320           0   4936          49      2359     12104   6600   12592   19192 java.util.ArrayList
    9   368   54335904        976           0   4952          32      1845     11968   4856   13744   18600 java.util.WeakHashMap
   10    14   54335856        656           0   7488          33      1513      8504   4792   12496   17288 sun.misc.URLClassPath
   11    14   45280240        504           0   4960          27      2551     11792   5232   12536   17768 java.security.AccessControlContext
   12    14   45279920        528           0   4328          12      1024      3760   2488    6496    8984 java.security.ProtectionDomain
   13    14   36226208        568           0   1344           8       223      1744   1024    2952    3976 java.util.concurrent.ConcurrentHashMap$Node
   14    -1   36224752        496           0   1144          14       109      2520   1112    3272    4384 java.lang.Object
   15    14   36224032        552           0   1840           7       410      2744   1288    4160    5448 java.lang.ref.ReferenceQueue
   16    14   36223936        552           0   5320          14      1796      4648   3552    7328   10880 java.security.CodeSource
   17     7   36223936       1424           0    864           6        88      1664    704    3552    4256 java.util.Stack
   18   373   27167952       1008           0    808           4        69      1000    592    2528    3120 java.util.Collections$SynchronizedSet
   19    -1   27167880        480           0      0           0         0         0     24     584     608 [Ljava.security.ProtectionDomain;
   20    14   18112048        496           0    360           2        10       920    216    1720    1936 java.lang.ref.ReferenceQueue$Lock
   21    -1   18111968        480           0      0           0         0         0     24     584     608 [Ljava.security.Principal;
...
  484    14          0        496           0   1416          20       737      3736   2240    3680    5920 sun.util.locale.LocaleUtils
            1535868936     298000        1536 955600        6934    264621   1445736 885528 1980368 2865896 Total
              53591.2%      10.4%        0.1%  33.3%           -      9.2%     50.4%  30.9%   69.1%  100.0%
Index Super  InstBytes KlassBytes annotations  CpAll MethodCount Bytecodes MethodAll  ROAll   RWAll   Total ClassName

D:\workspace\study\target\classes\com\dxz\jvm>
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

### 六、提高GC的性能

如果你理解了元空间的概念，很容易发现GC的性能得到了提升。

- Full GC中，元数据指向元数据的那些指针都不用再扫描了。很多复杂的元数据扫描的代码（尤其是CMS里面的那些）都删除了。
- 元空间只有少量的指针指向Java堆。这包括：类的元数据中指向java/lang/Class实例的指针;数组类的元数据中，指向java/lang/Class集合的指针。
- 没有元数据压缩的开销
- 减少了根对象的扫描（不再扫描虚拟机里面的已加载类的字典以及其它的内部哈希表）
- 减少了Full GC的时间
- G1回收器中，并发标记阶段完成后可以进行类的卸载

java8中metaspace总结如下：

#### PermGen 空间的状况

这部分内存空间将全部移除。

JVM的参数：PermSize 和 MaxPermSize 会被忽略并给出警告（如果在启用时设置了这两个参数）。

#### Metaspace 内存分配模型

大部分类元数据都在本地内存中分配。

用于描述类元数据的“klasses”已经被移除。

#### Metaspace 容量

默认情况下，类元数据只受可用的本地内存限制（容量取决于是32位或是64位操作系统的可用虚拟内存大小）。

新参数（MaxMetaspaceSize）用于限制本地内存分配给类元数据的大小。如果没有指定这个参数，元空间会在运行时根据需要动态调整。

#### Metaspace 垃圾回收

对于僵死的类及类加载器的垃圾回收将在元数据使用达到“MaxMetaspaceSize”参数的设定值时进行。

适时地监控和调整元空间对于减小垃圾回收频率和减少延时是很有必要的。持续的元空间垃圾回收说明，可能存在类、类加载器导致的内存泄漏或是大小设置不合适。

### 七、元空间的问题

前面已经提到，元空间虚拟机采用了组块分配的形式，同时区块的大小由类加载器类型决定。类信息并不是固定大小，因此有可能分配的空闲区块和类需要的区块大小不同，这种情况下可能导致碎片存在。元空间虚拟机目前并不支持压缩操作，所以碎片化是目前最大的问题。