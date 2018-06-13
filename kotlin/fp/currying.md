Currying is the process of transforming a function that accepts multiple parameters into a series of functions, each of which accept a single function.

```kotlin
fun foo(a: String, b: Int): Boolean

// The curried form
fun foo(a: String): (Int) -> Boolean
```

Currying is a useful technique for allowing functions with multiple parameters to work with other functions that only accept single argument.

*Partial application* is the process by which some, but not all, of the parameters of a function are specified in advance, returning a new function that accepts the missing parameters.

Partial application is useful for at least two reasons.
* Firstly, when some parameters are available in the current scope, but not every scope, we can partially apply those values, and then just pass a function of lower arity. This avoids the need to pass down all the parameters, as well as the function.
* Secondly, similar to currying, we can use partial application to reduce the arity of a function in order to match a lower arity input type of another function.

```kotlin
fun compute(logger: (String) -> Unit): Unit

fun log(level: Level, appender: Appendable, msg: String): Unit

log(Level.Warn, System.out, "Starting execution")

fun compute {
    msg -> log(Level.Warn, Appender.Console, msg)
}

```

Adding currying support
---

```kotlin
fun <P1, P2, R> Function2<P1, P2, R>.curried(): (P1) -> (P2) -> R = {
    p1 -> {
        p2 -> this(p1, p2)
    }
}

fun <P1, P2, P3, R> Function3<P1, P2, P3, R>.curried(): (P1) -> (P2) -> (P3) -> R = {
    p1 -> {
        p2 -> {
            p3 -> this(p1, p2, p3)
        }
    }
}
```

```kotlin
fun logger(level: Level, appender: Appendable, msg: String)

val logger = ::logger.curried()(Level.SEVERE)(System.out)
logger("my message")
```
