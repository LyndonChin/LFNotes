MPAndroidCharts 源码解析
===

MPAndroidCharts 功能非常强大，可以满足很多图表需求，但是代码质量不敢恭维，维护成本略大，所以必须要搞懂它，方便二次开发。

MPAndroidCharts 的精髓应该是**通过一系列矩阵运算实现坐标转换、拖动、放大等功能**。

坐标转换
---

Android 的坐标系统与我们常用的坐标系统不同，而用户提供的是基于“标准坐标系”的数据，所以在绘制之前我们必须先进行坐标转换。

*Android 坐标系*
<pre>
                            X
  --------------------------->
  |
  |
  |
  |
  |
  |
  |
Y |
 \|/
</pre>

举例来看，`A(100, 100)`、`B(200, 200)` 两个点在标准坐标系中的位置如下所示：

*标准坐标系*
<pre>
Y ^
  |
  |              B
  |
  |
  |       A
  |
  |
 O|---------------------------->
                               X
</pre>

但是如果我们让原点 O 显示值为 `(xChartMin, yChartMin)` 的点，那么 A 点需要平移（translate）`(-xChartMin, -yChartMin)`。

```
A' = A + (-xChartMin, -yChartMax);
```

我们再假设 Android 坐标系（*一个 View*）的宽度为 `width`，高度为 `height`；**用户数据** X 轴上的最大最小值分别为 `minX`、`maxX`，Y 轴分别为 `minY`、`maxY`。 那么我们可以计算出**坐标值**与**用户数据**的比值：

```java
float deltaX = maxX - minX;
float detalY = maxY - minY;
float scaleX = width / detalX;
float scaleY = height / detalY;
```

然后通过公式 `A * (scaleX, scaleY)` 就可以计算出 A 点对应的**坐标值**。

除此之外 Android 坐标系的 Y 轴与标准坐标系方向相反，所以 `scaleY` 还要乘以 `-1`：

```
A'' = A' * (scaleX, -scaleY)
```

但是这样仅仅是完成了数值转换，并没有完成显示功能。现在 A B 在 Android 坐标系的显示情况如下：

<pre>
  |
  |              B''
  |              .
  |              .
  |       A''    .
  |       .      .
  |       .      .
  |       .      .          X （上部超出 View 范围，无法绘制）
O --------------------------->
  |       .      .           *
  |       .      .           h
  |       .      .           e
  |       A'     .           i
  |              .           g
  |              .           h
  |              B'          t
Y |                          *
 \|/                         *
</pre>

上图中 X 轴以上的部分由于超出 View 边界，无法绘制，所以我们还需要对 A'' 和 B'' 在 Y 轴进行平移。

（**想象把 X 轴往下移动了 `height` 的距离，A'' 和 B'' 会跟着移动相同距离**）

```
A''' = A'' + (0, height)
B''' = B'' + (0, height)
```

最终的对应关系如下所示：

<pre>

  标准坐标系                            Android 坐标系

  ^                                    |------------------------------>
  |                                    |
  |                                    |
  |               B.. .. .. .. .. .. .. .. .. .. .. ..B'''
  |                                    |
  |                                    |
  |        A.. .. .. .. .. .. .. .. .. |.. .. ..A'''
  |                                    |
  |                                    |
  |--------------------------->       \|/
</pre>

其实 MPAndroidCharts 还定义了一个 `ViewPortHandler` 用于处理绘图区域。

<pre>
                                      X
  -------------------------------------->
  |            top offset             |
  |                                   |
  | l    * * * * * * * * * * * *    r |
  | e    *                     *    i |
  | f    *                     *    g |
  | t    *                     *    h |
  |      *                     *    t |
  | o    *       VIEW PORT     *      |
  | f    *                     *    o |
  | f    *                     *    f |
  | s    *                     *    f |
  | e    *                     *    s |
  | t    * * * * * * * * * * * *    e |
  |                                 t |
  |            bottom offset          |
  |-----------------------------------|
Y |
 \|/

</pre>

那么 A''、B'' 的位移应该由  `(0, height)` 改为 `(leftOffset, height - bottomOffset)`。

```
A''' = A'' + (leftOffset, height - bottomOffset)
B''' = B'' + (leftOffset, height - bottomOffset)
```

结合代码来看，首先是从用户数据到 **VIEW PORT** 坐标值的转换。

*com.github.mikephil.charting.utils.Transformer.java*

```java
protected Matrix mMatrixValueToPx = new Matrix();
public void prepareMatrixValuePx(float xChartMin, float deltaX, float deltaY, float yChartMin) {
  // 计算缩放倍数
  float scaleX = mViewPortHandler.contentWidth() / deltaX;
  float scaleY = mViewPortHandler.contentHeight() / deltaY;

  if (Float.isInfinite(scaleX)) scaleX = 0;
  if (Float.isInfinite(scaleY)) scaleY = 0;

  mMatrixValueToPx.reset();
  // 坐标原点设为 (xChartMin, yChartMin) 
  mMatrixValueToPx.postTranslate(-xChartMin, -yChartMin);
  // Y 轴翻转
  mMatrixValueToPx.postScale(scaleX, -scaleY);
}
```

```java
public void prepareMatrixOffset(boolean inverted) {
protected Matrix mMatrixOffset = new Matrix();
  mMatrixOffset.reset();
  if (inverted) { // 翻转 Y 轴
    mMatrixOffset.setTranslate(mViewPortHandler.offsetLeft(), -mViewPortHandler.offsetTop());
    mMatrixOffset.postScale(1.0f, -1.0f);
  } else {
    // offset 位移
    mMatrixOffset.postTranslate(mViewPortHandler.offsetLeft(), 
                        mViewPortHandler.getChartHeight() - mViewPortHandler.offsetBottom());
  }
}
```

`mMatrixValueToPx` 负责用户数据到坐标值，而`mMatrixOffset` 负责把坐标值位移到 **VIEW PORT**。 

MPAndroidCharts 的**手势操作**也是基于矩阵转换，而手势矩阵作用于整个 `Chart`，所以必须要手势矩阵完成之后才能进行 offset 位移。

<pre>
坐标矩阵 -> 手势矩阵 -> 位移矩阵
</pre>

继续看 `Transformer` 提供的方法：

*用户数值转换为最终坐标值*
```java
public void pointValuesToPixel(float[] pts) {
  // value to pixel
  mMatrixValueToPx.mapPoints(pts);
  // gesture
  mViewPortHandler.getMatrixTouch().mapPoints(pts);
  // offset
  mMatrixOffset.mapPoints(pts);
}
```



