## 1.utf8与utf8mb4（utf8 most bytes 4）

MySQL在5.5.3之后增加了这个utf8mb4的编码，mb4就是most bytes 4的意思，专门用来兼容四字节的[unicode](https://so.csdn.net/so/search?q=unicode&spm=1001.2101.3001.7020)。好在utf8mb4是utf8的超集，除了将编码改为utf8mb4外不需要做其他转换。当然，为了节省空间，一般情况下使用utf8也就够了。

最初的 UTF-8 格式使用一至六个字节，最大能编码 31 位字符。最新的 UTF-8 规范只使用一到四个字节，最大能编码21位，正好能够表示所有的 17个 Unicode 平面。   utf8 是 Mysql 中的一种字符集，只支持最长三个字节的 UTF-8字符，也就是 Unicode 中的基本多文本平面。

那上面说了既然utf8能够存下大部分中文汉字,那为什么还要使用utf8mb4呢? 原来mysql支持的 utf8 编码最大字符长度为 3 字节，如果遇到 4 字节的宽字符就会插入异常了。三个字节的 UTF-8 最大能编码的 Unicode 字符是 0xffff，也就是 Unicode 中的基本多文种平面(BMP)。也就是说，任何不在基本多文本平面的 Unicode字符，都无法使用 Mysql 的 utf8 字符集存储。包括 Emoji 表情(Emoji 是一种特殊的 Unicode 编码，常见于 ios 和 android 手机上)，和很多不常用的汉字，以及任何新增的 Unicode 字符等等。

- MySQL 5.5.3之后增加了utfmb4字符编码
- 支持BMP（Basic Multilingual Plane，基本多文种平面）和补充字符
- 最多使用四个字节存储字符

utf8mb4是utf8的超集并完全兼容utf8，能够用四个字节存储更多的字符。

标准的UTF-8字符集编码是可以使用1-4个字节去编码21位字符，这几乎包含了世界上所有能看见的语言。
**MySQL里面实现的utf8最长使用3个字符**，包含了大多数字符但并不是所有。例如emoji和一些不常用的汉字，如“墅”，这些需要四个字节才能编码的就不支持。

## 2.字符集、连接字符集、排序字符集

utf8mb4对应的排序字符集有utf8mb4_unicode_ci、utf8mb4_general_ci.

utf8mb4_unicode_ci和utf8mb4_general_ci的对比：

- 准确性：
  - utf8mb4_unicode_ci是基于标准的Unicode来排序和比较，能够在各种语言之间精确排序
  - utf8mb4_general_ci没有实现Unicode排序规则，在遇到某些特殊语言或者字符集，排序结果可能不一致。
  - 但是，在绝大多数情况下，这些特殊字符的顺序并不需要那么精确。
- 性能
  - utf8mb4_general_ci在比较和排序的时候更快
  - utf8mb4_unicode_ci在特殊情况下，Unicode排序规则为了能够处理特殊字符的情况，实现了略微复杂的排序算法。
  - 但是在绝大多数情况下发，不会发生此类复杂比较。相比选择哪一种collation，使用者更应该关心字符集与排序规则在db里需要统一。

总而言之，utf8mb4_general_ci 和utf8mb4_unicode_ci 是我们最常使用的排序规则。utf8mb4_general_ci 校对速度快，但准确度稍差。utf8_unicode_ci准确度高，但校对速度稍慢，两者都不区分大小写。这两个选哪个视自己情况而定，还是那句话尽可能保持db中的字符集和排序规则的统计。
