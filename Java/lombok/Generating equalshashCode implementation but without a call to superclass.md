Generating equals/hashCode implementation but without a call to superclass
1、lombok 警告，没有注入父类的字段

当我们给一个继承了父类的子类上使用@Data @ToString @EqualsAndHashCode 注解时，IDE 会警告

    Generating equals/hashCode implementation but without a call to superclass

意思是，该注解在实现 ToString EqualsAndHashCode 方法时，不会考虑父类的属性，通过反编译的源码也是可以看到他是没有对父类的字段进行比较的
2、解决方式一：直接在子类上声明 @EqualsAndHashCode(callSuper = true)
3、解决方式二[推荐]：在项目的src/main/java根目录下创建lombok配置文件

    请注意，该方式有版本要求，最低为lombok 1.14

如果是IDEA ，创建该配置文件会被IDEA 以一个黄色的小配置图标进行显示

配置文件(lombok.config)的配置内容如下

config.stopBubbling=true
lombok.equalsAndHashCode.callSuper=call

1、config.stopBubbling=true

该配置声明这个配置文件是一个根配置文件，他会从该配置文件所在的目录开始扫描
2、lombok.equalsAndHashCode.callSuper=call

全局配置 equalsAndHashCode 的 callSuper 属性为true，这样就不用每个类都要去写了
3、lombok 配置的分层

lombok 配置文件支持分层，在根目录配置的的配置文件对全局生效，如果某个子包中也有配置文件，则子包的类优先以子包中的配置为准