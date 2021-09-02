#### 一、scope属性
*依赖范围控制哪些依赖在哪些classpath中可用，哪些依赖包含在一个应用中。*
* compile （编译）：compile是默认的范围；如果没有提供一个范围，那该依赖的范围就是编译范围。编译范围依赖在所有的classpath中可用，同时它们也会被打包。

* provided （已提供）：provided依赖只有在当JDK或者一个容器已提供该依赖之后才使用。例如，如果你开发了一个web应用，你可能在编译 classpath 中需要可用的Servlet API来编译一个servlet，但是你不会想要在打包好的WAR 中包含这个Servlet API；这个Servlet API JAR 由你的应用服务器或者servlet容器提供。已提供范围的依赖在编译classpath （不是运行时）可用。它们不是传递性的，也不会被打包。
* runtime （运行时）：runtime依赖在运行和测试系统的时候需要，但在编译的时候不需要。比如，你可能在编译的时候只需要JDBC API JAR，而只有在运行的时候才需要JDBC驱动实现。
* test （测试）：test范围依赖在一般的编译和运行时都不需要，它们只有在测试编译和测试运行阶段可用。
* system （系统）：system范围依赖与provided类似，但是你必须显式的提供一个对于本地系统中JAR文件的路径。这么做是为了允许基于本地对象编译，而这些对象是系统类库的一部分。这样的构建应该是一直可用的，Maven也不会在仓库中去寻找它。如果你将一个依赖范围设置成系统范围，你必须同时提供一个systemPath元素。注意该范围是不推荐使用的（建议尽量去从公共或定制的 Maven 仓库中引用依赖）。示例如下：
```
<project>
  <dependencies>
    <dependency>
      <groupId>sun.jdk</groupId>
      <artifactId>tools</artifactId>
      <version>1.5.0</version>
      <scope>system</scope>
      <systemPath>${java.home}/../lib/tools.jar</systemPath>
    </dependency>
    ...
  </dependencies>
</project>
```
* import(导入)：import仅支持在<dependencyManagement>中的类型依赖项上。它表示要在指定的POM <dependencyManagement>部分中用有效的依赖关系列表替换的依赖关系。该scope类型的依赖项实际上不会参与限制依赖项的可传递性。

| scope取值 |有效范围(compile,runtime,test)| 依赖传递 | 例子 |
| :----: | :----: | :----: | :----: | :----: |
| compile | all | 是 | spring-core |
| provided | compile, test	 | 否 | servlet-api |
| runtime | runtime, test | 是 | JDBC驱动 |
| test | test | 否 | JUnit |
| system | compile, test | 是 |  |


#### 二、scope的依赖传递
A–>B–>C。当前项目为A，A依赖于B，B依赖于C，A与C的依赖关系？

|                                              |  compile   | provided | runtime  | test |
| :------------------------------------------: | :--------: | :------: | :------: | :--: |
|                   compile                    | compile(*) |    -     | runtime  |  -   |
|                   provided                   |  provided  |    -     | provided |  -   |
|                   runtime                    |  runtime   |    -     | runtime  |  -   |
|                     test                     |    test    |    -     |   test   |  -   |
| 说明：第一列是A对B的依赖，第一行是B对C的依赖 |            |          |          |      |
* 当B对C的依赖的scope是test或者provided，则A不依赖C。
* 当B对C的依赖是scope是runtime或者compile，则A依赖C。且传递依赖的scope的规则：如果A对B的依赖是compile，那么A对C的依赖和B对C的依赖相同，否则和A对B的依赖保持一致。


#### 三、scope为import的使用
*前面说过该类型作用于只在dependencyManagement内使用生效，它可以用来管理模块依赖，说白了就是针对包含了一系列子依赖进的模块导入到当前项目中进行管理使用，而不是把需要用到的依赖一个一个的加入到项目中进行管理，可以理解为多继承模式。比如在一些场景中：我们只是想单纯加入springboot模块的依赖，而不想将springboot作为父模块引入项目中，此时就可以使用import来处理。*

*一般我们会将springboot作为父模块引入到项目中，如下：*
```
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>2.1.9.RELEASE</version>
    <relativePath/> <!-- lookup parent from repository -->
</parent>
```
*一个项目一般只能有一个父依赖模块，真实开发中，我们都会自定义自己的父模块，这样就会冲突了。所以我们可以使用import来将springboot做为依赖模块导入自己项目中：*
```
<project xmlns="http://maven.apache.org/POM/4.0.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example.demo</groupId>
    <artifactId>MyService</artifactId>
    <version>1.0.0</version>
    <packaging>pom</packaging>
    <description>demo springboot</description>
    <inceptionYear>2019</inceptionYear>
    <organization>
        <name>若声艺美</name>
        <url>http://baidu.com</url>
    </organization>
    <licenses>
        <license>
            <name>The Apache Software License, Version 2.0</name>
            <url>http://www.apache.org/licenses/LICENSE-2.0.txt</url>
        </license>
    </licenses>

    <modules>
        <module>service</module>
        <module>common</module>
        <module>util</module>
    </modules>
    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <!-- 注入组件定义的第三方依赖 -->
    <dependencyManagement>
        <dependencies>
            <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-dependencies</artifactId>
            <version>2.1.9.RELEASE</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
            ......
        </dependencies>
    </dependencyManagement>

    <!-- 远程仓库配置 -->
    <distributionManagement> 
        <repository> 
            <id>releases</id> 
            <url>http://ali/nexus/content/repositories/releases</url> 
        </repository> 
        <snapshotRepository> 
            <id>snapshots</id> 
            <url>http://ali/nexus/content/repositories/snapshots/nexus/content/repositories/snapshots</url> 
        </snapshotRepository> 
    </distributionManagement>

    <build>
        <pluginManagement>
            <plugins>
                <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <!--使用-Dloader.path需要在打包的时候增加<layout>ZIP</layout>，不指定的话-Dloader.path不生效-->
                    <layout>ZIP</layout>
                    <!-- 指定该jar包启动时的主类[建议] -->
                    <mainClass>com.common.util.CommonUtilsApplication</mainClass>
                    <!--<includes>-->
                        <!--<!–依赖jar不打进项目jar包中–>-->
                        <!--<include>-->
                            <!--<groupId>nothing</groupId>-->
                            <!--<artifactId>nothing</artifactId>-->
                        <!--</include>-->
                    <!--</includes>-->
                    <!--配置的 classifier 表示可执行 jar 的名字，配置了这个之后，在插件执行 repackage 命令时，
                    就不会给 mvn package 所打成的 jar 重命名了,这样就可以被其他项目引用了，classifier命名的为可执行jar-->
                    <!--<classifier>myexec</classifier>-->
                </configuration>
                <executions>
                    <execution>
                        <goals>
                            <goal>repackage</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>

            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <configuration>
                    <!-- 剔除spring-boot打包的org和BOOT-INF文件夹(用于子模块打包) -->
                    <!--<skip>true</skip>-->
                    <source>1.8</source>
                    <target>1.8</target>
                    <!--<encoding>UTF-8</encoding>-->
                </configuration>
            </plugin>
            <!--拷贝依赖到jar外面的lib目录-->
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-dependency-plugin</artifactId>
                <executions>
                    <execution>
                        <id>copy</id>
                        <phase>package</phase>
                        <goals>
                            <goal>copy-dependencies</goal>
                        </goals>
                        <configuration>
                            <outputDirectory>
                                ${project.build.directory}/lib
                            </outputDirectory>
                        </configuration>
                    </execution>
                </executions>
            </plugin>
            <plugin>
                <artifactId>maven-assembly-plugin</artifactId>
                <version>${plugin.assembly.version}</version>
                <configuration>
                    <finalName>myservice</finalName>
                    <descriptor>deploy/assembly.xml</descriptor>
                </configuration>
                <executions>
                    <execution>
                        <id>make-assembly</id>
                        <phase>package</phase>
                        <goals>
                            <goal>single</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
            </plugins>
        </pluginManagement>
    </build>
</project>
```
*上述就可以将springboot模块作为依赖导入到项目中，然后就可以继承自己的父模块了，如果要加入其它类似springboot这样的模块的话就和加入springboot一样，这样就可以使模块管理看起来更简洁了，也实现了多继承的效果。*

#### 附注：
*在maven中经常会使用<optional>true</optional>参数，如下：*
```
<dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-devtools</artifactId>
            <optional>true</optional>
</dependency>
```
*此处的<optional>true</optional>的作用是让依赖只被当前项目使用，而不会在模块间进行传递依赖。*