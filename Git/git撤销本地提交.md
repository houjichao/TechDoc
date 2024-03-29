要撤销本地的commit，可以使用以下命令：

1. 撤销最近一次commit，但保留修改：

```
git reset HEAD^
```

这将取消最近的提交，并将更改保留在工作区中。您可以再次对这些更改进行修改并重新提交。

1. 撤销最近一次commit，同时撤销修改：

```
git reset --hard HEAD^
```

这将取消最近的提交并且将更改全部撤销。请注意，此操作将永久删除您的更改，因此请谨慎使用。

1. 撤销特定的commit：

```
git revert <commit-hash>
```

这将撤销指定的提交，并创建一个新的提交来撤销更改。请注意，这不会删除提交，而是创建一个新的提交来撤销更改。



如果您想要撤销最近的多次commit，可以使用以下命令：

1. 打开交互式rebase：



复制代码

```
git rebase -i HEAD~<num>
```

其中`<num>`是您想要撤销的提交数。这将打开一个交互式rebase编辑器。

1. 将要撤销的提交标记为`edit`：

在rebase编辑器中，将要撤销的提交的行标记为`edit`。例如，如果您想要撤销最近的两个提交，您可以将最近的两个提交的行标记为`edit`。

1. 执行rebase并撤销提交：

执行rebase操作，将会在每个标记为`edit`的提交处停止。在每个停止的提交处，使用以下命令撤销提交：

```
git reset HEAD^
```

这将撤销提交并将更改保留在工作区中。您可以再次对这些更改进行修改并重新提交。

1. 继续rebase操作：

在每个标记为`edit`的提交处执行撤销提交操作后，使用以下命令继续rebase操作：

```
git rebase --continue
```

这将继续rebase操作并将标记为`edit`的提交从提交历史中删除。

请注意，此操作将更改提交历史，并可能会影响其他开发人员的工作。因此，请在使用此命令之前谨慎考虑，并确保在执行此操作之前备份您的代码。





```
git rebase -i HEAD~2
git commit --amend
git rebase --continue
git push
```

