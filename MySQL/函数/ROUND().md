## ROUND() 函数

ROUND 函数用于把数值字段舍入为指定的小数位数。

### SQL ROUND() 语法

```
SELECT ROUND(column_name,decimals) FROM table_name
```

| 参数        | 描述                         |
| :---------- | :--------------------------- |
| column_name | 必需。要舍入的字段。         |
| decimals    | 必需。规定要返回的小数位数。 |

```
select table_rows,concat(round((DATA_LENGTH+INDEX_LENGTH)/1024/1024,2),'MB') as data from tables where table_name =  "object_index_result" and  TABLE_SCHEMA = "snpt_idata";
```

在mysql中，round函数用于数据的四舍五入，它有两种形式：

1、round(x,d)  ，x指要处理的数，d是指保留几位小数

这里有个值得注意的地方是，d可以是负数，这时是指定小数点左边的d位整数位为0,同时小数位均为0；

2、round(x)  ,其实就是round(x,0),也就是默认d为0；

