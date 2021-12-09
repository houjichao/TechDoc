### nginx.conf的目录结构

> 整个conf文件分为** 全局块、events块、http块、s erver块、location块**。每个块有每个块的作用域，越外层的块作用域就包含内部块的作用域，如全局块作用域就包含events块、http块、server块和location块。

```
                    #全局块

event{              #events块
    ...
}

http{               #http块

    server{         #server块
        ...         #server全局块

        location{   #location块
            ...
        }

        location{   #location块
            ...
        }
    }

    server{         #server块
        ...
    }
    ...             #http全局块
}

```

#### events块

> events模块中包含nginx中所有处理连接的设置.

#### http块

> http块是Nginx服务器配置中的重要部分，代理、缓存和日志定义等绝大多数的功能和第三方模块的配置都可以放在这模块中。作用包括：文件引入、MIME-Type定义、日志自定义、是否使用sendfile传输文件、连接超时时间、单连接请求数上限等。

#### server块

> server块，虚拟主机（虚拟服务器）。作用：使得Nginx服务器可以在同一台服务器上至运行一组Nginx进程，就可以运行多个网站。

#### location块

> location块是server块的一个指令。作用：基于Nginx服务器接收到的请求字符串，虚拟主机名称（ip，域名）、url匹配，对特定请求进行处理。

## location 说明

- location语法

```
location [=|~|~*|^~|@] /uri/ { … } ，意思是可以以“ = ”或“ ~* ”或“ ~ ”或“ ^~ ”或“ @ ”符号为前缀，
当然也可以没有前缀（因为 [A] 是表示可选的 A ； A|B 表示 A 和 B 选一个），紧接着是 /uri/ ，
再接着是{…} 指令块，整个意思是对于满足这样条件的 /uri/ 适用指令块 {…} 的指令。

location ~* /js/.*/\.js
以 = 开头，表示精确匹配；如只匹配根目录结尾的请求，后面不能带任何字符串。
以^~ 开头，表示uri以某个常规字符串开头，不是正则匹配
以~ 开头，表示区分大小写的正则匹配;
以~* 开头，表示不区分大小写的正则匹配
以/ 开头，通用匹配, 如果没有其它匹配,任何请求都会匹配到
```

- location的分类

> location分为两类，一类为普通 location，一类为正则location。
>
> 1.普通location
>
> > “普通 location ”是以“ = ”或“ ^~ ”为前缀或者没有任何前缀的 /uri/ 
> >
>
> 2.正则location
>
> > “正则 location ”是以“ ~ ”或“ ~* ”为前缀的 /uri/

- 多个location场景下的location匹配

> Nginx 的 location 匹配规则是：“正则 location ”让步 “普通 location”的严格精确匹配结果；但覆盖 “普通 location ”的最大前缀匹配结果。

## 二、Rewrite用法总结

###    1.rewrite的定义

   rewrite功能就是使用nginx提供的全局变量或自己设置的变量，结合正则表达式和标志位实现url重写以及重定向。

```
    rewrite只能放在 server{}, location{}, if{}中，并且只能对域名后边的除去传递的参数外的字符串起作用。
例如 http://seanlook.com/a/we/index.php?id=1&u=str 只对/a/we/index.php重写。
```

###   2.rewirte的 **语法**

​    **rewrite regex replacement [flag];**

 

​    如果相对域名或参数字符串起作用，可以使用全局变量匹配，也可以使用proxy_pass反向代理。

​    从上 表明看rewrite和location功能有点像，都能实现跳转。主要区别在于rewrite是在**同一域名内**更改获取资源的路径，而location是对一类路径做控制访问或反向代理，**可以proxy_pass到其他机器**。

 

很多情况下rewrite也会写在location里，它们的执行顺序是：

```
1 执行server块的rewrite指令
2 执行location匹配
3 执行选定的location中的rewrite指令
```

如果其中某步URI被重写，则重新循环执行1-3，直到找到真实存在的文件；循环超过10次，则返回500 Internal Server Error错误。

#### flag标志位

- last : 相当于Apache的[L]标记，表示完成rewrite
- break : 停止执行当前虚拟主机的后续rewrite指令集
- redirect : 返回302临时重定向，地址栏会显示跳转后的地址
- permanent : 返回301永久重定向，地址栏会显示跳转后的地址

因为301和302不能简单的只返回状态码，还必须有重定向的URL，这就是return指令无法返回301,302的原因了。

这里 last 和 break 区别有点难以理解：

1. last一般写在server和if中，而break一般使用在location中
2. last不终止重写后的url匹配，即新的url会再从server走一遍匹配流程，而break终止重写后的匹配
3. break和last都能组织继续执行后面的rewrite指令

### 3.rewrite常用正则

- . ： 匹配除换行符以外的任意字符
- ? ： 重复0次或1次
- \+ ： 重复1次或更多次
- \* ： 重复0次或更多次
- \d ：匹配数字
- ^ ： 匹配字符串的开始
- $ ： 匹配字符串的结束
- {n} ： 重复n次
- {n,} ： 重复n次或更多次
- [c] ： 匹配单个字符c
- [a-z] ： 匹配a-z小写字母的任意一个

小括号()之间匹配的内容，可以在后面通过$1来引用，$2表示的是前面第二个()里的内容。正则里面容易让人困惑的是\转义特殊字符。