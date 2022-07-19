### mysql出现which is not functionally dependent on columns in GROUP BY clause报错

# 问题

假设查询语句是下面这样：

```
SELECT
	 d_1, create_date
FROM
	table
WHERE
	id = 1 
GROUP BY
	create_date 
```

报错就是这样，从网上找的方法无非三种：

1. 为查找出的发生碰撞的字段加上any_value函数，于是就成了下面这种

```
SELECT
    any_value(d_1) create_date
FROM
   table
WHERE
   id = 1 
GROUP BY
   create_date 

```

什么叫发生碰撞？比如我这里以create_date 做聚合，查出来的d_1有三个值，分别是1、2、3，这就是碰撞，因为聚合之后某一列有了多个值。

2. 关闭ONLY_FULL_GROUP_BY模式。关于这个模式，是mysql提供的安全检查。 直接设置为一个新值就完事了

   ```
   SET GLOBAL sql_mode='STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';
   
   ```

   

注意：我在这里设置的值，是通过select @@sql_mode得到的结果，去掉ONLY_FULL_GROUP_BY得到的。以自己的配置为主，只要去掉ONLY_FULL_GROUP_BY就好（如果通过这种方法设置，重启mysql似乎就会失效，我没尝试过，不敢打包票）
3. 通过更改my.cnf实现。本质上和2是一样的，都是关闭ONLY_FULL_GROUP_BY模式。我是通过yum安装的mysql，所以直接编辑/etc/my.cnf，在文件的最后加上

  ```
  sql_mode=STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION
  ```

  然后通过

  ```
  ystemctl restart mysqld.service
  ```

  

重启数据库。

# 总结

总的来说，我个人感觉1是最好的，因为不需要更改系统配置，但是也有缺陷，就是每个你进行分组的语句，都要为查找出来的字段加上any_value()函数。如果没有那么多讲究，完全可以用2或者3的方法解决这个错误。



- 原因
  存在非聚合列 , 没有包含在 GROUP BY 子句中。

```
//按day分组后，得到新表的每一个列对应day有唯一数据
select id, max(hour) from biao  GROUP BY day;//会出错，因为同一天，会有多个id
select day, max(hour) from biao GROUP BY day;//对的
```