* Higher-order functions: lambdas as parameters and return values
    * Declaring higher-order functions
        * Function types
        * Calling functions passed as arguments
        * Using function types from Java
        * Default and null values for parameters with function types
        * Returning functions from functions.
        * Removing duplication through lambdas
    * Inline functions: removing the overhead of lambdas
        * How inlining works
        * Restrictions on inline functions
        * Inlining collection operations
        * Deciding when to declare functions as inline
        * Using inlined lambdas for resource management
    * Control flow in higher-order functions
        * Return statements in lambdas: return from an enclosing function
        * Returning from lambdas: return with a label
        * Anonymous functions: local returns by default

从一段代码说起

```kotlin
fun <T> Collection<T>.joinToString(
    separator: String = ", ",
    prefix: String = "",
    postfix: String = "",
    transform: (T) -> String = { it.toString() }
): String {
    val result = StringBuilder(prefix)

    for ((index, element) in this.withIndex()) {
        if (index > 0) result.append(separator)
        result.append(transform(element))
    }
    result.append(postfix)
    return result.toString()
}
```

```
>>> val letters = listOf("Alpha", "Beta")

// Uses the default conversion function
>>> println(letters.joinToString())
Alpha, Beta

// Passes a lambda as an argument
>>> println(letters.joinToString { it.toLowerCase() })
alpha, beta

// Uses the named argument syntax for passing several arguments including a lambda
>>> println(letters.joinToString(separator = "! ", postfix = "! ",
                                transform = { it.toUpperCase() })) 
```

定义
a higher-order function is a function that takes another function as an argument or returns one.

函数可以用值（value）来表示
Functions can be represented as values using lambdas or function references.
为什么没有 annoymous function 呢？annoymous function 也是 value。

终极定义
Therefore, a higher-order function is any function to which you can pass a lambda or a function reference as an argument, or a function which returns one, or both.

Function types
---
既然高阶函数可以把函数作为参数（parameter），我们又知道函数参数（parameter）要类型（type），那么这个作为参数的函数的类型是什么呢？

因为 Kotlin 有类型推导，所以在某些情况下，我们可以可以省略变量的类型：

```kotlin
val sum = { x: Int, y: Int -> x + y }
val action = { println(42) }
```

加上类型之后的完整版：

```kotlin
val sum: (Int, Int) -> Int = { x: Int, y: Int -> x + y }
val sum: (Int, Int) -> Int = { x, y -> x + y } // 简写，因为 x y 的类型已经知道了
val action: () -> Unit = { println(42) }
```

类型的语法解释一下 // TODO

`Unit` 在函数声明中可以省略，但是函数类型中不可省略。


当然函数类型也可声明为可空

```kotlin
var funOrNull: ((Int, Int) -> Int)? = null
```

我们可以给函数类型的参数指定一个名字，叫 named parameters，对 IDE 友好

```kotlin
fun performRequest(
    url: String,
    callback: (code: Int, content: String) -> Unit
) {
    /*...*/
}
```
