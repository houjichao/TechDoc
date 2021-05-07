#### 演示文件

```
hello world
awk
coding ants
hello world
awk
hello world
awk
coding ants
coding ants
```

#### 命令

```
awk '!a[$0]++' dup
```

　在《awk程序指令模型》中介绍了awk的程序指令由模式和操作组成，即Pattern { Action }的形式，如果省略Action，则默认执行 print $0 的操作。

　　实现去除重复功能的就是这里的Pattern：

```
!a[$0]++
```

在awk中，对于未初始化的数组变量，在进行数值运算的时候，会赋予初值0，因此a[$0]=0，++运算符的特性是先取值，后加1，因此Pattern等价于

```
!0
```

而0为假，!为取反，因此整个Pattern最后的结果为1，相当于if(1)，Pattern匹配成功，输出当前记录，对于dup文件，前3条记录的处理方式都是如此。

当读取第4行数据“hello world”的时候，a[$0]=1，取反后的结果为0，即Pattern为0，Pattern匹配失败，因此不输出这条记录，后续的数据以此类推，最终成功实现去除文件中的重复行。

```
awk '{a[$0]++}END{for(i in a){print i,a[i] | "sort -r -k 2"}}' test.txt

其中a[$0]大概表示将一整行写入数组a，如果是a[$2]则表示将每一行的第二个元素‘memlib’写入数组a，默认以空格作为分割一行的元素。可以用 -F指定分割符如下：

awk -F：'{a[$2]++}END{for(i in a){print i,a[i] | "sort -r -k 2"}}' testfile
```

