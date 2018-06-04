Lambda expressions are compiled to classes (often anonymous classes), and object creation in Java is a heavy operation.

Lambda expressions provided as arguments are replaced with their actual body. They will not be treated as functions, but as actual code.

```kotlin
inline fun printExecutionTime(f: () -> Unit) {
    val startTime = System.currentTimeMillis()
    f()
    val endTime = System.currentTimeMillis()
    println("It took " + (endTime - startTime))
}

fun measureOperation() {
    printExecutionTime {
        longOperation()
    }
}
```

While there is no need to create classes for lambda expressions, inline functions can speed up the execution of functions with function parameters.

It is recommended to use the inline modifier for all short functions with at least on function parameter.

Inline functions cannot be recursive and they cannot use functions or classes that have a more restrictive visiblity modifier than this lambda expression.

```kotlin
internal fun someFun() {}
inline fun inlineFun() {
    someFun() // ERROR
}
```

```kotlin
// Tester1.kt
fun main(args: Array<String>) { a() }

// Tester2.kt
inline fun a() { b() }
private fun b() { print("B") }
```

---

When a function is `inline`，then its function arguments cannot be passed to a function that is not inline.
This doesn't work because no `f` parameter has been created. It has just been defined to be replaced by the *function literal* body. This is why it cannot be passed to another function as an argument.

---

## The noinline modifier

```kotlin
fun boo(f: () -> Unit) {
    // ...
}

inline fun foo(before: () -> Unit, noinline f: () -> Unit) { // 1
    before() // 2
    boo(f) // 3
}
```

---

While it is unlikely that using `inline` will be beneficial, the compiler will show a warning. This is why, in most cases, `noinline` is only used when there are multiple function parameters and we only apply it to some of them.

---

```kotlin
inline fun forEach(list: List<Int>, body: (Int) -> Unit) {
    for (i in list) body(i)
}

fun maxBounded(list: List<Int>, upperBound: Int, lowerBound: Int): Int {
    var currentMax = lowerBound
    forEach(list) { i-> 
        when {
            i > upperBound -> return upperBound
            i > currentMax -> currentMax = i
        }
    }
    return currentMax
}
```

The `return` modifier used inside the lambda expression of the `inline` function is called a non-local return.

```kotlin
inline fun <T> forEach(list: List<T>, body: (T) -> Unit) {
    for (i in list) body(i)
}

fun processMessageButNotError(messages: List<String>) {
    forEach(messages) messageProcessor@ {
        if (it == "ERROR") return@messageProcessor // 3
        print(it)
    }
}

// Usage
val list = listOf("A", "ERROR", "B", "ERROR", "C")
processMessageButNotError(list) // Prints: ABC
```

Lambda expressions that are defined as function arguments have a default label whose name is the same as the function in which they are defined. This label is called an implicit label.

```kotlin
inline fun <T> forEach(list: List<T>, body: (T) -> Unit) { // 1
    for (i in list) body(i)
}

fun processMessageButNotError(messages: List<String>) {
    forEach(messages) {
        if (it == "ERROR") return @forEach
        process(it)
    }
}

// Usage
val list = listOf("A", "ERROR", "B", "ERROR", "C")
processMessageButNotError(list) // Prints: ABC
```

```kotlin
inline fun <T> forEach(list: List<T>, body: (T) -> Unit) {
}
```
