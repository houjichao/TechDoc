# 前言

explain（执行计划），使用explain关键字可以模拟优化器执行sql查询语句，从而知道MySQL是如何处理sql语句。

explain主要用于分析查询语句或表结构的性能瓶颈。

**mysql explain 的返回列：**

```
id , select_type , table , type ,possible_keys , key ,key_len , ref , rows ,Extra
```

**各列的含义：**

1. id：（子）表或（子）查询的执行顺序
2. select_type：（子）查询类型。
3. table：引用的表
4. type：索引类型
5. possible_keys： 可能使用哪个索引
6. key：实际使用的索引
7. key_len： 索引中使用的字节数
8. ref： 使用索引的列
9. rows：索引涉及的行数。
10. Extra： 额外信息。

# 一、id ： （子）表或（子）查询的执行顺序

id 是一组数字。

## 1.1、有4种情况：

1. **id相同** ：执行顺序由上到下；
2. **id不相同** ：如果是子查询，id的序号会递增。id值越大，优先级越高，越先被执行。
3. **id相同又不同** ： id数越大最先执行。
4. **id 为 null**： 最后执行

## 1.2、示例：

### 1.2.1、id相同（自上而下执行）

![在这里插入图片描述](https://img-blog.csdnimg.cn/20200407093106696.png)

下图的sql语句而言，执行顺序是`t1、t3、t2` 。

### 1.2.2、id不相同（id数越大最先执行）：

![在这里插入图片描述](https://img-blog.csdnimg.cn/20200407093118682.png)
执行顺序依次执行，即 `t3、t1、t2` 。

### 1.2.3、id相同又不同（id数越大最先执行）

![在这里插入图片描述](https://img-blog.csdnimg.cn/20200407093029464.png)

id不同的组，先执行id大的组；

id相同的组里面，从上到下执行。

所以执行顺序为 `t3->derived2(衍生表，也可以说临时表)->t2` 。

`<deriver2>` 就是 `(select t3.id from t3 where t3.other_column = '') s1` 。

# 二、select_type ：查询类型（6个）

查询类型 有 simple ， primary ，subquery （子查询），derived (衍生)， union，union_result。

主要是用于区别普通查询、联合查询、子查询等的复杂查询。

- `simple` ：简单的 select 查询，查询中不包含 子查询 或者 union。

- `primary` ：查询中若包含任何复杂的子查询，最外层查询则被标记为 primary 。

- `subquery` ：在 select 或 where 列表中的子查询。

- `derived （衍生）` ：在 from 列表中的子查询为 derived（衍生），MySQL会把结果放在临时表中。

- `union` ：在 union 有前后两个select sql 语句，其中 union 后面的 select 的sql 为 `union` ；

  如果 union 包含在 from 子句的子查询中，外层 select 将被标记为 derived。

- `union_result` ： 两个select执行union 后的结果。

## 2.1 、simple 简单查询

简单的select查询，查询中不包含子查询 或 union

## 2.2 、primary 复杂查询，最后被执行的SQL片段

查询中包含若干复杂的子查询，最外层的查询则被标记为 primary。
就是最后被执行的SQL片段。
可以理解为“鸡蛋壳”。

## 2.3、subquery （子查询）

select 或 where 列表中的子查询。

**select 中的子查询 ：**

```sql
select id, (select name from dic where dic.val=u.gender) name   #gender 中的 0,1 ，根据字典转换成汉字的男，女
from user u
```

**where 中的子查询 ：**

```sql
select * from  tb_emp e where exists (select * from tb_dept d where d.id=e.deptid );
```

## 2.4 、derived [dɪ’raɪvd] 衍生; 起源

在 from 列表中的子查询为 derived（衍生），MySQL会把结果放在临时表中。

## 2.5、union

在 union 有前后两个select sql 语句，其中 union 后面的 select 的sql 为 `union` ；

## 2.6、union_result

两个 select 执行 union 后的结果。
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200407093208834.png)

# 数据准备

tb_emp 表 ：

```sql
DROP TABLE IF EXISTS `tb_emp`;
CREATE TABLE `tb_emp` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(20) NOT NULL,
  `deptid` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_tb_emp_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `tb_emp`(name,deptid) VALUES ('jack', '1');
INSERT INTO `tb_emp`(name,deptid) VALUES ('tom', '1');
INSERT INTO `tb_emp`(name,deptid) VALUES ('tonny', '1');
INSERT INTO `tb_emp`(name,deptid) VALUES ('mary', '2');
INSERT INTO `tb_emp`(name,deptid) VALUES ('rose', '2');
INSERT INTO `tb_emp`(name,deptid) VALUES ('luffy', '3');
INSERT INTO `tb_emp`(name,deptid) VALUES ('outman', '4');

```

tb_dept 表：

```sql
DROP TABLE IF EXISTS `tb_dept`;
CREATE TABLE `tb_dept` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `deptname` varchar(20) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `tb_dept`(deptname) VALUES ('研发');
INSERT INTO `tb_dept`(deptname) VALUES ('测试');
INSERT INTO `tb_dept`(deptname) VALUES ('运维');
INSERT INTO `tb_dept`(deptname) VALUES ('经理');
```

# 三、type ： 索引类型 （7种）

索引种类：system 、 constant 、eq_ref 、 ref 、 range、 index 、 all

**从 最好 到 最差，依次是**

```
system > constant > eq_ref > ref > range > index > all
```

**注意：一般保证查询至少达到 range 级别，最好能达到 ref。**

## 3.1、system ：

表只有一行记录，这是const类型的特例，平时不会出现，这个可以忽略不计。

## 3.2、const ：

表示通过一次索引就找到了结果，常出现于primary key或unique索引。

因为只匹配一行数据，所以查询非常快。

将主键置于where条件中，MySQL就能将查询转换为一个常量。

```
EXPLAIN SELECT * FROM tb_emp where id = 1 ;
```

![在这里插入图片描述](https://img-blog.csdnimg.cn/2020040709331336.png)

id=1 可以只接确定一个具体的值。所以是const。

## 3.3、eq_ref

唯一性索引扫描，对于每个索引键，表中只有一条记录与之匹配。常见于主键或唯一索引扫描。

```
EXPLAIN SELECT * FROM tb_emp, tb_dept WHERE tb_dept.id = tb_emp.deptid and tb_emp.`name` = 'outman';
```

![在这里插入图片描述](https://img-blog.csdnimg.cn/20200407093334676.png)

注：经理只有一人，进行了tb_dept的主键扫描。

## 3.4、ref

非唯一性索引扫描，返回匹配某个单独值的所有行。

本质上也是一种索引访问，返回匹配某值（某条件）的多行值，属于查找和扫描的混合体。

由于是非唯一性索引扫描，所以对 tb_emp 表的 deptid 字段 创建索引：

```sql
create index idx_tb_emp_deptid on tb_emp(deptid);
//创建完索引后，为ref，否则为all
EXPLAIN SELECT * FROM tb_emp where deptid  = 2;
```

![在这里插入图片描述](https://img-blog.csdnimg.cn/20200407093356599.png)

## 3.5、range

range 使用索引范围查询。通过索引字段范围获取表中部分数据记录。

在 where 语句中使用 `between、in()、is null、= 、 !=、 >、 >=、 <、<=、 !=` 。

**复合索引中，range 会导致后面列的索引失效**

复合索引 `( a , b , c)` ，一般情况下，支持`a=?` 、`a,b` 、`a,b,c` 3种索引。
如果 a 使用的 range ，则 b ,c 列 索引失效。
如果 b 使用的 range ， 则 c 列 索引失效。 --- 最左匹配原则

**range 比 index索引 要好**

因为 range 开始于索引的某一点，而结束于索引的另一点，不用扫描全部索引。

```
EXPLAIN SELECT * FROM tb_emp where deptid  > 2;
```

![在这里插入图片描述](https://img-blog.csdnimg.cn/20200407093416174.png)

虽然我们为 deptid 字段创建了索引并在 where 中使用了 between 等，但是下图的示例中 type 仍为 all 。

```
EXPLAIN SELECT * FROM tb_emp where deptid  BETWEEN 1 AND 3 ;
```

![在这里插入图片描述](https://img-blog.csdnimg.cn/20200407093437244.png)

```
EXPLAIN SELECT * FROM tb_emp where id  BETWEEN 1 AND 3 ;
```

![在这里插入图片描述](https://img-blog.csdnimg.cn/20200407093445373.png)

对比两图，可以看到使用 deptid 和 id 进行操作，

其中，type 的值一个是 all， 也就是进行了全表扫描，

一个是 range 进行了指定索引范围值检索。

可能原因deptid并不是唯一索引。

## 3.6、index （全索引扫描）

`Full Index Scan` 全索引扫描。

**index 与 all 的区别 ？**

all 和 index 都是读全表。

index 是遍历 **索引树**， all 遍历的是 **数据文件**。当然是因为索引文件通常比数据文件小。

```
EXPLAIN SELECT deptid FROM tb_emp;
```

![在这里插入图片描述](https://img-blog.csdnimg.cn/20200407093515211.png)

## 3.7、all （全表扫描）

表示 查询是全表扫描，性能是最差的。

# 四、possible_keys ： 可能使用到的索引

显示可以应用到这张表中的索引（就是索引名称），一个或多个；
查询涉及到的字段上若存在索引，则该索引将被列出，但不一定被实际使用。

# 五、key ： 实际使用的索引

查询中若使用了覆盖索引，则该索引仅出现在key列表中。

**示例：**

1）possible_keys为 NULL，则没有使用索引

```
EXPLAIN SELECT id, deptid FROM tb_emp;
```

![在这里插入图片描述](https://img-blog.csdnimg.cn/20200407093527519.png)
但是 `key=idx_deptid` 表示在实际查询的过程中进行了索引的全扫描。

2）为 name 字段创建索引：

```sql
create index idx_name on tb_emp(name);
```

3） 执行查询

```sql
explain select * from tb_emp where deptid =2;
explain select * from tb_emp where deptid =2 and name = 'rose';
```

![在这里插入图片描述](https://img-blog.csdnimg.cn/20200407093544396.png)

![在这里插入图片描述](https://img-blog.csdnimg.cn/2020040709355392.png)

# 六、key_len：使用索引的字节数

表示查询优化器使用索引的字节数。

根据 key_len 可以评估 组合索引 是否完全被使用，或只有最左的部分字段被使用到 。

在不损失精确性的情况下，长度越短越好。

计算方式 是 根据使用到索引的字段类型而对应的长度累加起来。

## 6.1 、key_len 的计算规则：

- **字符串**
  - char(n) ： n 字节长度 。
  - varchar(n) ： 如果是 utf8 编码, 则是（ 3 n + 2）个字节；如果是 utf8mb4 编码, 则是 （4 n + 2）个字节。
- **数值类型：**
  - tinyint ：1字节
  - smallint ： 2字节
  - mediumint ： 3字节
  - int ：4字节
  - bigint ： 8字节
- **时间类型**
  - date ：3字节
  - timestamp ： 4字节
  - datetime ： 8字节

**是否为 NULL 属性：** 如果一个字段 可以为 null ，则在上面计算的结果上再加1个字节； 如果一个字段是 not null 的， 则不需要。

也就是说，如果字段为null，则长度要额外再加 1 。

**创建表和数据：**

```sql
create table `user_info` (
  `id` bigint(20) not null auto_increment,
  `name` varchar(50) not null default '',
  `age` int(11) default null,
  primary key (`id`),
  key `name_index` (`name`)
) engine=innodb auto_increment=11 default charset=utf8 comment='用户信息';
  
create table `order_info` (
  `id` bigint(20) not null auto_increment,
  `user_id` bigint(20) default null,
  `product_name` varchar(50) not null default '',
  `productor` varchar(30) default null,
  primary key (`id`),
  key `user_product_detail_index` (`user_id`,`product_name`,`productor`)
) engine=innodb auto_increment=10 default charset=utf8 comment='订单信息';
 
insert into user_info (name, age) values ('xys', 20);
insert into user_info (name, age) values ('a', 21);
insert into user_info (name, age) values ('b', 23);
insert into user_info (name, age) values ('c', 50);
insert into user_info (name, age) values ('d', 15);
insert into user_info (name, age) values ('e', 20);
insert into user_info (name, age) values ('f', 21);
insert into user_info (name, age) values ('g', 23);
insert into user_info (name, age) values ('h', 50);
insert into user_info (name, age) values ('i', 15);

 
insert into order_info (user_id, product_name, productor) values (1, 'p1', 'WHH');
insert into order_info (user_id, product_name, productor) values (1, 'p2', 'WL');
insert into order_info (user_id, product_name, productor) values (1, 'p1', 'DX');
insert into order_info (user_id, product_name, productor) values (2, 'p1', 'WHH');
insert into order_info (user_id, product_name, productor) values (2, 'p5', 'WL');
insert into order_info (user_id, product_name, productor) values (3, 'p3', 'MA');
insert into order_info (user_id, product_name, productor) values (4, 'p1', 'WHH');
insert into order_info (user_id, product_name, productor) values (6, 'p1', 'WHH');
insert into order_info (user_id, product_name, productor) values (9, 'p8', 'TE');
```

**示例：**

![在这里插入图片描述](https://img-blog.csdnimg.cn/2020041315483010.png)

上在是从 `order_info` 表中查询指定的内容，而从建表语句中知道， `order_info` 表中有一个`联合索引`：

```sql
key `user_product_detail_index` (`user_id`,`product_name`,`productor`)
1
```

查询语句 `where user_id < 3 AND product_name = 'p1' AND productor = 'WHH'` ，因为先进行 user_id 的范围查询， 而根据 `最左前缀匹配` 原则， 当遇到范围查询时， 就停止索引的匹配， 因此实际上我们使用到的索引的字段只有 `user_id`， 因此在 `explain` 中，显示的 key_len 为 9 。

因为 user_id 字段是 bigint ，占用 8 字节， 而 null 属性占用一个字节，因此总共是 9 个字节。

如果 我们将 user_id 字段改为 `bigint(20) not null default '0'` ， 则 key_length 应该是8。

在 `user_product_detail_index ( user_id , product_name , productor )` 联合索引的中，只用到 user_id 字段的索引， 因此效率不算高。

**示例2：**

![在这里插入图片描述](https://img-blog.csdnimg.cn/20200413160049455.png)

这次的查询中，我们没有使用到范围查询， key_len 的值为 161。这是怎么计算出来呢?

查询条件 `WHERE user_id = 1 AND product_name = 'p1'` 中 ，
使用到了 `user_product_detail_index ( user_id , product_name , productor )` 联合索引中的前两个字段，

因此， `keyLen(user_id) + keyLen(product_name)` = `9 +（ 50 * 3 + 2） = 161`。（ varchar(n) ： 因为是 utf8 编码， 则是 (3 n + 2) 个字节）

# 七、ref ：使用索引的列

使用索引的列。

- 如果是 常数，则显示 const，
- 如果显示是 列名，则表示 该列用于查询索引列上的值 。

**示例：**

```
explain select * from tb_emp,tb_dept where tb_emp.deptid =  tb_dept.id and tb_emp.name = 'rose';
```

![在这里插入图片描述](https://img-blog.csdnimg.cn/20200407093619132.png)
**注：** world 表示 数据库。

**说明：**

注：由于id相同，因此从上到下执行：

1. tb_emp 表为非唯一性索引扫描，
   实际使用的索引列为 idx_name ，由于 `tb_emp.name='rose'` 为一个常量，所以 ref=const 。
2. tb_dept 为唯一索引扫描，
   从 sql 语句可以看出，实际使用了`primary` 主键索引，`ref=world.tb_emp.deptid` 表示关联 world 数据库中 tb_emp 表的 deptid 字段。

# 八、rows（优化器扫描表的行数）

MySQL 查询优化器根据统计信息 ，估算 SQL 要查找到结果集需要扫描读取的数据行数。

这个值非常直观显示 SQL 的效率好坏, 原则上 rows 越少越好。

**注意**：这个不是结果集里的行数。

# 九、Extra （额外信息）

在其他列中没有显示，但是十分重要的额外信息。

## 9.1、Using filesort（文件排序）

Using filesort 表明 mysql 会对数据使用一个外部的索引排序，而不是按照表内的索引顺序进行读取。

mysql中无法利用索引完成的排序操作称为“文件排序”。

出现 Using filesort 就非常危险了，在数据量非常大的时候几乎“九死一生”。出现 Using filesort 尽快优化 sql 语句。

**示例：**

1）**deptname字段未建索引的情况：**

```
explain select * from tb_dept order by deptname;
```

![在这里插入图片描述](https://img-blog.csdnimg.cn/2020040709370520.png)

2）**为deptname字段创建索引后：**

```sql
create index idx_deptname on tb_dept(deptname);
```

3） 执行查询

```sql
explain select * from tb_dept order by deptname;
```

![在这里插入图片描述](https://img-blog.csdnimg.cn/20200407093716416.png)

## 9.2、Using index（索引）

select 操作中使用了 **覆盖索引**，避免访问表的全表数据，说明 效率不错。

如果同时出现了 Using where ，表明索引被用来执行索引键值的查找。（`where deptid=1`）

如果没有同时出现 Using where ，表明索引用来读取数据而非执行查找动作。 （没有where ，`select c1 , c2 from table` ，idx_t_c1_c2）

> 1、索引的功能 ： 读取数据 、键值查找 、排序
> 2、**覆盖索引的理解**： select 的数据列 只用从索引中 就能取到 ，不必读取数据行，mysql 利用索引返回 select 列表中的字段，而不必根据索引 再读取 数据文件。 换句话说 查询列 要被所建的 索引覆盖。
> 如果要使用 覆盖索引，一定要注意select 列中只取出需要的列，不可 `select *`。
> 如果将所有字段一起做成索引，索引文件过大，导致查询性能下降。

**示例：**

1）**删除 tb_emp 现有的全部的索引**

2）创建复合索引：

```sql
create index idx_name_id on tb_emp(name,deptid);
```

3）查询：

```sql
explain select name from tb_emp where deptid =1;
```

![在这里插入图片描述](https://img-blog.csdnimg.cn/20200407093642857.png)
4）说明

从这里给出 **覆盖索引的定义**：select的数据列只从 **索引中** 就能取得数据，不必读取数据行。

**通过上面的例子理解：**

创建了（name，deptid）的复合索引，查询的时候也使用复合索引或部分，这就形成了覆盖索引。

简记：查询使用复合索引，并且查询的列就是索引列，不能多，也不能少，个数必须对应。

使用优先级 `Using index > Using filesort（九死一生）> Using temporary（十死无生）`。也就说出现后面两项表明sql语句是非常烂的，急需优化！！！

## 9.3、Using temporary （临时表）

使用了临时表保存中间结果，常见于排序 `order by` 和 分组查询 `group by` 。非常危险，“十死无生”，急需优化。

**示例：**

1）将 tb_emp 中 name 的索引先删除。

2）执行查询，非常烂，Using filesort 和 Using temporary，“十死无生”。

```sql
explain select * from tb_emp group by name;
```

![在这里插入图片描述](https://img-blog.csdnimg.cn/20200407093829690.png)

3）**为name字段创建索引：**

```sql
create index idx_name on tb_emp(name);
```

![在这里插入图片描述](https://img-blog.csdnimg.cn/20200407093846936.png)

## 9.4、Using where

表明使用了where过滤

## 9.5、Using join buffer

表明使用了连接缓存，比如说在查询的时候，多表join的次数非常多，那么将配置文件中的缓冲区的 join buffer 调大一些。

## 9.6、 impossible where

where 子句的值总是 false，不能用来获取任何元组

```sql
select * from t_user where id = '1' and id = '2'
```

## 9.7、 select tables optimized away

在没有 group by 子句的情况下，基于索引优化 `min / max` 操作或者对于MyISAM存储引擎优化 `count(*)` 操作，不必等到执行阶段再进行计算，查询执行计划生成的阶段即完成优化。

## 9.8、 distinct

优化 distinct 操作，在找到第一匹配的元组后即停止找同样值的动作

# 十、实战

![在这里插入图片描述](https://img-blog.csdn.net/20180521091813929)

执行顺序按照id的顺序：4 -> 3 -> 2 -> 1 -> null

**执行顺序1**：id=4，select_type 是 union，table 是 t2， 是union 后面的sql语句，即 `【select name,id from t2】`

**执行顺序2**：id=3，select_type 是 derived， 表明是 from 后面的子查询，table 是 t1 ，说明是 `【select id,name from t1 where other_column='' 】`

**执行顺序3**：id=2， select_type 是 subquery，表明是select 或where 的子查询， table 是 t3 ，说明是 `【select id from t3】`

**执行顺序4**：id=1，select_type 为 primary，表示查询为最外层、最后的查询 ，table 是 `<derived3>` ，表示 from 后跟紧跟着的是 衍生表， `<derived3>` 中的3代表该查询衍生自第三个 select 查询。 此子查询union 前的SQL，即 `【select d1.name ….. d1】`

**执行顺序5**：id=null，是最后执行， 代表从union的临时表中读取行的阶段。 table列为`<union1,4>` ，表示用第一个（**执行顺序1** 的结果）和 第四个select（**执行顺序4** 的结果）的结果进行union操作。【两个select执行union 后的结果】

# 十一、总结

| 序号 | 信息          | 描述                                                         |
| ---- | ------------- | ------------------------------------------------------------ |
| 1    | id            | （子）表或（子）查询的执行顺序。 是一组数字，表示查询中执行select子句或操作表的顺序。 **两种情况：** id相同，执行顺序从上往下 。 id不同，id值越大，优先级越高，越先执行。 id 为 null ，最后执行。 |
| 2    | select_type   | （子）查询类型，主要用于区别普通查询，联合查询，子查询等的复杂查询 。 1、simple ——简单的select查询，查询中不包含子查询或者 union 。 2、primary ——查询中如果包含任何复杂的子查询，最外层的查询被标记为 primary 。 3、subquery——在select或where列表中包含子查询。 4、derived （衍生） ——在from列表中包含的子查询被标记为derived。MySQL会递归执行这些子查询，把结果放到临时表中 。 5、union——如果第二个select出现在union之后，则被标记为union，如果union包含在from子句的子查询中，外层select被标记为derived 。 6、`union_result` ：两个select执行union 后的结果 。 |
| 3    | table         | 输出的行所引用的表                                           |
| 4    | type          | 索引类型，显示查询使用了哪种类型，按照从好到坏的排序。 1、system：表中仅有一行（=系统表）这是const联结类型的一个特例。 2、const：表示通过索引一次就找到。const用于primary key、unique索引。因为只匹配一行数据，所以如果将主键置于where列表中，mysql能将该查询转换为一个常量。 3、eq_ref：唯一性索引扫描，对于每个索引键，**表中只有一条记录与之匹配**。常见于唯一索引或者主键扫描。 4、ref： 非唯一性索引扫描，返回匹配某个单独值的所有行，本质上也是一种索引访问，它返回所有匹配某个单独值的行，可能会找多个符合条件的行，属于查找和扫描的混合体。 5、range： 检索给定范围的行，使用一个索引来选择行。key列显示使用哪个索引，**一般就是where语句中出现了between、in、 <、=<、> 、>= 等范围的查询**。 这种范围扫描索引扫描比全表扫描要好，因为它开始于索引的某一个点，而结束另一个点，不用全表扫描。 6、index： index 与all区别为index类型只遍历索引树。通常比all快，因为索引文件比数据文件小很多。 7、all：遍历全表以找到匹配的行。（all和index都是全表扫描，但是index是从索引中读取，而all是从硬盘中读的）。 **注意：一般保证查询至少达到range级别，最好能达到ref。** |
| 5    | possible_keys | 可能使用哪个索引在该表中找到行。                             |
| 6    | key           | 实际使用的索引。 如果没有选择索引，键是NULL。 查询中如果使用覆盖索引，则该索引和查询的select字段重叠。 |
| 7    | key_len       | 索引中使用的字节数。 该列计算查询中使用的索引的长度在不损失精度的情况下，长度越短越好。 如果键是NULL,则长度为NULL。 该字段显示为索引字段的最大可能长度，并非实际使用长度。 |
| 8    | ref           | 使用索引的列名、字段名。 如果有可能是一个常数，哪些列或常量被用于查询索引列上的值 |
| 9    | rows          | 找到所需的记录，所需要读取的行数                             |
| 10   | Extra         | 在其他列中没有显示，但是十分重要的额外信息。 1、Using filesort：说明mysql会对数据适用一个外部的索引排序。而不是按照表内的索引顺序进行读取。MySQL中无法利用索引完成排序操作称为“文件排序” 2、Using temporary： 使用了临时表保存中间结果，mysql在查询结果排序时使用临时表。常见于排序order by和分组查询group by。 3、Using index： 表示相应的select操作用使用覆盖索引，避免访问了表的数据行。如果同时出现using where，表名索引被用来执行索引键值的查找；如果没有同时出现using where，表名索引用来读取数据而非执行查询动作。 4、Using where ：表明使用where过滤 5、using join buffer： 使用了连接缓存 6、impossible where： where子句的值总是false，不能用来获取任何元组 7、select tables optimized away：在没有group by子句的情况下，基于索引优化Min、max操作或者对于MyISAM存储引擎优化count（*），不必等到执行阶段再进行计算，查询执行计划生成的阶段即完成优化。 8、distinct：优化distinct操作，在找到第一匹配的元组后即停止找同样值的动作。 |