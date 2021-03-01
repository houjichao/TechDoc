#### error: src refspec master does not match any. 错误处理办法
##### 本地仓库使用如下命令初始化：
```
git init
```
##### 添加远程库
```
git remote add origin https://e.coding.net/cloud3products/*****.git
```
##### 推送远程库 
```
git push -u origin master
```
##### 出现如下错误
```
error: src refspec master does not match any.
error: failed to push some refs to 'git@******.git'
```

原因：
本地仓库为空
解决方法：使用如下命令 添加文件；

```
git add .

git commit -m "init files"
```

然后push即可