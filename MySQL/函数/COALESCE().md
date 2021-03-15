### 函数作用

用于进行空值处理

### 参数格式

```
COALESCE ( expression,value1,value2……,valuen) 
COALESCE()函数的第一个参数expression为待检测的表达式，而其后的参数个数不定。
COALESCE()函数将会返回包括expression在内的所有参数中的第一个非空表达式。

如果expression不为空值则返回expression；否则判断value1是否是空值，

如果value1不为空值则返回value1；否则判断value2是否是空值，

如果value2不为空值则返回value2；……以此类推，
如果所有的表达式都为空值，则返回NULL。 
```

### 案例

我们将使用COALESCE()函数完成下面的功能，返回人员的“重要日期”：

如果出生日期不为空则将出生日期做为“重要日期”，如果出生日期为空则判断注册日期是否为空，如果注册日期不为空则将注册日期做为“重要日期”，如果注册日期也为空则将“2008年8月8日”做为“重要日期”。实现此功能的SQL语句如下： 

#### MYSQL、MSSQLServer、DB2:

```
SELECT FName,FBirthDay,FRegDay, 
COALESCE(FBirthDay,FRegDay,'2008-08-08')  AS ImportDay  
FROM T_Person 

SELECT
	`NAME`,
	create_at,
	update_at,
	COALESCE (`create_at`,`update_at`,'2008-08-08') AS `import_day` 
FROM
	tb_index_main;
```

#### Oracle

```
SELECT FBirthDay,FRegDay,  
COALESCE(FBirthDay,FRegDay,TO_DATE('2008-08-08', 'YYYY-MM-DD HH24:MI:SS'))  
AS ImportDay  
FROM T_Person 
```

COALESCE()函数可以用来完成几乎所有的空值处理，不过在很多数据库系统中都提供了它的简化版，这些简化版中只接受两个变量，其参数格式如下： 
**MYSQL:** 
 IFNULL(expression,value) 
**MSSQLServer:** 
 ISNULL(expression,value) 
**Oracle:** 
 NVL(expression,value) 

这几个函数的功能和COALESCE(expression,value)是等价的。

比如SQL语句用于返回人员的“重要日期”，如果出生日期不为空则将出生日期做为“重要日期”，如果出生日期为空则返回注册日期的值：

```sql
MYSQL: 
SELECT FBirthDay,FRegDay,  
IFNULL(FBirthDay,FRegDay)  AS ImportDay  
FROM T_Person 

MSSQLServer: 
SELECT FBirthDay,FRegDay,  
ISNULL(FBirthDay,FRegDay)  AS ImportDay  
FROM T_Person 

Oracle: 
SELECT FBirthDay,FRegDay,  
NVL(FBirthDay,FRegDay)  AS ImportDay  
FROM T_Person
```

