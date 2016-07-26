```java
public final class FutureResult<T> {

  private final AtomicReference<T> resultHolder;
  private final CountDownLatch latch;

  public FutureResult() {
    resultHolder = new AtomicReference<>();
    latch = new CountDownLatch(1);
  }

  public boolean wait(long timeout, TimeUnit unit) {
    try {
      return latch.await(timeout, unit);
    } catch (InterruptedException e) {
      throw new RuntimeException("Did not expect thread to be interrupted", e);
    }
  }

  public T get() {
    if (latch.getCount() > 0) {
      throw new IllegalStateException("Call wait() and check its result");
    }
    return resultHolder.get();
  }

  public void set(T result) {
    resultHolder.set(result);
    latch.countDown();
  }
}
```
