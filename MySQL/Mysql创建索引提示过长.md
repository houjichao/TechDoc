mysql创建数据库中具体某一张表索引的时候，提示错误信息：

```
Error
1071 - Specified key was too long; max key length is 3072 bytes
```

问题：索引过长，最大值为3072字节，你创建的索引长度大于3072字节

解决方式：将数据表中字段的长度缩小即可

备注：索引长度计算说明：

不同的字符集，一个字符占用的字节数不同。【可通过命令 show variables like 'character_set_database' 查询数据库的字符集】

    latin1编码的，一个字符占用1个字节，
    
    gbk编码的，一个字符占用2个字节，
    
    utf8编码的，一个字符占用3个字节。
    
    utf8mb4编码的， 一个字符占4个字节

即当你选用的字符集是utf8mb4，并且字段长度为1000时，则1000*4=4000，则大于3072，会提示太长

此长度只准对数据库字段类型为varchar的

**MySQL** **5.6文档内容如下**

 

 

By default, the index key prefix length limit is 767 bytes. See Section 13.1.13, “CREATE INDEX Syntax”. For example, you might hit this limit with a column prefix index of more than 255 characters on a TEXT or VARCHAR column, assuming a utf8mb3 character set and the maximum of 3 bytes for each character. When the innodb_large_prefix configuration option is enabled, the index key prefix length limit is raised to 3072 bytes for InnoDB tables that use DYNAMIC or COMPRESSED row format.

 

Attempting to use an index key prefix length that exceeds the limit returns an error. To avoid such errors in replication configurations, avoid enablinginnodb_large_prefix on the master if it cannot also be enabled on slaves.

The limits that apply to index key prefixes also apply to full-column index keys.

 

 

**MySQL** **5.7文档内容如下**：

 

If innodb_large_prefix is enabled (the default), the index key prefix limit is 3072 bytes for InnoDB tables that use DYNAMIC or COMPRESSED row format. If innodb_large_prefix is disabled, the index key prefix limit is 767 bytes for tables of any row format.

innodb_large_prefix is deprecated and will be removed in a future release. innodb_large_prefix was introduced in MySQL 5.5 to disable large index key prefixes for compatibility with earlier versions of InnoDB that do not support large index key prefixes.

The index key prefix length limit is 767 bytes for InnoDB tables that use the REDUNDANT or COMPACT row format. For example, you might hit this limit with a column prefix index of more than 255 characters on a TEXT or VARCHAR column, assuming a utf8mb3 character set and the maximum of 3 bytes for each character.

Attempting to use an index key prefix length that exceeds the limit returns an error. To avoid such errors in replication configurations, avoid enablinginnodb_large_prefix on the master if it cannot also be enabled on slaves.

The limits that apply to index key prefixes also apply to full-column index keys.

如果启用了系统变量innodb_large_prefix（默认启用，注意实验版本为MySQL 5.6.41,默认是关闭的，MySQL 5.7默认开启），则对于使用DYNAMIC或COMPRESSED行格式的InnoDB表，索引键前缀限制为3072字节。如果禁用innodb_large_prefix，则对于任何行格式的表，索引键前缀限制为767字节。

 

innodb_large_prefix将在以后的版本中删除、弃用。在MySQL 5.5中引入了innodb_large_prefix，用来禁用大型前缀索引，以便与不支持大索引键前缀的早期版本的InnoDB兼容。

对于使用REDUNDANT或COMPACT行格式的InnoDB表，索引键前缀长度限制为767字节。例如，您可能会在TEXT或VARCHAR列上使用超过255个字符的列前缀索引达到此限制，假设为utf8mb3字符集，并且每个字符最多包含3个字节。

 

尝试使用超出限制的索引键前缀长度会返回错误。要避免复制配置中出现此类错误，请避免在主服务器上启用enableinnodb_large_prefix（如果无法在从服务器上启用）。



适用于索引键前缀的限制也适用于全列索引键。

注意：上面是767个字节，而不是字符，具体到字符数量，这就跟字符集有关。GBK是双字节的，UTF-8是三字节的



**解决方案：**

 **1：启用系统变量**innodb_large_prefix

注意：光有这个系统变量开启是不够的。必须满足下面几个条件：

  1： 系统变量innodb_large_prefix为ON

  2： 系统变量innodb_file_format为Barracuda

  3： ROW_FORMAT为DYNAMIC或COMPRESSED 

如下测试所示：

```
mysql> show variables like '%innodb_large_prefix%';
+---------------------+-------+
| Variable_name       | Value |
+---------------------+-------+
| innodb_large_prefix | OFF   |
+---------------------+-------+
1 row in set (0.00 sec)
 
mysql> set global innodb_large_prefix=on;
Query OK, 0 rows affected (0.00 sec)
 
mysql> ALTER TABLE TEST MODIFY CODE_VALUE1 VARCHAR(350);
ERROR 1709 (HY000): Index column size too large. The maximum column size is 767 bytes.
mysql> 
mysql> show variables like '%innodb_file_format%';
+--------------------------+-----------+
| Variable_name            | Value     |
+--------------------------+-----------+
| innodb_file_format       | Antelope  |
| innodb_file_format_check | ON        |
| innodb_file_format_max   | Barracuda |
+--------------------------+-----------+
3 rows in set (0.01 sec)
 
mysql> set global innodb_file_format=Barracuda;
Query OK, 0 rows affected (0.00 sec)
 
mysql> ALTER TABLE TEST MODIFY CODE_VALUE1 VARCHAR(350);
ERROR 1709 (HY000): Index column size too large. The maximum column size is 767 bytes.
mysql> 
 
mysql> 
mysql> show table status from MyDB where name='TEST'\G;
*************************** 1. row ***************************
           Name: TEST
         Engine: InnoDB
        Version: 10
     Row_format: Compact
           Rows: 0
 Avg_row_length: 0
    Data_length: 16384
Max_data_length: 0
   Index_length: 16384
      Data_free: 0
 Auto_increment: NULL
    Create_time: 2018-09-20 13:53:49
    Update_time: NULL
     Check_time: NULL
      Collation: utf8_general_ci
       Checksum: NULL
 Create_options: 
        Comment: 
 
mysql>  ALTER TABLE TEST ROW_FORMAT=DYNAMIC;
Query OK, 0 rows affected (0.05 sec)
Records: 0  Duplicates: 0  Warnings: 0
 
mysql> show table status from MyDB where name='TEST'\G;
*************************** 1. row ***************************
           Name: TEST
         Engine: InnoDB
        Version: 10
     Row_format: Dynamic
           Rows: 0
 Avg_row_length: 0
    Data_length: 16384
Max_data_length: 0
   Index_length: 16384
      Data_free: 0
 Auto_increment: NULL
    Create_time: 2018-09-20 14:04:05
    Update_time: NULL
     Check_time: NULL
      Collation: utf8_general_ci
       Checksum: NULL
 Create_options: row_format=DYNAMIC
        Comment: 
1 row in set (0.00 sec)
 
ERROR: 
No query specified
 
mysql> ALTER TABLE TEST MODIFY CODE_VALUE1 VARCHAR(350);
Query OK, 0 rows affected (0.02 sec)
Records: 0  Duplicates: 0  Warnings: 0
```

[![clip_image001](https://img2018.cnblogs.com/blog/73542/201809/73542-20180920144505497-1863903327.png)](https://img2018.cnblogs.com/blog/73542/201809/73542-20180920144501886-864899266.png)

**2：使用前缀索引解决这个问题** 

之所以要限制索引键值的大小，是因为性能问题，而前缀索引能很好的解决这个问题。不需要修改任何系统变量。

```
mysql> show index from TEST;
..................................
 
mysql> ALTER TABLE TEST DROP INDEX IDX_GEN_CODE;
Query OK, 0 rows affected (0.00 sec)
Records: 0  Duplicates: 0  Warnings: 0
 
mysql> CREATE IDX_GEN_CODE TEST ON TEST (CODE_NAME, CODE_VALUE1(12));
Query OK, 0 rows affected (0.01 sec)
Records: 0  Duplicates: 0  Warnings: 0
 
mysql> ALTER TABLE TEST MODIFY CODE_VALUE1 VARCHAR(350);
Query OK, 1064 rows affected (0.08 sec)
Records: 1064  Duplicates: 0  Warnings: 0
```

 