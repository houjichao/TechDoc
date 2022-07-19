```
mvn deploy:deploy-file -DgroupId=xxx -DartifactId=xxx -Dversion=0.0.1 -Dpackaging=pom -Dfile=pom.xml -Durl=http://xxxx/nexus/content/repositories/releases/ -DrepositoryId=nexus-releases -e
```



经常或遇到上传单个pom文件到远程私库的情况，但是单个pom下又有子项目，又不想把子项目一起上传到私库，该怎么办，很简单，一个参数搞定，-N 意思是：不会递归到子项目里执行当前命令

```
mvn deploy -N
```



> -N,–non-recursive Do not recurse into sub-projects