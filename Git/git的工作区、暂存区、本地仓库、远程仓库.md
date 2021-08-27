1、git的工作区：在当前仓库中，新增，更改，删除文件这些动作，都发生在工作区里面。

2、git的暂存区：英文叫stage, 或index。在版本库.git）目录下，有一个index文件。它实际上就是一个包含文件索引的目录树，像是一个虚拟的工作区。在这个虚拟工作区的目录树中，记录了文件名、文件的状态信息（时间戳、文件长度等），文件的内容并不存储其中，而是保存在Git对象库（.git/objects）中，文件索引建立了文件和对象库中对象实体之间的对应。如果当前仓库，有文件更新，并且使用git add 命令，那么这些更新就会出现在暂存区中。

3、版本库：当前仓库下，如果没有任何的提交，那么版本库就是对应上次提交后的内容。![在这里插入图片描述](https://img-blog.csdnimg.cn/20190815220454926.PNG?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80Mzk5MDM2Mw==,size_16,color_FFFFFF,t_70)
版本库与工作区和暂存区的关系：
![这里写图片描述](https://img-blog.csdn.net/20170209165810591?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvZHV5aXdlaWxhbg==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

“HEAD” 实际是指向 master 分支的一个“游标”。所以图示的命令中出现 HEAD 的地方可以用 master 来替换。
图中的 objects 标识的区域为 Git 的对象库，实际位于 “.git/objects” 目录下，里面包含了创建的各种对象及内容。

当对工作区修改（或新增）的文件执行 “git add” 命令时，暂存区的目录树被更新，同时工作区修改（或新增）的文件内容被写入到对象库中的一个新的对象中，而该对象的ID被记录在暂存区的文件索引中。

当执行提交操作（git commit）时，暂存区的目录树写到版本库（对象库）中，master 分支会做相应的更新。即 master 指向的目录树就是提交时暂存区的目录树。

当执行 “git reset HEAD” 命令时，暂存区的目录树会被重写，被 master 分支指向的目录树所替换，但是工作区不受影响。

当执行 “git rm –cached ” 命令时，会直接从暂存区删除文件，工作区则不做出改变。

当执行 “git checkout .” 或者 “git checkout – ” 命令时，会用暂存区全部或指定的文件替换工作区的文件。这个操作很危险，会清除工作区中未添加到暂存区的改动。

------

使用git diff查看各个区之间的差异

| 使用命令         | 代表意义                     |
| ---------------- | ---------------------------- |
| git diff         | 比较的是工作区和暂存区的差别 |
| git diff –cached | 比较的是暂存区和版本库的差别 |
| git diff HEAD    | 可以查看工作区和版本库的差别 |

每次commit后,git diff –cached没有内容，是因为暂存区的内容已经更新到版本库中，因此暂存区和版本库中的内容无差别

git reset和git revert的区别：
reset是重置，默认是git reset –mixed 可以让版本库重置到某个commit状态，该commit之后的commit不会保留，并重置暂存区，但是不改变工作区。即这个时候，上次提交的内容在工作区中还会存在。

如果使用git reset –hard 将版本库，暂存区和工作区的内容全部重置为某个commit的状态。之前的commit不会保留。

revert比reset更加温柔一点，回滚到某次commit且该commit之后的提交记录都会保留，并且会在此基础上新建一个提交。对于已经push到服务器上的内容作回滚，推荐使用revert。