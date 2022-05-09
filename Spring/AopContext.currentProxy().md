原来在springAOP的用法中，只有代理的类才会被切入，我们在controller层调用service的方法的时候，是可以被切入的，但是如果我们在service层 A方法中，调用B方法，切点切的是B方法，那么这时候是不会切入的，解决办法就是如上所示，在A方法中使用((Service)AopContext.currentProxy()).B() 来调用B方法，这样一来，就能切入了！

AopContext.currentProxy()该用法的意义
具体的用法在下面的代码中可以体会：



    @Configuration
    @ComponentScan("com.dalianpai.spring5.aop")
    @EnableAspectJAutoProxy(exposeProxy = true)//开启spring注解aop配置的支持
    public class SpringConfiguration {
    }
     
     
     
    public class User implements Serializable {
        private String id;
        private String username;
        private String password;
        private String email;
        private Date birthday;
        private String gender;
        private String mobile;
        private String nickname;
     
        public String getId() {
            return id;
        }
     
        public void setId(String id) {
            this.id = id;
        }
     
        public String getUsername() {
            return username;
        }
     
        public void setUsername(String username) {
            this.username = username;
        }
     
        public String getPassword() {
            return password;
        }
     
        public void setPassword(String password) {
            this.password = password;
        }
     
        public String getEmail() {
            return email;
        }
     
        public void setEmail(String email) {
            this.email = email;
        }
     
        public Date getBirthday() {
            return birthday;
        }
     
        public void setBirthday(Date birthday) {
            this.birthday = birthday;
        }
     
        public String getGender() {
            return gender;
        }
     
        public void setGender(String gender) {
            this.gender = gender;
        }
     
        public String getMobile() {
            return mobile;
        }
     
        public void setMobile(String mobile) {
            this.mobile = mobile;
        }
     
        public String getNickname() {
            return nickname;
        }
     
        public void setNickname(String nickname) {
            this.nickname = nickname;
        }
    }
     
     
    @Service("userService")
    public class UserServiceImpl implements UserService {
     
        @Override
        public void saveUser(User user) {
            System.out.println("执行了保存用户"+user);
        }
     
        @Override
        public void saveAllUser(List<User> users) {
            for(User user : users){
                UserService proxyUserServiceImpl = (UserService)AopContext.currentProxy();
                proxyUserServiceImpl.saveUser(user);
            }
        }
    }
     
     
    public interface UserService {
     
        /**
         * 模拟保存用户
         * @param user
         */
        void saveUser(User user);
     
        /**
         * 批量保存用户
         * @param users
         */
        void saveAllUser(List<User> users);
    }
     
     
    @Component
    @Aspect//表明当前类是一个切面类
    public class LogUtil {
     
        /**
         * 用于配置当前方法是一个前置通知
         */
        @Before("execution(* com.dalianpai.spring5.aop.service.impl.*.saveUser(..))")
        public void printLog(){
            System.out.println("执行打印日志的功能");
        }
    }

测试类：

    public class SpringEnableAspecctJAutoProxyTest {
     
        public static void main(String[] args) {
            //1.创建容器
            AnnotationConfigApplicationContext ac = new AnnotationConfigApplicationContext(SpringConfiguration.class);
            //2.获取对象
            UserService userService = ac.getBean("userService",UserService.class);
            //3.执行方法
            User user = new User();
            user.setId("1");
            user.setUsername("test");
            List<User> users = new ArrayList<>();
            users.add(user);
     
            userService.saveAllUser(users);
        }
    }
![image-20200921231626082](https://img-blog.csdnimg.cn/img_convert/917be2e27050c7880bbf8024ab2a2d09.png)

如果去掉这行UserService proxyUserServiceImpl = (UserService)AopContext.currentProxy();

![image-20200921231738938](https://img-blog.csdnimg.cn/img_convert/30fa08366d13c042f2e811c02a97acbb.png)





在同一个类中，非事务方法A调用事务方法B，事务失效，得采用AopContext.currentProxy().xx()来进行调用，事务才能生效。

> B方法被A调用，对B方法的切入失效，但加上AopContext.currentProxy()创建了代理类，在代理类中调用该方法前后进行切入。对于B方法![proxy.B，执行的过程是先记录日志后调用方法体，但在A方法](https://math.jianshu.com/math?formula=proxy.B%EF%BC%8C%E6%89%A7%E8%A1%8C%E7%9A%84%E8%BF%87%E7%A8%8B%E6%98%AF%E5%85%88%E8%AE%B0%E5%BD%95%E6%97%A5%E5%BF%97%E5%90%8E%E8%B0%83%E7%94%A8%E6%96%B9%E6%B3%95%E4%BD%93%EF%BC%8C%E4%BD%86%E5%9C%A8A%E6%96%B9%E6%B3%95)proxyA中调用只能对A进行增强，A里面调用B使用的是对象.B(),而不是$proxy.B(),所以对B的切入无效。

AopContext.currentProxy()使用了ThreadLocal保存了代理对象，因此
AopContext.currentProxy().B()就能解决。

在不同类中，非事务方法A调用事务方法B，事务生效。
 在同一个类中，事务方法A调用非事务方法B，事务具有传播性，事务生效
 在不同类中，事务方法A调用非事务方法B，事务生效。

