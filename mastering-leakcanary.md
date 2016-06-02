LeakCanary 原理分析
---

用法请参考 [LeakCanary 中文使用说明](http://www.liaohuqiu.net/cn/posts/leak-canary-read-me/)。

LeakCanary 的用法非常简单，只需要在 `onApplication#onCreate` 中添加一行代码就可以了。

```java
LeakCanary.install(this);
```

我们就顺着 `install` 方法看下去。

install
---

*com/squareup/leakcanary/LeakCanary.java*

```java
/**
  * Creates a {@link RefWatcher} that works out of the box, and starts watching activity
  * references (on ICS+).
  */
public static RefWatcher install(Application application) {
  return install(application, DisplayLeakService.class,
      AndroidExcludedRefs.createAppDefaults().build());
}
```

`install` 方法创建了一个 `RefWatcher` 用于监控 `activity` 的 `references`。

这里的 `install` 方法使用默认参数 `DisplayLeakService.class`、`AndroidExcludedRefs.createAppDefaults().build()` 调用了另外一个 `install` 方法。

```java
/**
 * Creates a {@link RefWatcher} that reports results to the provided service, and starts watching
 * activity references (on ICS+).
 */
public static RefWatcher install(Application application,
    Class<? extends AbstractAnalysisResultService> listenerServiceClass,
    ExcludedRefs excludedRefs) {
  if (isInAnalyzerProcess(application)) {
    return RefWatcher.DISABLED;
  }
  enableDisplayLeakActivity(application);
  HeapDump.Listener heapDumpListener =
      new ServiceHeapDumpListener(application, listenerServiceClass);
  RefWatcher refWatcher = androidWatcher(application, heapDumpListener, excludedRefs);
  ActivityRefWatcher.installOnIcsPlus(application, refWatcher);
  return refWatcher;
}
```

带三个参数的 `install` 方法会将检测结果传递给通过 `listenerServiceClass` 创建的实例。

传递结果
---

*com/squareup/leakcanary/AbstractAnalysisResultService.java*

`AbstractAnalysisResultService` 是一个抽象类，继承自 `IntentService`，在 `onHandleIntent` 方法中把 **heapDump** 及 **AnalysisResult** 回调给 `onHeapAnalyzed` 方法，`onHeapAnalyzed` 执行完毕后立即删除 dump 文件。

```java
@Override
protected final void onHandleIntent(Intent intent) {
  HeapDump heapDump = (HeapDump) intent.getSerializableExtra(HEAP_DUMP_EXTRA);
  AnalysisResult result = (AnalysisResult) intent.getSerializableExtra(RESULT_EXTRA);
  try {
    onHeapAnalyzed(heapDump, result);
  } finally {
    heapDump.heapDumpFile.delete();
  }
}

protected abstract void onHeapAnalyzed(HeapDump heapDump, AnalysisResult result);
```

`AbstractAnalysisResultService` 还是提供了一个非常 *handy* 的静态方法 - `sendResultToListener`，用于启动 Service 并传递参数。

```java
public static void sendResultToListener(Context context, String listenerServiceClassName,
    HeapDump heapDump, AnalysisResult result) {
  Class<?> listenerServiceClass;
  try {
    listenerServiceClass = Class.forName(listenerServiceClassName);
  } catch (ClassNotFoundException e) {
    throw new RuntimeException(e);
  }
  Intent intent = new Intent(context, listenerServiceClass);
  intent.putExtra(HEAP_DUMP_EXTRA, heapDump);
  intent.putExtra(RESULT_EXTRA, result);
  context.startService(intent);
}
```

`install` 方法提供了一个默认的 AnalysisResultService - `DisplayLeakService`。

*com/squareup/leakcanary/DisplayLeakService.java*

先来看覆写的方法 - `onHeapAnalyzed`：

```java
@Override
protected final void onHeapAnalyzed(HeapDump heapDump, AnalysisResult result) {
  // leakInfo 是 LeakCanary 提供的一个 static 方法，创建一个描述内存泄露的字符串
  String leakInfo = leakInfo(this, heapDump, result, true);
  CanaryLog.d(leakInfo);

  boolean resultSaved = false;
  // 如果分析出有泄露或者分析失败（result.failure 不为空）则保存 heapDump
  boolean shouldSaveResult = result.leakFound || result.failure != null;
  if (shouldSaveResult) {
    // renameHeapdump 会给 heapDump.heapDumpFile 文件名上加上时间戳；
    // 如果 dump 文件数量多于预先设置的数量（默认是 7 个）则按照时间顺序删除旧文件。
    heapDump = renameHeapdump(heapDump);
    // 把 dump 结果保存到 disk。
    resultSaved = saveResult(heapDump, result);
  }

  // 中间代码省略（构建 Notification 所需要的数据）

  // 通过 Notification 通知用户分析结果，点击后启动 DisplayLeakActivity
  showNotification(this, contentTitle, contentText, pendingIntent);
  afterDefaultHandling(heapDump, result, leakInfo);
}

/**
 * You can override this method and do a blocking call to a server to upload the leak trace and
 * the heap dump.
 */
protected void afterDefaultHandling(HeapDump heapDump, AnalysisResult result, String leakInfo) {
}
```

我们最后再分析显示结果的代码 - `DisplayLeakActivity`，先来看 `install` 方法的另外一个参数 `ExcludedRefs`。

ExcludedRefs
---

LeakCanary 的 heap analyzer 会分析 suspected leaking reference 到 GC roots（一般是 reference tree 的叶子节点）最短路径，具体[可看这里](http://stackoverflow.com/questions/6366211/what-are-the-roots)。
