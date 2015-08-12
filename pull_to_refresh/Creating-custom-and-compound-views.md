## Creating screenshots (Images) of views

Every `View` class support the creating of an image of its current display.

```java
# Build the Drawing Cache
view.buildDrawingCache();

# Create Bitmap
Bitmap cache = view.getDrawingCache();

# Save Bitmap
saveBitmap(cache);
view.destoryDrawingCache();
```

## Measurement

The layout manager calls the `onMeasure()` method of the view. The view receives the **layout parameter** from the layout manager. A layout manager is responsible to determine the size of all its children.

The view must call the `setMeasureDimension(int, int)` method with the result.

*You can implement your custom layout manager by extending the `ViewGroup` class. It can leave out the time consuming support of `layout_weight` of the `LinearLayout` class.*

To calculate the size of the child you can use the `measureChildWithMargins()` method of the `ViewGroup` class.

## Life cycle

* The `onAttachedToWindow()` is called once the window is available.
* The `onDetachedFromWindow()` is used when the view removed from its parent.


    -----------    -----------    -----------    -----------
    | Animate |--->| Measure |--->|  Layout |--->|  Draws  |
    -----------    -----------    -----------    -----------


## Canvas API

You paint on a `Bitmap` surface. The `Canvas` class provides the drawing methods to draw on a bitmap and the `Paint` clas specifies how you draw on the bitmap.

The `Canvas` object contains the bitmap on which you draw. It also provides methods for drawing operations.

---

Via *Shaders* you can define that the `Paint` is filled with more than one color.

A shader allows to define for a `Paint` object the content which should be drawn. For example you can use a `BitmapShaer` to define that a bitmap should be used to draw. This allows you for example to draw an image with rounded corners. Simply define a `BitmapShader` for you `Paint` object and use the `drawRoundRect()` method to draw a rectangle with rounded corners.  

* `LinearGradient`
* `RadialGradient`
* `SweepGradient`

`Paint.setShader()`

* `Shader.TileMode.CLAMP`
* `Shader.TileMode.MIRROR`
* `Shader.TileMode.REPEAT`

## Persisting View data

Most standard view can save there state so that it can be persisted by the system. The Android system calls the `onSaveInstanceState()` method and the `onRestoreInstanceState(Parceable)` to save and restore the view state.

The conversion is to extend `View.BasedSaveState` as a static inner class in the view for persisting the data.

Android searches based on the ID of the view in the layout for the view and pass a `Bundle` to the view which the view can use to restore its state.

