### 问题描述：

MySQL查询语句优化问题

这里再次说明一下问题：

```
SELECT a.`name` FROM t_prov_city_area_street a WHERE a.id = 24818;

SELECT c.`name` FROM t_prov_city_area_street c WHERE c.`code` = 4209;

SELECT p.`name` FROM t_prov_city_area_street p WHERE p.`code` = 42;
```


将这三个语句合成一个获得的结果就是a.`name`， c.`name`， p.`name`

解决方法是使用左连接（LEFT JOIN），做两次左连接就好了，我现在知道地区的id，想要获取省、市、地区的信息，省、市、地区的关系为：

省.code = 市.parentId
市.code = 地区.parentId
实现上面三条语句的代码：

```
SELECT
	t. NAME,
	t1. NAME,
	t2. NAME
FROM
	t_prov_city_area_street t
LEFT JOIN t_prov_city_area_street t1 ON t1.`code` = t.parentId
LEFT JOIN t_prov_city_area_street t2 ON t2.`code` = t1.parentId
WHERE
	t.id = 24818;
```

