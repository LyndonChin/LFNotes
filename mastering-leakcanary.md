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

LeakCanary 的 heap analyzer 会寻找 suspected leaking reference 到 GC roots（一般是 reference tree 的叶子节点）的最短路径，但是如果由于路径上的某个节点造成的泄露暂时无法解决，我们应当结束本次寻找，转而去寻找次短路径。
那么，那么我们应当把这些造成泄漏但是暂时无法解决的节点存储起来，而且最短路径中不能包含这些 reference。

_关于 GC root 可[查看这里](http://stackoverflow.com/questions/6366211/what-are-the-roots)。_

`ExcludedRefs` 其实就是这些 Reference 的存储器。

Reference 可分为以下几种类型：

* field
* static field
* thread
* class
* root class

```java
public final Map<String, Map<String, Exclusion>> fieldNameByClassName;
public final Map<String, Map<String, Exclusion>> staticFieldNameByClassName;
public final Map<String, Exclusion> threadNames;
public final Map<String, Exclusion> classNames;
public final Map<String, Exclusion> rootClassNames;
```
他们都用 unmodifiable map 来存储：

```java
ExcludedRefs(BuilderWithParams builder) {
  this.fieldNameByClassName = unmodifiableRefStringMap(builder.fieldNameByClassName);
  this.staticFieldNameByClassName = unmodifiableRefStringMap(builder.staticFieldNameByClassName);
  this.threadNames = unmodifiableRefMap(builder.threadNames);
  this.classNames = unmodifiableRefMap(builder.classNames);
  this.rootClassNames = unmodifiableRefMap(builder.rootClassNames);
}
```

其中 `Exclusion` 是节点 reference 的数据结构：

```java
public final class Exclusion implements Serializable {
  public final String name;
  public final String reason;
  public final boolean alwaysExclude;
  public final String matching;
}
```

`ExcludedRefs` 同时提供了一个 `Builder`，用于构建 references。

```java
public interface Builder {
  BuilderWithParams instanceField(String className, String fieldName);
  BuilderWithParams staticField(String className, String fieldName);
  BuilderWithParams thread(String threadName);
  BuilderWithParams clazz(String className);
  BuilderWithParams rootClass(String rootSuperClassName);
  ExcludedRefs build();
}
```

其中 `BuilderWithParams` 实现了 `Builder` 接口（*这个地方设计好奇怪*）用于构建一个 `ExcludedRefs`。

**instanceField** 和 **staticField** 的构建方式相同，我们只看 `staticField` 方法。

```java
@Override
public BuilderWithParams staticField(String className, String fieldName) {
  Map<String, ParamsBuilder> excludedFields = staticFieldNameByClassName.get(className);
  if (excludedFields == null) {
    excludedFields = new LinkedHashMap<>();
    staticFieldNameByClassName.put(className, excludedFields);
  }
  lastParams = new ParamsBuilder("static field " + className + "#" + fieldName);
  excludedFields.put(fieldName, lastParams);
  return this;
}
```

`staticFieldNameByClassName` 的 key 是 `className`，value 是 `excludedFields`，也是一个 Map - `Map<String, ParamsBuilder>`。

`excludedFields` 的 key 是 `fieldName`，value 是一个 `ParamsBuilder`，定义跟 `Exclusion` 一样，也代表 reference 节点。

**thread**、**clazz**、**rootClass** 的构造方式向同，我们只看 `thread` 方法。

```java
@Override
public BuilderWithParams thread(String threadName) {
  lastParams = new ParamsBuilder("any threads named " + threadName);
  threadNames.put(threadName, lastParams);
  return this;
}
```
`threadNames` 也是一个 map，key 对应 `threadName`, value 是 `ParamsBuilder` 类型的 reference 节点。

 LeakCanary 也提供了一个默认的 `ExcludedRefs`，不过构造方式有点特殊，它没有直接继承 `ExcludedRefs`，而是首先定义了一个 enum 类型的类 - `AndroidExcludedRefs`，然后通过 enum 的变量对需要 exclude 的 ref 进行了分类，我们可以通过代码具体来看。

 _**注意**：`AndroidExcludedRefs` 是一个 enum，并没有继承 `ExcludedRefs`。_

 首先是 enum 的全貌：

```java
public enum AndroidExcludedRefs {
  ACTIVITY_CLIENT_RECORD__NEXT_IDLE(SDK_INT >= KITKAT && SDK_INT <= LOLLIPOP) {
    @Override void add(ExcludedRefs.Builder excluded) {
      excluded.instanceField("android.app.ActivityThread$ActivityClientRecord", "nextIdle")
          .reason("Android AOSP sometimes keeps a reference to a destroyed activity as a"
              + " nextIdle client record in the android.app.ActivityThread.mActivities map."
              + " Not sure what's going on there, input welcome.");
    }
  },

  // 其他 enum instances 省略

  /**
   * This returns the references in the leak path that should be ignored by all on Android.
   */
  public static ExcludedRefs.Builder createAndroidDefaults() {
    return createBuilder(
        EnumSet.of(SOFT_REFERENCES, FINALIZER_WATCHDOG_DAEMON, MAIN, LEAK_CANARY_THREAD,
            EVENT_RECEIVER__MMESSAGE_QUEUE, SERVICE_BINDER));
  }
  /**
   * This returns the references in the leak path that can be ignored for app developers. This
   * doesn't mean there is no memory leak, to the contrary. However, some leaks are caused by bugs
   * in AOSP or manufacturer forks of AOSP. In such cases, there is very little we can do as app
   * developers except by resorting to serious hacks, so we remove the noise caused by those leaks.
   */
  public static ExcludedRefs.Builder createAppDefaults() {
      return createBuilder(EnumSet.allOf(AndroidExcludedRefs.class));
  }

  public static ExcludedRefs.Builder createBuilder(EnumSet<AndroidExcludedRefs> refs) {
      ExcludedRefs.Builder excluded = ExcludedRefs.builder();
      for (AndroidExcludedRefs ref : refs) {
        if (ref.applies) {
          ref.add(excluded);
          ((ExcludedRefs.BuilderWithParams) excluded).named(ref.name());
        }
      }
      return excluded;
  }

  final boolean applies;

  AndroidExcludedRefs() {
    this(true);
  }

  AndroidExcludedRefs(boolean applies) {
    this.applies = applies;
  }

  abstract void add(ExcludedRefs.Builder excluded);
}
```

*`EnumSet` 是一个以 enum 为 key 的 set*

---

再回到 `install` 方法。

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
`HeapAnalyzerService` 是一个单独的 process。

```java
<service
    android:name=".internal.HeapAnalyzerService"
    android:process=":leakcanary"
    android:enabled="false"
    />
```
`isInAnalyzerProcess` 用于保证 `application` 跟 `HeapAnalyzerService` 不是同一个线程，如果分析和监控在同一个线程会影响到 `application` 的内存状态。

如果 `application` 跟 `HeapAnalyzerService` 是同一个 process，则返回一个空的 `RefWatcher`，什么都不做。

来看一下 `enableDisplayLeakActivity(application)` 做了哪些事。

```java
public static void enableDisplayLeakActivity(Context context) {
  setEnabled(context, DisplayLeakActivity.class, true);
}
```

其中 `setEnabled` 是类 `LeakCanaryInternals` 的一个 `static` 方法：

```java
public static void setEnabled(Context context, final Class<?> componentClass,
    final boolean enabled) {
  final Context appContext = context.getApplicationContext();
  executeOnFileIoThread(new Runnable() {
    @Override public void run() {
      setEnabledBlocking(appContext, componentClass, enabled);
    }
  });
}

private static final Executor fileIoExecutor = newSingleThreadExecutor("File-IO");
public static void executeOnFileIoThread(Runnable runnable) {
  fileIoExecutor.execute(runnable);
}
```

`setEnabledBlocking` 用于使能一个 `component`：

```java
public static void setEnabledBlocking(Context appContext, Class<?> componentClass,
    boolean enabled) {
  ComponentName component = new ComponentName(appContext, componentClass);
  PackageManager packageManager = appContext.getPackageManager();
  int newState = enabled ? COMPONENT_ENABLED_STATE_ENABLED : COMPONENT_ENABLED_STATE_DISABLED;
  // Blocks on IPC.
  packageManager.setComponentEnabledSetting(component, newState, DONT_KILL_APP);
}
```

`HeapDump` 用于存储被 dump 出的 heap 信息（未分析），它包含了如下内容：

* `File heapDumpFile` - dump 文件名，可上传到服务器
* `String referenceKey` - RefWatcher 会给需要监控的 Reference 创建一个带了 key 和 name 的 `WeakReference`
* `String referenceName` - Reference 的 name
* `ExcludedRefs excludedRefs` - 前面已经分析过了，用于计算最短引用路径时需要排除的节点
* `long watchDurationMs` - 从 watch request 开始到 gc 之前的时间
* `long gcDurationMs` - gc 持续时间
* `long heapDumpDurationMs` - dump heap 所花费时间

`HeapDump` 还定义了一个内部类 - `Listener`，用于回调分析 heap。

```java
public interface Listener {
  void analyze(HeapDump heapDump);
}
```

---

`RefWatcher#install` 在 `enableDisplayLeakActivity` 之后创建了一个 `heapDumpListener`。

```java
HeapDump.Listener heapDumpListener = new ServiceHeapDumpListener(application, listenerServiceClass);
```

其中 `ServiceHeapDumpListener` 继承自 `HeapDump.Listener`。

```java
public final class ServiceHeapDumpListener implements HeapDump.Listener {

  private final Context context;
  private final Class<? extends AbstractAnalysisResultService> listenerServiceClass;

  public ServiceHeapDumpListener(Context context,
      Class<? extends AbstractAnalysisResultService> listenerServiceClass) {
    setEnabled(context, listenerServiceClass, true);
    setEnabled(context, HeapAnalyzerService.class, true);
    this.listenerServiceClass = checkNotNull(listenerServiceClass, "listenerServiceClass");
    this.context = checkNotNull(context, "context").getApplicationContext();
  }

  @Override public void analyze(HeapDump heapDump) {
    checkNotNull(heapDump, "heapDump");
    HeapAnalyzerService.runAnalysis(context, heapDump, listenerServiceClass);
  }
}
```

构造方法中 enable 了两个 intentService：

* `listenerServiceClass` - `install` 方法传进来的是 `DisplayLeakService`，用于通知用户分析结果
* `HeapAnalyzerService` - 用于 `runAnalysis`

你耕田来我织布，你分析来我通知，

---

继续看 `HeapAnalyzerService` 的实现。

静态方法 `runAnalysis` 启动了 `HeapAnalyzerService`，并把 heapDump 和 listenerServiceClass 传递给它。

```java
private static final String LISTENER_CLASS_EXTRA = "listener_class_extra";
private static final String HEAPDUMP_EXTRA = "heapdump_extra";

public static void runAnalysis(Context context, HeapDump heapDump,
    Class<? extends AbstractAnalysisResultService> listenerServiceClass) {
  Intent intent = new Intent(context, HeapAnalyzerService.class);
  intent.putExtra(LISTENER_CLASS_EXTRA, listenerServiceClass.getName());
  intent.putExtra(HEAPDUMP_EXTRA, heapDump);
  context.startService(intent);
}
```

在异步方法 `onHandleIntent` 创建一个 heap analyzer，然后 check for leak，最后把分析结果通过 `AbstractAnalysisResultService` 的静态方法 `sendResultToListener` 交给 `DisplayLeakService`。

```java
HeapAnalyzer heapAnalyzer = new HeapAnalyzer(heapDump.excludedRefs);
AnalysisResult result = heapAnalyzer.checkForLeak(heapDump.heapDumpFile, heapDump.referenceKey);
AbstractAnalysisResultService.sendResultToListener(this, listenerClassName, heapDump, result)
```

`heapAnalyzer.checkForLeak` 在原理部分再做分析，先来看 `AbstractAnalysisResultService#sendResultToListener`，
它是一个 static 方法，因此无法多态，但是其中一个参数是 `String listenerServiceClassName`，有了 `DisplayLeakService` （继承自 `AbstractAnalysisResultService`）的 class name 就可以通过 `Class.forName` 找到对应的 class，进而创建一个 `Intent`，启动 `DisplayLeakService`。

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

通过以上分析可知，**`ServiceHeapDumpListener` 在 `HeapDump` 创建之后通过 `analyze` 方法启动了 HeapAnalyzerService，而 HeapAnalyzerService 在分析完 heap dump file 之后又启动了 `DisplayLeakService`**。

那 `analyze` 是什么时候被调用的呢？再回到 `LeakCanary#install` 方法。

---

新建了一个 `heapDumpListener` 之后又通过静态方法 `androidWatcher` 创建了 `RefWatcher`。

```java
HeapDump.Listener heapDumpListener = new ServiceHeapDumpListener(application, listenerServiceClass);
RefWatcher refWatcher = androidWatcher(application, heapDumpListener, excludedRefs)
```
