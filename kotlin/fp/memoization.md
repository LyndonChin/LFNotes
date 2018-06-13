Memoization is a technique for speeding up function calls by caching and reusing the output instead of recomputing for a given set of inputs.

```kotlin
fun fib(k: Int): Long = when (k) {
    0 -> 1
    1 -> 1
    else -> fib(k - 1) + fib(k -2 )
}
```

```kotlin
val map = mutableMapOf<Int, Long>()

fun memfib(k: Int): Long {
    return map.getOrPut(k) {
        when (k) {
            0 -> 1
            1 -> 1
            else -> memfib(k - 1) + memfib(k - 2)
        }
    }
}
```

```kotlin
fun <A, R> memoize(fn: (A) -> R): (A) -> R {
    val map = ConcurrentHashMap<A, R>()
    return { a -> 
        map.getOrPut(a) {
            fn(a)
        }
    }
}
```

```kotlin
val memquery = memoize(::query)
```

```kotlin
fun <A, R> Function1<A, R>.memoized(): (A) -> R {
    val map = CocurrentHashMap<A, R>()
    return {
        a -> map.getOrPut(a) {
            this(a)
        }
    }
}

val memquery = ::query.memoized()
```
