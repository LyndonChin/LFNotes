## A Short Introduction to Reactive Programming

### What is reactive programming

Reactive programming is an aynchronous programming paradigm that revolves around data streams and the propagation of change. In simpler words, those programs which propagate all the changes that affected its data/data streams to all the interested parties (such as end users, components and sub-parts, and other programs that are somehow related) are called **reactive programs**.

### Reasons to adapt functional reactive programming

* Get rid of the callback hell
* Standard mechanism for error handling
* It's a lot simpler that regular threading
* Straightforward way for async operations
* One for everything, the same API for every operations
* The functional way
* Maintainable and testable code

### Reactive Manifesto

* Responsive
* Resilient
* Message driven

[Reactive Streams standard specifications](http://www.reactive-streams.org/)

Reactive Frameworks for Kotlin
* RxKotlin
* Reactor-Kotlin
* Redux-Kotlin
* FunKTionale

## Functional Programming with Kotlin and RxKotlin

It focuses on the use of declarative and expressive programs and immutable data rather than on statements.

> Functional programming is a programming system that relies on structuring the program as the evaluation of mathematical functions with immutable data, and it avoids state-change.


### Introducing functional programming
So, functional programming wants you to distribute your programming logic into small pieces of reusable declarative small and pure functions. Distributing your logic into small pieces of code will make the code modular and non-complex, thus you will be able to refactor/chagne any module/part of the code at any given point without any effects to other modules.

* Lisp
* Clojure
* Wolfram
* Erlang
* OCaml
* Haskell
* Scala
* F#

**functional reactive programming (FRP)**
* a product of mixing reactive programming with functional programming
* The main objective of writing functional programming is to implement *modular programming*

### Fundamentals of functional programming

#### Lambda expressions
Lambda or lambda expressions generally mean anonymous functions.

#### Pure function
> If the return value of a function is completely dependent on its arguments/parameters, then this function may be referred to as a pure function.

Side effects: A function or expression is said to have a side effect if it modifies some state outside its scope or has an observable interaction with its calling functions or the outside world besides returning a value.

#### Higher-order functions

#### Inline functions

### Coroutines

asynchronous, non-blocking code

Coroutines provide a great abstraction on threads, making context chagnes and concurrency easier.

```kotlin
suspend fun longRunningTask(): Long {
    val time = measureTimeMillis {
        println("Please wait")
        delay(2, TimeUnit.SECONDS)
        println("Delay Over")
    }
    return time
}

fun main(args: Array<String>) {
    runBlocking {
        val exeTime = longRunningTask()
        println("Execution Time is $exeTime")
    }
}
```

### Functional programming - monads

```kotlin
fun main(args: Array<String>) {
    val maybeValue: Maybe<Int> = Maybe.just(14) // 1
    maybeValue.subsribeBy( // 2
        onComplete = { println("Completed Empty") },
        onError = { println("Error $it") },
        onSuccess = { println("Completed with value $it") }
    )

    val maybeEmpty: Maybe<Int> = Maybe.empty() // 3
    maybeEmpty.subscribeBy (
        onComplete = { println("Complted Empty") },
        onError = { println("Error $it") },
        onSuccess = { println("Completed with value $it") }
    )
}
```

terminal methods

### Single monad


