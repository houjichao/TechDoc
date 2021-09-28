### 将hotfix分支合并到master分支

#### 1.查看当前分支(当前分支可以直接查看或者命令查看)

```
git branch或者命令git status

*代表当前分支
```

#### 2.切换分支到master

```
git checkout mater
```

#### 3.将代码更新到最新版本

```
git pull

git fetch origin
```

#### 4.在master分支上，将hotfix分支合并到master上面

```
git merge --no-ff hotfix-bugid
如果不行，使用命令
git merge develop --allow-unrelated-histories
```

#### 5.添加到缓存、提交、推送

```
git add .
git commit -m "合并hotfix"
git push origin master
```

