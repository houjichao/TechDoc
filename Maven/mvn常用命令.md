**查看依赖树**

```
mvn dependency:tree
```

**使用命令传包：**

```
mvn deploy:deploy-file -DgroupId=com.hjc.demo -DartifactId=wll-mgr-common -Dversion=1.2.3-SNAPSHOT -Dpackaging=jar -Dfile=/Users/jackjchou/workspace/wyjxmzc/wll-app-common/target/wll-app-common-1.2.3-SNAPSHOT.jar -Durl=https://ipcmaven.pdcts.com.cn/repository/maven-snapshots/ -DrepositoryId=prod3-nexus
```



