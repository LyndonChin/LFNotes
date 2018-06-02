## 3 Playing with Functions
The function is the most basic building block in Kotlin.

### Basic function declaration and usage

### Parameters

Parameters in Kotlin functions are declared using **Pascal notation**.

> 这里可以回答为什么 Kotlin 支持 name shadowing

All parameters are defined as read-only variables. There is no way to make parameters mutable, because such behavior is error-prone and in Java it was often abused by programmers. If there is a need for that, then we can explicitly shadow parameters by declaring local variables with the same name:

```kotlin
fun findDuplicates(list: List<Int>): Set<Int> {
    var list = list.sorted()
    //...
}
```

Note that `Any?` is the supertype of all nullable and non-nullable types

### Returning functions

Procedures: functions that do not return any values

---

The Unit object is the equivalent of Java's void, but it can be treated as any other object.

```kotlin
fun printSum(a: Int, b: Int): Unit { // 1
    val sum = a + b
    print(sum) 
}

val p = printSum(1, 2)
println(p is Unit) // Prints: true
```

---

`Unit` is a singleton:

```kotlin
println(p is Unit) // Print: true
println(p == Unit) // Print: true
println(p === Unit) // Print: true
```

---

`*` = the `spread` operator

```kotlin
val texts = arrayOf("B", "C", "D")
printAll(*texts) // Prints: Texts are: B,C,D
printAll("A", *texts, "E") // Prints: Texts are: A,B,C,D,E
```

---

### Single-expression Functions

```kotlin
override fun onOptionsItemSelected(item: MenuItem): Boolean = when {
    item.itemId == android.R.id.home -> {
        onBackPressed()
        true 
    }
    else -> super.onOptionsItemSelected(item)
}
```

## Functions as First-Class Citizens

> The sentence *a function is a first-class citizen in Kotlin* should then be understood as: *it is possible in Kotlin to pass functions as an argument, return them from functions, and assign them to variables.*

### What is function type under the hood?

* `() -> Unit` = `Function0<Unit>`
* `(Int) -> Unit` = `Function1<Int, Unit>`
* `() -> (Int, Int) -> String` = `Function0<Function2<Int, Int, String>>`

> All of these interfaces have only one method, invoke, which is an operator.

### Lambda expressions

> They are similar to Java 8 lambda expressions, but the biggest difference is that Kotlin lambdas are actually closures, so they allow us to change variables from the creation context.

### The implicit name of a single parameter

LINQ Style

```kotlin
strings.filter { it.length = 5 }.map { it.toUpperCase() }
```

### The last lambda in an argument convention

```kotlin
public fun thread(
  start: Boolean = true,
  isDaemon: Boolean = false,
  contextClassLoader: ClassLoader? = null,
  name: String? = null,
  priority: Int = -1,
  block: () -> Unit): Thread {
      // implementation
  }
```

### Named code surrounding

### Java SAM support in Kotlin

**Single Abstract Method (SAM)**

### Type alias

```kotlin
typealias OnElementClicked = (position: Int, view: View, parent: View) -> Unit

class MainActivity: Activity(), OnElementClicked {
   override fun invoke(position: Int, view: View, parent: View) {
       // code
   } 
}

```

### Destructuring in lambda expressions

```kotlin
val showUser: (User) -> Unit = { (name, surname, phone) ->
   println("$name $surname have phone number: $phone")
}
val user = User("Marcin", "Moskala", "+48 123 456 789")
showUser(user)
// Marcin Moskala have phone number: +48 123 456 789
```

> Kotlin's destructing declaration is position-based, as opposed to the property name-based destructuring declaration that can be found, for example, in TypeScript.



