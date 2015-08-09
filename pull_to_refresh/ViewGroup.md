Notes on `ViewGroup`
===

Layout Modes
---

* LAYOUT_MODE_UNDEFINED
* LAYOUT_MODE_OPTICAL_BOUNDS
    * They sit inside the clip bounds which need to cover a larger area to allow other effects, such as **shadows** and **glows**, to be drawn
* LAYOUT_MODE_CLIP_BOUNDS
* LAYOUT_MODE_DEFAULT = LAYOUT_MODE_CLIP_BOUNDS

> Layout managers can run the measure pass several times. For example `LinearLayout` supports the weight attribute which distributes the remaining empty space among views and `RelativeLayout` measures child views several times to solve constraints given in the layout file.

