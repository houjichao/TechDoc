### 一、基础知识

#### （1）SQL LEFT JOIN 关键字

**LEFT JOIN 关键字会从左表（table_name1）那里返回所有的行，即使在右表（table_name2）中没有匹配的行**

 语法：

```
SELECT column_name(s)
FROM table_name1
LEFT JOIN table_name2 
ON table_name1.column_name=table_name2.column_name

SELECT a.name,a.task_id,b.task_name FROM tb_object a LEFT JOIN index_analyse_task b on a.task_id = b.task_id;

SELECT a.name,a.benchmarking_id,b.name FROM tb_object a LEFT JOIN object_benchmarking b on a.benchmarking_id = b.id;


show variables where Variable_name like 'collation%';
```

#### （2）SQL UNION 操作符

**UNION 操作符用于合并两个或多个 SELECT 语句的结果集。**

**请注意，UNION 内部的 SELECT 语句必须拥有相同数量的列。列也必须拥有相似的数据类型。同时，每条 SELECT 语句中的列的顺序必须相同。**

语法：

```
SELECT column_name(s) FROM table_name1
UNION
SELECT column_name(s) FROM table_name2
```



[blog](https://blog.csdn.net/myxzxd/article/details/107044068)

