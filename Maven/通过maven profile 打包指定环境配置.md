#### 配置不同环境的配置文件

#### 配置pom设置porfile
```
<profiles>
    <profile>
        <!-- 本地开发环境 -->
        <id>dev</id>
        <properties>
            <profiles.active>dev</profiles.active>
        </properties>
        <activation>
            <activeByDefault>true</activeByDefault>
        </activation>
    </profile>
    <profile>
        <!-- 测试环境 -->
        <id>test</id>
        <properties>
            <profiles.active>test</profiles.active>
        </properties>
    </profile>
    <profile>
        <!-- 生产环境 -->
        <id>pro</id>
        <properties>
            <profiles.active>pro</profiles.active>
        </properties>
    </profile>
</profiles>
```

#### 打包时根据环境选择配置目录
这个项目比较坑，他把配置文件放到了webapps/config下面。所以这里打包排除 dev/test/pro 这三个目录时候，不能使用exclude去排除，在尝试用 warSourceExcludes 可以成功。之前还试过 packagingExcludes 也没有生效，查了下资料发现 packagingExcludes maven 主要是用来过滤 jar 包的。

```
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-war-plugin</artifactId>
    <version>3.1.0</version>
    <configuration>
        <warSourceExcludes>
            config/test/**,config/pro/**,config/dev/**
        </warSourceExcludes>
        <webResources>
            <resource>
                <directory>src/main/webapp/config/${profiles.active}</directory>
                <targetPath>config</targetPath>
                <filtering>true</filtering>
            </resource>
        </webResources>
    </configuration>
</plugin>
```

#### 最后根据环境打包
```
## 开发环境打包
mvn clean package -P dev

## 测试环境打包
mvn clean package -P test

## 生产环境打包
mvn clean package -P pro
```