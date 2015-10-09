## awesome summary

* http://blog.danlew.net/2014/03/30/android-tips-round-up-part-1/
* [Space](http://developer.android.com/reference/android/widget/Space.html)
    * Lightweight View which skips drawing. Great for any situation that might require a placeholder.

## 获取 Action Bar 高度

```java
int getActionBarHeight() {
    int actionBarHeight = 0;
    final TypedValue tv = new TypedValue();
    if (getContext().getTheme().resolveAttribute(android.R.attr.actionBarSize, tv, true)) {
        actionBarHeight = TypedValue.complexToDimensionPixelSize(
            tv.data, getContext().getResources().getDisplayMetrics());
    }
    return actionBarHeight;
}
```


## 获取 Status Bar 高度

```java
int getStatusBarHeight() {
    try {
        Class<?> c = Class.forName("com.android.internal.R$dimen");
        Object obj = c.newInstance();
        Field field = c.getField("status_bar_height");
        final int dpSize = Integer.parseInt(field.get(obj).toString());
        statusBarHeight = getResources().getDimensionPixelSize(dpSize);
    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

## WindowManager

```java
```
