# golang中cannot refer to unexported name问题

今日在golang中编写了个特定包，该包的某个函数试图让外部引用。

结果，在外部引用中，该函数发生错误：cannot refer to unexported name。

比较奇怪的是，其他函数可以被引用。

后来发现一个golang的语法：模块中要导出的函数，必须首字母大写。

PS：1）C语言外部引用的函数，没有这个限制；

​        2）C语言会有extern C或者extern说明，但golang的首字母大写才能导出的语法，显然是golang语言的特性，值得学习





export GO111MODULE=on 
