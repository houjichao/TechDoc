#### 演示文件

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

#### 命令

```
awk '{a[$0]++}END{for(i in a){print i,a[i] | "sort -r -k 2"}}' test.txt

其中a[$0]大概表示将一整行写入数组a，如果是a[$2]则表示将每一行的第二个元素‘memlib’写入数组a，默认以空格作为分割一行的元素。可以用 -F指定分割符如下：

awk -F：'{a[$2]++}END{for(i in a){print i,a[i] | "sort -r -k 2"}}' testfile
```

