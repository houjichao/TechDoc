#### 1、insert ignore 语法

insert ignore into table_name values…

使用insert ignore语法插入数据时，如果发生主键或者唯一键冲突，则忽略这条插入的数据。

满足以下条件之一：

- 主键重复
- 唯一键重复