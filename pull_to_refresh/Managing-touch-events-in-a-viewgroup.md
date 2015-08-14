Managing Touch Events in a ViewGroup
===

https://developer.android.com/training/gestures/viewgroup.html#intercept

Intercept Touch Events in a ViewGroup
---

The `onInterceptTouchEvent()` method is called whenever a touch event is detected on the surface of a `ViewGroup`, **including on the surface of its children**.

If `onInterceptTouchEvent()` returns `true`, the `MotionEvent` is intercepted, meaning it will not be passed on to the child, but rather to the `onTouchEvent()` method of the parent.

The `onInterceptTouchEvent()` method gives a parent the chance to see any touch event before its children do.

`ViewGroup` also provides a `requestDisallowInterceptTouchEvent()` method. The `ViewGroup` calls this method when a child does not want the parent and its ancestors to intercept touch events with `onInterceptTouchEvent()`.

Use ViewConfiguration Constants
---

```java
ViewConfiguration vc = ViewConfiguration.get(view.getContext());
private int mSlop = vc.getScaledTouchSlop();
private int mMinFlingVelocity = vc.getScaledMinimumFlingVelocity();
private int mMaxFlingVelocity = vc.getScaledMaximumFlingVelocity();
```

Extend a Child View's Touchable Area
---

```java
public class MainActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        spuer.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        // Get the parent view
        View parentView = findViewById(R.id.parent_layout);

        parentView.post(new Runnable() {
            // Post in the parent's message queue to make sure the parent
            // lays out its children before you call getHitRect()
            @Override
            public void run() {
                // The bounds for the delegate view (an ImageButton
                // in this example
                Rect delegateArea = new Rect();
                ImageButton myButton = (ImageButton) findViewById(R.id.button);
                myButton.setEnabled(true);
                myButton.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View view) {
                        Toast.makeText(MainActivity.this,
                                "Touch occured within ImageButton touch region.",
                                Toast.LENGTH_SHORT).show();
                    }
                };

                // The hit rectangle for the ImageButton
                myButton.getHitRect(delegateArea);

                // Extend the touch area of the ImageButton beyond its bounds
                // on the right and bottom
                delegateArea.right += 100;
                delegateArea.bottom += 100;

                // Instantizte a TouchDelegate.
                // "delegateArea" is the bounds in local coordinates of
                // containing view to be mapped to the delegate view.
                // "myButton" is the child view that should receive motion
                // events.
                TouchDelegate touchDelegate = new TouchDelegate(delegateArea, myButton);

                // Sets the TouchDelegate on the parent view, such that touches 
                // within the touch delegate bounds are routed to the child.
                if (View.class.isInstance(myButton.getParent))) {
                    ((View) myButton.getParent()).setTouchDelegate(touchDelegate);
                }
            }
        });
}
```
