#### curl发送post请求

```
curl -H "Content-Type:application/json"  -H "Andon-Caller:telesales"  -H "Andon-Random:1962316453" -H "Andon-Timestamp:1673438870"  -H "Andon-Signature:xxxxxxxxxxxxxxxxx" -X POST -d '{\"ticket_id\":3978187,\"user_id\":\"HouJiChao#7\",\"inner_reply\":\"jack测试工单评论\",\"request_id\":\"1673230877595\"}' http://xxxx.com/open/api/v1/tickets/3978187/comment
```

#### curl检查网络

-I 把访问的内容省略掉，只显示状态码，-v可显示详细过程

curl  -Iv显示状态码  -O下载对象页面  -o自定义名字下载  -u指定登录用户和密码  -x指定ip和端口 

```
curl -Iv http://xxxx.com/open/api/v1/tickets/3978187/comment
```

