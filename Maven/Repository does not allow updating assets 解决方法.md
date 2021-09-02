#### Repository does not allow updating assets 解决方法
##### 背景
```
1.在内网服务器上搭建nexus私服，并尝试在工程中直接使用‘mvn deploy’将本地项目打包，上传私服

2.nexus版本3.6.0-02，通过安装过程，知道与nexus2.X有很大差别
```
##### 问提报错
```
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-deploy-plugin:2.7:deploy (deploy) on project light.inf: Failed to deploy artifacts: Could not transfer artifact com.xxx.game:light.inf:jar:1.0 from/to releases (http://192.168.10.xxx:8081/repository/maven-releases/): Failed to transfer file:
http://192.168.10.xxx:8081/repository/maven-releases/com/xxx/game/light.inf/1.0/light.inf-1.0.jar. Return code is: 400, ReasonPhrase: Repository does not allow updating assets: maven-releases. -> [Help 1]
```
##### 解决
```
1.事先请确保nexus搭建正确，可以使用cmd执行带参数的mvn deploy命令成功上传一个jar来验证，cmd命令附上
mvn deploy:deploy-file -DgroupId=com.test -DartifactId=test -Dversion=1.2 -Dpackaging=jar -Dfile=E:\workspace\test-1.2.jar -Durl=http://192.168.xx.xxx:8081/repository/maven-releases/ -DrepositoryId=releases
当然，该命令能成功执行的前提是本地安装的mvn目录的conf/settings.xml中配置有id为releases的server

2.浏览器登录nexus管理界面–>设置图标–>Repository–>Repositories–>maven-releases–>Hosted–>请选择‘Allow redeploy’策略，默认是disable策略，然后保存。 请注意，不同版本的nexus，进入的路径可能有细微区别
```