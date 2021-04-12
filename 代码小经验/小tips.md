### 1. 优化你的程序，拒绝创建不必要的对象

如果你的变量，后面的逻辑判断，一定会被赋值；或者说，只是一个字符串变量，直接初始化字符串常量就可以了，没有必要愣是要new String().

反例：

```
String s = new String ("欢迎关注公众号：捡田螺的小男孩");
```

正例：

```
String s=  "欢迎关注公众号：捡田螺的小男孩 ”;
```

java中除了8中基本类型外，其他的都是类对象以及其引用。

所以 "xyz "在java中它是一个String对象.对于string类对象来说他的对象值是不能修改的，也就是具有不变性。

在jvm的工作过程中，会创建一片的内存空间专门存入string对象。我们把这片内存空间叫做string池。

**String s = "a";与String s = new String("a")的区别**

String s1 = "a" 时，首先会在字符串常量池中查找有无 “a” 这个对象。 若没找到，就创建一个 "a" 对象，

然后，以 s1 为它的引用。若在字符串常量池中找到了 “a” 这个对象， 同样也将 s1 作为它的引用。

若再执行一次 String s2 = "a" , 那么 s1 和 s2 都是同一个对象的引用，即 逻辑判断 s1 == s2 的结果是 true。

String s3 = new String("a") 时，将在字符串常量池外的堆里，创建一个 "a" 对象，

然后，以 s3 为它的引用。这时，s3 对应的是 字符串常量池外的一个对象。因此，无论 s3 == s2，还是 s3 ==s1，其结果都是 false。

```
public class Demo {
    public static void main(String[] args) {
        String s1 = "a";
        String s2 = "a";
        String s3 = new String("a");
        System.out.println(s1 == s2);// true
        System.out.println(s1 == s3);// false
        System.out.println(s2 == s3);// false
    }
}
```

### 2. 写查询Sql的时候，只查你需要用到的字段，还有通用的字段，拒绝反手的select *

**反例：**

```
select * from user_info where user_id =#{userId};
```

**正例：**

```
select user_id , vip_flag from  user_info where user_id =#{userId};
```

**理由：**

- 节省资源、减少网络开销。
- 可能用到覆盖索引，减少回表，提高查询效率。

**结论：**

这个也不是一定的，当选择字段比较多的时候，select * 反而更快，因为省去了解析字段的时间。推荐用select 字段主要是为了可读性更好吧，知道自己要什么字段

### 3. 初始化集合时，指定容量

阿里的开发手册，也明确提到这个点： ![image.png](https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/2ac43ab291794c608537f1c4da6a9caa~tplv-k3u1fbpfcp-watermark.image)

假设你的map要存储的元素个数是15个左右，最优写法如下

```
 //initialCapacity = 15/0.75+1=21
 Map map = new HashMap(21);
 又因为hashMap的容量跟2的幂有关，所以可以取32的容量
 Map map = new HashMap(32);
```

### 7. 打印日志的时候，对象没有覆盖Object的toString的方法，直接把类名打印出来了。

我们在打印日志的时候，经常想看下一个请求参数对象request是什么。于是很容易有类似以下这些代码：

```
publick Response dealWithRequest(Request request){
   log.info("请求参数是：".request.toString)
}
```

打印结果如下：

```
请求参数是：local.Request@49476842
```

这是因为对象的toString方法，默认的实现是“类名@散列码的无符号十六进制”。所以你看吧，这样子打印日志就没啥意思啦，你都不知道打印的是什么内容。

所以一般对象(尤其作为传参的对象），**都覆盖重写toString()方法**：

```
class Request {

    private String age;

    private String name;

    @Override
    public String toString() {
        return "Request{" +
                "age='" + age + '\'' +
                ", name='" + name + '\'' +
                '}';
    }
}

publick Response dealWithRequest(Request request){
   log.info("请求参数是：".request.toString)
}
```

打印结果如下：

```
请求参数是：Request{age='26', name='jackjchou'}
```

### 5. 一个方法，拒绝过长的参数列表。

假设有这么一个公有方法，形参有四个。。。

```
public void getUserInfo（String name,String age,String sex,String mobile){
  // do something ...
}
```

如果现在需要多传一个version参数进来，并且你的公有方法是类似dubbo这种对外提供的接口的话，那么你的接口是不是需要兼容老版本啦？

```
public void getUserInfo（String name,String age,String sex,String mobile){
  // do something ...
}

/**
 * 新接口调这里
 */
public void getNewUserInfo（String name,String age,String sex,String mobile，String version){
  // do something ...
}
```

所以呢，一般一个方法的参数，一般不宜过长。过长的参数列表，不仅看起来不优雅，并且接口升级时，可能还要考虑新老版本兼容。如果参数实在是多怎么办呢？可以用个DTO对象包装一下这些参数呢~如下：

```
public void getUserInfo（UserInfoParamDTO userInfoParamDTO){
  // do something ...
}

class UserInfoParamDTO{
  private String name;
  private String age; 
  private String sex;
  private String mobile;
}
```

用个DTO对象包装一下，即使后面有参数变动，也可以不用动对外接口了，好处杠杠的。

### 12. 当成员变量值不会改变时，优先定义为静态常量

**反例：**

```
public class Task {
    private final long timeout = 10L;
    ...
}
```

**正例：**

```
public class Task {
    private static final long TIMEOUT = 10L;
    ...
}
```

> 因为如果定义为static，即类静态常量，在每个实例对象中，它只有一份副本。如果是成员变量，每个实例对象中，都各有一份副本。显然，如果这个变量不会变的话，定义为静态常量更好一些。

### 7. 处理Java日期时，当心YYYY格式设置的问题。

日常开发中，我们经常需要处理日期。我们要当时日期格式化的时候，年份是大写`YYYY`的坑。

```
Calendar calendar = Calendar.getInstance();
calendar.set(2019, Calendar.DECEMBER, 31);

Date testDate = calendar.getTime();

SimpleDateFormat dtf = new SimpleDateFormat("YYYY-MM-dd");
System.out.println("2019-12-31 转 YYYY-MM-dd 格式后 " + dtf.format(testDate));
```

运行结果：

```
2019-12-31 转 YYYY-MM-dd 格式后 2020-12-31
```

> 为什么明明是2019年12月31号，就转了一下格式，就变成了2020年12月31号了？因为YYYY是基于周来计算年的，它指向当天所在周属于的年份，一周从周日开始算起，周六结束，只要本周跨年，那么这一周就算下一年的了。正确姿势是使用yyyy格式。

### 8. 如果一个类确定不会被继承，不会拿来搞AOP骚操作，可以指定final修饰符，如用final修饰一个工具类。

**正例：**

```
public final class Tools {
    public static void testFinal(){
        System.out.println("工具类方法");
    }
}
```

### 9. 如果变量的初值一定会被覆盖，就没有必要给变量赋初值。

**反例:**

```
List<UserInfo> userList = new ArrayList<>();
if (isAll) {
    userList = userInfoDAO.queryAll();
} else {
    userList = userInfoDAO.queryActive();
}

```

**正例：**

```
List<UserInfo> userList ;
if (isAll) {
    userList = userInfoDAO.queryAll();
} else {
    userList = userInfoDAO.queryActive();
}
```

### 10. 尽量使用函数内的基本类型临时变量

> - 在方法函数内，基本类型参数以及临时变量，都是保存在栈中的，访问速度比较快。
> - 对象类型的参数和临时变量的引用都保存在栈中，内容都保存在堆中，访问速度较慢。
> - 在类中，任何类型的成员变量都保存在堆（Heap）中，访问速度较慢。

```
public class AccumulatorUtil {

    private double result = 0.0D;
    //反例
    public void addAllOne( double[] values) {
        for(double value : values) {
            result += value;
        }
    }
    //正例，先在方法内声明一个局部临时变量，累加完后，再赋值给方法外的成员变量
    public void addAll1Two(double[] values) {
        double sum = 0.0D;
        for(double value : values) {
            sum += value;
        }
        result += sum;
    }
}
```

### 11. 尽量减少对变量的重复计算

一般我们写代码的时候，会以以下的方式实现遍历：

```
for (int i = 0; i < list.size; i++){

}
```

如果list数据量比较小那还好。如果list比较大时，可以优化成这样：

```
for (int i = 0, int length = list.size; i < length; i++){

}
```

理由：

- 对方法的调用，即使是只有一个语句，也是有有消耗的，比如创建栈帧。如果list比较大时，多次调用list.size也是会有资源消耗的。

### 12. 策略模式+工厂方法优化冗余的if else

反例：

```
    String medalType = "guest";
    if ("guest".equals(medalType)) {
        System.out.println("嘉宾勋章");
     } else if ("vip".equals(medalType)) {
        System.out.println("会员勋章");
    } else if ("guard".equals(medalType)) {
        System.out.println("展示守护勋章");
    }
    ...
```

首先，我们把每个条件逻辑代码块，抽象成一个公共的接口，我们根据每个逻辑条件，定义相对应的策略实现类，可得以下代码：

```
//勋章接口
public interface IMedalService {
    void showMedal();
}

//守护勋章策略实现类
public class GuardMedalServiceImpl implements IMedalService {
    @Override
    public void showMedal() {
        System.out.println("展示守护勋章");
    }
}
//嘉宾勋章策略实现类
public class GuestMedalServiceImpl implements IMedalService {
    @Override
    public void showMedal() {
        System.out.println("嘉宾勋章");
    }
}
//VIP勋章策略实现类
public class VipMedalServiceImpl implements IMedalService {
    @Override
    public void showMedal() {
        System.out.println("会员勋章");
    }
}
```

接下来，我们再定义策略工厂类，用来管理这些勋章实现策略类，如下：

```
//勋章服务工产类
public class MedalServicesFactory {

    private static final Map<String, IMedalService> map = new HashMap<>();
    static {
        map.put("guard", new GuardMedalServiceImpl());
        map.put("vip", new VipMedalServiceImpl());
        map.put("guest", new GuestMedalServiceImpl());
    }
    public static IMedalService getMedalService(String medalType) {
        return map.get(medalType);
    }
}
```

优化后，正例如下：

```
ublic class Test {
    public static void main(String[] args) {
        String medalType = "guest";
        IMedalService medalService = MedalServicesFactory.getMedalService(medalType);
        medalService.showMedal();
    }
}
```