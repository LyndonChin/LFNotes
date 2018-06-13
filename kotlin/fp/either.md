Either
===

```kotlin
sealed class Either<out L, out R> {
    fun <T> fold(lfn: (L) -> T, rfn: (R) -> T): T = when (this) {
        is Left -> lfn(this.value)
        is Right -> rfn(this.value)
    }
}

class Left<out L>(value: L) : Either<L, Nothing>()
class Right<out R>(value: R) : Either<Nothing, R>()
```
