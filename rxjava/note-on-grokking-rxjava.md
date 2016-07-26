Functional Reactive Programming
---
* Observable & Subscriber
    * `Observable` emits items.
    * `Subscriber` consumes these items.
    * `Observables` often don't start emitting items until someone explicitly subscribes to them.
* Operators let you do anything to the stream of data.
    * `map`
    * `flatMap()` can return any `Observable` it wants.
    * `filter()` emits the same item it received, but only if it passes the boolean check.
    * `take()` emits, at most, the number of items specified. (If there are fewer than 5 titles it'll just stop early.)
    * `doOnNext()` allows us to add extra behavior each time an item is emitted, in this case saving the title.


* **Key ideas**
    0. `Observable` and `Subscriber` can do anything.
    0. The `Observable` and `Subscriber` are independent of the transformational steps in between them.

* Error Handling
    0. You can leave all your error handling to the `Subscriber`.

* RxAndroid
    * `HandlerThreadScheduler1`

Combine multiple REST calls into one with RxJava + Retrofit.

```java
Observable.zip(
    service.getUserPhoto(id),
    service.getPhotoMetadata(id),
    (photo, metadata) -> createPhotoWithData(photo, metadata))
    .subscribe(photoWithData -> showPhoto(photoWithData));
```
