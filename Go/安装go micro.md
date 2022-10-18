```
 go install github.com/micro/micro/v2@latest
 
 
安装go protocol buffers的插件 protoc-gen-go 
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
```



git clone https://github.com/micro/protoc-gen-micro.git $GOPATH/src/github.com/micro/protoc-gen-micro
#到这个插件所在目录
cd $GOPATH/src/github.com/golang/micro/protoc-gen-micro
go build
#ls 查看是否有protoc-gen-go可执行文件，如果有放到/bin目录下，确保随时可以使用
sudo cp protoc-gen-micro /bin