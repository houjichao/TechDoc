## FORMAT() 函数

FORMAT 函数用于对字段的显示进行格式化。

### SQL FORMAT() 语法

```
SELECT FORMAT(column_name,format) FROM table_name
```

| 参数        | 描述                   |
| :---------- | :--------------------- |
| column_name | 必需。要格式化的字段。 |
| format      | 必需。规定格式。       |

```
SELECT object_id, DATE_FORMAT(Now(),'%Y-%m-%d') as PerDate from index_his_value LIMIT 1;
```

