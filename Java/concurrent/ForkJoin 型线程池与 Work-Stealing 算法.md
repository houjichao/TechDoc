JDK 1.7 时，标准类库添加了 `ForkJoinPool`，作为对 Fork/Join 型线程池的实现。*Fork* 在英文中有 **分叉** 的意思，而 *Join* 有 **合并** 的意思。`ForkJoinPool` 的功能也是如此：**Fork** 将大任务分叉为多个小任务，然后让小任务执行，**Join** 是获得小任务的结果，然后进行合并，将合并的结果作为大任务的结果 —— 并且这会是一个递归的过程 —— 因为任务如果足够大，可以将任务多级分叉直到任务足够小。

![Fork-Join](https://segmentfault.com/img/bVIh7x?w=1282&h=663)

由此可见，`ForkJoinPool` 可以满足 **并行** 地实现 **分治算法（Divide-and-Conquer)** 的需要。

------

`ForkJoinPool` 的类图如下：
![ForkJoinPool 的类图](https://segmentfault.com/img/bVIihv?w=332&h=362)

可以看到 `ForkJoinPool` 实现了 `ExecutorService` 接口，所以首先 `ForkJoinPool` 也是一个 `ExecutorService` （**线程池**）。因而 `Runnable` 和 `Callable` 类型的任务，`ForkJoinPool` 也可以通过 `submit`、`invokeAll` 和 `invokeAny` 等方法来执行。但是标准类库还为 `ForkJoinPool` 定义了一种新的任务，它就是 `ForkJoinTask<V>`。

`ForkJoinTask` 类图：
![ForkJoinTask 类图](https://segmentfault.com/img/bVIino?w=300&h=273)

`ForkJoinTask<V>` 用来专门定义 Fork/Join 型任务 —— 完成将大任务分割为小任务以及合并结果的工作。一般我们不需要直接使用 `ForkJoinTask<V>`，而是通过继承它的子类 `RecursiveAction` 和 `RecursiveTask` 并实现对应的抽象方法 —— `compute` ，来定义我们自己的任务。其中，`RecursiveAction` 是不带返回值的 Fork/Join 型任务，所以使用此类任务并不产生结果，也就不涉及到结果的合并；而 `RecursiveTask` 是带返回值的 Fork/Join 型任务，使用此类任务的话，在任务结束前，我们需要进行结果的合并。其中，通过 `ForkJoinTask<V>` 的 `fork` 方法，我们可以产生子任务并执行；通过 `join` 方法，我们可以获得子任务的结果。

------

`ForkJoinPool` 可以使用三种方法用来执行 `ForkJoinTask`：

`invoke` 方法：
![invoke 方法](https://segmentfault.com/img/bVIiIM?w=385&h=24)

`invoke` 方法用来执行一个带返回值的任务（通常继承自`RecursiveTask`），并且该方法是阻塞的，直到任务执行完毕，该方法才会停止阻塞并返回任务的执行结果。

`submit` 方法：
![submit 方法](https://segmentfault.com/img/bVIiSS?w=510&h=24)

除了从 `ExecutorService` 继承的 `submit` 方法外，`ForkJoinPool` 还定义了用来执行 `ForkJoinTask` 的 `submit` 方法 —— 一般该 `submit` 方法用来执行带返回值的`ForkJoinTask`（通常继承自`RecursiveTask`）。该方法是非阻塞的，调用之后将任务提交给 `ForkJoinPool` 去执行便立即返回，返回的便是已经提交到 `ForkJoinPool` 去执行的 *task* —— 由类图可知 `ForkJoinTask` 实现了 `Future` 接口，所以可以直接通过 *task* 来和已经提交的任务进行交互。

`execute` 方法：
![execute 方法](https://segmentfault.com/img/bVIiUF?w=386&h=22)

除了从 `Executor` 获得的 `execute` 方法外，`ForkJoinPool` 也定义了用来执行`ForkJoinTask` 的 `execute` 方法 —— 一般该 `execute` 方法用来执行不带返回值的`ForkJoinTask`（通常继承自`RecursiveAction`） ，该方法同样是非阻塞的。

------

现在让我们来实践下 `ForkJoinPool` 的功能：计算 π 的值。计算 π 的值有一个通过多项式方法，即：π = 4 * (1 - 1/3 + 1/5 - 1/7 + 1/9 - ……)，而且多项式的项数越多，计算出的 π 的值越精确。

首先我们定义用来估算 π 的 `PiEstimateTask`：

```arduino
class PiEstimateTask extends RecursiveTask<Double> {

    private final long begin;
    private final long end;
    private final long threshold; // 分割任务的临界值

    public PiEstimateTask(long begin, long end, long threshold) {
        this.begin = begin;
        this.end = end;
        this.threshold = threshold;
    }

    @Override
    protected Double compute() {  // 实现 compute 方法
        if (end - begin <= threshold) {  // 临界值之下，不再分割，直接计算

            int sign; // 符号，多项式中偶数位取 1，奇数位取 -1（位置从 0 开始）
            double result = 0.0;
            
            for (long i = begin; i < end; i++) {
                sign = (i & 1) == 0 ? 1 : -1;
                result += sign / (i * 2.0 + 1);
            }

            return result * 4;
        }

        // 分割任务
        long middle = (begin + end) / 2;
        PiEstimateTask leftTask = new PiEstimateTask(begin, middle, threshold);
        PiEstimateTask rightTask = new PiEstimateTask(middle, end, threshold);

        leftTask.fork();  // 异步执行 leftTask
        rightTask.fork(); // 异步执行 rightTask

        double leftResult = leftTask.join();   // 阻塞，直到 leftTask 执行完毕返回结果
        double rightResult = rightTask.join(); // 阻塞，直到 rightTask 执行完毕返回结果

        return leftResult + rightResult; // 合并结果
    }

}
```

然后我们使用 `ForkJoinPool` 的 `invoke` 执行 `PiEstimateTask`：

```gradle
public class ForkJoinPoolTest {

    public static void main(String[] args) throws Exception {
        ForkJoinPool forkJoinPool = new ForkJoinPool(4);
    
        // 计算 10 亿项，分割任务的临界值为 1 千万
        PiEstimateTask task = new PiEstimateTask(0, 1_000_000_000, 10_000_000);
    
        double pi = forkJoinPool.invoke(task); // 阻塞，直到任务执行完毕返回结果
    
        System.out.println("π 的值：" + pi);
        
        forkJoinPool.shutdown(); // 向线程池发送关闭的指令
    }
}
```

运行结果：
![运行结果](https://segmentfault.com/img/bVIiGs?w=248&h=44)

我们也可以使用 `submit` 方法异步的执行任务（此处 `submit` 方法返回的 *future* 指向的对象即提交任务时的 *task*)：

```gradle
public static void main(String[] args) throws Exception {
    ForkJoinPool forkJoinPool = new ForkJoinPool(4);

    PiEstimateTask task = new PiEstimateTask(0, 1_000_000_000, 10_000_000);
    Future<Double> future = forkJoinPool.submit(task); // 不阻塞
    
    double pi = future.get();
    System.out.println("π 的值：" + pi);
    System.out.println("future 指向的对象是 task 吗：" + (future == task));
    
    forkJoinPool.shutdown(); // 向线程池发送关闭的指令
}
```

运行结果：
![运行结果](https://segmentfault.com/img/bVIiHX?w=299&h=62)

------

值得注意的是，选取一个合适的分割任务的临界值，对 `ForkJoinPool` 执行任务的效率有着至关重要的影响。临界值选取过大，任务分割的不够细，则不能充分利用 CPU；临界值选取过小，则任务分割过多，可能产生过多的子任务，导致过多的线程间的切换和加重 GC 的负担从而影响了效率。所以，需要根据实际的应用场景选择一个合适的分割任务的临界值。

------

`ForkJoinPool` 相比于 `ThreadPoolExecutor`，还有一个非常重要的特点（优点）在于，`ForkJoinPool`具有 **Work-Stealing** （工作窃取）的能力。**所谓 Work-Stealing，在 `ForkJoinPool` 中的实现为：线程池中每个线程都有一个互不影响的任务队列（双端队列），线程每次都从自己的任务队列的队头中取出一个任务来运行；如果某个线程对应的队列已空并且处于空闲状态，而其他线程的队列中还有任务需要处理但是该线程处于工作状态，那么空闲的线程可以从其他线程的队列的队尾取一个任务来帮忙运行 —— 感觉就像是空闲的线程去偷人家的任务来运行一样，所以叫 “工作窃取”。**

Work-Stealing 的适用场景是不同的任务的耗时相差比较大，即某些任务需要运行较长时间，而某些任务会很快的运行完成，这种情况下用 Work-Stealing 很合适；但是如果任务的耗时很平均，则此时 Work-Stealing 并不适合，因为窃取任务时不同线程需要抢占锁，这可能会造成额外的时间消耗，而且每个线程维护双端队列也会造成更大的内存消耗。所以 `ForkJoinPool` 并不是 `ThreadPoolExecutor` 的替代品，而是作为对 `ThreadPoolExecutor` 的补充。

------

总结：
`ForkJoinPool` 和 `ThreadPoolExecutor` 都是 `ExecutorService`（线程池），但`ForkJoinPool` 的独特点在于：

1. `ThreadPoolExecutor` 只能执行 `Runnable` 和 `Callable` 任务，而 `ForkJoinPool` 不仅可以执行 `Runnable` 和 `Callable` 任务，还可以执行 Fork/Join 型任务 —— `ForkJoinTask` —— 从而满足并行地实现分治算法的需要；
2. `ThreadPoolExecutor` 中任务的执行顺序是按照其在共享队列中的顺序来执行的，所以后面的任务需要等待前面任务执行完毕后才能执行，而 `ForkJoinPool` 每个线程有自己的任务队列，并在此基础上实现了 Work-Stealing 的功能，使得在某些情况下 `ForkJoinPool` 能更大程度的提高并发效率。



工作窃取(work-stealing)算法是指某个线程从其他队列里窃取任务来执行。
一个大任务分割为若干个互不依赖的子任务，为了减少线程间的竞争，把这些子任务分别放到不同的队列里，并未每个队列创建一个单独的线程来执行队列里的任务，线程和队列一一对应。比如线程1负责处理1队列里的任务，2线程负责2队列的。但是有的线程会先把自己队列里的任务干完，而其他线程对应的队列里还有任务待处理。干完活的线程与其等着，不如帮其他线程干活，于是它就去其他线程的队列里窃取一个任务来执行。而在这时它们可能会访问同一个队列，所以为了减少窃取任务线程和被窃取任务线程之间的竞争，通常会使用双端队列，被窃取任务线程永远从双端队列的头部拿任务执行，而窃取任务线程永远从双端队列的尾部拿任务执行。

![这里写图片描述](https://img-blog.csdn.net/20180707151815286?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3BhbmdlMTk5MQ==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)


优点：充分利用线程进行并行计算，减少线程间的竞争。
缺点：在某些情况下还是会存在竞争，比如双端队列里只有一个任务时。并且该算法会消耗更多的系统资源， 比如创建多个线程和多个双端队列。

在Java中：

* 可以使用LinkedBlockingDeque来实现工作窃取算法
* JDK1.7引入的Fork/Join框架就是基于工作窃取算法
  