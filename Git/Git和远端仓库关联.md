## Git和远端仓库关联

### **1. 打开在你的项目文件夹，输入下面的命令**

git init

 输完上面的命令，文件夹中会出现一个.git文件夹

### **2. 添加所有文件**

git add .

注意最后的点是有用的哦

###  **3. 提交所有文件**

git commit -m "这里是备注信息" -a

### **4. 连接到远程仓库**

提前在你的github中新建一个仓库

### **5. 连接远程仓库，在本地的命令框中输入下面的命令，即连接到了名为viua-manager-service的仓库上**

git remote add origin https://git.****.com/***.git

### **6.把本地项目推送到远程仓库**

```
git push -u origin master 
git push -u origin master -f
```

