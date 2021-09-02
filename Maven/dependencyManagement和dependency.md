#### dependencyManagement和dependency的区别
> 1.Maven中的dependencyManagement的作用在于对所依赖的jar包的版本进行管理

> 2.在pom文件中,jar的版本判断的两种方式:
>
> > 1.如果dependencies里面的dependency自己没有声明version元素,那么maven就会到dependencyManagement里面去找有没有对该artifactId和groupId进行过版本声明,如果有,就继承它,如果没有就会报错,告诉我们必须为dependency声明一个version

>> 2.如果dependencies中的dependency声明了version,那么无论dependencyManagement中有无对该jar的version声明,都以dependency里的为准.

```
pom.xml  
//只是对版本进行管理，不会实际引入jar  
<dependencyManagement>  
      <dependencies>  
            <dependency>  
                <groupId>org.springframework</groupId>  
                <artifactId>spring-core</artifactId>  
                <version>3.2.7</version>  
            </dependency>  
    </dependencies>  
</dependencyManagement>  
  
//会实际下载jar包  
<dependencies>  
       <dependency>  
                <groupId>org.springframework</groupId>  
                <artifactId>spring-core</artifactId>  
       </dependency>  
</dependencies>

```

***
使用maven可以很方便的进行项目依赖的管理，即可以管理我们显示引入具体版本的依赖，也可以管理某些第三方引入的一些依赖的版本，从而能更好的实现摸一个依赖在整个项目中只存在唯一一个版本（使用dependencyManagement元素进行管理），示例效果如下：

***

