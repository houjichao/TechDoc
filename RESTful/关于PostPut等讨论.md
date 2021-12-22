#### 公司规定所有接口都用 post 请求，这是为什么？

『业界最佳实践』制定规范，幂等不修改服务器状态的用GET，幂等修改服务器状态的用PUT，不幂等修改服务器状态的用POST。





 get 与 post 的请求的一些区别：

- post更安全（不会作为url的一部分，不会被缓存、保存在服务器日志、以及浏览器浏览记录中）
- post发送的数据更大（get有url长度限制）
- post能发送更多的数据类型（get只能发送ASCII字符）
- post比get慢
- post用于修改和写入数据，get一般用于搜索排序和筛选之类的操作
- get请求的是静态资源，则会缓存，如果是数据，则不会缓存





Restful的优势：

* 表达不同的业务动作语义：GET/POST/PATCH/PUT/DELETE……，
* 表达“资源”的概念利用
* url path，querystring，header，status code等来表达很多接口功能
* 以上两条可以达成一种“统一”的接口表达形式，以至于可以围绕这个形式实现接口维护的工具，比如swagger。
* Get资源可以利用缓存

