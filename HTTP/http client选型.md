## 背景

​    大多的项目中都会涉及到第三方的服务调用，特别的，例如健康码这种大型的高并发项目中，会涉及大量的第三方的服务调用，而http的调用客户端将直接影响到系统的整体性能，希望通过一些测试、分析手段，能够为其他项目后续提供一个使用指引和参考。



## 目标选型

​    提及HttpClient，首先想起的是ApacheHttpClient，HttpClient 是 Apache Jakarta Common 下的子项目，用来提供高效的、最新的、功能丰富的支持 HTTP 协议的客户端编程工具包，并且它支持 HTTP 协议最新的版本和建议。HttpClient 已经应用在很多的项目中，比如 Apache Jakarta 上很著名的另外两个开源项目 Cactus 和 HTMLUnit 都使用了 HttpClient。



​    另外，OkHttp3凭借友好的框架，简便易懂的API以及原生封装高级功能的特性，在目前众多HTTP客户端框架中脱颖而出，并受到持续追捧，在各种底层SDK的封装中都能够看见OkHttp3作为HttpClient提供连接访问。



​    最后是Hutool-Http，Hutool系列工具追求简单易用，很多时候，我们想追求轻量级的Http客户端，并且追求简单易用。而JDK自带的HttpUrlConnection可以满足大部分需求。Hutool针对此类做了一层封装，使Http请求变得无比简单，使用Hutool-Http，甚至可以不用考虑https的SSL连接问题，极简的调用方式、自动识别各种标签编码，这也是越来越多项目使用Hutool系列工具的原因。



​    总的来说，会在三款目前比较流行的HttpClient客户端中进行测试、分析，希望后续能够为其他项目提供一个使用参考

- ApacheHttpClient
- OkHttp3
- Hutool-Http



## **测试&分析**

**
**

### **服务端设计**

服务端的设计上，使用SpringBoot框架，Controller使用了一个空方法，直接返回了一个空对像



```java
@PostMapping("/v1/handleDoValid")
public ServerResponse<DoValidResponseVO> handleDoValid(@RequestBody DoValidRequestVO requestVO) {
    DoValidResponseVO result = doValidService.handleDoValid(requestVO);
    return result != null ? ServerResponse.success(result) : ServerResponse.fail(ErrorCode.FAILED_OPERATION);
}
```

 

```java
  @Override
    public DoValidResponseVO handleDoValid(DoValidRequestVO requestVO) {
        // TODO 业务逻辑调用
        return new DoValidResponseVO();
    }
```

 

### **服务端配置**

8核16G的tlinux，启用2G的JVM堆

```
-Xms2048m -Xmx2048m -XX:NewRatio=1 -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=256m
```

 

### **客户端配置**

6核32G的win10



### **客户端设计-****ApacheHttpClient**

启用了ApacheHttpClient的连接池设置，并且最大连接默认设置为64

```java
SSLContext sslcontext = SSLClient.createIgnoreVerifySSL();
Assert.notNull(sslcontext, "sslcontext can not be null");
Registry<ConnectionSocketFactory> socketFactoryRegistry = RegistryBuilder.<ConnectionSocketFactory>create()
        .register("http", PlainConnectionSocketFactory.INSTANCE)
        .register("https", new SSLConnectionSocketFactory(sslcontext)).build();
// 连接池管理
PoolingHttpClientConnectionManager connManager = new PoolingHttpClientConnectionManager(socketFactoryRegistry);
connManager.setDefaultMaxPerRoute(64);
connManager.setMaxTotal(256);
final HttpClientBuilder builder = HttpClients.custom();
builder.setConnectionManager(connManager);
httpclient = builder.build();
requestConfig = RequestConfig.custom().setConnectionRequestTimeout(TIME_OUT).setSocketTimeout(TIME_OUT)
        .setConnectTimeout(TIME_OUT).build();
```

 

封装了POST调用方法

```java
private static volatile CloseableHttpClient httpclient;

public static String post(String url, String params, List<BasicNameValuePair> headers) {
    if (httpclient == null) {
        synchronized (HttpsClient.class) {
            if (httpclient == null) {
                createHttpclient();
            }
        }
    }
    HttpPost post = getHttpPost(url, params, headers);
    try (CloseableHttpResponse resp = httpclient.execute(post);
         InputStream is = resp.getEntity().getContent()) {
        final String s = IOUtils.toString(is, StandardCharsets.UTF_8);
        if (logger.isDebugEnabled()) {
            logger.debug("返回结果：{}", s);
        }
        return s;
    } catch (Exception e) {
        logger.error(e.getMessage(), e);
    } finally {
        post.releaseConnection();
    }
    return null;
}
```

 

调用方式中，模拟实际调用入参，新建对象，传入参数，接收返回结果

```java
public void doApacheHttp() {
    DoValidRequestVO requestVO = new DoValidRequestVO();
    requestVO.setHttpsUrl(UUID.randomUUID().toString());
    final List<BasicNameValuePair> headers =
            Collections.singletonList(new BasicNameValuePair("Content-Type", "application/json; charset=utf-8"));
    try {
        final String res = ApacheHttpClient.post(URL, JacksonUtils.toJson(requestVO), headers);
        Assert.assertNotNull(res);
    } catch (Exception e) {
        log.error("wrong in ApacheHttp  {}" , e.getMessage());
        WRONG.incrementAndGet();
    }
}
```

 

示例代码也可以说明Apache HttpClient主要的劣势在于，**API设计过于臃肿**，使用起来有诸多不便，此外Apache HttpClient对于一些功能没有提供原生化的支持，需要在每次使用的时候自定义（比如池化HTTP请求、空闲连接处理等），对于**首次接触的开发者就显得不是特别友好**。



### **客户端设计-****OkHttp3**

设置OkHttpClient单例

```java
final OkHttpClient.Builder builder = new OkHttpClient.Builder();
builder.connectTimeout(30L, TimeUnit.SECONDS).readTimeout(30L, TimeUnit.SECONDS)
        .writeTimeout(30L, TimeUnit.SECONDS);
final SSLContext sslContext = SSLClient.createIgnoreVerifySSL();
builder.sslSocketFactory(sslContext.getSocketFactory(), SSLClient.getTrustManager());
builder.connectionPool(new ConnectionPool(64, 5, TimeUnit.MINUTES));
client = builder.build();
```

 

封装POST方法

```java
public static String post(String url, String param, Headers headers) throws IOException {
    RequestBody body = RequestBody.create(JSON, param);
    Request request = new Request.Builder()
            .url(url).post(body).headers(headers)
            .build();
    try (Response response = client.newCall(request).execute()) {
        Assert.assertNotNull(response.body());
        return response.body().string();
    }
}
```

 

实际调用与ApacheHttpClient的设计完全一致

```java
public void doOkhttp3Http() throws IOException {
    DoValidRequestVO requestVO = new DoValidRequestVO();
    requestVO.setHttpsUrl(UUID.randomUUID().toString());
    try {
        final String res = Okhttp3HttpClient.post(URL, JacksonUtils.toJson(requestVO));
        Assert.assertNotNull(res);
    } catch (Exception e) {
        log.error("wrong in Okhttp3Http {}" , e.getMessage());
        WRONG.incrementAndGet();
    }
}
```

 

OkHttp3确实对新手很友好，代码的更易读，同时后者已经默认实现连接池、重试等功能，而ApacheHttpClient要是支持这些额外的功能则需要自定义实现



### **客户端设计-****Hutool-Http**

Hutool-Http提供的api封装程度最高，不需要客户端自己做任何封装了，直接调用，可以算是懒人必备

```java
public void doHutoolHttp() {
    DoValidRequestVO requestVO = new DoValidRequestVO();
    requestVO.setHttpsUrl(UUID.randomUUID().toString());
    try {
        final HttpRequest body = HttpRequest.post(URL).body(JacksonUtils.toJson(requestVO));
        final HttpResponse response = body.execute();
        final String res = response.body();
        Assert.assertNotNull(res);
    } catch (Exception e) {
        log.error("wrong in HutoolHttp");
        WRONG.incrementAndGet();
    }
}
```

 

### **最基本的源码分析**

- ApacheHttpClient默认是不带连接池的，示例中，单例初始化的时候我设置了一个64大小的连接池，超时等都是按默认设置，基本没大改动
- OkHttp3默认已经带了连接池，但是大小只有5，同样的我设置了一个64大小的连接池，其他取默认值
- Hutool-Http的源码我反复看了好几次，有几个点我是确认的，Hutool-Http中不提供连接池功能，当然也没法设置，每次http连接都是一次新建连接，特别我留意到其中关键的一段：

cn.hutool.http.HttpRequest#initConnection

```java
/**
 * 初始化网络连接
 */
private void initConnection() {
   if (null != this.httpConnection) {
      // 执行下次请求时自动关闭上次请求（常用于转发）
      this.httpConnection.disconnectQuietly();
   }

   this.httpConnection = HttpConnection
         .create(this.url.toURL(this.urlHandler), this.proxy)//
         .setConnectTimeout(this.connectionTimeout)//
         .setReadTimeout(this.readTimeout)//
         .setMethod(this.method)//
         .setHttpsInfo(this.hostnameVerifier, this.ssf)//
         // 关闭JDK自动转发，采用手动转发方式
         .setInstanceFollowRedirects(false)
         // 流方式上传数据
         .setChunkedStreamingMode(this.blockSize)
         // 覆盖默认Header
         .header(this.headers, true);

   if (null != this.cookie) {
      // 当用户自定义Cookie时，全局Cookie自动失效
      this.httpConnection.setCookie(this.cookie);
   } else {
      // 读取全局Cookie信息并附带到请求中
      GlobalCookieManager.add(this.httpConnection);
   }

   // 是否禁用缓存
   if (this.isDisableCache) {
      this.httpConnection.disableCache();
   }
}
```

 

【this.httpConnection】每次都先关闭（如果存在），然后重新create，选型的背景是希望高并发下的性能&稳定，**Hutool-Http除了没带连接池，****是否可以认为每次连接都是新建的？每次三次握手，特别是https的调用，是否可以认为这个的时耗花费必然要大于其他的2款框架？**



### **串行&低压力测试**

有了最基本的源码分析，那就准备开始测试了，先从低并发开始，测试框架选用**JMH**[https://github.com/openjdk/jmh]，核心代码

```java
@BenchmarkMode(Mode.Throughput)//基准测试类型
@OutputTimeUnit(TimeUnit.SECONDS)//基准测试结果的时间类型
@Warmup(iterations = 2)//预热的迭代次数
@Threads(2)//测试线程数量
@State(Scope.Thread)//该状态为每个线程独享
@Measurement(iterations = 10, time = -1, timeUnit = TimeUnit.SECONDS, batchSize = -1)
public class BenchmarkHttpTest {
    public static void main(String[] args) throws RunnerException {
        Options opt = new OptionsBuilder()
                .include(BenchmarkHttpTest.class.getSimpleName())
                .forks(1)
                .jvmArgs("-XX:+UnlockDiagnosticVMOptions", "-XX:+LogCompilation", "-XX:+TraceClassLoading", "-XX:+PrintAssembly", "-Xms2048m", "-Xmx2048m", "-XX:NewRatio=1", "-XX:MetaspaceSize=128m", "-XX:MaxMetaspaceSize=256m")
                .build();
        new Runner(opt).run();
    }
    
    @Benchmark
    public void doHutoolHttp() {
        ...
    }
    
    @Benchmark
    public void doOkhttp3Http() throws IOException {
        ...
    }
    
    @Benchmark
    public void doApacheHttp() {
        ...
    }
}
```

 

使用了2G的JVM堆，2线程并发，结果如下

```
Benchmark                         Mode  Cnt    Score    Error  Units
BenchmarkHttpTest.doApacheHttp   thrpt   10  136.622 ±  3.031  ops/s
BenchmarkHttpTest.doHutoolHttp   thrpt   10  133.508 ± 11.518  ops/s
BenchmarkHttpTest.doOkhttp3Http  thrpt   10   79.490 ± 10.080  ops/s
```

 

看见这个结果，我当时的反应是一堆问号，在客户端与服务端都是超低负载的情况下，这里主要有2个疑团：

1. 按照之前的想法，既然Hutool-Http每次都需要做握手，**ops就不应该与Apache HttpClient一致**
2. OkHttp3在低负载的环境下，吞吐比其他2个框架有较大差距

不过OkHttp3在低负载下的吞吐较低倒是其次的，因为目标是高并发下的表现，最让人奇怪的是Hutool-Http的表现令人不解，重复看了几次源码及Debug跟踪，请求和连接的构造与设想是一致的，并没特别的地方，为了弄清楚原因，我尝试查看抓包结果

![1](/Users/houjichao/Work/tmp/图片/1.png)

启动Wireshark，设置一下dst与src，重新执行Hutool-Http、ApacheHttpClient的基准测试

![2](/Users/houjichao/Work/tmp/图片/2.png)

![3](/Users/houjichao/Work/tmp/图片/3.png)

在高达10W多次的交互过程中，Hutool-Http与ApacheHttpClient都是只有**2次[SYN]，2次[SYN，ACK]，4次[RST，ACK]**，这个抓包结果恰好能够反映出实际结果，得益于http1.1中默认开启的keepalived，虽然代码上写的是新建连接，但是实际上，同一线程下，原有的连接可以持续复用而**不需要重新握手**



### **高并发测试**

将@Threads(2)调整为@Threads(1024)，即启用1024线程并发，ApacheHttpClient与OkHttp3的连接池调整为128，同时打开JMH的JVM堆栈分析，然后启用JProfiler做监控分析

```java
addProfiler(StackProfiler.class)  // JVM堆栈分析
```

 

结果如下



**ApacheHttpClient**

堆栈分析

```java
....[Thread state distributions]....................................................................
 79.0%         TIMED_WAITING
 10.8%         WAITING
 10.2%         RUNNABLE

....[Thread state: TIMED_WAITING]...................................................................
 78.9%  99.8% sun.misc.Unsafe.park
  0.2%   0.2% java.lang.Thread.sleep

....[Thread state: WAITING].........................................................................
 10.8% 100.0% sun.misc.Unsafe.park

....[Thread state: RUNNABLE]........................................................................
  9.9%  96.9% java.net.SocketInputStream.socketRead0
  0.2%   1.9% <stack is empty, everything is filtered?>
  0.0%   0.3% sun.misc.Unsafe.unpark
  0.0%   0.2% java.util.LinkedList.remove
  0.0%   0.2% java.net.SocketOutputStream.socketWrite0
  0.0%   0.1% com.tencent.abc.thirdparty.jmh_generated.BenchmarkHttpTest_doApacheHttp_jmhTest.doApacheHttp_Throughput
  0.0%   0.1% com.jprofiler.agent.LockManager.registerContendedEnter
  0.0%   0.1% com.jprofiler.agent.InstrumentationCallee.netIOMethod
  0.0%   0.0% com.jprofiler.agent.LockManager.finished
  0.0%   0.0% java.nio.HeapByteBuffer.<init>
  0.0%   0.2% <other>
```

 

吞吐量

```java
Benchmark                               Mode  Cnt     Score     Error  Units
BenchmarkHttpTest.doApacheHttp         thrpt   10  3738.146 ± 480.371  ops/s
BenchmarkHttpTest.doApacheHttp:·stack  thrpt            NaN              ---
```

 

资源监控

![4](/Users/houjichao/Work/tmp/图片/4.png)



**OkHttp3**

堆栈分析

```java
....[Thread state distributions]....................................................................
 92.7%         RUNNABLE
  4.3%         WAITING
  2.5%         BLOCKED
  0.5%         TIMED_WAITING

....[Thread state: RUNNABLE]........................................................................
 87.9%  94.8% java.net.SocketInputStream.socketRead0
  4.4%   4.7% java.net.DualStackPlainSocketImpl.waitForConnect
  0.2%   0.2% <stack is empty, everything is filtered?>
  0.1%   0.1% java.net.SocketOutputStream.socketWrite0
  0.0%   0.0% com.jprofiler.agent.InstrumentationCallee.netIOMethod
  0.0%   0.0% okio.AsyncTimeout.scheduleTimeout
  0.0%   0.0% java.lang.Throwable.fillInStackTrace
  0.0%   0.0% okhttp3.internal.connection.StreamAllocation.newStream
  0.0%   0.0% okio.AsyncTimeout.cancelScheduledTimeout
  0.0%   0.0% java.net.DualStackPlainSocketImpl.connect0

....[Thread state: WAITING].........................................................................
  4.3% 100.0% sun.misc.Unsafe.park

....[Thread state: BLOCKED].........................................................................
  1.3%  51.0% okio.AsyncTimeout.scheduleTimeout
  0.9%  37.5% okio.AsyncTimeout.cancelScheduledTimeout
  0.1%   5.3% okhttp3.internal.connection.StreamAllocation.newStream
  0.1%   2.1% okhttp3.internal.connection.StreamAllocation.findConnection
  0.0%   2.0% okhttp3.internal.connection.StreamAllocation.release
  0.0%   1.4% okhttp3.internal.connection.StreamAllocation.streamFinished
  0.0%   0.4% okhttp3.internal.connection.StreamAllocation.findHealthyConnection
  0.0%   0.3% java.lang.Object.wait
  0.0%   0.0% okhttp3.ConnectionPool$1.run
  0.0%   0.0% okio.SegmentPool.recycle

....[Thread state: TIMED_WAITING]...................................................................
  0.2%  42.0% java.lang.Thread.sleep
  0.2%  36.9% java.lang.Object.wait
  0.1%  21.1% sun.misc.Unsafe.park
```

 

吞吐量

```
Benchmark                                Mode  Cnt     Score      Error  Units
BenchmarkHttpTest.doOkhttp3Http         thrpt   10  6249.977 ± 1367.637  ops/s
BenchmarkHttpTest.doOkhttp3Http:·stack  thrpt            NaN               ---
```

 

资源监控

![5](/Users/houjichao/Work/tmp/图片/5.png)



**Hutool-Http**

堆栈分析

```java
....[Thread state distributions]....................................................................
 96.6%         RUNNABLE
  3.0%         WAITING
  0.4%         TIMED_WAITING

....[Thread state: RUNNABLE]........................................................................
 95.1%  98.5% java.net.SocketInputStream.socketRead0
  1.2%   1.3% java.net.DualStackPlainSocketImpl.connect0
  0.2%   0.2% <stack is empty, everything is filtered?>
  0.0%   0.0% java.net.SocketOutputStream.socketWrite0
  0.0%   0.0% java.security.AccessController.doPrivileged
  0.0%   0.0% com.tencent.abc.thirdparty.jmh_generated.BenchmarkHttpTest_doHutoolHttp_jmhTest.doHutoolHttp_Throughput
  0.0%   0.0% sun.net.www.HeaderParser.<init>
  0.0%   0.0% com.jprofiler.agent.InstrumentationCallee.netIOMethod
  0.0%   0.0% java.lang.Throwable.fillInStackTrace
  0.0%   0.0% java.net.DualStackPlainSocketImpl.available0

....[Thread state: WAITING].........................................................................
  3.0% 100.0% sun.misc.Unsafe.park

....[Thread state: TIMED_WAITING]...................................................................
  0.3%  74.8% java.lang.Thread.sleep
  0.1%  25.2% sun.misc.Unsafe.park
```

 

吞吐量

```java
Benchmark                               Mode  Cnt      Score      Error  Units
BenchmarkHttpTest.doHutoolHttp         thrpt   10  14850.443 ± 7128.794  ops/s
BenchmarkHttpTest.doHutoolHttp:·stack  thrpt             NaN               ---
```

 

资源监控

![6](/Users/houjichao/Work/tmp/图片/6.png)



#### **数据结果分析**

整合到一起看

```
Benchmark                               Mode  Cnt      Score      Error      Units
BenchmarkHttpTest.doApacheHttp         thrpt   10      3738.146   ± 480.371   ops/s
BenchmarkHttpTest.doOkhttp3Http        thrpt   10      6249.977   ± 1367.637  ops/s
BenchmarkHttpTest.doHutoolHttp         thrpt   10      14850.443  ± 7128.794  ops/s
```

 

其实这样的结果我并不惊讶，有几个点是可以注意到的

- 因为之前已经分析过，Hutool-Http单个的性能并不低，在没有连接池的情况下，1024的并发下去，等于每个线程都会新建自己的连接，最大限度（没节制）使用系统资源，从CPU的使用又或者GC的次数跟频率都能够看出来，数据十分夸张，已经将客户端的资源全部耗尽，最后有超高的吞吐（14850.443 ± 7128.794）
- ApacheHttpClient的表现也如期，**79.0%的TIMED_WAITING**，并发1024，连接池128，大多的时间在等连接池响应
- OkHttp3得益于Deque的**双端队列和非阻塞的异步回调设计**，尽可能在资源允许的情况下最大限度做连接复用请求



#### **调整线程池**



**ApacheHttpClient**

将连接池调整到与并发一致使用1024的连接池

```
....[Thread state distributions]....................................................................
 97.6%         RUNNABLE
  2.3%         WAITING

....[Thread state: RUNNABLE]........................................................................
 97.4%  99.9% java.net.SocketInputStream.socketRead0
  0.1%   0.1% java.net.SocketOutputStream.socketWrite0
  0.0%   0.0% com.tencent.abc.thirdparty.jmh_generated.BenchmarkHttpTest_doApacheHttp_jmhTest.doApacheHttp_Throughput
  0.0%   0.0% java.nio.HeapByteBuffer.<init>
  0.0%   0.0% org.apache.commons.io.IOUtils.copyLarge
  0.0%   0.0% java.lang.AbstractStringBuilder.<init>
  0.0%   0.0% java.util.Arrays.copyOfRange
  0.0%   0.0% org.apache.http.impl.io.SessionOutputBufferImpl.writeLine
  0.0%   0.0% java.util.Arrays.copyOf
  0.0%   0.0% java.net.IDN.toUnicode

....[Thread state: WAITING].........................................................................
  2.3% 100.0% sun.misc.Unsafe.park
```

 

```
Benchmark                               Mode  Cnt     Score     Error  Units
BenchmarkHttpTest.doApacheHttp         thrpt   10  6551.880 ± 945.418  ops/s
BenchmarkHttpTest.doApacheHttp:·stack  thrpt            NaN              ---
```

 ![7](/Users/houjichao/Work/tmp/图片/7.png)

**
**

**OkHttp3**

```
Benchmark                                Mode  Cnt     Score     Error  Units
BenchmarkHttpTest.doOkhttp3Http         thrpt   10  6894.496 ± 754.218  ops/s
BenchmarkHttpTest.doOkhttp3Http:·stack  thrpt            NaN              ---
```

 

![8](/Users/houjichao/Work/tmp/图片/8.png)



这里有几个值得留意的地方

1. 在几种用例场景下，Okhttp3的内存控制能够看出来效果非常好，GC次数很少，**比较****ApacheHttpClient依旧是较大较优的差距**
2. ApacheHttpClient在设置合适的连接池后，性能也上来了，并且从JVM堆栈分析中，**有效的线程利用率非常高，没有BLOCK，并且WAIT的时间占比也很少**，这点是值得肯定的
3. Okhttp3在连接池设置最大值分别为64、128、256、1024，结果差异不大，这个是一个非常疑惑的地方

```
builder.connectionPool(new ConnectionPool(64, 5, TimeUnit.MINUTES));
```

 

#### **分析Okhttp3连接池**

okhttp3.ConnectionPool#executor

```java
private final int maxIdleConnections;

private static final Executor executor = new ThreadPoolExecutor(0 /* corePoolSize */,
    Integer.MAX_VALUE /* maximumPoolSize */, 60L /* keepAliveTime */, TimeUnit.SECONDS,
    new SynchronousQueue<Runnable>(), Util.threadFactory("OkHttp ConnectionPool", true));

public ConnectionPool(int maxIdleConnections, long keepAliveDuration, TimeUnit timeUnit) {
  this.maxIdleConnections = maxIdleConnections;
  this.keepAliveDurationNs = timeUnit.toNanos(keepAliveDuration);
}

long cleanup(long now) {
    if (longestIdleDurationNs >= this.keepAliveDurationNs
    || idleConnectionCount > this.maxIdleConnections) {
      // We've found a connection to evict. Remove it from the list, then close it below (outside
      // of the synchronized block).
      connections.remove(longestIdleConnection);
}
```

 

这里在刚开始的源码分析中有一个较大的认知错误，错误把最大空闲值（maxIdleConnections）挂钩于线程池，实际源码上，**Okhttp3默认是使用的是【无限制】线程池去做连接池的**，【maxIdleConnections】扮演的仅仅是空闲值角色，跟连接池的最大值完全不挂钩，所以这里也解释了，【maxIdleConnections】最大值分别为64、128、256、1024，结果差异不大的疑问



**正确的有限线程池设置方式应该为**

```java
final ThreadPoolExecutor executor = new ThreadPoolExecutor(0, 1024, 60, TimeUnit.SECONDS,
                new SynchronousQueue<Runnable>(), Util.threadFactory("OkHttp Dispatcher", false));
final Dispatcher dispatcher = new Dispatcher(executor);
builder.dispatcher(dispatcher);
OkHttpClient client = builder.build();
```

 

## **选型总结**



​    通过**源码分析、基准测试（Benchmark）、抓包分析（Wireshark）、性能监控（JProfiler）、堆栈分析（StackProfiler）**，我们对三款HttpClient客户端进行了横向的对比和分析，能够得到一些较为确认的结论可以提供到后续项目的技术选型



#### **值得肯定的方面**



- 从内存上分析，3款客户端都不存在内存问题，但是从内存资源的利用率来说，**Okhttp3的内存资源利用率是最高的**，GC次数明显少于其他2个框架
- 是否使用连接池与**TCP握手时间及次数无关**，TCP的握手主要跟keepalived相关，而http1.1下keepalived默认是开启的，所以实际上3款客户端在实际调用的时候，都是使用长连接，都不需要重复建立连接
- Hutool-http的封装程度最高，完全不需要客户端额外写工具类，并且调用方式也非常优雅，而Okhttp3仅需要简单编写单例工具类即可以获取到非常好的调用性能，轻松获得连接池、重试等高级功能
- ApacheHttpClient虽然相对中庸，但也是最明显的优势，资源完全可控，大并发、少并发都能通过参数控制，并且与人们的认知完全一致，同时**ApacheHttpClient的线程/CPU利用率也是最高的**，从堆栈分析中可以知道，ApacheHttpClient的线程基本都是用于业务调用而不是框架额外的开销



#### **存在的隐患或不足**

- Hutool-http没有连接池，可以查看到github上的issue和官网博客，其实作者的原意很简单，希望推出一款客户端降低JDK的HttpUrlConnection的使用难度，所以Hutool-http也没有设置连接池，但是从项目实际的角度出发，没有连接池的设计，**必然会导致在高并发场景下，资源瞬间耗尽的情况**，我们希望提高CPU使用率，但是资源是需要有一定额度保留的，无论从内存抑或是CPU的角度，都**推荐在高并发场景下应用连接池**
- ApacheHttpClient的客户端工具类不光相对臃肿，最关键是必须针对实际项目场景去做参数调优，参数设置对吞吐影响非常大



#### **建议及结论**

- 如果项目中主要是一些**低频接口**，例如是拨测、获取缓存配置等，用Hutool-http完全没问题，封装程度好，调用优雅，你希望的结果他都已经封装好了。
- 如果不希望浪费心思在调优上面，希望程序跑得又稳又快，可以选用Okhttp3，默认的参数就提供好足够的性能指标。但是同样的，Okhttp3的问题也是这里，**Okhttp3默认使用的是【无限线程池】**，例如一个程序中既有三方服务接口，也有一些定时任务，并发来到的时候，三方服务接口把大部分资源占用了，可能导致一些定时任务运行异常。
- ApacheHttpClient虽然中庸，客户端需要额外编写，各种功能、参数需要自行设置，但是资源十分可控、资源利用认知一致，这个在高并发环境下是一个特别大的优势，我们通过压力测试，虽然会花费一些时间，但总是能够找到最合适调用参数，因此在**高并发环境**下最推荐的应该还是**ApacheHttpClient作为首选客户端。**