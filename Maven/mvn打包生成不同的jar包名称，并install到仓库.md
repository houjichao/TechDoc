### 1.理解生成jar包名称和安装仓库的jar名称的区别

1. build.finalName指定生成jar包的名称，即生成到target目录下的jar包名称
2. 安装到仓库的jar包名称artifactId-version指定的，包路径是groupId指定的
3. 由此artifactId是固定的情况下，安装到仓库的jar名称是无法改变的，即使profile中的build.finalName不同。修改仓库里面jar的名称，就必须修改artifactId这个东西。

### 2.根据不同的profile指定finalName

```
<profile>
    <!-- 默认，普通方式打包 -->
    <activation>
        <activeByDefault>true</activeByDefault>
    </activation>
    <id>jar</id>
    <build>
        <finalName>license-gov-spring-boot-starter-${version}</finalName>
    </build>
</profile>
<profile>
    <!-- 为前端构建的jar包 -->
    <id>nodejs</id>
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <executable>true</executable>
                </configuration>
            </plugin>
        </plugins>
        <finalName>license-gov-spring-boot-starter-web-${version}</finalName>
    </build>
</profile>
```

### 3.修改artifactId名称为动态获取

```
<artifactId>${project.build.finalName}</artifactId>
```

### 4.构建jar包

```
mvn clean install -P nodejs
```

此处指定了不同的包名称，生成的仓库里面jar的路径也就不一样了

### 5.注意

```
[ERROR] The build could not read 1 project -> [Help 1]
[ERROR]   
[ERROR]   The project com.hjc.gov:null:1.0.5-RELEASES (/Users/houjichao/Work/Java/hjc/basic-components/gov-license/license-gov-spring-boot-starter/pom.xml) has 3 errors
[ERROR]     Resolving expression: '${build.finalName}': Detected the following recursive expression cycle in 'build.finalName': [build.finalName, artifactId] @ com.hjc.gov:${build.finalName}:1.0.5-RELEASES, /Users/houjichao/Work/Java/xxx/license-gov-spring-boot-starter/pom.xml -> [Help 2]
[ERROR]     For artifact {com.hjc.gov:null:1.0.5-RELEASES:jar}: The artifactId cannot be empty. @ com.hjc.gov:[unknown-artifact-id]:1.0.5-RELEASES, /Users/houjichao/Work/Java/hjc/basic-components/gov-license/license-gov-spring-boot-starter/pom.xml
[ERROR]     'artifactId' is missing. @ com.hjc.gov:${build.finalName}:1.0.5-RELEASES, /Users/houjichao/Work/Java/xxxx/license-gov-spring-boot-starter/pom.xml, line 12, column 17
[ERROR] 
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR] 
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/ProjectBuildingException
[ERROR] [Help 2] http://cwiki.apache.org/confluence/display/MAVEN/InterpolationCycleException
```

**Detected the following recursive expression cycle in 'build.finalName':**

如果将<artifactId>${project.build.finalName}</artifactId>赋值，<finalName>${artifactId}-web-${version}</finalName>赋值，则会出现循环引用，所以profile中的build.finalName需要固定值。