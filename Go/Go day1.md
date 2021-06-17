### 1

报错：

　　$GOPATH/go.mod exists but should not

开启模块支持后，需要把项目从GOPATH中移出



### 2

1.先贴上工程的目录图

![img](https:////upload-images.jianshu.io/upload_images/19439088-593d4114f35dd509.png?imageMogr2/auto-orient/strip|imageView2/2/w/164/format/webp)

e8bfd40ddd47003db99749f1ea89bf9.png

1. 再贴上代码

```go
//test.go 
package cfg

import "fmt"

func Test() {
    fmt.Println("test")
}
```

```go
package main

import (
    "fmt"
    "demo/cfg"
)

func main() {
    cfg.Test()
    fmt.println("Hello")
}
```

3.命令

```go
go mod init app
go build
```

然后就是标题上面的错误，其实这个问题根本原因就是命令go mod init app 和代码 import "demo/cfg" 不对应。引用本地模块的引用方法是 import "module/path"，也就是说如果用了go mod init app命令，代码引用本地模块就需是import "app/cfg", 反之，就是命令需是go mod init demo。注意module名和工程所在文件夹名无必然关联。（这个其实go的相关文档有写，有兴趣可以去看看）