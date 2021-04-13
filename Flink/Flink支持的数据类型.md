大数据生态中有很多的组件，Flink是当前最火爆的一个，头哥儿这两年一直在研究使用Flink，今天有点时间，专门总结一下Flink支持的数据类型，希望对需要的同学有所帮助。

Flink对DataSet和DataStream中可使用的元素类型添加了一些约束。原因是系统可以通过分析这些类型来确定有效的执行策略和选择不同的序列化方式。

## 有7中不同的数据类型：

1. Java Tuple 和 Scala Case类；

2. Java POJO；

3. 基本类型；

4. 通用类；

5. 值；

6. Hadoop Writables;

7. 特殊类型

### 1. Java Tuple

Tuple是包含固定数量各种类型字段的复合类。Flink Java API提供了Tuple1-Tuple25。Tuple的字段可以是Flink的任意类型，甚至嵌套Tuple。

访问Tuple属性的方式有以下两种：

1.属性名(f0,f1…fn)

2.getField(int pos)

### 2. Scala Case类

Scala的Case类（以及Scala的Tuple,实际是Case class的特殊类型）是包含了一定数量多种类型字段的组合类型。Tuple字段通过他们的1-offset名称定位，例如 _1代表第一个字段。Case class 通过字段名称获得：

case class WordCount(word: String, count: Int)

val input = env.fromElements(

WordCount("hello", 1),

WordCount("world", 2)) // Case Class Data Set

input.keyBy("word")// key by field expression "word"

val input2 = env.fromElements(("hello", 1), ("world", 2)) // Tuple2 Data Set

input2.keyBy(0, 1) // key by field positions 0 and 1

### 3. POJOs

Java和Scala的类在满足下列条件时，将会被Flink视作特殊的POJO数据类型专门进行处理：

1.是公共类；

2.无参构造是公共的；

3.所有的属性都是可获得的（声明为公共的，或提供get,set方法）；

4.字段的类型必须是Flink支持的。Flink会用Avro来序列化任意的对象。

Flink会分析POJO类型的结构获知POJO的字段。POJO类型要比一般类型好用。此外，Flink访问POJO要比一般类型更高效。

```
public class WordWithCount {

public String word;

public int count;

public WordWithCount() {}

public WordWithCount(String word, int count) { this.word = word; this.count = count; }

}

DataStream<WordWithCount> wordCounts = env.fromElements(

new WordWithCount("hello", 1),

new WordWithCount("world", 2));

wordCounts.keyBy("word");
```

### 4. 基本类型

Flink支持Java和Scala所有的基本数据类型，比如 Integer,String,和Double。

### 5. 一般通用类

Flink支持大多数的Java,Scala类（API和自定义）。包含不能序列化字段的类在增加一些限制后也可支持。遵循Java Bean规范的类一般都可以使用。

所有不能视为POJO的类Flink都会当做一般类处理。这些数据类型被视作黑箱，其内容是不可见的。通用类使用Kryo进行序列/反序列化。

### 6. 值类型Values

通过实现org.apache.flinktypes.Value接口的read和write方法提供自定义代码来进行序列化/反序列化，而不是使用通用的序列化框架。

Flink预定义的值类型与原生数据类型是一一对应的(例如:ByteValue, ShortValue, IntValue, LongValue, FloatValue, DoubleValue, StringValue, CharValue, BooleanValue)。这些值类型作为原生数据类型的可变变体，他们的值是可以改变的，允许程序重用对象从而缓解GC的压力。

### 7. Hadoop的Writable类

它实现org.apache.hadoop.Writable接口的类型，该类型的序列化逻辑在write()和readFields()方法中实现。

### 8. 特殊类型

Flink比较特殊的类型有以下两种：

1.Scala的 Either、Option和Try。

2.Java ApI有自己的Either实现。

### 9. 类型擦除和类型推理

**注意：本小节内容仅针对Java**

Java编译器在编译之后会丢弃很多泛型类型信息。这在Java中称为类型擦除。这意味着在运行时，对象的实例不再知道其泛型类型。

例如，在JVM中，DataStream<String>和DataStream<Long>的实例看起来是相同的。

```
List<String> l1 = new ArrayList<String>();

List<Integer> l2 = new ArrayList<Integer>();

System.out.println(l1.getClass() == l2.getClass());
```

泛型：一种较为准确的说法就是为了参数化类型，或者说可以将类型当作参数传递给一个类或者是方法。

Flink 的Java API会试图去重建（可以做类型推理）这些被丢弃的类型信息，并将它们明确地存储在数据集以及操作中。你可以通过DataStream.getType()方法来获取类型，这个方法将返回一个TypeInformation的实例，这个实例是Flink内部表示类型的方式。