# Gestures on Android

## Gestures

* Touch Mechanics - *What your fingers do on the screen*
* Touch Activities - *Results of specific gestures*

### Drag, swipe, or fling details

Swipe gesture activities vary based on context. The **speed** at which a gesture is performed is the primary distinction between Drag, Swipe, and Fling.

* **Drag:** Fine gesture, slower, more controllerd, typically has an on-screen target
* **Swipe:** Cross gesture, faster, typically has no on-screen target.
* **Fling:** Cross gesture, with no on-screen target.

Gesture velocity impacts whether the action is immediately reversible.

* A swipe becomes a fling based on **ending velocity** and whether the affected element has crossed a **threshold** (or point past which an action can be undone).
* A drag maintains contact with an element, so reversing the direction of the gesture will drag the element back across the threshold.
* A fling moves at a **faster speed** and removes contact with the element while it crosses the threshold, **preventing** the action from being **undone**.

### Detecting Common Gestures

* `GestureDetectorCompat`
* `MotionEventCompat`

```java
@Override
public boolean onTouchEvent(MotionEvent event) {
    int action = MotionEventCompat.getActionMasked(event);
    switch (action) {
    }
    return super.onTouchEvent(event);
}
```

`ACTION_DOWN` is the starting point for all touch events.

### Detect Gestures

* `GestureDetectorCompat`
* `GestureDetector.OnGestureListener`
* `GestureDetector.OnDoubleTapListener`

## Tracking Movement
---
To help apps distinguish between movement-based gestures (such as a swipe) and non-movement gestures (such as a single tap), Android includes the notion of "**touch slop**". Touch slop refers to the distance in pixels a user's touch can wander before the gesture is interpreted as a movement-based gesture.

### Track Velocity

* `VelocityTracker`
* `VelocityTrackerCompat`

## Animating a scroll Gesture

* `Scroller`
* `OverScroller`
    * It includes methods for indicating to users that they've reached the content edges after a pan or fling gesture.
    * **It also provides the best backward compatibility with older devices.**
* `EdgeEffect`
* `EdgeEffectCompat`

### Understanding Scrolling Terminology

* *Padding:* When scrolling is in both the x and y axes, it's called *panning*.
* Dragging
    * `onScroll` in `GestureDetector.OnGestureListener`.
* Fling
    * `onFling` in `GestureDetector.OnGestureListener`.
* `postInvalidateOnAnimation` - Cause an invalidate to happen on the next animation time step, typically the next display frame.

Stuff
---
* [Android "Swpie" vs "Fling"](http://stackoverflow.com/questions/22843671/android-swipe-vs-fling)
* [Gestures](https://www.google.com/design/spec/patterns/gestures.html)
* [Using Touch Gestures](https://developer.android.com/training/gestures/index.html)
