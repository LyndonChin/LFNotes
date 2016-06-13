* **Retrofit** is the class through which your *API interfaces* are turned into *callable* objects.
* A type-safe HTTP client for Android and Java

URL MANIPULATION
---

For complex query parameter combinations a `Map` can be used.

```java
@GET("group/{id}/users")
Call<List<User>> groupList(@Path("id") int groupId, @QueryMap Map<String, String> options);
```

REQUEST BODY
---

An object can be specified for use as an HTTP request body with the `@Body` annotation.

```java
@POST("users/new")
Call<User> createUser(@Body User user);
```

FORM ENCODED AND MULTIPART
---

form-encoded data

```java
@FormUrlEncoded
@POST("user/edit")
Call<User> updateUser(@Field("first_name") String first, @Field("last_name") String last);
```

multipart data

```java
@Multipart
@PUT("user/photo")
Call<User> updateUser(@Part("photo") RequestBody photo, @Part("description") RequestBody description);
```

HEADER MANIPULATION
---

*Note that headers do not overwrite each other.* 
*All headers with the same name will be included in the request.*

```java
@Headers("Cache-Control: max-age=640000")
@GET("widget/list")
Call<List<Widget>> widgetList();
```

```java
@Headers({
    "Accept: application/vnd.github.v3.full+json",
    "User-Agent: Retrofit-Sample-App"
})
@GET("users/{username}")
Call<User> getUser(@Path("username") String username);
```

```java
@GET("user")
Call<User> getUser(@Header("Authorization") String authorization)
```

*[OkHttp interceptor](https://github.com/square/okhttp/wiki/Interceptors)*

proguard
---

```proguard
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }
-keepattributes Signature
-keepattributes Exceptions
```
