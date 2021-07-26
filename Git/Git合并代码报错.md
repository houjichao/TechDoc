### Git的报错

在使用Git的过程中有时会出现一些问题，那么在解决了每个问题的时候，都需要去总结记录下来，下次不再犯。



#### 一、fatal: refusing to merge unrelated histories

今天在使用Git创建项目的时候，在两个分支合并的时候，出现了下面的这个错误。

```
$ git merge origin/druid
fatal: refusing to merge unrelated histories
```

这里的问题的关键在于：fatal: refusing to merge unrelated histories
你可能会在git pull或者git push中都有可能会遇到，这是因为两个分支没有取得关系。那么怎么解决呢？

#### 二、解决方案

在你操作命令后面加--allow-unrelated-histories，把两段不相干的 分支进行强行合并
例如：

```
git merge develop --allow-unrelated-histories
```

如果你是git pull或者git push报fatal: refusing to merge unrelated histories
同理：
git pull origin master --allow-unrelated-histori

