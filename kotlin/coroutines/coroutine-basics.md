# Coroutine basics
## Your first coroutine

```kotlin
fun main(args: Array<String>) {
    launch { // launch new coroutine in background and continue
        delay(1000L) // non-blocking delay for 1 second (default time unit is ms)
        println("World!") // print after delay
    }
    println("hello,") // main thread continues while coroutine is delayed
    Thread.sleep(2000L) // block main thread for 2 seconds to keep JVM alive
}
```

## Bridging blocking and non-blocking worlds

```kotlin
fun main(args: Array<String>) {
    launch {
        delay(1000L)
        println("World!")
    }
    println("hello,")
    runBlocking {
        delay(2000L)
    }
}
```

```kotlin
fun main(args: Array<String>) = runBlocking<Unit> { // start main coroutine
    launch { // launch new coroutine in background and continue
        delay(1000L)
        println("World!")
    }
    println("Hello,") // main coroutine continues here immediately
    delay(2000L)      // delaying for 2 seconds to keep JVM alive
}
```

```kotlin
class MyTest {
    @Test
    fun testMySuspendingFunction() = runBlocking<Unit> {
        // here we can use suspending functions using any assertion style that we like
    }
}
```

## Waiting for a job

```kotlin
fun main(args: Array<String>) = runBlocking<Unit> {
    val job = launch { // launch new coroutine and keep a reference to its job
        delay(1000L)
        println("World!")
    }
    println("Hello,")
    job.join() // wait until child coroutine completes
}
```

## Extract function refactoring

```kotlin
fun main(args: Array<String>) = runBlocking<Unit> {
    val job = launch { doWorld() }
    println("Hello,")
    job.join()
}

// this is your first suspending function
suspend fun doWorld() {
    delay(1000L)
    println("World!")
}
```

## Continues ARE light-weight

```kotlin
fun main(args: Array<String>) = runBlocking<Unit> {
    val jobs = List(100_00)) { // launch a lot of coroutines and list their jobs
        launch {
            delay(1000L)
            print(".")
        }
    }
    jobs.forEach { it.join() } // wait for all jobs to complete
}
```

## Coroutines are like daemon threads

```kotlin
fun main(args: Array<String>) = runBlocking<Unit> {
    launch {
        repeat(1000) { i ->
            println("I'm sleeping $i ...")
            delay(500L)
        }
    }
    delay(1300L) // just quit after delay
}
```
