Android Development with Kotlin
===

语言设计的几个关键点：
---

* variables
* type systems
* control structures
* building blocks 
    * 对于建房子来说，building blocks 是砖瓦之类的东西
    * 对于 Java 来说，building blocks 是 class
    * Kotlin 支持 FP，所以它的 building blocks 包括 function

函数（function）和方法（method）的区别
---
* A function is a piece of code that is called by name. A method is a function associated with an instance of a class (object). Sometimes it is called member function.
* So in simpler words, functions inside classes are called **methods**. In Java, there are officially only methods, but academics often argue that static Java methods are in fact functions. In Kotlin, we can define functions that are not associated with any object.

参数
---
* 命名符合 Pascal notation
* 所有的参数都是只读，而且没有办法声明为 mutable。
    * All parameters are defined as read-only variables. There is no way to make parameters mutable, because such behavior is error-prone and in Java it was often abused by programmers.
* Parameters vs Arguments
    * An argument is an actual value that is passed to a function when the function is called. A parameter refers to the variables declared inside a function declaration.

返回函数
---
* 什么是 procedure
    * functions that do not return any values
* 注意 `Unit` 类型也可以有实例：`val p = printSum(1, 2)`，`printSum` 的返回值类型是 `Unit`

Vararg parameter
---
* `vararg` 的参数类型是数组
* primitive type 的数组 `IntArray`，还有一个泛型 `Array<T>`，两者的区别是什么呢？

```kotlin
fun printAll(vararg texts: Any) {
    val allTexts = texts.joinToString(",") // 1
    println(allTexts)
}

// Usage
printAll("A", 1, 'c') // Prints: A,1,c

val texts = arrayOf("B", "C", "D")
printAll(*texts)
printAll("A", *texts, "E")
```

Single-expression functions
---
* 函数体有两种 expression body & block body
* 让代码变得更 concise & improve readability
* Imperative vs Declarative
    * **Imperative programming**: This programming paradigm describes the exact sequence of steps required to perform an operation. It is most intuitive for most programmers.
    * **Declarative programming**: This programming paradigm describes a desired result, but not necessarily steps to achieve it (implementation of behavior). This means that programming is done with expressions or declarations instead of statements. Both functional and logic programming are characterized as declarative programming styles. Declarative programming is often shorter and more readable than imperative.

Tail-recursive functions
---


Different ways of calling a function
---
* Default argument values
* Named arguments syntax

Top-level functions
---

Local functions
---
* 函数定义的位置
    * Top-level
    * method
    * local function

Nothing return type
---
* This is why Nothing is referred to as an empty type, which means that no value can have this type at runtime, and it's also a subtype of every other class.

function types
---
* 既然函数是一等公民，那么函数就可以像其他变量一样被用作函数实参、函数返回值或者把函数赋值给变量。因为 Kotlin 是静态类型语言，所以函数值还需要一个函数类型。
* 通过反射操作（`::`）可以拿到一个 function type 的 value
    * `KFunction<out R>`
    * `KFunction3<T1, T2, T3, R>`
* 作用于 property 上的 `::` 拿到的是一个 `KProperty`
* A first-class citizen in a given programming language is a term that describes an entity that supports all the operations generally available to other entities.
* Under the hood, function types are just a syntactic sugar for generic interfaces.
    * `()->Unit` = `Function0<Unit>`
    * `(Int)->Unit` = `Function1<Int, Unit>`
    * `() -> (Int, Int) -> String` = `Function0<Function2<Int, Int, String>>`
* 所有上面的 function interface 都有一个方法叫 `invoke`，对应着操作符 `()`
* function interfaces 是在编译时合成的，所以说参数个数没有限制

Anonymous functions
---
* 匿名函数实际上是一个函数类型的object，所以可以作为对象来使用或者传递。

Lambda expressions
---
Kotlin 的 lambda 与 Java8 的 lambda 有所不同，Kotlin 的lambda 是一个真正的闭包，so they allow us to change variables from the creation context.

lambda 中的 return 是 non-local return，所以，如果要在 lambda 中使用 return，必须 qualified by a label：

```kotlin
var a: (Int) -> Int = { i: Int -> return i * 2 } // Error
var l: (Int) -> Int = l@ { i: Int -> return@l i * 2 }
```

Kotlin 的 lambda 支持多行：

```kotlin
val printAndReturn = { i: Int, j: Int ->
    println("I calculate $i + $j")
    i + j
}
```

当然多行也可以用分号来分隔：

```kotlin
val printAndReturn = {i: Int, j: Int -> println("I calculate $i + $j"); i+j }
```

那么什么是闭包呢？很重要一点：在 lambda 内可以修改它所包含的局部变量。
Lambda expressions that enclose local variables and allow us to change them inside the function body are called **closures**.

Lambda expressions can use and modify variables from the local context.

LINQ style is popular in functional languages because it make the syntax of collections or string processing really simple and concise.

Higher-order functions
---
A higher order function is a function that takes at least one function as an argumet, or returns a function as its result.

The three most common cases when functions in arguments are used are:
* Providing operations to functions
* The Observer (Listener) pattern
* A callback after a threaded operation

lambda 表达式一个很大的问题是不具备 self-explanatory

The last lambda in an argument convention
---
* named code surrouding

Java SAM support in Kotlin
---
* A *funciton literal* is an expression that defines an unnamed function. In Kotin, there are two kinds of *function literal*:
    * Anonymous functions
    * Lambda expressions

```kotlin
val a = fun() { } // Anonymous function
val b = {} // Lambda expression
```

lambda 可以写成多行，当然多行也可以用分号来分隔：

```kotlin
view.setOnLongClickListener { /* ... */; true }
view.onFocusChange { view, b -> /* ... */ }

val callback = Runnable { /* ... */ }
view.postDelayed(callback, 1000)
view.removeCallbacks(callback)
```
