#### 从某一个commit开始创建本地分支 
```
1、git log 查看提交
2、// 通过checkout 跟上commitId 即可创建制定commit之前的本地分支 
git checkout commitId -b 本地新branchName
```

#### 上传到远程服务器 
```
// 依然通过push 跟上你希望的远程新分支名字即可 
git push origin HEAD:远程新branchName 
```

