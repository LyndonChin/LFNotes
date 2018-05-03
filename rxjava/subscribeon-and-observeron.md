RxJava is known as *a library for composing asynchronous and event-based programs using observable sequences*.

Schedulers
---

* `Schedulers.io()`
    * unbounded thread pool
    * non CPU-intensive I/O type (file system / network calls / database interactions)
* `Schedulers.computation()`
    * bounded thread pool with size up the number of available processors
    * computational or CPU-intensive work (resizing iamges, processing large data sets)
* `Schedulers.newThread()`
    * new thread is spawned every time
    * no resuse happens
* `Schedulers.newThread()`
    * Limit the number  of simultaneous threads - `Schedulers.from(Executors.newFixedThreadPool(n))`
* `Schedulers.single()`
* `Schedulers.trampoline()`


Code
---
```java
Observable.just("long", "longer", "longest")
    .map(String::length)
    .subscribe(length -> System.out.println("item length" + length"));
```

See what thread this work is being done

```java
Observable.just("long", "longer", "longest")
    .doOnNext(c -> System.out.println("processing item on thread " + Thread.currentThread().getName()))
    .map(String::length)
    .subscribe(length -> System.out.println("item length " + length));
```

```java
Observable.just("long", "longer", "longest")
    .doOnNext(c -> System.out.println("processing item on thread " + Thread.currentThread().getName()))
    .subscribeOn(Schedulers.newThread())
    .map(String::length)
    .observeOn(AndroidSchedulers.mainThread())
    .subscribe(length -> System.out.println("item length " + length + " received on thread " + Thread.currentThread().getName()));
```

Ref
---
* [Understanding RxJava subscribeOn and observeOn](https://proandroiddev.com/understanding-rxjava-subscribeon-and-observeon-744b0c6a41ea)
