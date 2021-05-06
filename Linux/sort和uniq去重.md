### 演示文件

```
Hello World.
Apple and Nokia.
Hello World.
I wanna buy an Apple device.
The Iphone of Apple company.
Hello World.
The Iphone of Apple company.
My name is Friendfish.
Hello World.
Apple and Nokia.
```

1. 排序

由于uniq命令只能对相邻行进行去重复操作，所以在进行去重前，先要对文本行进行排序，使重复行集中到一起。

```
sort test.txt
```

2. 文本行去重并按重复次数排序

(1)首先，对文本行进行去重并统计重复次数(uniq命令加-c选项可以实现对重复次数进行统计。)。

```
sort test.txt | uniq -c
```

(2)对文本行按重复次数进行排序。
sort -n可以识别每行开头的数字，并按其大小对文本行进行排序。默认是按升序排列，如果想要按降序要加-r选项(sort -rn)。

```
sort test.txt | uniq -c | sort -rn
```

(3)每行前面的删除重复次数。
cut命令可以按列操作文本行。可以看出前面的重复次数占8个字符，因此，可以用命令cut -c 5- 取出每行第5个及其以后的字符。

这个5可能会不一样，mac上是5，Linux可能是9，根据具体的情况具体看待

```
sort test.txt | uniq -c | sort -rn | cut -c 5-
```

```
下面附带说一下cut命令的使用，用法如下：

cut -b list [-n] [file …]
cut -c list [file …]
cut -f list [-d delim][-s][file …]

上面的-b、-c、-f分别表示字节、字符、字段（即byte、character、field）；
list表示-b、-c、-f操作范围，-n常常表示具体数字；
file表示的自然是要操作的文本文件的名称；
delim（英文全写：delimiter）表示分隔符，默认情况下为TAB；
-s表示不包括那些不含分隔符的行（这样有利于去掉注释和标题）
三种方式中，表示从指定的范围中提取字节（-b）、或字符（-c）、或字段（-f）。

范围的表示方法：
n 只有第n项
n- 从第n项一直到行尾
n-m 从第n项到第m项(包括m)
-m 从一行的开始到第m项(包括m)
- 从一行的开始到结束的所有项
```

