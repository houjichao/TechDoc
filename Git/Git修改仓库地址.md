#### 删除原有地址

```
git remote rm origin
```

#### 修改为新的地址

```
git remote add origin new_git_url
```

#### 提交代码，推送至新地址

```
git add .
git commit -m '提交备注信息'
git push origin branch_name:branch_name
```

