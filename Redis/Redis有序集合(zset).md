## Redis 有序集合(sorted set)

Redis 有序集合和集合一样也是 string 类型元素的集合,且不允许重复的成员。

不同的是每个元素都会关联一个 double 类型的分数。redis 正是通过分数来为集合中的成员进行从小到大的排序。

有序集合的成员是唯一的,但分数(score)却可以重复。

集合是通过哈希表实现的，所以添加，删除，查找的复杂度都是 O(1)。 集合中最大的成员数为 2的32次方 - 1 (4294967295, 每个集合可存储40多亿个成员)。

**集合是通过哈希表实现的，所以添加，删除，查找的复杂度都是O(1)**其实不太准确。

其实在redis sorted sets里面当items内容大于64的时候同时使用了hash和skiplist两种设计实现。这也会为了排序和查找性能做的优化。所以如上可知： 

添加和删除都需要修改skiplist，所以复杂度为O(log(n))。 

但是如果仅仅是查找元素的话可以直接使用hash，其复杂度为O(1) 

其他的range操作复杂度一般为O(log(n))

当然如果是小于64的时候，因为是采用了ziplist的设计，其时间复杂度为O(n)



### 常用命令

#### 向有序集合添加一个或多个成员，或者更新已存在成员的分数

```
ZADD key score1 member1 [score2 member2]
127.0.0.1:6379> zadd houjichao 1 redis 1 mysql
(integer) 2
```

#### 获取有序集合的成员数

```
ZCARD key
127.0.0.1:6379> zcard houjichao
(integer) 2
```

#### 计算在有序集合中指定区间分数的成员数

```
ZCOUNT key min max
127.0.0.1:6379> zcount houjichao 0 10
(integer) 2
127.0.0.1:6379> zcount houjichao 0 1
(integer) 2
127.0.0.1:6379> zcount houjichao -1 0
(integer) 0
```

#### 有序集合中对指定成员的分数加上增量 increment

```
ZINCRBY key increment member
127.0.0.1:6379> zincrby houjichao 5 redis
"6"
```

#### 计算给定的一个或多个有序集的交集并将结果集存储在新的有序集合 destination 中

Redis Zinterstore 命令计算给定的一个或多个有序集的交集，其中给定 key 的数量必须以 numkeys 参数指定，并将该交集(结果集)储存到 destination 。

默认情况下，结果集中某个成员的分数值是所有给定集下该成员分数值之和。

```
ZINTERSTORE destination numkeys key [key ...]
127.0.0.1:6379> zadd houjichao1 1 redis 1 mysql 2 mongo
(integer) 3
127.0.0.1:6379> zinterstore houjichao2 2 houjichao houjichao1
(integer) 2
127.0.0.1:6379> zrange houjichao2 0 100
1) "mysql"
2) "redis"
127.0.0.1:6379> zrange houjichao2 0 100 withscores
1) "mysql"
2) "2"
3) "redis"
4) "7"
```

#### 在有序集合中计算指定字典区间内成员数量

```
ZLEXCOUNT key min max
127.0.0.1:6379> zlexcount houjichao - +
(integer) 2
127.0.0.1:6379> ZADD myzset 0 a 0 b 0 c 0 d 0 e 0 f 0 g
(integer) 7
127.0.0.1:6379> ZLEXCOUNT myzset - +
(integer) 7
127.0.0.1:6379> ZLEXCOUNT myzset [b [f
(integer) 5
```

#### 返回有序集合中指定成员的索引

```
ZRANK key member
127.0.0.1:6379> zrank myzset f
(integer) 5
```

#### 移除有序集合中的一个或多个成员

```
ZREM key member [member ...]
127.0.0.1:6379> zrem myzset g
(integer) 1
```

#### 通过索引区间返回有序集合指定区间内的成员

```
ZRANGE key start stop [WITHSCORES]
127.0.0.1:6379> zrange myzset 0 1 withscores
1) "a"
2) "0"
3) "b"
4) "0"
127.0.0.1:6379> zrange myzset 0 -1 withscores
 1) "a"
 2) "0"
 3) "b"
 4) "0"
 5) "c"
 6) "0"
 7) "d"
 8) "0"
 9) "e"
10) "0"
11) "f"
12) "0"
127.0.0.1:6379> zrange myzset 1 2 withscores
1) "b"
2) "0"
3) "c"
4) "0"
```

#### 返回有序集中，成员的分数值

```
ZSCORE key member
127.0.0.1:6379> zscore houjichao redis
"6"
```

#### 返回有序集中指定区间内的成员，通过索引，分数从高到低

```
ZREVRANGE key start stop [WITHSCORES]
127.0.0.1:6379> zrevrange houjichao2 0 -1 withscores
1) "oracle"
2) "10"
3) "redis"
4) "7"
5) "mysql"
6) "2"
```

#### 返回有序集合中指定成员的排名，有序集成员按分数值递减(从大到小)排序，分数越大序号越小

```
ZREVRANK key member
127.0.0.1:6379> zrevrank houjichao2 redis
(integer) 1
127.0.0.1:6379> zrevrank houjichao2 mysql
(integer) 2
127.0.0.1:6379> zrevrank houjichao2 oracle
(integer) 0
```

