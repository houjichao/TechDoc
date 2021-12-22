有时候需要为字段创建索引时，但是字段太长，为整个字段创建索引的话，太浪费存储空间了，所以需要计算出字段区分度，选择合适的索引长度。

计算字段文本区分度的公式：

```
select  COUNT(DISTINCT left(column_name,length))/COUNT(*) from table_name
```

其中column_name是需要建立索引的字段，而length则是选择这个字段用来建立索引的长度。

公式的作用就是，选择出字段长度，去重求总，这时候就可以知道使用这个长度来建立索引，大概会有多少值，然后再把这个值除以总数，得到的值越接近1，则表示用这个长度来建立索引的区分度越大，自然就越适合。

测试表USER_ROLE的数据如下：

| ID   | USER_NAME | ROLE_ID |
| ---- | --------- | ------- |
| 1    | 用户211   | 1       |
| 2    | 用户221   | 2       |
| 3    | 用户311   | 3       |


比如要对字段USER_NAME建立索引，代入上述公式

先选择这个字段的1个长度来建立索引，看下区分度：

```
select  COUNT(DISTINCT left(USER_NAME,1))/COUNT(*) from USER_ROLE
```

区分度如下：

0.3333

再选择这个字段的3个长度来建立索引:

```
select  COUNT(DISTINCT left(USER_NAME,3))/COUNT(*) from USER_ROLE
```

看下区分度：

0.6667

再选择这个字段的4个长度来建立索引:

```
select  COUNT(DISTINCT left(USER_NAME,4))/COUNT(*) from USER_ROLE
```

看下区分度：

1

最后选择这个字段的5个长度来建立索引

```
select  COUNT(DISTINCT left(USER_NAME,5))/COUNT(*) from USER_ROLE
```


看下区分度：

1


可以发现长度4和长度5的区分度都是1，那自然选择占用空间小的方案了。

**总结**

要建立大字段的索引时，可以配合计算字段文本区分度的公式，选出合适的字段长度来建立索引。