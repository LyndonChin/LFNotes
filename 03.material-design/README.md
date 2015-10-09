## Color Scheme
```xml
<item name="colorPrimary">#2196F3</item>
<item name="colorPrimaryDark">#1565C0</item>
<item name="colorAccent">#E91E63</item>
```
## Dependency
```groovy
compile 'com.android.support:design:22.2.0'
```
> NOTE: Design Support Library depends on *Support V4* and *AppCompat v7*. Once you include this library in your project, you will also gain an access to those libraries' components.

## Widgets

[Sample Using Design Support Library](https://github.com/chrisbanes/cheesesquare)

### FloatingActionButton

* `app:fabSize="normal"` =&gt;56dp
* `app:fabSize="mini"` =&gt;40dp
* `app:borderWidth="0"`

**Use Configuration Qualifier to Define dimens**

* res/values/dimens.xml
* res/values-21/dimens.xml

> The depth is automatically set to the best practices one, 6dp at idle state and 12dp at pressed state.

* `app:elevation`
* `app:pressedTranslationZ`
* `app:backgroundTint` to override the accent color

### Toolbar

* `app:popupTheme="@style/ThemeOverlay.AppCompat.Light"`
* `app:theme="@style/ThemeOverlay.AppCompat.Dark.ActionBar"`

### AppBarLayout

```xml
<android.support.design.widget.CoordinatorLayout
    ...>

    <android.support.design.widget.AppBarLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content">
        <android.support.v7.widget.Toolbar
            .../>
    </android.support.design.widget.AppBarLayout>

    <android.support.design.widget.FloatingActionButton
        ...>
    </android.support.design.widget.FloatingActionButton>
</android.support.design.widget.CoordinatorLayout>

```

## Ref

* [Design Support Library](https://guides.codepath.com/android/Design-Support-Library)
* [Codelab for Android Design Support Library used in I/O Rewind Bangkok session](http://inthecheesefactory.com/blog/android-design-support-library-codelab/)
* [Becoming Material with Android's Design Support Library](https://www.bignerdranch.com/blog/becoming-material-with-android-design-support-library/)
* [Instagram with Material Design concept is getting real](http://frogermcs.github.io/Instagram-with-Material-Design-concept-is-getting-real/)
    * [Palette](https://developer.android.com/reference/android/support/v7/graphics/Palette.html)
    * [rebound](http://facebook.github.io/rebound/)
    * [Timber](https://github.com/JakeWharton/timber)
    * [hugo](https://github.com/JakeWharton/hugo)
    * [Material Design resources](http://www.google.com/design/spec/resources/sticker-sheets-icons.html)
    * [AppCompat v21 — Material Design for Pre-Lollipop Devices!](http://android-developers.blogspot.com/2014/10/appcompat-v21-material-design-for-pre.html)
    * [Using the Material Theme](http://developer.android.com/training/material/theme.html#ColorPalette)

## Code Snippet

```xml
<?xml version="1.0" encoding="utf-8"?>
<ripple xmlns:android="http://schemas.android.com/apk/res/android"
    android:color="@colo/fab_color_shadown">
    <item>
        <shape android:shape="oval">
            <solid android:color="@color/style_color_accent" />
        </shape>
    </item>
</ripple>
```

---

*Animate item views for RecyclerView*

```java
private void runEnterAnimation(View view, int position) {
    if (position >= ANIMATED_ITEMS_COUNT - 1) {
        return;
    }

    if (position > lastAnimatedPosition) {
        lastAnimatedPosition = position;
        view.setTranslationY(Utils.getScreenHeight(context));
        view.animate()
            .translationY(0)
            .setInterpolator(new DecelerateInterpolator(3.f))
            .setDuration(700)
            .start();
    }
}
```
