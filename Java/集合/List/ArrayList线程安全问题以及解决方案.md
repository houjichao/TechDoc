#### ArrayList是否为线程安全的？

否

####  ArrayList产生线程安全的原因是什么？

 ArrayList出现问题的方法为add方法，首先我们看下add方法的源码。

```
    public boolean add(E e) {
        ensureCapacityInternal(size + 1);  // Increments modCount!!
        elementData[size++] = e;
        return true;
    }
```

可以看出add方法主要包含两个重要的操作：

1、判断集合容量是否还足够添加元素：此方法在多线程情况下会出现下标越界的问题，假如初始容量为5，线程A调用add方法，而elementData的容量为6，因此无需扩容。线程B同时调用add方法，而elementData的容量为6，因此也无需扩容，但是实际需要容量为7。

2、将元素添加到指定的位置：由于size++也是非原子操作，此方法可能出现线程B将线程Aadd位置的元素覆盖，而应该正确add的位置元素为null。

有什么方法能够解决上述的问题？

 1、在使用多线程add元素时使用synchronized方法，保证只有一个线程在执行add方法。

2、使用CopyOnWriteArrayList,该集合读写分离，在写数据时，使用lock锁控制并发，在读数据时分情况而定。