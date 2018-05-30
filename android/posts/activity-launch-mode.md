四种启动模式：

* standard
* singleTop
* singleTask
* singleInstance

Task Manager 用于管理 Task

![](https://inthecheesefactory.com/uploads/source/launchMode/gallerystandard.jpg)

standard
---
pre-lolipop：位于一个 Task 的栈顶

lolipop：
* If those Activities are from the same application, it will work just like on pre-Lollipop, stacked on top of the task.
* But in case that an Intent is sent from a different application. New task will be created and the newly created Activity will be placed as a root Activity

为什么 lolipop 的行为改变了呢？因为 Task Management 改掉了。

使用场景：

An example of this kind of Activity is a **Compose Email Activity** or a **Social Network's Status** Posting Activity. If you think about an Activity that can work separately to serve an separate Intent, think about standard one.

singleTop
---

![](https://cdn-images-1.medium.com/max/1600/1*4B06eN1SBWd24tKzxQFCDA.png)
![](https://cdn-images-1.medium.com/max/1600/1*XgiBG79DUEa72kFuehneOw.png)
![](https://cdn-images-1.medium.com/max/1600/1*OGnZgLmpGB_siARD7ZZ-XA.png)

singleTask
---


singleInstance
---
类似 `singleTask`，但是 `singleInstance` 的 task 只能有一个 Activity instance。

---

参考资料

* https://medium.com/@iammert/android-launchmode-visualized-8843fc833dbe
