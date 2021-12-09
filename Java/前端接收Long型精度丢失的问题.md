*说明：数据设计使用bigint 类型作为主键，Java后台使用Long 类型进行接收。在进行数据查询时发现前端preview获取到的数据后两位是0。断点发现Java后端是没有问题的。后经查询问题如下：*

- javascript 的 Number 类型最大长度是17位；
- mysql 使用bigint 类型长度是20位；

**解决办法：**
 方法一：Java 后台 更换类型，使用String类型替换Long类型
 方法二：让javascript 去支持Long类型（此方法我也不会）
 方法三：Java传值给前端进行JSON序列化时，将Long 类型转成string 类型序列化。（推荐）
 使用   @JsonSerialize(using = ToStringSerializer.class) 注解