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

