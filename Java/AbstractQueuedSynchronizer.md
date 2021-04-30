# 前言

Java并发编程系列第四篇`AbstractQueuedSynchronizer`，文章风格依然是图文并茂，通俗易懂，本文带读者们深入理解`AbstractQueuedSynchronizer`设计思想。

# 内容大纲

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/91528623d75946829ece7b66b2d65417~tplv-k3u1fbpfcp-zoom-1.image)

# 基础

`AbstractQueuedSynchronizer`抽象同步队列简称`A Q S`，它是实现同步器的基础组件，如常用的`ReentrantLock、Semaphore、CountDownLatch`等。

`A Q S`定义了一套多线程访问共享资源的同步模板，解决了实现同步器时涉及的大量细节问题，能够极大地减少实现工作，虽然大多数开发者可能永远不会使用`A Q S`实现自己的同步器（`J U C`包下提供的同步器基本足够应对日常开发），但是知道`A Q S`的原理对于架构设计还是很有帮助的，面试还可以吹吹牛，下面是`A Q S`的组成结构。

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/737c4c938c904bcb8a9d034b6818ec2d~tplv-k3u1fbpfcp-zoom-1.image)

三部分组成，`state`同步状态、`Node`组成的`CLH`队列、`ConditionObject`条件变量（**包含`Node`组成的条件单向队列**），下面会分别对这三部分做介绍。

先贴下`AbstractQueuedSynchronizer`提供的核心函数，混个脸熟就够了，后面会讲解

**状态**

- `getState()`：返回同步状态
- `setState(int newState)`：设置同步状态
- `compareAndSetState(int expect, int update)`：使用`C A S`设置同步状态
- `isHeldExclusively()`：当前线程是否持有资源

**独占资源（不响应线程中断）**

- `tryAcquire(int arg)`：独占式获取资源，子类实现
- `acquire(int arg)`：独占式获取资源模板
- `tryRelease(int arg)`：独占式释放资源，子类实现
- `release(int arg)`：独占式释放资源模板

**共享资源（不响应线程中断）**

- `tryAcquireShared(int arg)`：共享式获取资源，返回值大于等于0则表示获取成功，否则获取失败，子类实现
- `acquireShared(int arg)`：共享式获取资源模板
- `tryReleaseShared(int arg)`：共享式释放资源，子类实现
- `releaseShared(int arg)`：共享式释放资源模板

这里补充下，获取独占、共享资源操作还提供超时与响应中断的扩展函数，有兴趣的读者可以去`AbstractQueuedSynchronizer`源码了解。

## 同步状态

在`A Q S`中维护了一个同步状态变量`state`，`getState`函数获取同步状态，`setState、compareAndSetState`函数修改同步状态，对于`A Q S`来说，线程同步的关键是对`state`的操作，可以说获取、释放资源是否成功都是由`state`决定的，比如`state>0`代表可获取资源，否则无法获取，所以`state`的具体语义由实现者去定义，现有的`ReentrantLock、ReentrantReadWriteLock、Semaphore、CountDownLatch`定义的`state`语义都不一样。

- **`ReentrantLock`的`state`用来表示是否有锁资源**
- **`ReentrantReadWriteLock`的`state`高`16`位代表读锁状态，低`16`位代表写锁状态**
- **`Semaphore`的`state`用来表示可用信号的个数**
- **`CountDownLatch`的`state`用来表示计数器的值**

## CLH队列

`CLH`是`A Q S`内部维护的`FIFO`（**先进先出**）双端双向队列（**方便尾部节点插入**），基于链表数据结构，当一个线程竞争资源失败，就会将等待资源的线程封装成一个`Node`节点，通过`C A S`原子操作插入队列尾部，最终不同的`Node`节点连接组成了一个`CLH`队列，所以说`A Q S`通过`CLH`队列管理竞争资源的线程，个人总结`CLH`队列具有如下几个优点：

- 先进先出保证了公平性
- 非阻塞的队列，通过自旋锁和`C A S`保证节点插入和移除的原子性，实现无锁快速插入
- 采用了自旋锁思想，所以`CLH`也是一种基于链表的可扩展、高性能、公平的自旋锁

### Node内部类

`Node`是`A Q S`的内部类，每个等待资源的线程都会封装成`Node`节点组成`C L H`队列、等待队列，所以说`Node`是非常重要的部分，理解它是理解`A Q S`的第一步。

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/25cd1c5dd841492c97ddd1003a2c7b4d~tplv-k3u1fbpfcp-zoom-1.image)

列`Node`类中的变量都很好理解，只有`waitStatus、nextWaiter`没有细说，下面做个补充说明

**waitStatus等待状态如下**

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/73fc541af3324a6abe5f6e2a292402e2~tplv-k3u1fbpfcp-zoom-1.image)

**nextWaiter特殊标记**

- **`Node`在`CLH`队列时，`nextWaiter`表示共享式或独占式标记**
- **`Node`在条件队列时，`nextWaiter`表示下个`Node`节点指针**

### 流程概述

线程获取资源失败，封装成`Node`节点从`C L H`队列尾部入队并阻塞线程，某线程释放资源时会把`C L H`队列首部`Node`节点关联的线程唤醒（**此处的首部是指第二个节点，后面会细说**），再次获取资源。

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/d5d69bafebb64835b0d39d35764ed700~tplv-k3u1fbpfcp-zoom-1.image)

### 入队

获取资源失败的线程需要封装成`Node`节点，接着尾部入队，在`A Q S`中提供`addWaiter`函数完成`Node`节点的创建与入队。

```java
   /**
     * @author: 程序猿阿星
     * @description:  Node节点入队-CLH队列
     * @param mode 标记  Node.EXCLUSIVE独占式 or Node.SHARED共享式
     */
    private Node addWaiter(Node mode) {
        //根据当前线程创建节点，等待状态为0
        Node node = new Node(Thread.currentThread(), mode);
        // 获取尾节点
        Node pred = tail;
        if (pred != null) {
            //如果尾节点不等于null，把当前节点的前驱节点指向尾节点
            node.prev = pred;
            //通过cas把尾节点指向当前节点
            if (compareAndSetTail(pred, node)) {
                //之前尾节点的下个节点指向当前节点
                pred.next = node;
                return node;
            }
        }
        //如果添加失败或队列不存在，执行end函数
        enq(node);
        return node;
    }
```

添加节点的时候，如果从`C L H`队列已经存在，通过`C A S`快速将当前节点添加到队列尾部，如果添加失败或队列不存在，则指向`enq`函数自旋入队。

```java
    /**
     * @author: 程序猿阿星
     * @description: 自旋cas入队
     * @param node 节点
     */
    private Node enq(final Node node) {
        for (;;) { //循环
            //获取尾节点
            Node t = tail;
            if (t == null) {
                //如果尾节点为空，创建哨兵节点，通过cas把头节点指向哨兵节点
                if (compareAndSetHead(new Node()))
                    //cas成功，尾节点指向哨兵节点
                    tail = head;
            } else {
                //当前节点的前驱节点设指向之前尾节点
                node.prev = t;
                //cas设置把尾节点指向当前节点
                if (compareAndSetTail(t, node)) {
                    //cas成功，之前尾节点的下个节点指向当前节点
                    t.next = node;
                    return t;
                }
            }
        }
    }
```

通过自旋`C A S`尝试往队列尾部插入节点，直到成功，自旋过程如果发现`C L H`队列不存在时会初始化`C L H`队列，入队过程流程如下图

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/701b87f687724b229ac460de4bb20c42~tplv-k3u1fbpfcp-zoom-1.image)

**第一次循环**

1. 刚开始`C L H`队列不存在，`head`与`tail`都指向`null`
2. 要初始化`C L H`队列，会创建一个哨兵节点，`head`与`tail`都指向哨兵节点

**第二次循环** 3. 当前线程节点的前驱节点指向尾部节点（哨兵节点） 4. 设置当前线程节点为尾部，`tail`指向当前线程节点 5. 前尾部节点的后驱节点指向当前线程节点（当前尾部节点）

最后结合`addWaiter`与`enq`函数的入队流程图如下

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/275b4150d0194c7fbc04f489e3455d5d~tplv-k3u1fbpfcp-zoom-1.image)

### 出队

`C L H`队列中的节点都是获取资源失败的线程节点，当持有资源的线程释放资源时，会将`head.next`指向的线程节点唤醒（**`C L H`队列的第二个节点**），如果唤醒的线程节点获取资源成功，线程节点清空信息设置为头部节点（**新哨兵节点**），原头部节点出队（**原哨兵节点**）

**acquireQueued函数中的部分代码**

```java
//1.获取前驱节点
final Node p = node.predecessor();
//如果前驱节点是首节点，获取资源（子类实现）
if (p == head && tryAcquire(arg)) {
    //2.获取资源成功，设置当前节点为头节点，清空当前节点的信息，把当前节点变成哨兵节点
    setHead(node);
    //3.原来首节点下个节点指向为null
    p.next = null; // help GC
    //4.非异常状态，防止指向finally逻辑
    failed = false;
    //5.返回线程中断状态
    return interrupted;
}

private void setHead(Node node) {
    //节点设置为头部
    head = node;
    //清空线程
    node.thread = null;
    //清空前驱节点
    node.prev = null;
}
复制代码
```

只需要关注`1~3`步骤即可，过程非常简单，假设获取资源成功，更换头部节点，并把头部节点的信息清除变成哨兵节点，注意这个过程是不需要使用`C A S`来保证，因为只有一个线程能够成功获取到资源。

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/b9af1d40fd6f4d5aa3503027502d64dc~tplv-k3u1fbpfcp-zoom-1.image)

## 条件变量

`Object`的`wait、notify`函数是配合`Synchronized`锁实现线程间同步协作的功能，`A Q S`的`ConditionObject`条件变量也提供这样的功能，通过`ConditionObject`的`await`和`signal`两类函数完成。

不同于`Synchronized`锁，一个`A Q S`可以对应多个条件变量，而`Synchronized`只有一个。

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/c35050dca9df469e9f72348d49862556~tplv-k3u1fbpfcp-zoom-1.image)

如上图所示，`ConditionObject`内部维护着一个单向条件队列，不同于`C H L`队列，条件队列只入队执行`await`的线程节点，并且加入条件队列的节点，不能在`C H L`队列， 条件队列出队的节点，会入队到`C H L`队列。

当某个线程执行了`ConditionObject`的`await`函数，阻塞当前线程，线程会被封装成`Node`节点添加到条件队列的末端，其他线程执行`ConditionObject`的`signal`函数，会将条件队列头部线程节点转移到`C H L`队列参与竞争资源，具体流程如下图

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/b1dfd73d42a34efe8937a101ad3bf7fa~tplv-k3u1fbpfcp-zoom-1.image)

最后补充下，条件队列`Node`类是使用`nextWaiter`变量指向下个节点，并且因为是单向队列，所以`prev`与`next`变量都是`null`

# 进阶

`A Q S`采用了模板方法设计模式，提供了两类模板，一类是独占式模板，另一类是共享形模式，对应的模板函数如下

- 独占式
  - **`acquire`获取资源**
  - **`release`释放资源**
- 共享式
  - **`acquireShared`获取资源**
  - **`releaseShared`释放资源**

## 独占式获取资源

`acquire`是个模板函数，模板流程就是线程获取共享资源，如果获取资源成功，线程直接返回，否则进入`CLH`队列，直到获取资源成功为止，且整个过程忽略中断的影响，`acquire`函数代码如下

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/e6e67eb71fc64ccb9f11dd09e4892aa5~tplv-k3u1fbpfcp-zoom-1.image)

- 执行`tryAcquire`函数，`tryAcquire`是由子类实现，代表获取资源是否成功，如果资源获取失败，执行下面的逻辑
- 执行`addWaiter`函数（前面已经介绍过），根据当前线程创建出独占式节点，并入队`CLH`队列
- 执行`acquireQueued`函数，自旋阻塞等待获取资源
- 如果`acquireQueued`函数中获取资源成功，根据线程是否被中断状态，来决定执行线程中断逻辑

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/b1c44e38e0d54afa96d9e6c06e7618e5~tplv-k3u1fbpfcp-zoom-1.image)

`acquire`函数的大致流程都清楚了，下面来分析下`acquireQueued`函数，线程封装成节点后，是如何自旋阻塞等待获取资源的，代码如下

```java
    /**
     * @author: 程序猿阿星
     * @description: 自旋机制等待获取资源
     * @param node
     * @param arg
     * @return: boolean
     */
    final boolean acquireQueued(final Node node, int arg) {
        //异常状态，默认是
        boolean failed = true;
        try {
            //该线程是否中断过，默认否
            boolean interrupted = false;
            for (;;) {//自旋
                //获取前驱节点
                final Node p = node.predecessor();
                //如果前驱节点是首节点，获取资源（子类实现）
                if (p == head && tryAcquire(arg)) {
                    //获取资源成功，设置当前节点为头节点，清空当前节点的信息，把当前节点变成哨兵节点
                    setHead(node);
                    //原来首节点下个节点指向为null
                    p.next = null; // help GC
                    //非异常状态，防止指向finally逻辑
                    failed = false;
                    //返回线程中断状态
                    return interrupted;
                }
                /**
                 * 如果前驱节点不是首节点，先执行shouldParkAfterFailedAcquire函数，shouldParkAfterFailedAcquire做了三件事
                 * 1.如果前驱节点的等待状态是SIGNAL，返回true，执行parkAndCheckInterrupt函数，返回false
                 * 2.如果前驱节点的等大状态是CANCELLED，把CANCELLED节点全部移出队列（条件节点）
                 * 3.以上两者都不符合，更新前驱节点的等待状态为SIGNAL，返回false
                 */
                if (shouldParkAfterFailedAcquire(p, node) &&
                    //使用LockSupport类的静态方法park挂起当前线程，直到被唤醒，唤醒后检查当前线程是否被中断，返回该线程中断状态并重置中断状态
                    parkAndCheckInterrupt())
                    //该线程被中断过
                    interrupted = true;
                }
            } finally {
                // 尝试获取资源失败并执行异常，取消请求，将当前节点从队列中移除
                if (failed)
                    cancelAcquire(node);
            }
    }

复制代码
```

一图胜千言，核心流程图如下

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/5f9fbdbc8e044410b72abdcd7e34f239~tplv-k3u1fbpfcp-zoom-1.image)

## 独占式释放资源

有获取资源，自然就少不了释放资源，`A Q S`中提供了`release`模板函数来释放资源，模板流程就是线程释放资源成功，唤醒`CLH`队列的第二个线程节点（**首节点的下个节点**），代码如下

```java
    /**
     * @author: 程序猿阿星
     * @description: 独占式-释放资源模板函数
     * @param arg
     * @return: boolean
     */
    public final boolean release(int arg) {

        if (tryRelease(arg)) {//释放资源成功，tryRelease子类实现
            //获取头部线程节点
            Node h = head;
            if (h != null && h.waitStatus != 0) //头部线程节点不为null，并且等待状态不为0
                //唤醒CHL队列第二个线程节点
                unparkSuccessor(h);
            return true;
        }
        return false;
    }
    
    
    private void unparkSuccessor(Node node) {
        //获取节点等待状态
        int ws = node.waitStatus;
        if (ws < 0)
            //cas更新节点状态为0
            compareAndSetWaitStatus(node, ws, 0);
    
        //获取下个线程节点        
        Node s = node.next;
        if (s == null || s.waitStatus > 0) { //如果下个节点信息异常，从尾节点循环向前获取到正常的节点为止，正常情况不会执行
            s = null;
            for (Node t = tail; t != null && t != node; t = t.prev)
                if (t.waitStatus <= 0)
                    s = t;
        }
        if (s != null)
            //唤醒线程节点
            LockSupport.unpark(s.thread);
        }
    }

复制代码
```

`release`逻辑非常简单，流程图如下

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/5abfe3d852484aca900158c924be7015~tplv-k3u1fbpfcp-zoom-1.image)

## 共享式获取资源

`acquireShared`是个模板函数，模板流程就是线程获取共享资源，如果获取到资源，线程直接返回，否则进入`CLH`队列，直到获取到资源为止，且整个过程忽略中断的影响，`acquireShared`函数代码如下

```java
    /**
     * @author: 程序猿阿星
     * @description: 共享式-获取资源模板函数
     * @param arg
     * @return: void
     */
    public final void acquireShared(int arg) {
        /**
         * 1.负数表示失败
         * 2.0表示成功，但没有剩余可用资源
         * 3.正数表示成功且有剩余资源
         */
        if (tryAcquireShared(arg) < 0) //获取资源失败，tryAcquireShared子类实现
            //自旋阻塞等待获取资源
            doAcquireShared(arg);
    }
    
    
复制代码
```

`doAcquireShared`函数与独占式的`acquireQueued`函数逻辑基本一致，唯一的区别就是下图红框部分

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/a19509ee62d34ef992d0eefbbc057283~tplv-k3u1fbpfcp-zoom-1.image)

- **节点的标记是共享式**
- **获取资源成功，还会唤醒后续资源，因为资源数可能`>0`，代表还有资源可获取，所以需要做后续线程节点的唤醒**

## 共享式释放资源

`A Q S`中提供了`releaseShared`模板函数来释放资源，模板流程就是线程释放资源成功，唤醒CHL队列的第二个线程节点（**首节点的下个节点**），代码如下

```java
    /**
     * @author: 程序猿阿星
     * @description: 共享式-释放资源模板函数
     * @param arg
     * @return: boolean
     */
    public final boolean releaseShared(int arg) {
        if (tryReleaseShared(arg)) {//释放资源成功，tryReleaseShared子类实现
            //唤醒后继节点
            doReleaseShared();
            return true;
        }
        return false;
    }
    
    private void doReleaseShared() {
        for (;;) {
            //获取头节点
            Node h = head;
            if (h != null && h != tail) {
                int ws = h.waitStatus;
    
                if (ws == Node.SIGNAL) {//如果头节点等待状态为SIGNAL
                    if (!compareAndSetWaitStatus(h, Node.SIGNAL, 0))//更新头节点等待状态为0
                        continue;            // loop to recheck cases
                    //唤醒头节点下个线程节点
                    unparkSuccessor(h);
                }
                //如果后继节点暂时不需要被唤醒，更新头节点等待状态为PROPAGATE
                else if (ws == 0 &&
                         !compareAndSetWaitStatus(h, 0, Node.PROPAGATE))
                    continue;               
            }
            if (h == head)              
                break;
        }
    }

复制代码
```

与独占式释放资源区别不大，都是唤醒头节点的下个节点，就不做过多描述了。

# 实战

说了这么多理论，现在到实战环节了，正如前文所述，`A Q S`定义了一套多线程访问共享资源的同步模板，解决了实现同步器时涉及的大量细节问题，能够极大地减少实现工作，现在我们基于`A Q S`实现一个不可重入的独占锁，直接使用`A Q S`提供的独占式模板，只需明确`state`的语义与实现`tryAcquire`与`tryRelease`函数（**获取资源与释放资源**），在这里`state`为`0`表示锁没有被线程持有，`state`为`1`表示锁已经被某个线程持有，由于是不可重入锁，所以不需要记录持有锁线程的获取锁次数。

不可重入的独占锁代码如下

```java
/**
 * @Author 程序猿阿星
 * @Description 不可重入的独占锁
 */
public class NonReentrantLock implements Lock {


    /**
     * @Author 程序猿阿星
     * @Description 自定义同步器
     */
    private static class Sync extends AbstractQueuedSynchronizer {

        /**
         * 锁是否被线程持有
         */
        @Override
        protected boolean isHeldExclusively() {
            //0：未持有 1：已持有
            return super.getState() == 1;
        }

        /**
         * 获取锁
         */
        @Override
        protected boolean tryAcquire(int arg) {
            if (arg != 1) {
                //获取锁操作，是需要把state更新为1，所以arg必须是1
                throw new RuntimeException("arg not is 1");
            }
            if (compareAndSetState(0, arg)) {//cas 更新state为1成功，代表获取锁成功
                //设置持有锁线程
                setExclusiveOwnerThread(Thread.currentThread());
                return true;
            }
            return false;
        }

        /**
         * 释放锁
         */
        @Override
        protected boolean tryRelease(int arg) {
            if (arg != 0) {
                //释放锁操作，是需要把state更新为0，所以arg必须是0
                throw new RuntimeException("arg not is 0");
            }
            //清空持有锁线程
            setExclusiveOwnerThread(null);
            //设置state状态为0，此处不用cas，因为只有获取锁成功的线程才会执行该函数，不需要考虑线程安全问题
            setState(arg);
            return true;
        }

        /**
         * 提供创建条件变量入口
         */
        public ConditionObject createConditionObject() {
            return new ConditionObject();
        }

    }

    private final Sync sync = new Sync();

    /**
     * 获取锁
     */
    @Override
    public void lock() {
        //Aqs独占式-获取资源模板函数
        sync.acquire(1);
    }
        
    /**
     * 获取锁-响应中断
     */
    @Override
    public void lockInterruptibly() throws InterruptedException {
        //Aqs独占式-获取资源模板函数(响应线程中断)
        sync.acquireInterruptibly(1);
    }

    /**
     * 获取锁是否成功-不阻塞
     */
    @Override
    public boolean tryLock() {
        //子类实现
        return sync.tryAcquire(1);
    }
    
    /**
     * 获取锁-超时机制
     */
    @Override
    public boolean tryLock(long time, TimeUnit unit) throws InterruptedException {
        //Aqs独占式-获取资源模板函数(超时机制)
        return sync.tryAcquireNanos(1,unit.toNanos(time));
    }
    
    /**
     * 释放锁
     */
    @Override
    public void unlock() {
        //Aqs独占式-释放资源模板函数
        sync.release(0);
    }
    
    /**
     * 创建条件变量
     */
    @Override
    public Condition newCondition() {
        return sync.createConditionObject();
    }
}


复制代码
```

`NonReentrantLock`定义了一个内部类`Sync`，`Sync`用来实现具体的锁操作，它继承了`A Q S`，因为使用的是独占式模板，所以重写`tryAcquire`与`tryRelease`函数，另外提供了一个创建条件变量的入口，下面使用自定义的独占锁来同步两个线程对`j++`。

```java
    private static int j = 0;

    public static void main(String[] agrs) throws InterruptedException {
        NonReentrantLock  nonReentrantLock = new NonReentrantLock();

        Runnable runnable = () -> {
            //获取锁
            nonReentrantLock.lock();
            for (int i = 0; i < 100000; i++) {
                j++;
            }
            //释放锁
            nonReentrantLock.unlock();
        };

        Thread thread = new Thread(runnable);
        Thread threadTwo = new Thread(runnable);

        thread.start();
        threadTwo.start();

        thread.join();
        threadTwo.join();

        System.out.println(j);
    }
    


无论执行多少次输出内容都是：
200000
复制代码
```

# AQS简化流程图

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/bda407eb78c84b4db30f9b054705c3a4~tplv-k3u1fbpfcp-zoom-1.image)

# 唠叨唠叨

十分抱歉，这次拖更了，因为`AbstractQueuedSynchronizer`内容有点多，所以花了较长的时间，希望各位大佬理解一下，手下留情~

另外本文只是阿星的理解，如果哪里有问题，也欢迎各位大佬纠正，下一篇开始写`ReentrantLock`，因为有`AbstractQueuedSynchronizer`铺垫，`ReentrantLock`理解起来会非常简单，所以大家一定要看懂`AbstractQueuedSynchronizer`，最后如果觉得阿星的文章对您有帮助，也请一键三连支持阿星（**点赞、再看、转发**）

# 历史好文推荐

- [写给小白看的LockSupport](https://mp.weixin.qq.com/s/xSro-bwg__ir9EXwoCJ-rg)
- [13张图，深入理解Synchronized](https://mp.weixin.qq.com/s/esLXkYi3KiYMxYDiVXSnkA)
- [由浅入深CAS，小白也能与BAT面试官对线](https://mp.weixin.qq.com/s/GR7lLGp9JH4bsAgQB3uLrw)
- [小白也能看懂的Java内存模型](https://mp.weixin.qq.com/s/48OLw2koXwrcJ5YOKSNmFw)
- [保姆级教学，22张图揭开ThreadLocal](https://mp.weixin.qq.com/s/woFmXOt5zOxidlkduIfruA)
- [进程、线程与协程傻傻分不清？一文带你吃透！](https://mp.weixin.qq.com/s/jhOSjVyRA6rNKqVT2pKMIQ)
- [什么是线程安全？一文带你深入理解](https://mp.weixin.qq.com/s/_ATueOBN4UM2bim_1hDBFQ)