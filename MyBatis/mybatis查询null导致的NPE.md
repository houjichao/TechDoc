**背景：**
我们在写sql语句时，不推荐使用select *的，所以我们只需要查询出我们需要的字段值就可以了。但是，如果查询的某几个字段值都是null，我们使用list接收的话，那么list中的对象就是null，引起NPE问题。

```
    public List<String> getAllIndexMainId() {
        Example example = new Example(IndexSubDetail.class);
        example.selectProperties(IndexConstant.INDEX_MAIN_ID);
        List<IndexSubDetail> indexs = indexSubDetailMapper.selectByExample(example);
        return indexs.stream().map(IndexSubDetail::getIndexMainId).collect(Collectors.toList());
    }
```

当index_main_id字段有为空时，对象就是null

**分析：**
查看mybatis处理查询结果的源码，主要是将结果封装成对象
![在这里插入图片描述](https://image.dandelioncloud.cn/images/20220321/92baae89a8e24913adf7a77655e97d1d.png)

getRowValue就是把每行的结果封装成对象返回。
其中有一个方法是applyAutomaticMappings()自动化属性映射，源码如下
![在这里插入图片描述](https://image.dandelioncloud.cn/images/20220321/30e4a8cf6040406c9eb0444425b6adae.png)
其中final Object value = mapping.typeHandler.getResult(rsw.getResultSet(), mapping.column);就是获取每一列的值

```
if (value != null) {
foundValues = true;
}
if (value != null || (configuration.isCallSettersOnNulls() && !mapping.primitive)) {
// gcode issue #377, call setter on nulls (value is not 'found')
metaObject.setValue(mapping.property, value);
}
```

接着对该列值判null，如果不为null，才说明找到值了，且通过反射set属性的值。否则foundValues为fasle。
那么，**applyAutomaticMappings方法返回的就是false，在getRowValue中，rowValue也就是null，即封装的每个对象都是null，add进list中。**

**解决办法：**
**1.在select 查询的字段中增加一个一定不为null的字段，比如主键
2.mybatis提供了一个配置，对于null值，是否返回对象。默认为false，设置true即可
mybatis:
configuration:
return-instance-for-empty-row: true**