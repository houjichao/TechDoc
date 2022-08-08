在Jenkins声明式Pipeline（Declaritive Pipeline）中，如果需要执行多个命令，可以在Jenkinsfile中，将它们用三个单引号或三个双引号来包围。

我们以Jenkins调用Powershell执行脚本为例，说明这两种方式的区别。

注：在本文代码中，被'#'所注释的代码行，都是存在语法错误或执行不符合预期的代码。

1. 如果使用三个单引号，那么其中的字符，除了'\'会被解析为转义字符外，其他都会被原封不动地传递给Powershell，不作任何解析。例如：


```
pipeline {
	agent any
	environment {
		name = "Alice"
    }
	stage(example) {
		steps {
			powershell '''               
				Write-Output "Happy birthday!"
                # 以下两条命令能够让Powershell输出"Hello world"
				$str = 'Hello world'    # 一对三单引号之间可以使用单个单引号
				Write-Output $str
                # 由于不作解析，因此下一行命令将会输出"${env.name}"这一字符串
                # 事实上，使用三单引号是无法引用Jenkins环境变量的
				# Write-Output ${env.name}
			'''
        }
    }
}
```

2. 如果使用三个双引号，则绝大部分字符也会被原封不动地传递给Powershell，但如下三个字符除外：

① '$'（美元字符）：用于引用Jenkinsfile中的环境变量。

② '\'（反斜杠字符）：用于转义。

③ ' " '（双引号字符）：本身无特殊含义，但是三个双引号之间不允许出现非转义的双引号字符，否则将导致语法错误。

如果确实需要使用上述三个字符本身，而不是使用其特殊含义，则必须在前面加上'\'字符进行转义，即：'\$'、'\\'、'\"'。

例如
```
pipeline {
	agent any
	environment {
		name = "Alice"
    }
	stage(example) {
		steps {
			powershell """ 
                # 以下两条命令能够让Powershell输出"Hello world"。注意必须使用'\$'进行转义
                \$str = 'Hello world'
				Write-Output \$str
                # 现在我们尝试输出环境变量中的name，预期输出是："name = Alice"。
                # 执行结果错误：单引号之间的字符将不作解析，故输出的是"name = ${env.name}"
                # Write-Output 'name = ${env.name}'
                # 执行结果错误："name"、"="和"Alice"将分为三行输出
                # Write-Output name = ${env.name}
                # 语法错误：三双引号之间不得出现非转义双引号
                # Write-Output "Happy birthday!"
                # 正确。输出"name = Alice"
				Write-Output \"name = ${env.name}\"
			"""
        }
    }
}
```

总结：

三单引号的优点是，语法简洁，不存在过多转义；缺点是，无法引用Jenkins中的环境变量。而三双引号的优缺点与此正好相反。

个人对于使用三双引号的建议是：仅在必须声明和引用Powershell变量（而非Jenkins环境变量）时，才使用三单引号或三双引号。其他时候，每一条命令都应拆分，并以powershell开头。这样做的好处是便于调试（尤其是使用Blue Ocean调试时）。在这一前提下，如果需要在三引号中引用Jenkins环境变量，则必须使用三双引号；否则，使用三单引号表达更为简洁。
