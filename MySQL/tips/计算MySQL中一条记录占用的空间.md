### 计算MySQL中一条记录占用的空间

####  information_schema 数据库，TABLES 表说明

TABLE_SCHEMA : 数据库名

TABLE_NAME：表名

ENGINE：所使用的存储引擎

TABLES_ROWS：记录数

DATA_LENGTH：数据大小

INDEX_LENGTH：索引大小

其他字段请参考MySQL的手册，我们只需要了解这几个就足够了。

所以要知道一个表占用空间的大小，那就相当于是 数据大小 + 索引大小 即可。

#### 查询一个表中的记录数以及数据大小，索引大小

```
MySQL [information_schema]> select table_rows,index_length, data_length from tables where table_name =  "object_index_result" and  TABLE_SCHEMA = "snpt_idata";
+------------+--------------+-------------+
| table_rows | index_length | data_length |
+------------+--------------+-------------+
|      18599 |      5308416 |    12075008 |
+------------+--------------+-------------+

MySQL [information_schema]> select table_rows,concat(round((DATA_LENGTH+INDEX_LENGTH)/1024/1024,2),'MB') as data from tables where table_name =  "object_index_result" and  TABLE_SCHEMA = "snpt_idata";
+------------+---------+
| table_rows | data    |
+------------+---------+
|      18599 | 16.58MB |
+------------+---------+
```

从上可以估算出来18599条记录是16.58MB，那一条记录的大小就很容易估算了