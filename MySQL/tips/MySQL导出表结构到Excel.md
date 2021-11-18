```
SELECT
COLUMN_NAME 字段标识,
COLUMN_COMMENT 字段中文说明,
COLUMN_TYPE 数据类型,
IS_NULLABLE 是否允许空值
FROM
INFORMATION_SCHEMA.COLUMNS
where
-- mysql为数据库名称，到时候只需要修改成你要导出表结构的数据库即可
table_schema ='snpt_idata'
AND
-- table_name为表名，到时候换成你要导出的表的名称
-- 如果不写的话，默认会查询出所有表中的数据，这样可能就分不清到底哪些字段是哪张表中的了
table_name = 'exponent_calc_model'
```

