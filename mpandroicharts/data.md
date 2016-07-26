数据
---

我已经对 Data 相关类的命名方式无力吐槽，先来看一张类图：

![](images/data.png)

`data` `dataset` `Entry` 三者的对应关系如下所示：

<pre>
--------              -----------              ---------
| data | 1 <------> N | dataset | 1 <------> N | entry |
--------              -----------              ---------
</pre>

`data` 是一组 `dataset`，`dataset` 同时是一组 `entry`。

例如下面的折线图：


![](images/linechart.png)

* 一条线就是一个 `dataset`
* 线上的一个点就是一个 `entry`

Entry 显示值
---

每个点上显示的数字叫 `value`，其实就是 `Entry` 的 `x` 值，但是可以通过 `ValueFormatter` 进行值转换。
`IDataSet` 提供了方法设置 `value` 的各种属性。

```java
void setValueFormatter(ValueFormatter f);
void setValueTextColor(int color);
void setValueTextColors(List<Integer> colors);
void setValueTypeface(Typeface tf);
void setValueTextSize(float size);
void setDrawValues(boolean enabled);
```

> To be continued

