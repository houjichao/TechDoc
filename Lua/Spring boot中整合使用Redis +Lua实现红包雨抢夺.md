### 一、需求介绍

如同前两年的爆款“答题抢红包”的类似需求，当一轮题目答完后会下起红包雨，我们本次分析的也是类似的需求。
题目答完前，已初始化本轮次的红包雨批次ID，并将总金额拆分成若干份放入此批次红包。题目答完后，用户可抢红包，每轮次每用户最多抢3个。红包雨结束后，需在页面展示本轮次红包雨中抢夺金额前N名。


### 二、红包雨的需求分析及概要设计

1. 用户ID:userId, 红包ID:redBagId
2. 红包雨的存储设计
   1. 红包雨详情：redis的列表结构存储，预先将红包金额塞入其中
   2. 红包雨名单：redis的有序集合结构存储，后续需展示红包金额前N名
   3. 抢红包雨限制：redis的Hash结构存储，单用户一次红包雨最多抢多3个红包
3. Redis的相关结构和Key的设计

|      | 红包雨详情              | 红包雨名单                     | 抢红包雨限制                      |
| ---- | ----------------------- | ------------------------------ | --------------------------------- |
| 结构 | 列表 List<金额>         | 有序集合 SortedSet <金额, uid> | Hash集合 Hash<uid, ‘uid-第N次抢’> |
| key  | RedBagBatch:${redBagId} | RedBagBatch:${redBagId}:Users  | RedBagBatch:${redBagId}:Limit     |

### 三、红包雨的Lua脚本设计及模拟演示

下面开始具体的表演

1. 红包id为：7758521，用户id分别为：u1、u3、u3、u4、u5
2. redis的key分别为：RedBagBatch:7758521、RedBagBatch:7758521:Users、RedBagBatch:7758521:Limit
3. 给redBagId=7758521的红包，初始化进去10个红包。红包金额为1-10，随机顺序。以下为redis-cli的截图

```
-- 抢红包雨的lua脚本
local REDBAG_LIMIT_KEY = KEYS[1]
local REDBAG_INFO_KEY = KEYS[2]
local REDBAG_USER_KEY = KEYS[3]

local userId = ARGV[1]

-- 抢了超过3个，返回没抢到
local grabCount = redis.call('hincrby', REDBAG_LIMIT_KEY, userId, 1)
if(grabCount > 3) then
    return "-1"
end

-- pop一个红包数据
local amount = redis.call('lpop', REDBAG_INFO_KEY)

-- 没抢到返回0
if(amount == nil) then
    return "-2"
end

-- 放入结果Set
redis.call('zadd', REDBAG_USER_KEY, amount, userId.."-"..grabCount);

return amount
```

```
## 为方便演示，以下为redis客户端使用命令行操作记录
## step1：初始化红包数据
127.0.0.1:6379> lpush RedBagBatch:7758521 1 3 10 6 8 7 2 5 4 9
(integer) 10
127.0.0.1:6379> lrange RedBagBatch:7758521 0 -1
 1) "9"
 2) "4"
 3) "5"
 4) "2"
 5) "7"
 6) "8"
 7) "6"
 8) "10"
 9) "3"
10) "1"
```

```
## step2：使用lua脚本抢红包，模拟用户抢夺情况 
[root@vm01 learn_lua]# redis-cli -a 123456 --eval RedBagBatchGrab.lua RedBagBatch:7758521:Limit RedBagBatch:7758521 RedBagBatch:7758521:Users , u1 
"9"
[root@vm01 learn_lua]# redis-cli -a 123456 --eval RedBagBatchGrab.lua RedBagBatch:7758521:Limit RedBagBatch:7758521 RedBagBatch:7758521:Users , u2
"4"
[root@vm01 learn_lua]# redis-cli -a 123456 --eval RedBagBatchGrab.lua RedBagBatch:7758521:Limit RedBagBatch:7758521 RedBagBatch:7758521:Users , u3 
"5"
[root@vm01 learn_lua]# redis-cli -a 123456 --eval RedBagBatchGrab.lua RedBagBatch:7758521:Limit RedBagBatch:7758521 RedBagBatch:7758521:Users , u4
"2"
[root@vm01 learn_lua]# redis-cli -a 123456 --eval RedBagBatchGrab.lua RedBagBatch:7758521:Limit RedBagBatch:7758521 RedBagBatch:7758521:Users , u5
"7"
[root@vm01 learn_lua]# redis-cli -a 123456 --eval RedBagBatchGrab.lua RedBagBatch:7758521:Limit RedBagBatch:7758521 RedBagBatch:7758521:Users , u1 
"8"
[root@vm01 learn_lua]# redis-cli -a 123456 --eval RedBagBatchGrab.lua RedBagBatch:7758521:Limit RedBagBatch:7758521 RedBagBatch:7758521:Users , u2 
"6"
[root@vm01 learn_lua]# redis-cli -a 123456 --eval RedBagBatchGrab.lua RedBagBatch:7758521:Limit RedBagBatch:7758521 RedBagBatch:7758521:Users , u1 
"10"
[root@vm01 learn_lua]# redis-cli -a 123456 --eval RedBagBatchGrab.lua RedBagBatch:7758521:Limit RedBagBatch:7758521 RedBagBatch:7758521:Users , u1 
"-1"
[root@vm01 learn_lua]# redis-cli -a 123456 --eval RedBagBatchGrab.lua RedBagBatch:7758521:Limit RedBagBatch:7758521 RedBagBatch:7758521:Users , u2 
"3"
[root@vm01 learn_lua]# redis-cli -a 123456 --eval RedBagBatchGrab.lua RedBagBatch:7758521:Limit RedBagBatch:7758521 RedBagBatch:7758521:Users , u2 
"-1"
[root@vm01 learn_lua]# redis-cli -a 123456 --eval RedBagBatchGrab.lua RedBagBatch:7758521:Limit RedBagBatch:7758521 RedBagBatch:7758521:Users , u3
"1"

```

![红包雨抢夺情况](https://img-blog.csdnimg.cn/2019081013235198.jpg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2xwZjQ2MzA2MTY1NQ==,size_16,color_FFFFFF,t_70)

```
## step3.查看红包雨排行榜，按红包金额倒序（奇数行为：value，偶数行为：score）
## value解读：用户-本轮次红包第N次抢夺
## score解读：红包金额
127.0.0.1:6379> zrevrange RedBagBatch:7758521:Users 0 -1 WITHSCORES 
 1) "u1-3"
 2) "10"
 3) "u1-1"
 4) "9"
 5) "u1-2"
 6) "8"
 7) "u5-1"
 8) "7"
 9) "u2-2"
10) "6"
11) "u3-1"
12) "5"
13) "u2-1"
14) "4"
15) "u2-3"
16) "3"
17) "u4-1"
18) "2"
19) "u3-2"
20) "1" 
```



### 四、Lua脚本在生产环境的使用

真正在项目中总不能像上面显示那样，使用命令行操作lua脚本了，下面介绍下我们在项目中是如何使用的。
项目环境：spring boot+mybatis
项目redis客户端：redisTemplate

基本步骤如下：

1. 创建一个Service类，实现ApplicationListener接口，当容器初始化完成时触发“初始化加载lua脚本”的事件
2. 加锁加载lua脚本：使用script load方式调用Redis服务端，获取该脚本的sha值，方便后续使用。类似单例，加载一份，后续循环使用，节约资源。
3. 使用lua脚本：后续的每次调用，均使用初始化产生的该脚本的sha值，调用redis的evalsha方法，并传入相应的keys和params，执行脚本。
   看一下代码：

       package com.hjc.learn.service.impl;
       
       import lombok.extern.slf4j.Slf4j;
       import org.apache.commons.lang3.StringUtils;
       import org.springframework.context.ApplicationListener;
       import org.springframework.context.event.ContextRefreshedEvent;
       import org.springframework.stereotype.Service;
       
       import javax.annotation.Resource;
       
       @Service
       @Slf4j
       public class RedBagBatchServiceImpl implements ApplicationListener<ContextRefreshedEvent> {
           // 红包雨lua脚本script load的sha1值
           private String redBagScriptSha1 = "";
           private static final String LUA_SCRIPT_PATH = "/lua_script/";
       
           @Resource
           private RedisUtil redisUtil;
       
           @Override
           public void onApplicationEvent(ContextRefreshedEvent event) {
               try {
                   log.info("初始化LUA脚本");
                   initRedBagScriptSha1();
                   log.info("成功初始化LUA脚本");
               } catch (LiveException e) {
                   logger.error("初始化lua脚本出错", e);
               }
           }
       
           /**
            * 读取抢红包Lua脚本
            */
           private String initRedBagScriptSha1() {
               if (StringUtils.isBlank(redBagScriptSha1)) {
                   synchronized (redBagScriptSha1) {
                       if (StringUtils.isBlank(redBagScriptSha1)) {
                           try {
                               // 读取资源文件内容，并scriptLoad到Redis，记录sha值
                               String scriptText = readResource(LUA_SCRIPT_PATH + "/RedBagBatchGrab.lua");
                               redBagScriptSha1 = redisUtil.scriptLoad(scriptText);
                           } catch (Exception e) {
                               logger.error("初始化LUA脚本出错 - " + e.getMessage(), e);
                               throw new RunTimeException("初始化LUA脚本出错 - " + e.getMessage());
                           }
                       }
                   }
               }
               return grabScriptSha1;
           }
       
           /**
            * 抢红包的方法
            */
           @Override
           public BigDecimal grabRedBag(Long userId, Long redBagId) {
       
               // 判断用户是否在黑名单、红包雨时间是否已失效等业务逻辑的判断
               // ..............
       
               // 抢红包lua脚本使用keys，需要与脚本中顺序保持一致
               List<String> luaKey = new ArrayList<>();
               luaKey.add(receiveLimitKey); // KEYS[1]
               luaKey.add(redBagBatchKey); // KEYS[2]
               luaKey.add(redBagUserKey); // KEYS[3]
       
               // 抢红包lua脚本使用args，需要与脚本中顺序保持一致
               List<String> luaArgs = new ArrayList<>();
               luaArgs.add(userId.toString());  // ARGV[1]
       
               Object luaResult = redisUtil.evalsha(this.redBagScriptSha1, luaKey, luaArgs);
       
               // 没抢到返回0
               if (luaResult == null || new BigDecimal(luaResult.toString()).compareTo(BigDecimal.ZERO) == 0) {
                   return BigDecimal.ZERO;
               }
       
               // 抢到，记日志并返回结果
               BigDecimal result = new BigDecimal(luaResult.toString());
               return result;
           }
       }
   