使用exp4j快速实现自定义数学公式计算

## 背景

在产品需求迭代中，需要用户自定义输入数学公式，并含有变量，需求描述如下：

指数计算
（一）子任务增加【指数计算】菜单；

（二）计算基准：只有 指标得分
（1）加权平均（默认）：固定计算公式：[（指标得分1×权重1）+（指标得分2×权重2）+...+（指标得分n×权重n）]/权重之和

（2）**自定义**

- 仅允许输入数字、变量、符号+-*/.（）[ ]
- 通过键盘or数字符号面板输入数字、符号；点击输入变量，变量可重复选择，样式应与数字和符号有所区分；
- 可用变量：任务中所有的指标得分，包括配置时暂无指标值、暂无得分的指标；
- 搜索变量：按指标名称关键字模糊搜索；
- 输入其他字符无效；
- 点击【计算】，计算该公式：

①若可正常计算，则在计算结果中展示计算出来的值，可正常保存；

②若因指标得分为空，无法计算，提示“有变量值为空，公式可保存”，计算结果提示“暂无结果”，可正常保存；

③若因公式错误不可计算，则提示“计算公式错误，请检查”，计算结果保持为“-”，并且不允许保存；

## 实现思路

### 思路一

1. 采用sql的方式可以实现目前版本的需求，但是相对复杂，而且涉及到的表较多
2. 如果后续需求变动，增加公式复杂度，如增加log、sin cos函数或者一些自定义函数，sql方式实现很复杂，而且不易维护

### 思路二

1. 加权平均其实也是数学公式，相当于一个默认的拼接公式，只是变量不同
2. 考虑成熟组件完成数学公式的计算，只需要定义变量的存储和传入
3. 成熟组件是否支持复杂的数学计算、自定义函数等

**经过调研，采用了exp4j完成本次的需求**

## exp4j介绍以及实际使用

### 介绍

exp4j能够评估实域中的表达式和函数。这是一个很小的（40KB）库，没有任何外部依赖性，它实现了[Dijkstra的Shunting Yard Algorithm](http://en.wikipedia.org/wiki/Shunting-yard_algorithm)。exp4j带有一组标准的内置函数和运算符。此外，用户还可以创建自定义运算符和函数。

[exp4j](https://www.objecthunter.net/exp4j/index.html)

### 实际使用

#### maven依赖

```
<dependency>
    <groupId>net.objecthunter</groupId>
    <artifactId>exp4j</artifactId>
    <version>0.4.8</version>
</dependency>
```

#### 工具类代码

```java
import java.math.BigDecimal;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import lombok.extern.slf4j.Slf4j;
import net.objecthunter.exp4j.Expression;
import net.objecthunter.exp4j.ExpressionBuilder;
import net.objecthunter.exp4j.ValidationResult;
import org.apache.commons.lang3.StringUtils;
import org.springframework.util.CollectionUtils;

/**
 * 数学公式计算
 *
 * @author houjichao
 */
@Slf4j
public class Exp4jUtil {

    /**
     * 利用计算公式计算结果
     *
     * @param expressionStr 数学公式
     * @param variables 变量
     * @param decimalDigits 保留小数位数，四舍五入
     * @return 计算结果
     */
    public static Double calculation(String expressionStr, Map<String, Double> variables, Integer decimalDigits) {
        /*
           变量名称必须以字母或下划线_开头，并且只能包含字母，数字或下划线。
           以下是有效的变量名称：
           varX
           _x1
           _var_X_1
           而1_var_x不是，因为它不是以字母或下划线开头。
         */

        if (StringUtils.isNotBlank(expressionStr)) {
            // 1.判断表达式有变量参数，但是变量中没有 或数量不匹配
            if (expressionStr.contains("_") && CollectionUtils.isEmpty(variables)) {
                return null;
            }
            /*int variablesCount = CharMatcher.is('_').countIn(expressionStr);
            if (variablesCount < variablesKey.size()) {
                return null;
            }*/
            boolean variablesIllegal = false;
            for (Map.Entry<String, Double> map : variables.entrySet()) {
                if (map.getValue() == null) {
                    variablesIllegal = true;
                    break;
                }
            }
            if (variablesIllegal) {
                return null;
            }
            Set<String> variablesKey = variables.keySet();
            // 2.构建表达式
            log.debug("Exp4jUtil.calculation计算表达式为:{};;;;计算参数为{}", expressionStr, variables.toString());
            Expression expression = new ExpressionBuilder(expressionStr).variables(variablesKey).build();
            // 3.循环放置变量
            expression.setVariables(variables);
            // 4.校验
            ValidationResult validate = expression.validate();
            if (!validate.isValid()) {
                return null;
            }
            try {
                // 5.计算结果，进行小数位四舍五入
                double result = expression.evaluate();
                BigDecimal bigDecimal = new BigDecimal(result);
                result = bigDecimal.setScale(decimalDigits, BigDecimal.ROUND_HALF_UP).doubleValue();
                return result;
            } catch (ArithmeticException e) {
                log.error("Exp4jUtil.calculation计算结果错误，表达式:{}，参数为{}", expressionStr, variables.toString());
            }
        }
        return null;
    }

    /**
     * 检查表达式
     *
     * @param expressionStr 数学公式
     * @param variables 变量
     */
    public static Boolean checkExpression(String expressionStr, Map<String, Double> variables) {
        if (StringUtils.isNotBlank(expressionStr)) {
            // 1.构建表达式
            Set<String> variablesKey = variables.keySet();
            Expression expression = new ExpressionBuilder(expressionStr).variables(variablesKey).build();
            // 2.循环放置变量
            expression.setVariables(variables);
            // 3.校验
            ValidationResult validate = expression.validate();
            return validate.isValid();
        }
        return false;
    }

    public static void main(String[] args) {
        Expression e = new ExpressionBuilder("[(2*3)+ (3*4)+(4*5)]/x")
                .variable("x")
                .build()
                .setVariable("x", 3);
        double result = e.evaluate();
        System.out.println(result);

        //test calculation
        String expressionStr = "[(_1124e76845b141809a1ac3d1b158bb94*_44f25f7880f440f19c602e2c431f43ce)+ (0.3*4)+(4*5)"
                + "]/_1124e76845b141809a1ac3d1b158bb94";
        Map<String, Double> variables = new HashMap<>();
        variables.put("_1124e76845b141809a1ac3d1b158bb94", 3D);
        variables.put("_44f25f7880f440f19c602e2c431f43ce", 3D);
        variables.put("_adasda3ce", 3D);
        variables.put("_ad123123asda3ce", 3D);
        System.out.println(variables.toString());
        System.out.println(calculation(expressionStr, variables, 3));
        expressionStr = "1/0";
        System.out.println(checkExpression(expressionStr, variables));

    }
}

```

#### 变量存储的设计

relationId：表示变量id，exp4j中变量名称必须以字母或下划线_开头，并且只能包含字母，数字或下划线，所以使用uuid作为变量名称会存在数字开头的情况，统一在uuid前增加下划线，但是存储关系时只需要存储uuid即可

relationName：表示变量名称，方便前端展示

relationType：表示变量类型，表示指标得分 or 任务指数 or 子任务指数 or 任务组指数

weight： 表示权重，用于加权平均公式的拼接

```
[{
	"relationId": "1893e1e14df7404080291c51fcc4dd4c",
	"relationName": "南山区空气",
	"weight": 1.0,
	"relationType": 3
}, {
	"relationId": "1d1090e6b5774e6aae933ebaffada8c2",
	"relationName": "演示-气象环境",
	"weight": 3.0,
	"relationType": 2
}]
```

#### 计算公式存储

1. 加权平均：不存储计算公式，根据现存关联关系进行拼接，权重相加
2. 自定义计算公式如下：

```
[(_1893e1e14df7404080291c51fcc4dd4c*3)+(_1d1090e6b5774e6aae933ebaffada8c2+10)]/2
```



最后在需要进行计算公式 校验 和 实际计算的时候，组装参数、进行调用即可。



代码见spring-boot-learn

[spring-boot-learn](https://github.com/houjichao/spring-boot-learn)

