MTTR/MTTF/MTBF图解
MTTR、MTTF、MTBF是体现系统可靠性的重要指标，但是三者容易混淆,下文使用图解方式解释三者之间的区别，希望能起到解惑的效用。

MTTF (Mean Time To Failure，平均无故障时间)，指系统无故障运行的平均时间，取所有从系统开始正常运行到发生故障之间的时间段的平均值。 MTTF =∑T1/ N

MTTR (Mean Time To Repair，平均修复时间)，指系统从发生故障到维修结束之间的时间段的平均值。MTTR =∑(T2+T3)/ N

MTBF (Mean Time Between Failure，平均失效间隔)，指系统两次故障发生时间之间的时间段的平均值。 MTBF =∑(T2+T3+T1)/ N

很明显:MTBF= MTTF+ MTTR

![在这里插入图片描述](https://img-blog.csdnimg.cn/20191104113807315.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3N0YXJzaGlubmluZzk3NQ==,size_16,color_FFFFFF,t_70)

