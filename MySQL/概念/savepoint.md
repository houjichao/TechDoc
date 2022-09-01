Mysql默认是自动提交的，如果要开启使用事务，首先要关闭自动提交后START TRANSACTION 或者 BEGIN 来开始一个事务，使用ROLLBACK/COMMIT来结束一个事务。但即使如此，也并不是所有的操作都能被ROLLBACK，以下语句在执行后会导致回滚失效，比如DDL语句创建一个数据库，而且不止此，这样的语句包括以下这些等：

ALTER FUNCTION,ALTER PROCEDURE,ALTER TABLE,BEGIN,CREATE DATABASE,CREATE FUNCTION,CREATE INDEX,CREATE PROCEDURE,CREATE TABLE,DROP DATABASE,DROP FUNCTION,DROP INDEX,DROP PROCEDURE,DROP TABLE,LOAD MASTER DATA,LOCK TABLES,RENAME TABLE,SET AUTOCOMMIT=1,START TRANSACTION,TRUNCATE TABLE,UNLOCK TABLES，CREATE TABLE,CREATE DATABASE DROP DATABASE,TRUNCATE TABLE,ALTER FUNCTION,ALTER PROCEDURE,CREATE FUNCTION,CREATE PROCEDURE,DROP FUNCTION和DROP PROCEDURE...

这些语句(以及同义词)均隐含地结束一个事务，即在执行本语句前，它已经隐式进行了一个COMMIT。InnoDB中的CREATE TABLE语句被作为一个单一事务进行处理。所以ROLLBACK不会撤销用户在事务处理过程中操作的CREATE TABLE语句。另外上面的语句中包括START TRANSACTION，这即是说明事务不能被嵌套。事物嵌套会隐式进行COMMIT，即一个事务开始前即会把前面的事务默认进行提交。


我们可以使用mysql中的savepoint保存点来实现事务的部分回滚~

基本用法如下

```css
SAVEPOINT identifier
ROLLBACK [WORK] TO [SAVEPOINT] identifier
RELEASE SAVEPOINT identifier
```

1、使用 SAVEPOINT identifier 来创建一个名为identifier的回滚点

2、ROLLBACK TO identifier，回滚到指定名称的SAVEPOINT，这里是identifier

3、 使用 RELEASE SAVEPOINT identifier 来释放删除保存点identifier

4、如果当前事务具有相同名称的保存点，则将删除旧的保存点并设置一个新的保存点。

5、回滚到SAVEPOINT语句返回以下错误，则表示不存在具有指定名称的保存点：

```undefined
ERROR 1305 (42000): SAVEPOINT **** does not exist
```

6、如果执行START TRANSACTION，COMMIT和ROLLBACK语句，则将删除当前事务的所有保存点。

