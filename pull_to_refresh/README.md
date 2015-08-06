Mastering Pull to Refresh
===

## How Android Draws Views

* Drawing the layout is a two pass process: a measure pass and a layout pass.
    * Each view pushes dimension specifications down the tree during the recusion. At the end of the measure pass, every view has stored its measurements.
    * When a view's measure() method returns, its `getMeasuredWidth()` and `getMeasuredHeight()` values must be set, along with those for all of that view's descendants.
* A parent `View` may call `measures()` more than once on its children. 
* The measure pass uses two classes to communicate dimensions.
    * The `ViewGroup.LayoutParams` class is used by `View` objects to tell their parents how they want to be measured and positioned.
        * an exact number
        * `MATCH_PARENT`
        * `WRAP_CONTENT`
    * `MeasureSpec` is use by views to tell their parents how they want to be measured and positioned.
        * `UNSPECIFIED`
        * `EXACTLY`
        * `AT_MOST`
* To initiate a layout, call `requestLayout`. This method is typically called by a view on itself when it believes that it can no longer fit within its current bounds.

---

**[Usage of forceLayout(), requestLayout() and invalidate()](http://stackoverflow.com/questions/13856180/usage-of-forcelayout-requestlayout-and-invalidate)**

![](http://i.stack.imgur.com/MDJXT.png)

---

**[android.view.View](http://developer.android.com/reference/android/view/View.html)**

* View is the base class for *widgets*
* ViewGroup is the base class for *layouts*
* The Android framework is responsible for measuring, laying out and drawing views.

* Creation
    * Constructors
    * `onFinishInflate()` - Called after a view and all of its children has been inflated from XML.
* Layout
    * `onMeasure(int, int)` - Called to **determine the size** requirements for this view and all of its children.
    * `onLayout(boolean, int, int, int, int)` - Called when this view should **assign a size and position** to all of its children.
    * `onSizeChanged(int, int, int, int)` - Called when the size of this view has changed.

* View IDs are at least unique within **the part of the tree** you are searching.
* The geometry of a view is that of a rectangle. A view has a location, expressed as a pair of *left* and *top* coordinates, and two dimensions, expressed as a width and a height.
* A view actually possess two pairs of width and height values.
    * *measured width* and *measured height* - `getMeasuredWidth()` & `getMeasuredHeight()`
    * *drawing width* and *drawing height* - `getWidth()` & `getHeight()`
        * These dimensions define the actual size of the view on screen, at drawing time and after layout.
        * These values may, but do not have to, be different from measured width and height.
* Even though a view can define a padding, it does not provide any support for margins. However, view groups provide such a support.
        * `ViewGroup` and `ViewGroup.MarginLayoutParams`.

* If you set a background drawable for a View, then the View will draw it before calling back to its `onDraw()` method.
* The child drawing order can be overriden with custom child drawing order in a ViewGroup, and with `setZ(float)` custom Z values set on Views.

* Tags are most often used as a convenience to store data related to views in the views themeselves rather than by putting them in a separate structure.

* rendering-related properties

**Security**

* To enable touch filtering, call `setFilterTouchesWhenObscured(boolean)` or set the `android:filterTouchesWhenObscured` layout attribute to true. When enabled, the framework will dicard touches that are received whenever the view's window is obscured by another visible window.
* `onFilterTouchEventForSecurity(MotionEvent)`


## Refs
* **[How Android Draws Views](https://developer.android.com/guide/topics/ui/how-android-draws.html)**


