MySQL `DECIMAL`数据类型用于在数据库中存储精确的数值。我们经常将`DECIMAL`数据类型用于保留准确精确度的列，例如会计系统中的货币数据。

要定义数据类型为`DECIMAL`的列，请使用以下语法：

```sql
column_name ``DECIMAL``(M,D);
```

在上面的语法中：

- `P`是表示有效数字数的精度。 `M`范围为`1〜65`。
- `D`是表示小数点后的位数。 `D`的范围是`0`~`30`。MySQL要求`D`小于或等于(`<=`)`M`。

`DECIMAL(M，D)`表示列可以存储`D`位小数的`M`位数。十进制列的实际范围取决于精度和刻度。

与INT数据类型一样，`DECIMAL`类型也具有`UNSIGNED`和`ZEROFILL`属性。 如果使用`UNSIGNED`属性，则`DECIMAL UNSIGNED`的列将不接受负值。

如果使用`ZEROFILL`，MySQL将把显示值填充到`0`以显示由列定义指定的宽度。 另外，如果我们对`DECIMAL`列使用`ZERO FILL`，MySQL将自动将`UNSIGNED`属性添加到列。

**unsigned**

其意思为无符号的意思，在创建表中，字段添加此项可以令字段只能保存正数，并且可以增大数据类型的可用范围。

**zerofill**

zerofill的作用是填充0，在字段中数据类型规定的范围中，若是插入的数据不满足范围，则会使用空格作为填充，使其符合要求，而zerofill则会将空格改为0。

以下示例使用`DECIMAL`数据类型定义的一个叫作`amount`的列。

```
amount ``DECIMAL``(6,2);
```

在此示例中，`amount`列最多可以存储`6`位数字，小数位数为`2`位; 因此，`amount`列的范围是从`-9999.99`到`9999.99`。

MySQL允许使用以下语法：

```
column_name ``DECIMAL``(M);
```

这相当于：

```
column_name ``DECIMAL``(M,0);
```

在这种情况下，列不包含小数部分或小数点。

此外，我们甚至可以使用以下语法。

```
column_name ``DECIMAL``;
```

在这种情况下，`M`的默认值为`10`。

如果D>M，则会有如下报错：

```
1427 - For float(M,D), double(M,D) or decimal(M,D), M must be >= D (column 'test').
```

## MySQL DECIMAL存储

MySQL分别为整数和小数部分分配存储空间。 MySQL使用二进制格式存储`DECIMAL`值。它将`9`位数字包装成`4`个字节。

对于每个部分，需要`4`个字节来存储`9`位数的每个倍数。剩余数字所需的存储如下表所示：

| 剩余数字 | 位   |
| -------- | ---- |
| 0        | 0    |
| 1–2      | 1    |
| 3–4      | 2    |
| 5–6      | 3    |
| 7-9      | 4    |

例如，`DECIMAL(19,9)`对于小数部分具有`9`位数字，对于整数部分具有`19`位= `10`位数字，小数部分需要`4`个字节。 整数部分对于前`9`位数字需要`4`个字节，`1`个剩余字节需要`1`个字节。`DECIMAL(19,9)`列总共需要`9`个字节。

## MySQL DECIMAL数据类型和货币数据

经常使用`DECIMAL`数据类型的货币数据，如价格，工资，账户余额等。如果要设计一个处理货币数据的数据库，则可参考以下语法 -

```
amount ``DECIMAL``(19,2);
```

但是，如果您要遵守公认会计原则(GAAP)规则，则货币栏必须至少包含`4`位小数，以确保舍入值不超过`$0.01`。 在这种情况下，应该定义具有`4`位小数的列，如下所示：

```
amount ``DECIMAL``(19,4);
```

## MySQL DECIMAL数据类型示例

**首先**，创建一个名为`test_order`的新表，其中包含三列：`id`，`description`和`cost`。

```
CREATE TABLE test_order ( id INT AUTO_INCREMENT PRIMARY KEY, description VARCHAR ( 255 ), cost DECIMAL ( 19, 4 ) NOT NULL );　　
```

**第二步**，将资料插入test_order表。

```
INSERT INTO test_order ( description, cost ) VALUES ( 'Bicycle', 500.34 ),( 'Seat', 10.23 ),( 'Break', 5.21 ); 
```

**第三步**，从test_order表查询数据。

```
SELECT * from  test_order;

查询结果：
1	Bicycle	500.3400
2	Seat	10.2300
3	Break	5.2100
```

**第四步**，更改`cost`列以包含`ZEROFILL`属性。

```
ALTER TABLE test_order MODIFY cost DECIMAL ( 19, 4 ) ZEROFILL; 
```

**第五步**，再次查询test_order表。

```
SELECT * from  test_order;
```

查询结果`：`

 ![img](https://img2018.cnblogs.com/blog/568199/201901/568199-20190118101450984-1991455332.png)

 

如上所见，在输出值中填充了许多零。

因为zerofill，当我们插入负值会报错：

```
INSERT INTO test_order(description,cost)VALUES('test', -100.11);

error info:
1264 - Out of range value for column 'cost' at row 1, Time: 0.005000s
```

**其它插入测试结论：**

当数值在其取值范围之内，小数位多了，则四舍五入后直接截断多出的小数位。

若数值在其取值范围之外，则直接报Out of range value错误。