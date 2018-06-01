# Select expression

## Selecting from channels

```kotlin
fun fizz(context: CoroutineContext) = produce<String>(context) {
    while (true) { // sends "Fizz" every 300 ms
        delay(300)
        send("Fizz")
    }
}
```

```kotlin
fun buzz(context: CoroutineContext) = produce<String>(context) {
    while (true) {
        delay(500)
        send("Buzz!")
    }
}
```

```kotlin
suspend fun selectFizzBuzz(fizz: ReceiveChannel<String>,
                           buzz: ReceiveChannel<String>) {
    select<Unit> {
        fizz.onReceive { value -> 
            println("fizz -> '$value'")
        }
        buzz.onReceive { value ->
            println("buzz -> '$value'")
        }
    }
}
```

```kotlin
fun main(args: Array<String>) = runBlocking<Unit> {
    val fizz = fizz(coroutineContext)
    val buzz = buzz(coroutineContext)
    repeat(7) {
        selectFizzBuzz(fizz, buzz)
    }
    coroutineContext.cancelChildren() // cancel fizz & buzz coroutines
}
```

## Selecting on close

```kotlin
suspend fun selectAorB(a: ReceiveChannel<String>,
                       b: ReceiveChannel<String>): String = 
    select<String> {
        a.onReceiveOrNull { value -> 
            if (value == null)
                "Channel 'a' is closed"
            else
                "a -> '$value'"
        }
        b.onReceiveOrNull { value ->
            if (value == null)
                "Channel 'b' is closed"
            else
                "b -> '$value'"
        }
    }
```

```kotlin
fun main(args: Array<String>) = runBlocking<Unit> {
    val a = produce<String>(coroutineContext) {
        repeat(4) { send("Hello $it") }
    }
    val b = produce<String>(coroutineContext) {
        repeat(4) { send("World $it") }
    }
    repeat(8) {
        println(selectAorB(a, b))
    }
    coroutineContext.cancelChildren()
}
```

## Selecting to send

```kotlin
fun produceNumbers(context: CoroutineContext, side: SendChannel<Int>) = produce<Int>(context) {
    for (num in 1..10) { // produce 10 numbers from 1 to 10
        delay(100) // every 100 ms
        select<Unit> {
            onSend(num) {} // Send to the primary channel
            side.onSend(num) {} // or to the side channel
        }
    }
}
```

```kotlin
fun main(args: Array<String>) = runBlocking<Unit> {
    val side = Channel<Int>() // allocate side channel
    launch(coroutineChannel) { // this is a very fast consumer for the side channel
        side.consumeEach { println("Side channel has $it") }
    }
    produceNumbers(coroutineContext, side).consumeEach {
        println("Consuming $it")
        delay(250) // let us digest the consumed number properly, do not hurry
    }
    println("Done consuming")
    coroutineContext.cancelChildren()
}
```

## Selecting deferred values

```kotlin
fun asyncString(time: Int) = async {
    delay(time.toLong())
    "Waited for $time ms"
}
```

```kotlin
fun asyncStringsList(): List<Deferred<String>> {
    val random = Random(3)
    return List(12) { asyncString(random.nextInt(1000)) }
}
```

```kotlin
fun main(args: Array<String>) = runBlocking<Unit> {
    val list = asyncStringList()
    val result = select<String> {
        list.withIndex().forEach { (index, deferred) ->
            deferred.onAwait { answer ->
                "Deferred $index produced answer '$answer'"
            }
        }
    }
    println(result)
    val countActive = list.count { it.isActive }
    println("$countActive coroutines are still active")
}
```

## Switch over a channel of deferred values

```kotlin
fun switchMapDeferreds(input: ReceiveChannel<Deferred<String>>) = produce<String> {
    var current = input.receive() // start with first received deferred value
    while (isActive) { // loop while not cancelled/closed
        val next = select<Deferred<String>?> { // return next deferred value from this select or null
            input.onReceiveOrNull { update ->
                update // replaces next value to wait
            }
            current.onAwait { value ->
                send(value) // send value that current deferred has produced
                input.receiveOrNull() // and use the next deferred from the input channel
            }
            if (next == null) {
                println("Channel was closed")
                break // out of loop
            } else {
                current = next
            }
    }
}
```

```kotlin
fun asyncString(str: String, time: Long) = async {
    delay(time)
    str
}
```

```kotlin
fun main(args: Array<String>) = runBlocking<Unit> {
    val chan = Channel<Deferred<String>>() // the channel for test
    launch (coroutineContext) { // launch pringting coroutine
        for (s in switchMapDeferreds(chan))
            println(s) // print each received string
    }
    chan.send(asyncString("BEGIN", 100))
    delay(200)
    chan.send(asyncString("Slow", 500))
    delay(100)
    chan.send(asyncString("Replace", 100))
    delay(500)
    chan.send(asyncString("END", 500))
    delay(1000)
    chan.close()
    delay(500)
}
```
