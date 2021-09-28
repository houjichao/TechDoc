#### git merge 和 git merge --no-ff

git merge和 git merge --no-ff都是合并分支，但是意义稍有不一样。git merge也可以写成git merge --ff，其中参数--ff意为fast-forward。该命令指的是把HEAD指针指向要合并分支的头，完成一次合并。git merge --no-ff中的--no-ff意为强行关掉fast-forward，所以在使用这种方式后，分支合并后会生成一个新的commit，这样，在使用git log从提交历史上就可以看到分支信息。






