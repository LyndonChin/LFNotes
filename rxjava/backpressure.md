## 定义：
Backpressure in RxJava comes into picture when you have an observable which emits items so fast that consumer can’t keep up with the flow leading to the existence of emitted but unconsumed items.

a quickly-producing Observables meets a slow-consuming observer.

### Code Observable
> A cold Observable emits a particular sequence of items, but can begin emitting this sequence when its Observer finds it to be convenient, and at whatever rate the Observer desires, without disrupting the integrity of the sequence. 

场景：
* database query
* file retrieval
* web request

### Hot Observable
> A hot Observable begins generating items to emit immediately when it is created.

场景：
* mouse & keyboard events
* system events
* stock prices

### Multicast Observable

## 三种策略应对
### 1) Reducing Number of Items
对应的操作符有：

* sample
* throttleFirst
* throttleLast
* throttleWithTimeout

* debounce
* take
* takeLast
* filter
* first
* last
* debounce
* skip

### 2) Collecting Items
> items are collected and emitted as a collection using RxJava operators.

Operators:
* buffer
    * buffer closing selector
    * `debounce`
* window

    ```java
    // first
    Observable<Observable<Integer>> burstyWindowed = bursty.window(500, TimeUnit.MILLISECONDS);
    // second
    Observable<Observable<Integer>> burstyWindowed = bursty.window(5);
    ```


### 3) Reactive Pull
> your application need to process all the items emitted by source observable

`zip` 操作符就是利用了 Reactive Pull。

RxJava2 的 `Flowable` 是支持 back pressure 的。

对于不支持 back pressure 的 `Observable`，可有三种办法解决：
* `onBackpressureBuffer`
* `onBackpressureDrop`
* `onBackpressureBlock` (experimental, not in RxJava 1.0)

## 参考资料
* [RxJava Backpressure @medium](https://medium.com/@srinuraop/rxjava-backpressure-3376130e76c1)

