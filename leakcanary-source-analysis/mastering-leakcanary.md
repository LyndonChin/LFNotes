LeakCanary 原理分析
---
**LeakCanary** 的用法非常简单，如果 SDK 版本 >= ICS，只需要在 `Application` 的 `onCreate` 方法中添加一行代码就搞定。
```java
LeakCanary.install(this);
```
具体用法请参考 [LeakCanary 中文使用说明](http://www.liaohuqiu.net/cn/posts/leak-canary-read-me/)。

我们就从 `LeakCanary#install` 方法开始分析。

LeakCanary#install
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

这里的 `install` 方法使用默认参数 `DisplayLeakService.class`、`AndroidExcludedRefs.createAppDefaults().build()` 通过调用另外一个 `install` 方法，创建了一个 `RefWatcher` ，用于监控 `activity` 的 `references`。

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

这个 `install` 方法会在 `Activity` 执行 `onDestory` 之后立即开始监控当前 `Activity` 的 `reference`，主动触发 GC 之后将 dump 出的 heap 数据通过 `heapDumpListener` 传递给 `AbstractAnalysisResultService` 的实例。

AbstractAnalysisResultService
---

*com/squareup/leakcanary/AbstractAnalysisResultService.java*

`AbstractAnalysisResultService` 是一个继承自 `IntentService` 的抽象类，在 `onHandleIntent` 方法中把 `heapDump` 及 `AnalysisResult` 回调给抽象方法 -  `onHeapAnalyzed`，并在 `onHeapAnalyzed` 执行完成后就删除存储在 `heapDump` 的 `heapDumpFile`。

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

同时 `AbstractAnalysisResultService` 还提供了一个非常 *handy* 的静态方法 - `sendResultToListener`，用于传递参数并启动 Service。这也是 LeakCanary 的代码风格，无论是 `Service` 还是 `Activity` 基本都提供了一个这样的 static 方法。

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

第一个 `install` 方法提供了一个默认的 `AnalysisResultService` 的一个具体实现 - `DisplayLeakService`。

AbstractAnalysisResultService 的子类 DisplayLeakService
---
*com/squareup/leakcanary/DisplayLeakService.java*

`DisplayLeakService` 实现了方法 `onHeapAnalyzed(HeapDump heapDump, AnalysisResult result)`。

首先通过 `LeakCanary` 的静态方法 `leakInfo` 创建一个用于描述 heap analysis result 的字符串 - `leakInfo`。

```java
String leakInfo = leakInfo(this, heapDump, result, true);
```

如果参数 `AnalysisResult` 的 `leakFound` 为 `true`，并且 `failure` 不为 `null`，那么会通过 `renameHeapdump` 方法为 `heapDump.heapDumpFile` 的文件名加上时间戳，并判断 `heapDumpFile` 所在目录下的文件数量，如果多于设定值（默认为 7 个）则删除旧文件，最后通过 `saveResult` 保存文件。

```java
boolean resultSaved = false;
boolean shouldSaveResult = result.leakFound || result.failure != null;
if (shouldSaveResult) {
  heapDump = renameHeapdump(heapDump);
  resultSaved = saveResult(heapDump, result);
}
```

结果保存以后，发送 Notification 通知用户到 `DisplayLeakActivity` 查看结果。

```java
showNotification(this, contentTitle, contentText, pendingIntent);
```

最后给子类一个机会“收拾残局”（上传数据到服务器之类的）。
```java
afterDefaultHandling(heapDump, result, leakInfo);
```


```java
protected void afterDefaultHandling(HeapDump heapDump, AnalysisResult result, String leakInfo) {
  // dummy
}
```

除次之外，第一个 `install` 方法还提供了另外一个参数 `ExcludedRefs`。

ExcludedRefs
---

**LeakCanary** 的 heap analyzer 会寻找 **suspected leaking reference 到 [GC roots](http://stackoverflow.com/questions/6366211/what-are-the-roots)（*一般是 reference tree 的叶子节点*）的最短路径**，但是如果由于路径上的某个节点造成的泄露暂时无法解决，**LeakCanary* 会放弃本次寻找，转而去寻找次短路径。我们应当把这些造成泄漏但是暂时无法解决的节点存储起来，而且最短路径中不能包含这些节点，因为即使报给用户也无法解决，还不如不要浪费时间。

`ExcludedRefs` 就事先记录了这些无法解决的节点 `reference`，类型如下：
```java
public final Map<String, Map<String, Exclusion>> fieldNameByClassName;
public final Map<String, Map<String, Exclusion>> staticFieldNameByClassName;
public final Map<String, Exclusion> threadNames;
public final Map<String, Exclusion> classNames;
public final Map<String, Exclusion> rootClassNames;
```
他们都用 `UnmodifiableMap` 来存储：

```java
ExcludedRefs(BuilderWithParams builder) {
  this.fieldNameByClassName = unmodifiableRefStringMap(builder.fieldNameByClassName);
  this.staticFieldNameByClassName = unmodifiableRefStringMap(builder.staticFieldNameByClassName);
  this.threadNames = unmodifiableRefMap(builder.threadNames);
  this.classNames = unmodifiableRefMap(builder.classNames);
  this.rootClassNames = unmodifiableRefMap(builder.rootClassNames);
}
```

其中 `Exclusion` 是 `reference` 的数据结构：

```java
public final class Exclusion implements Serializable {
  public final String name;
  public final String reason;
  public final boolean alwaysExclude;
  public final String matching;
}
```

`ExcludedRefs` 同时提供了一个 `Builder`，用于构建 `references`。

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

`BuilderWithParams` 实现了 `Builder` 接口用于构建一个 `ExcludedRefs`。

> 这个地方设计好奇怪

`instanceField` 和 `staticField` 的构建方式相同，我们只看 `staticField` 方法。

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

`staticFieldNameByClassName` 的 key 是 `className`，value `excludedFields` 也是一个 Map - `Map<String, ParamsBuilder>`。

`excludedFields` 的 key 是 `fieldName`，value 是一个 `ParamsBuilder`，定义跟 `Exclusion` 一样，也是 `reference` 的数据结构。

`thread`、`clazz`、`rootClass` 的构造方式向同，我们只看 `thread` 方法。

```java
@Override
public BuilderWithParams thread(String threadName) {
  lastParams = new ParamsBuilder("any threads named " + threadName);
  threadNames.put(threadName, lastParams);
  return this;
}
```
`threadNames` 也是一个 map，key 对应 `threadName`, value 是 一个 `ParamsBuilder`。

**LeakCanary** 定义了一个默认的 `ExcludedRefs`，不过构造方式有点特殊，它没有直接继承 `ExcludedRefs`，而是首先定义了一个 `enum` - `AndroidExcludedRefs`，然后通过 `enum` 实例对需要 exclude 的 ref 进行了分类，看代码。

 > **注意**：`AndroidExcludedRefs` 是一个 `enum`，并没有继承 `ExcludedRefs`。

 首先是 `AndroidExcludedRefs` 全貌：

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

>`EnumSet` 是一个以 `enum` 为 key 的 `set`

看完第一个 `install` 方法提供的两个默认参数之后再继续看
第二个 `install` 方法。

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

`isInAnalyzerProcess` 用于保证 `application` 跟 `HeapAnalyzerService` 不是同一个线程，如果分析和监控在同一个线程会影响到 `application` 的内存状态，直接返回一个空的 `RefWatcher`，什么都不做。

通过 `AndroidManifest.xml` 可以看出 `HeapAnalyzerService` 是一个单独的 process。

```java
<service
    android:name=".internal.HeapAnalyzerService"
    android:process=":leakcanary"
    android:enabled="false"
    />
```

顺便看一下 `enableDisplayLeakActivity(application)` 做了哪些事。

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

> 看名字 `fileIoExecutor` 是一个单线程的用于 IO 操作的 `Executor`，不知道为什么要用它执行 `setEnabledBlocking`，而且为什么 enable 一个 component，没搞懂。

`enableDisplayLeakActivity` 执行完之后，创建了一个 `HeapDump.Listener` 的实例。

```java
HeapDump.Listener heapDumpListener = new ServiceHeapDumpListener(application, listenerServiceClass);
```

HeapDump
---

`HeapDump` 用于存储被 dump 出的 heap 信息（未分析），它包含了如下内容：

* `File heapDumpFile` - dump 文件（可上传到服务器）
* `String referenceKey` - [RefWatcher](refwatcher-details.md) 会为 `Reference` 创建一个带 key 和 name 的 `WeakReference`
* `String referenceName` - `Reference` 的 name
* `ExcludedRefs excludedRefs` - 前面已经分析过了，用于计算最短引用路径时需要排除的节点
* `long watchDurationMs` - 从开始 watch 到 GC 开始之前的时间
* `long gcDurationMs` - GC 持续时间
* `long heapDumpDurationMs` - dump heap 所花费时间

`HeapDump.Listener` 是 `HeapDump` 的一个内部类，用于回调分析 heap。

```java
public interface Listener {
  void analyze(HeapDump heapDump);
}
```

`ServiceHeapDumpListener`  实现了 `HeapDump.Listener`。

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

构造方法中 enable 了两个 `intentService`：

* `listenerServiceClass` - `install` 方法传进来的是 `DisplayLeakService`，用于通知用户分析结果
* `HeapAnalyzerService` - 用于 `runAnalysis`

知道了 `HeapAnalyzerService` 运行在一个单独的 process 之后再来看它的实现。

HeapAnalyzerService
---

静态方法 `runAnalysis` 启动了 `HeapAnalyzerService`，并把 `heapDump` 和 `listenerServiceClass` 传递给它。

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

`heapAnalyzer.checkForLeak` 后面再分析，先来看 `AbstractAnalysisResultService#sendResultToListener`，
它是一个 static 方法，因此无法多态，但是其中一个参数是 `String listenerServiceClassName`，有了 class name 就可以通过 `Class.forName` 找到对应的 class，进而创建一个 `Intent`，启动 `DisplayLeakService`。

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

通过以上分析可知，**`ServiceHeapDumpListener` 在 `HeapDump` 创建之后通过 `analyze` 方法启动了 `HeapAnalyzerService`，而 `HeapAnalyzerService` 在分析完 heap dump file 之后又启动了 `DisplayLeakService`**。

那 `analyze` 是什么时候被调用的呢？再回到 `LeakCanary#install` 方法，创建了 `heapDumpListener` 之后又通过静态方法 `androidWatcher` 创建了一个 `RefWatcher` 实例。

```java
HeapDump.Listener heapDumpListener = new ServiceHeapDumpListener(application, listenerServiceClass);
RefWatcher refWatcher = androidWatcher(application, heapDumpListener, excludedRefs)
```

创建RefWatcher
---

来分析一下 Android 的 `RefWatcher` 是如何被创建出来的。

```java
public static RefWatcher androidWatcher(Context context, HeapDump.Listener heapDumpListener,
    ExcludedRefs excludedRefs) {
  LeakDirectoryProvider leakDirectoryProvider = new DefaultLeakDirectoryProvider(context);
  DebuggerControl debuggerControl = new AndroidDebuggerControl();
  AndroidHeapDumper heapDumper = new AndroidHeapDumper(context, leakDirectoryProvider);
  heapDumper.cleanup();
  Resources resources = context.getResources();
  int watchDelayMillis = resources.getInteger(R.integer.leak_canary_watch_delay_millis);
  AndroidWatchExecutor executor = new AndroidWatchExecutor(watchDelayMillis);
  return new RefWatcher(executor, debuggerControl, GcTrigger.DEFAULT, heapDumper,
      heapDumpListener, excludedRefs);
}
```

LeakDirectoryProvider
---

`LeakDirectoryProvider` 是一个用于存储 heap dumps & analysis result 的 interface，除此之外它还定义了用于获取权限的方法。

```java
public interface LeakDirectoryProvider {

  /** Returns a path to an existing directory were leaks can be stored. */
  File leakDirectory();

  void requestWritePermissionNotification();

  void requestPermission(Activity activity);

  /** True if we can currently write to the leak directory. */
  boolean isLeakStorageWritable();
}
```

`DefaultLeakDirectoryProvider` 默认的 leak directory 位于 **Download/leakcanary-APP包名（ApplicationId）**。

```java
@Override
public File leakDirectory() {
  File downloadsDirectory = Environment.getExternalStoragePublicDirectory(DIRECTORY_DOWNLOADS);
  File directory = new File(downloadsDirectory, "leakcanary-" + context.getPackageName());
  // ...
}
```

`isLeakStorageWritable` 用于判断是否有 write 权限。

```java
@Override
public boolean isLeakStorageWritable() {
  if (!hasStoragePermission()) {
    return false;
  }
  String state = Environment.getExternalStorageState();
  return Environment.MEDIA_MOUNTED.equals(state);
}

@TargetApi(M)
private boolean hasStoragePermission() {
  if (SDK_INT < M) {
    return true;
  }
  return context.checkSelfPermission(WRITE_EXTERNAL_STORAGE) == PERMISSION_GRANTED;
}
```

DebuggerControl
---

`DebuggerControl` 也是一个 interface，用于判断 debugger 是否 attached，debugger 会持有变量的 reference 因此会干扰分析，`RefWatcher#watch` 检测到 `debuggerControl.isDebuggerAttached()` 为 `true` 会直接返回，不执行 watch 线程。

```java
/**
 * Gives the opportunity to skip checking if a reference is gone when the debugger is connected.
 * An attached debugger might retain references and create false positives.
 */
public interface DebuggerControl {
  DebuggerControl NONE = new DebuggerControl() {
    @Override public boolean isDebuggerAttached() {
      return false;
    }
  };

  boolean isDebuggerAttached();
}
```

`AndroidDebuggerControl` 实现了 `DebuggerControl`。

```java
public final class AndroidDebuggerControl implements DebuggerControl {
  @Override public boolean isDebuggerAttached() {
    return Debug.isDebuggerConnected();
  }
}
```

创建完 `AndroidDebuggerControl` 之后，利用 刚刚创建的 `leakDirectoryProvider` 又创建了一个 `AndroidHeapDumper`。

先来看 `AndroidHeapDumper` 的父类 `HeapDumper`，其功能是把 dump heap 到文件。

HeapDumper
---

```java
public interface HeapDumper {

  File NO_DUMP = null;

  /**
   * @return a {@link File} referencing the heap dump, or {@link #NO_DUMP} if the heap could not be
   * dumped.
   */
  File dumpHeap();
}
```

再来看 `AndroidHeapDumper` 如何利用 `LeakDirectoryProvider` 实现这一功能。

```java
final Context context;
final LeakDirectoryProvider leakDirectoryProvider;
private final Handler mainHandler;
public AndroidHeapDumper(Context context, LeakDirectoryProvider leakDirectoryProvider) {
  this.leakDirectoryProvider = leakDirectoryProvider;
  this.context = context.getApplicationContext();
  mainHandler = new Handler(Looper.getMainLooper());
}
```

构造函数中除了保存 leakDirectoryProvider 和 `Application` 的 context，还 new 了一个主线程的 `mainHandler`。

`dumpHeap` 首先判断 leak directory 是否可写，否的话会请求写权限。

```java
if (!leakDirectoryProvider.isLeakStorageWritable()) {
  CanaryLog.d("Could not write to leak storage to dump heap.");
  leakDirectoryProvider.requestWritePermissionNotification();
  return NO_DUMP;
}
```

这里会有一个问题，如果 `isLeakStorageWritable` 返回 `false` 是因为 external storage 没有挂载，即使申请到了写权限，最终也无法创建 leak directory，并会在 `leakDirectoryProvider#leakDirectory` 方法中抛出异常。

```java
if (!success && !directory.exists()) {
  throw new UnsupportedOperationException(
      "Could not create leak directory " + directory.getPath());
}
```

从代码逻辑上来讲，如果 external storage 没有挂载就不应该去申请权限了，但是这样设计也无可厚非，毕竟未挂载的情况比较少见，而且会使 API 的设计更加简洁。

`leakDirectoryProvider.requestWritePermissionNotification()` 会在通知栏显示一个 `Notification`，然后这个 `Notification` 会把用户带到一个请求专门用于请求权限的 `Activity` - `RequestStoragePermissionActivity`。

如果 `leakDirectoryProvider.isLeakStorageWritable()` 返回 `true`，则通过 `getHeapDumpFile` 获取一个 `File`。

```java
private static final String HEAPDUMP_FILE = "suspected_leak_heapdump.hprof"
File getHeapDumpFile() {
  return new File(leakDirectoryProvider.leakDirectory(), HEAPDUMP_FILE);
}
```

为了避免同一个 App 里的多个进程同时 dump heap，所以要用一个 `Atomic` 方式去创建刚被 new 出来的 `heapDumpFile`。

```java
// Atomic way to check for existence & create the file if it doesn't exist.
// Prevents several processes in the same app to attempt a heapdump at the same time.
boolean fileCreated;
try {
  fileCreated = heapDumpFile.createNewFile();
} catch (IOException e) {
  cleanup();
  CanaryLog.d(e, "Could not check if heap dump file exists");
  return NO_DUMP;
}

if (!fileCreated) {
  CanaryLog.d("Could not dump heap, previous analysis still is in progress.");
  // Heap analysis in progress, let's not put too much pressure on the device.
  return NO_DUMP;
}
```

其中 `cleanUp` 用于清除 `heapDumpFile`：

```java
/**
 * Call this on app startup to clean up all heap dump files that had not been handled yet when
 * the app process was killed.
 */
public void cleanup() {
  LeakCanaryInternals.executeOnFileIoThread(new Runnable() {
    @Override public void run() {
      if (!leakDirectoryProvider.isLeakStorageWritable()) {
        CanaryLog.d("Could not attempt cleanup, leak storage not writable.");
        return;
      }
      File heapDumpFile = getHeapDumpFile();
      if (heapDumpFile.exists()) {
        CanaryLog.d("Previous analysis did not complete correctly, cleaning: %s", heapDumpFile);
        boolean success = heapDumpFile.delete();
        if (!success) {
          CanaryLog.d("Could not delete file %s", heapDumpFile.getPath());
        }
      }
    }
  });
}
```

`heapDumpFile` 创建成功之后会展示一个自定义的 `Toast`，如果 5 秒钟之内 Main Thread 有 idle 状态，则 dump 出一个 [.hprof 文件](http://docs.oracle.com/javase/7/docs/technotes/samples/hprof.html)。

```java
Debug.dumpHprofData(heapDumpFile.getAbsolutePath())
```

*关于弹出 Toast 并等待 5 秒钟的代码可参考 [futureresult-and-its-usage.md]*

创建 `AndroidHeapDumper` 之后，清除其他 process 创建的 heap dump file。

```java
AndroidHeapDumper heapDumper = new AndroidHeapDumper(context, leakDirectoryProvider);
heapDumper.cleanup();
```

然后获取 **watch** 时的延迟时间 - `watchDelayMillis`，并创建一个 **watch** 用的 `executor`。

```java
int watchDelayMillis = resources.getInteger(R.integer.leak_canary_watch_delay_millis);
AndroidWatchExecutor executor = new AndroidWatchExecutor(watchDelayMillis);
```

最后创建一个 `RefWatcher`，`androidWatcher` 的使命结束。

```java
return new RefWatcher(executor, debuggerControl, GcTrigger.DEFAULT, heapDumper,
        heapDumpListener, excludedRefs);
```

`RefWatcher` 应该是 `LeakCanary` 的精髓，负责触发 GC 并 **watch** 一个 reference，
关于它的详细功能请参考 `[refwatcher-details.md]`，我们先回到 `LeakCanary#install` 方法的最后一行：

```java
ActivityRefWatcher.installOnIcsPlus(application, refWatcher);
```

`ActivityRefWatcher` 并不是 `RefWatcher` 的子类，这点需要注意，我们从 `installOnIcsPlus` 方法开始分析。

```java
public static void installOnIcsPlus(Application application, RefWatcher refWatcher) {
  if (SDK_INT < ICE_CREAM_SANDWICH) {
    // If you need to support Android < ICS, override onDestroy() in your base activity.
    return;
  }
  ActivityRefWatcher activityRefWatcher = new ActivityRefWatcher(application, refWatcher);
  activityRefWatcher.watchActivities();
}
```

如果 SDK 版本小于 ICS，那么需要手动在 `onDestroy` 方法中通过 `refWatcher` 来 watch 需要被监控的 `activity`。
ICS 版本 `Application` 类提供了监听 `Activity` 生命周期的方法，方便了许多。

*android/app/Application.java*
```java
public void registerActivityLifecycleCallbacks(ActivityLifecycleCallbacks callback) {
    synchronized (mActivityLifecycleCallbacks) {
        mActivityLifecycleCallbacks.add(callback);
    }
}
```

通过 `Application` 及 `RefWatcher` 构造一个 `ActivityRefWatcher`：
```java
/**
 * Constructs an {@link ActivityRefWatcher} that will make sure the activities are not leaking
 * after they have been destroyed.
 */
public ActivityRefWatcher(Application application, final RefWatcher refWatcher) {
  this.application = checkNotNull(application, "application");
  this.refWatcher = checkNotNull(refWatcher, "refWatcher");
}
```

`ActivityRefWatcher` 实例化之后，通过 `application` 注册 activity life callbacks，

```java
public void watchActivities() {
  // Make sure you don't get installed twice.
  stopWatchingActivities();
  application.registerActivityLifecycleCallbacks(lifecycleCallbacks);
}

public void stopWatchingActivities() {
  application.unregisterActivityLifecycleCallbacks(lifecycleCallbacks);
}
```

在 `watchActivities` 中调用 `stopWatchingActivities` 可以确保即使 `LeakCanary` 被 `install` 了多次，也可以正常监控。

```java
private final Application.ActivityLifecycleCallbacks lifecycleCallbacks =
    new Application.ActivityLifecycleCallbacks() {
      @Override public void onActivityCreated(Activity activity, Bundle savedInstanceState) {
      }

      @Override public void onActivityStarted(Activity activity) {
      }

      @Override public void onActivityResumed(Activity activity) {
      }

      @Override public void onActivityPaused(Activity activity) {
      }

      @Override public void onActivityStopped(Activity activity) {
      }

      @Override public void onActivitySaveInstanceState(Activity activity, Bundle outState) {
      }

      @Override public void onActivityDestroyed(Activity activity) {
        ActivityRefWatcher.this.onActivityDestroyed(activity);
      }
    };
```

每个 `Activity` 在 `onDestory` 之后会调用 `ActivityRefWatcher` 的 `onActivityDestroyed` 方法：

```java
void onActivityDestroyed(Activity activity) {
  refWatcher.watch(activity);
}
```

よし、开启监控。

点击 [详解 RefWatcher](refwatcher-details.md) 了解 `RefWatcher` 原理。
