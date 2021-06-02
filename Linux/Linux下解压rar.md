### rar文件解压，压缩

下载地址：https://www.rarlab.com/download.htm（目前最新为 RAR 6.02beta 1 for Linux），以最新的为准。

下载完后安装：

```
# tar -xzpvf rarlinux-x64-5.6.b5.tar.gz
# cd rar
# make
```

这样就安装好了，安装后就有了 rar 和 unrar 这两个命令，rar 是压缩命令，unrar 是解压命令。它们的参数选项很多，举例说明一下其用法:

```
# rar a all *.jpg
```

这条命令是将所有 .jpg 的文件压缩成一个 rar 包，名为 all.rar，该程序会将 .rar 扩展名将自动附加到包名后。

```
# unrar e all.rar
```

这条命令是将 all.rar 中的所有文件解压出来。