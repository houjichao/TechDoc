### zip -r myfile.zip ./*

将当前目录下的所有文件和文件夹全部压缩成myfile.zip内联代码块文件,内联代码块-r表示递归压缩子目录下所有文件。

### unzip

```
unzip -o -d /home/sunny myfile.zip
```

把myfile.zip文件解压到 /home/sunny/

-o:不提示的情况下覆盖文件;

-d:-d /home/sunny指明将文件解压缩到/home/sunny目录下。



### 其他

```
删除压缩文件中smart.txt文件

zip -d myfile.zip smart.txt

向压缩文件中myfile.zip中添加rpm_info.txt文件。

zip -m myfile.zip ./rpm_info.txt
```

