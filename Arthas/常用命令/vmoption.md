## vmoption

> 查看，更新VM诊断相关的参数

vmoption最大的作用是用来热更调整gc的输出

通过两步：

```
vmoption //用来查看当前的参数及配置值列表
vmoption HeapDumpPath /Users/stevenhuangqian/heapdump  //动态配置heapdump的路径
vmoption HeapDumpBeforeFullGC true  //更新指定的option
```

可以在不重启的情况下增加fullgc的heapdump。验证方法：通过jmap -histo:live pid （强制触发一次fullgc，**生产慎用**）

