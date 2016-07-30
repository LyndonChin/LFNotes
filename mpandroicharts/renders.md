渲染器
---

*类关系图*

![](images/renderer.png)

由上图可以看出，`Renderer` 是所有渲染器的**基类**，它引用了一个 `ViewPortHandler`：

```java
protected ViewPortHandler mViewPortHandler;
```

`mViewPortHandler` 作为 `Chart` 的可视区域，在 [坐标转换](coordinate-transformations.md)一节已经分析过了，数据的渲染（`DataRenderer` 的子类）必须要在 `ViewPort` 范围内进行。

先来看 `Renderer` 的第一个子类 - `DataRenderer`。

### DataRenderer

`DataRenderer` 有一个动画变量 `mAnimator`，当需要渐进绘制图表时，可以通过 `ChartAnimator` 的两个成员变量来控制进度。

```java
public class ChartAnimator {

  /** the phase that is animated and influences the drawn values on the y-axis */
  protected float mPhaseY = 1f;

  /** the phase that is animated and influences the drawn values on the x-axis */
  protected float mPhaseX = 1f;
}
```

当动画开始时 `mPhaseY` 或 `mPhaseX` 通过 `ObjectAnimator` 从 0 渐变到 1。

*com.github.mikephil.charting.animation.ChartAnimator*
```java
ObjectAnimator animatorY = ObjectAnimator.ofFloat(this, "phaseY", 0f, 1f);
ObjectAnimator animatorX = ObjectAnimator.ofFloat(this, "phaseX", 0f, 1f);
```

这样可以在动画过程中很方便地计算 x y：

```java
float x = entry.getX() * mAnimator.getPhaseX();
float y = entry.getY() * mAnimator.getPhaseY();
```

除了 `mAnimator`，`DataRenderer` 还提供了绘制必须要用到的 `Paint`。

再来看另外一个子类。

### LegendRenderer

*Legend 示例*

![](images/legendsample.png)

在绘制之前要根据 `ChartData` 计算出图表种每一组 `DataSet` 的 `color` 和 `label`。

```java
public void computeLegend(ChartData<?> data);
```

它的调用栈如下所示：

<pre>
LegendRenderer#computeLegend(mData)
              ^
              |
BarLineChartBase#notifyDataSetChanged()
              ^
              |
Chart#setData(T data)
</pre>

`computeLegend` 执行完毕之后会输出 `color` 和 `label` 的数组。

```java
protected List<String> mLabels = new ArrayList<>(16);
protected List<Integer> mColors = new ArrayList<>(16);
```

数据计算完成之后开始渲染。

```java
public void renderLegend(Canvas c);
```

它的调用栈如下：

<pre>
LegendRenderer#renderLegend(canvas);
              ^
              |
BarLineChartBase#onDraw(Canvas canvas)
</pre>

AxisRenderer
---

`AxisRenderer` 是**坐标轴**渲染器，除了渲染对象 `AxisBase` 实例之外，它还定义了绘图所需要的四个 `Paint`，当然还有绘图必不可少的坐标转换器 - `Transformer`。

```java
protected AxisBase mAxis; // 渲染对象
protected Transformer mTrans; // 坐标转换

protected Paint mGridPaint; // 图表网格
protected Paint mAxisLabelPaint; // 坐标 Label
protected Paint mAxisLinePaint; // 坐标线
protected Paint mLimitLinePaint; // 图表所需 Limit Line
```

`AxisRenderer` 会根据父类定义的成员变量 - `ViewPortHandler` 去计算出绘图区域中左上角（点p1）和左下角（点p2）分别对应的**真实值**（非坐标值）。

```java
MPPointD p1 = mTrans.getValuesByTouchPoint(mViewPortHandler.contentLeft(), mViewPortHandler.contentTop());
MPPointD p2 = mTrans.getValuesByTouchPoint(mViewPortHandler.contentLeft(), mViewPortHandler.contentBottom());
```

`Transfromer#getValuesByTouchPoint` 可以把坐标值转换成真实值，[坐标转换](coordinate-transformations.md) 一节已经讲解过转换原理。

如果 Y 轴不翻转，那么 `p1.y` 就是最大值，`p2.y` 是最小值。

```java
if (!inverted) {
  min = (float) p2.y;
  max = (float) p1.y;
} else {
  min = (float) p1.y;
  max = (float) p2.y;
}
```

然后根据 `max` `min` 计算出坐标轴 `mAxis` 上的**点** - `computeAxisValues(float min, float max)`。

首先根据用户设定的 `labelCount` 计算出每个 `label` 的间隔值 - `interval`。

```java
int labelCount = mAxis.getLabelCount();
double range = Math.abs(max - min);
double rawInterval = range / labelCount;
double interval = Utils.roundToNextSignificant(rawInterval);
```

`roundToNextSignificant` 会根据四舍五入向量级取整：

```
15001 ->20000.0 
14999 ->10000.0
```

如果用户指定了 `Granularity` 那么就取两者最大值，主要为了解决 `label` 多而 `range` 小的情况会显示过密。

```java
if (mAxis.isGranularityEnabled()) {
  interval = Math.max(interval, mAxis.getGranularity());
}
```

如果 `interval` 的最高位数字 > 5 就升高一个量级，例如 65001 变为 100000。

```java
double intervalMagnitude = Utils.roundToNextSignificant(Math.pow(10, (int) Math.log10(interval)));
int intervalSigDigit = (int) (interval / intervalMagnitude);
if (intervalSigDigit > 5) {
  interval = Math.floor(10 * intervalMagnitude);
}
```

如果用户设定了必须要绘制 `labelCount` 个 label，那么绘制方式如下所示：

<pre>
                  axis
            label5 *
                   * 
      (max) ------ *
                   *
            label4 * 
                   *
                   *
                   *
            label3 *---------------------------------
                   *
                   *  step = range / (labelCount - 1)
                   *
            label2 *----------------------------------
                   *
                   *
                   *
 (min+step) label1 *
                   *
                   *
                   *
      (min) label0 *
</pre>

计算结果为：

```java
mAxis.mEntries = new float[] {label0, label1, label2, label3, label4, label5};
mAxis.mEntryCount = labelCount;
```

这样做可能 `label5` 的值会超出 `max` 值。

如果没有强制 label 的个数，那么最小值和最大值都会换算成 `interval` 的倍数。

```java
double first = interval == 0.0 ? 0.0 : Math.ceil(yMin / interval) * interval;
double last = interval == 0.0 ? 0.0 : Utils.nextUp(Math.floor(yMax / interval) * interval);
```

绘制效果如下所示：

<pre>
                 axis
   (max) ----------*
   (last)   label3 *
                   *
                   *
                   *
            label2 *-----------
                   *
                   * interval
                   *
            label1 *-----------
                   *
                   *
                   *
   (first)  label0 *
   (min) --------- *
</pre>

这样可以保证 `label` 位于 `(min, max)` 区间内。

然后设置一下小数点位数：

```java
if (interval < 1) {
  mAxis.mDecimals = (int) Math.ceil(-Math.log10(interval));
} else {
  mAxis.mDecimals = 0;
}
```

如果要居中显示 label，那么 `n = labelCount + 1`，label 坐标上移 `offset`。

```java
boolean centeringEnabled = mAxis.isCenterAxisLabelsEnabled();
```

```java
float offset = (mAxis.mEntries[1] - mAxis.mEntries[0]) / 2f;
for (int i = 0; i < n; i++) {
  mAxis.mCenteredEntries[i] = mAxis.mEntries[i] + offset;
}
```

---

`AxisRenderer` 只负责计算，渲染的“脏活累活”就交给子类去做吧。

```java
public abstract void renderAxisLabels(Canvas c);
public abstract void renderGridLines(Canvas c);
public abstract void renderAxisLine(Canvas c);
public abstract void renderLimitLines(Canvas c);
```
