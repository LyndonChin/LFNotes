Notes on `ViewGroup`
===

Layout Modes
---

* LAYOUT_MODE_UNDEFINED
* LAYOUT_MODE_OPTICAL_BOUNDS
    * They sit inside the clip bounds which need to cover a larger area to allow other effects, such as **shadows** and **glows**, to be drawn
* LAYOUT_MODE_CLIP_BOUNDS
* LAYOUT_MODE_DEFAULT = LAYOUT_MODE_CLIP_BOUNDS
