### 在mybatis中#和$的主要区别是：

**#传入的参数在SQL中显示为字符串，$传入的参数在SqL中直接显示为传入的值.**

### 方式能够很大程度防止sql注入，$方式无法防止Sql注入；

1、传入的参数在SQL中显示不同

#传入的参数在SQL中显示为字符串（当成一个字符串），会对自动传入的数据加一个双引号。

例：使用以下SQL

```
select id,name,age from student where id =#{id}
```

当我们传递的参数id为 "1" 时，上述 sql 的解析为：

```
select id,name,age from student where id ="1"
```

$传入的参数在SqL中直接显示为传入的值

例：使用以下SQL

```
select id,name,age from student where id =${id}
```

当我们传递的参数id为 "1" 时，上述 sql 的解析为：

```
select id,name,age from student where id =1
```

2、#可以防止SQL注入的风险（语句的拼接）；但$无法防止Sql注入。

3、$方式一般用于传入数据库对象，例如传入表名。

4、大多数情况下还是经常使用#，一般能用#的就别用$；但有些情况下必须使用$，例：MyBatis排序时使用order by 动态参数时需要注意，用$而不是#。