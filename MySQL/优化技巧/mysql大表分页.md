### limit分页原理

当我们查询到最后几页时，查询的sql通常是：select * from table where column = xxx order by xxx limit 1000000,10

查询非常慢，但是我们查看前几页的时候，速度并不慢。这是因为limit的偏移量太大导致的。

Mysql使用limit的原理是（用上面的例子举例）：

1. mysql将查询出1000010条记录
2. 然后舍弃掉前面的1000000条记录
3. 返回剩下的10条记录



### 优化方法

```
1、尽量给出查询的大致范围
SELECT a1,a2,a3... FROM table WHERE id>=20000 LIMIT 10;

2、子查询法
explain SELECT * from  table where belongModule in(5,7) limit 800000,5;

explain SELECT * from  table t INNER JOIN (SELECT id from table where belongModule in(5,7) limit 800000,5)t1 on t.id = t1.id;
```

