### required关键字

顾名思义，就是必须的意思，数据发送方和接收方都必须处理这个字段，不然还怎么通讯呢



### optional关键字

字面意思是可选的意思，具体protobuf里面怎么处理这个字段呢，就是protobuf处理的时候另外加了一个bool的变量，用来标记这个optional字段是否有值，发送方在发送的时候，如果这个字段有值，那么就给bool变量标记为true，否则就标记为false，接收方在收到这个字段的同时，也会收到发送方同时发送的bool变量，拿着bool变量就知道这个字段是否有值了，这就是option的意思。

这也就是他们说的所谓平滑升级，无非就是个兼容的意思。

其实和传输参数的时候，给出数组地址和数组数量是一个道理。



### repeated关键字

字面意思大概是重复的意思，其实protobuf处理这个字段的时候，也是optional字段一样，另外加了一个count计数变量，用于标明这个字段有多少个，这样发送方发送的时候，同时发送了count计数变量和这个字段的起始地址，接收方在接受到数据之后，按照count来解析对应的数据即可。



其他说明
上述内容是在proto2版本下面的关键字说明，在proto3上，关键字做了很多调整，比如去掉了required，默认什么都不写，就是required，就是必须的，如果想使用optional，可以使用，但是protobuf-c的实现(即C语言版本的protobuf)没有支持该关键字，所以最好改成oneof关键字代替，效果是一样的，repeated保持和proto2版本一直，整体说proto3的语法简洁了很多。

