多进程中的用法
---

如果觉得 `Context.MODE_MULTI_PROCESS` 可以实现多进程共享共享：

```java
context.getSharedPreferences(PREFERENCE_NAME, Context.MODE_MULTI_PROCESS);
```

那么，你错了，大错特错，原因是：

https://stackoverflow.com/questions/27827678/use-sharedpreferences-on-multi-process-mode

所以，用 ContentProvider 吧。

---

* https://zmywly8866.github.io/2015/09/09/sharedpreferences-in-multiprocess.html
* https://stackoverflow.com/questions/27827678/use-sharedpreferences-on-multi-process-mode
