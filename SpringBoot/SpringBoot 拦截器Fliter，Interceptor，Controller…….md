在项目的开发中，在某些情况下，我们需要对客户端发出的请求进行拦截，常用的API拦截方式有Fliter，Interceptor，ControllerAdvice以及Aspect。



上面的图是Spring中拦截机制，请求从Filter-->>Controller的过程中，只要在指定的环节出现异常，可以通过对应的机制进行处理。反之在任何一个环节如果异常未处理则不会进入下一个环节，会直接往外抛，例如在ControllerAdvice验证发生异常则会抛给Filter，如果Filter未处理，则最终会由Tomcat容器抛出。

过滤器：Filter
可以获得Http原始的请求和响应信息，但是拿不到响应方法的信息。
注册Filter，在springboot当中提供了FilterRegistrationBean类来注册Filter


//通过注解实现
@Slf4j
@Component
@WebFilter(filterName = "TimerFilter",urlPatterns = "/*")
public class TimerFilter implements Filter {
    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        log.info("" + getClass() + " init");
    }

    /**
     * 在这方法中进行拦截
     * @param request
     * @param response
     * @param chain
     * @throws IOException
     * @throws ServletException
     */
    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
        log.info("time filter start class is {}",getClass());
        long start = System.currentTimeMillis();
        chain.doFilter(request, response);
        log.info("time filter:{}"+(System.currentTimeMillis()-start));
        log.info("time filter finish");
    }
     
    @Override
    public void destroy() {
        log.info("" + getClass() + " init");
    }
}
//通过configuration实现
//自定义 一个Servlet类型的Filter实现类
public class FilterDemo3 implements Filter {
    private final Logger log = LoggerFactory.getLogger(getClass());

    @Resource
    private CommonConfig commonConfig;
     
    @Override
    public void destroy() {
        log.info("" + getClass() + " destroy");
     
    }
     
    @Override
    public void doFilter(ServletRequest arg0, ServletResponse arg1, FilterChain arg2) throws IOException, ServletException {
        log.info("" + getClass() + " doFilter " + commonConfig);
        arg2.doFilter(arg0, arg1);
     
    }
     
    @Override
    public void init(FilterConfig arg0) throws ServletException {
        log.info("" + getClass() + " init");
     
    }

}

/**
 * web 组件配置
 * 
 * @author sdcuike
 *         <p>
 *         Created on 2017-02-10
 *         <p>
 *         自定义注入，并支持依赖注入，组件排序
     */
    @Configuration
    public class WebComponent2Config   {

    @Bean
    public FilterRegistrationBean filterDemo3Registration() {
        FilterRegistrationBean registration = new FilterRegistrationBean();
        registration.setFilter(filterDemo3());
        registration.addUrlPatterns("/*");
        registration.addInitParameter("paramName", "paramValue");
        registration.setName("filterDemo3");
        registration.setOrder(6);
        return registration;
    }

    @Bean
    public FilterRegistrationBean filterDemo4Registration() {
        FilterRegistrationBean registration = new FilterRegistrationBean();
        registration.setFilter(filterDemo4());
        registration.addUrlPatterns("/*");
        registration.addInitParameter("paramName", "paramValue");
        registration.setName("filterDemo4");
        registration.setOrder(7);
        return registration;
    }

    @Bean
    public Filter filterDemo3() {
        return new FilterDemo3();
    }

    @Bean
    public Filter filterDemo4() {
        return new FilterDemo4();
    }

}


常用属性


拦截器：Interceptor
可以获得Http原始的请求和响应信息，也拿得到响应方法的信息，但是拿不到方法响应中的参数的值。
在web开发中，拦截器是经常用到的功能。它可以帮我们验证是否登陆、预先设置数据以及统计方法的执行效率等。在spring中拦截器有两种，第一种是HandlerInterceptor，第二种是MethodInterceptor。HandlerInterceptor是SpringMVC中的拦截器，它拦截的是Http请求的信息，优先于MethodInterceptor。而MethodInterceptor是springAOP的。前者拦截的是请求的地址，而后者是拦截controller中的方法，因为下面要将Aspect，就不详细讲述MethodInterceptor。

```
        
/**
 * @author: yx.zh
 * @date: 2020-06-14 08:06
 * Interceptor拦截器中。
 **/
@Component
@Slf4j
public class Interceptor implements HandlerInterceptor {
    /**
     * 控制器方法调用之前会进行
     * 和上面的Filter一样，继承的某些接口方法中也加了default关键字，可以不用重写，这里为了演示就都写了
     *
     * @param request
     * @param response
     * @param handler
     * @return true就是选择可以调用后面的方法  如果后续有ControllerAdvice的话会去执行对应的方法等。
     * @throws Exception
     */
    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        log.info(((HandlerMethod) handler).getBean().getClass().getName());
        log.info(((HandlerMethod) handler).getMethod().getName());
        request.setAttribute("startTime", System.currentTimeMillis());
        return true;
    }
 
    /**
     * 控制后方法执行之后会进行，抛出异常则不会被执行
     *
     * @param request
     * @param response
     * @param handler
     * @param modelAndView
     * @throws Exception
     */
    @Override
    public void postHandle(HttpServletRequest request, HttpServletResponse response, Object handler, ModelAndView modelAndView) throws Exception {
        log.info("postHandle");
        Long start = (Long) request.getAttribute("startTime");
        log.info("time interceptor 耗时：{}" , (System.currentTimeMillis() - start));
    }
 
    /**
     * 方法被调用或者抛出异常都会被执行
     * @param request
     * @param response
     * @param handler
     * @param ex
     * @throws Exception
     */
    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) throws Exception {
        log.info("afterCompletion");
        Long start = (Long) request.getAttribute("startTime");
        log.info("time interceptor 耗时{}", (System.currentTimeMillis() - start));
    }
}
```

ControllerAdvice（Controller增强）
与ControllerAdvice相同作用的，还有RestControllerAdvice。主要是用于全局的异常拦截和处理,这里的异常可以使自定义异常也可以是JDK里面的异常用于处理当数据库事务业务和预期不同的时候抛出封装后的异常，进行数据库事务回滚，并将异常的显示给用户。

```
        
/**
 * @author: yx.zh
 * @date: 2020-06-13 16:59
 **/
@Slf4j
@RestControllerAdvice
public class ControllerExceptionFilter {
    /**
     * 处理自定义异常
     */
    @ExceptionHandler(FrameException.class)
    public Response handleFrameException(FrameException e) {
        log.error(e.getMessage(), e);
        return ResultUtil.exceptionResult(e);
    }
 
    /**
     * 方法参数校验
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public Response handleMethodArgumentNotValidException(MethodArgumentNotValidException e) {
        log.error(e.getMessage());
        return ResultUtil.exceptionResult(new FrameException(ExceptionEnum.PARAMS_ERROR), e.getBindingResult().getFieldError().getDefaultMessage());
    }
 
    /**
     * ValidationException
     */
    @ExceptionHandler(ValidationException.class)
    public Response handleValidationException(ValidationException e) {
        log.error(e.getMessage(), e);
        return ResultUtil.exceptionResult(new FrameException(ExceptionEnum.PARAMS_ERROR), e.getCause().getMessage());
    }
 
    /**
     * ConstraintViolationException
     */
    @ExceptionHandler(ConstraintViolationException.class)
    public Response handleConstraintViolationException(ConstraintViolationException e) {
        log.error(e.getMessage(), e);
        return ResultUtil.exceptionResult(new FrameException(ExceptionEnum.PARAMS_ERROR), e.getMessage());
    }
 
    @ExceptionHandler(NoHandlerFoundException.class)
    public Response handlerNoFoundException(Exception e) {
        log.error(e.getMessage(), e);
        return ResultUtil.exceptionResult(new FrameException(ExceptionEnum.URLNOTFUOND), "路径不存在，请检查路径是否正确");
    }
 
    @ExceptionHandler(DuplicateKeyException.class)
    public Response handleDuplicateKeyException(DuplicateKeyException e) {
        log.error(e.getMessage(), e);
        return ResultUtil.exceptionResult(new FrameException(ExceptionEnum.DUPLICATE_KEY_CODE), "数据重复，请检查后提交");
    }
 
 
    @ExceptionHandler(Exception.class)
    public Response handleException(Exception e) {
        log.error(e.getMessage(), e);
        return ResultUtil.exceptionResult(new FrameException(ExceptionEnum.SYSTEM_EXCEPTION), "系统繁忙,请稍后再试");
    }
 
   
}
```

#### 切面：Aspect

主要是进行公共方法的可以拿得到方法响应中参数的值，但是拿不到原始的Http请求和相对应响应的方法,属于方法级别的拦截器。
执行顺序如下


            
    正常异常AroundBeforeAfterReturningAfterThrowing
    /**
     * @auther zhyx
     * @Date 2020/6/11 9:08
     * @Description
     */
    @Component
    @Aspect
    @Slf4j
    public class HttpAspect {
        @Pointcut("execution(* com.universe.polaris.controller.*.*(..))")
        public void controllerPointcut(){}
     
     
        @Before("controllerPointcut()")
        public void before(JoinPoint joinPoint){
            ServletRequestAttributes requestAttributes = (ServletRequestAttributes)RequestContextHolder.getRequestAttributes();
            HttpServletRequest request = requestAttributes.getRequest();
            /**
             * url
             */
            log.info("Before：url={}",request.getRequestURL());
            /**
             * ip
             */
            log.info("Before：ip={}",request.getRemoteAddr());
            /**
             * 请求方式
             */
            log.info("Before：method={}",request.getMethod());
            /**
             * 代理类
             */
            log.info("Before：代理类调用的方法:{}",joinPoint.getSignature().getDeclaringTypeName() + "#" + joinPoint.getSignature().getName());
            StringBuilder sb=new StringBuilder();
            for(Object temp:joinPoint.getArgs()){
                sb.append(temp.toString());
            }
            /**
             * 参数
             */
            log.info("params={}",sb.toString());
        }
        @Around("controllerPointcut()")
        public Object  around(ProceedingJoinPoint proceedingJoinPoint)   {
            try {
                log.info("Around: 环绕执行");
                return proceedingJoinPoint.proceed();
            } catch (Throwable e) {
                e.printStackTrace();
            }
            return null;
        }
        @AfterReturning( pointcut = "controllerPointcut()",returning = "object")
        public void afterReturning(Object object){
            log.info("AfterReturning 执行: response={}", JSON.toJSONString(object));
        }
     
        @AfterThrowing(throwing = "e", pointcut = "controllerPointcut()")
        public void afterThrowing(Throwable e) {
            log.error("系统异常:{}", e.getMessage());
        }
    }

