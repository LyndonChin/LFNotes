`LeakCanary#install` 返回一个 `RefWatcher`，这个 `RefWatcher` 在Activity 销毁的时候开始 watch 当前 activity。

```java
@Override
public void onActivityDestroyed(Activity activity) {
  refWatcher.watch(activity);
}
```

watch 方法
---

```java
public void watch(Object watchedReference) {
  watch(watchedReference, "");
}

public void watch(Object watchedReference, String referenceName) {
  checkNotNull(watchedReference, "watchedReference");
  checkNotNull(referenceName, "referenceName");
  if (debuggerControl.isDebuggerAttached()) {
    return;
  }
  final long watchStartNanoTime = System.nanoTime();
  String key = UUID.randomUUID().toString();
  retainedKeys.add(key);
  final KeyedWeakReference reference =
      new KeyedWeakReference(watchedReference, key, referenceName, queue);

  watchExecutor.execute(new Runnable() {
    @Override public void run() {
      ensureGone(reference, watchStartNanoTime);
    }
  });
}
```

因为 debugger 会影响对象的引用，所以如果有 debugger attached 直接 return。

```java
if (debuggerControl.isDebuggerAttached()) {
  return;
}
```

然后记录 watch 开始的时间 - `watchStartNanoTime`。

```java
final long watchStartNanoTime = System.nanoTime();
```

为 `watchedReference` （这里是 activity）生成一个 key，保存在 `retainedKeys` (类型是 `Set<String>`)中。

```java
String key = UUID.randomUUID().toString();
retainedKeys.add(key);
```

如果直接保存 `watchedReference` 的引用会干扰到 GC，所以只能生成一个与 `watchedReference` 本身无关的 `key`，然后通过一个 `KeyedWeakReference` （继承自 `WeakReference<Object>`，多了两个 `String` 类型的字段 - `key`、`name`）保存对应关系。

```java
final KeyedWeakReference reference =
    new KeyedWeakReference(watchedReference, key, referenceName, queue);
```

注意这里创建 `KeyedWeakReference reference` 时传入了一个变量 `queue`：

```java
private final ReferenceQueue<Object> queue;
```

这个 `queue` 其实就是检测内存泄露的关键，我们先来看 *WeakReference.java* 的源码：
```java
public class WeakReference<T> extends Reference<T> {
  public class WeakReference<T> extends Reference<T> {
    public WeakReference(T r) {
      super(r, null);
  }
  public WeakReference(T r, ReferenceQueue<? super T> q) {
    super(r, q);
  }
}
```

第一个构造方法 - `WeakReference(T r)` 是我们最常用的方式，除此之外还有一个带 `ReferenceQueue` 的构造方法。

`WeakReference` 的原理注释里解释得很清楚。

> 当 GC 检测到对象 `obj` 变成 **weakly-reachable** 后会执行如下操作：

> * 所有与 `obj` **相关的 weak references** 都会被保存到一个 Set - `ref` 中 。其中**相关的 weak references** 包括：
    * `obj` 自己的 weak references。
    * 所有与 `obj` 相关（strongly or softly reachable）的对象的 weak references。
> * `ref` 中的所有 references 会被自动清理掉。
> * `ref` 中的 weak references 所指向的 **objects** 随时可能被回收。
> * 最后在某个时间点，`ref` 中的所有 references （以及它们的 reference queue）会被 enqueue 到 `ReferenceQueue` 中。

创建好 `KeyedWeakReference` 后，为了不阻塞当前线程，异步执行 `ensureGone`。其中 `watchExecutor` 是构建 `RefWatcher` 时由外部传递进来。

```java
watchExecutor.execute(new Runnable() {
  @Override public void run() {
    ensureGone(reference, watchStartNanoTime);
  }
});
```

ensureGone 方法
---

记录 GC 的开始时间，并计算 watch 所花费的时间。
```java
long gcStartNanoTime = System.nanoTime();
long watchDurationMs = NANOSECONDS.toMillis(gcStartNanoTime - watchStartNanoTime);
```

从 `retainedKeys` 中清除可以被回收的 `obj` 对应的 `key`。（如果所有与 `obj` 相关的 weak references 被放到 `queue` 中，说明 `obj` 会被回收掉）

```java
removeWeaklyReachableReferences();
```

```java
private void removeWeaklyReachableReferences() {
  // WeakReferences are enqueued as soon as the object to which they point to becomes weakly
  // reachable. This is before finalization or garbage collection has actually happened.
  KeyedWeakReference ref;
  while ((ref = (KeyedWeakReference) queue.poll()) != null) {
    retainedKeys.remove(ref.key);
  }
}
```

如果 reference 被移出 `retainedKeys`（说明不会发生内存泄漏），或者有 debugger 进来，直接返回。

```
if (gone(reference) || debuggerControl.isDebuggerAttached()) {
  return;
}
```

```java
private boolean gone(KeyedWeakReference reference) {
  return !retainedKeys.contains(reference.key);
}
```

主动触发 GC。

```java
gcTrigger.runGc();
```

```java
/**
 * Called when a watched reference is expected to be weakly reachable, but hasn't been enqueued
 * in the reference queue yet. This gives the application a hook to run the GC before the {@link
 * RefWatcher} checks the reference queue again, to avoid taking a heap dump if possible.
 */
public interface GcTrigger {
  GcTrigger DEFAULT = new GcTrigger() {
    @Override public void runGc() {
      // Code taken from AOSP FinalizationTest:
      // https://android.googlesource.com/platform/libcore/+/master/support/src/test/java/libcore/
      // java/lang/ref/FinalizationTester.java
      // System.gc() does not garbage collect every time. Runtime.gc() is
      // more likely to perform a gc.
      Runtime.getRuntime().gc();
      enqueueReferences();
      System.runFinalization();
    }

    private void enqueueReferences() {
      // Hack. We don't have a programmatic way to wait for the reference queue daemon to move
      // references to the appropriate queues.
      try {
        Thread.sleep(100);
      } catch (InterruptedException e) {
        throw new AssertionError();
      }
    }
  };

  void runGc();
}
```

再次执行 `removeWeaklyReachableReferences()`

```java
removeWeaklyReachableReferences();
```
如果 reference 没有被 enqueued，那么内存泄露就发生了，dump 出 heap，开始分析。

```java
if (!gone(reference)) {
  long startDumpHeap = System.nanoTime();
  long gcDurationMs = NANOSECONDS.toMillis(startDumpHeap - gcStartNanoTime);

  File heapDumpFile = heapDumper.dumpHeap();

  if (heapDumpFile == HeapDumper.NO_DUMP) {
    // Could not dump the heap, abort.
    return;
  }
  long heapDumpDurationMs = NANOSECONDS.toMillis(System.nanoTime() - startDumpHeap);
  heapdumpListener.analyze(
      new HeapDump(heapDumpFile, reference.key, reference.name, excludedRefs, watchDurationMs,
          gcDurationMs, heapDumpDurationMs));
}
```

其中 `heapDumper` 以及 `heapdumpListener` 都是由 `LeakCanary#install` 传递进来，可参考[LeakCanary原理分析](README.md)。
