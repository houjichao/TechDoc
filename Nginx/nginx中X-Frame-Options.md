**X-Frame-Options 响应头**

X-Frame-Options HTTP 响应头是用来给浏览器指示允许一个页面可否在 <frame>, <iframe> 或者 <object> 中展现的标记。网站可以使用此功能，来确保自己网站的内容没有被嵌到别人的网站中去，也从而避免了点击劫持 (clickjacking) 的攻击。

**X-Frame-Options 有三个值:**

#### **DENY**

表示该页面不允许在 frame 中展示，即便是在相同域名的页面中嵌套也不允许。

#### **SAMEORIGIN**

表示该页面可以在相同域名页面的 frame 中展示。

#### **ALLOW-FROM uri**

表示该页面可以在指定来源的 frame 中展示。

换一句话说，如果设置为 DENY，不光在别人的网站 frame 嵌入时会无法加载，在同域名页面中同样会无法加载。另一方面，如果设置为 SAMEORIGIN，那么页面就可以在同域名页面的 frame 中嵌套。





# 设置X-Frame-Options的两种方法

介绍nginx分别通过http和server设置 `X-Frame-Options` ，防止网站被别人用iframe嵌入使用。需要说明的是，只需用其中一个方法即可，在http配置代码块或server配置代码块里设置。

- 在http配置里设置X-Frame-Options
- 在server配置里设置X-Frame-Options

### **在http配置里设置X-Frame-Options**

打开`nginx.conf`，文件位置一般在安装目录 `/usr/local/nginx/conf` 里。

然后在http配置代码块里某一行添加如下语句即可：

- add_header X-Frame-Options SAMEORIGIN;

如图所示：

![在http配置里设置X-Frame-Options](https://imgconvert.csdnimg.cn/aHR0cDovL3d3dy53ZWJrYWthLmNvbS90dXRvcmlhbC9zZXJ2ZXIvdXBsb2FkLzIwMTgvMS8yMDE4MDExODE2NDg1NDM1NjIuZ2lm)

在http配置里设置X-Frame-Options

添加后，重启nginx，命令是：

- /usr/local/nginx/sbin/nginx -s reload

即可生效。

### **在server配置里设置X-Frame-Options**

在server配置里设置X-Frame-Options跟在http配置里设置X-Frame-Options方法是一样的，同样是在server的配置代码块里添加如下语句即可：

- add_header X-Frame-Options SAMEORIGIN;

如下所示：

```
    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  _;
        #root         /usr/local/openresty/nginx/html/;

        add_header X-Frame-Options SAMEORIGIN;

        location /api/model-market {
                proxy_pass http://snpt-model-market-snpt-display:9096;
                proxy_set_header X-Forward-For $remote_addr;
        }
```

在server配置里设置X-Frame-Options

添加后，重启nginx，命令是：

- /usr/local/nginx/sbin/nginx -s reload

即可生效。