#### 常用的排查SQL

* 按客户端IP分组，看哪个客户端的链接数最多
```
select client_ip,count(client_ip) as client_num from (select substring_index(host,':' ,1) as client_ip from information_schema.processlist ) as connect_info group by client_ip order by client_num desc;
```
* 查看正在执行的线程，并按 Time 倒排序，看看有没有执行时间特别长的线程
```
select * from information_schema.processlist where Command != 'Sleep' order by Time desc;
```
* 找出所有执行时间超过 5 分钟的线程，拼凑出 kill 语句，方便后面查杀 （此处 5分钟 可根据自己的需要调整SQL标红处），可复制查询结果到控制台，直接执行，杀死堵塞进程
```
select concat('kill ', id, ';') from information_schema.processlist where Command != 'Sleep' and Time > 300 order by Time desc;
```
* 查询线程及相关信息
```
show full processlist;
```

***
show processlist 是显示用户正在运行的线程，需要注意的是，除了 root 用户能看到所有正在运行的线程外，其他用户都只能看到自己正在运行的线程，看不到其它用户正在运行的线程。除非单独个这个用户赋予了PROCESS 权限。

***