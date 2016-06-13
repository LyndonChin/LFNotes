参数化的 Response
---

```java
class Response<T> {
  int code();
  String message();
  Headers headers();

  boolean isSuccess();
  T body();
  ResponseBody errorBody();
  com.squareup.okhttp.Response raw();
}
```

0. `code()` 返回 200 表示网络请求成功，但是不代表请求成功，有可能反序列化失败。
0. 反序列化失败通过 `errorBody()` 可得到一个 `ResponseBody`。
0. 拿到这个 Response 之后可通过 `isSuccess()` 判断是否请求成功。


**用法**

```java
Response<List<Contributor>> response = call.execute();

// HTTP/1.1 200 OK
// Link: <https://api.github.com/repositories/892275/contributors?
page=2>; rel="next", <https://api.github.com/repositories/892275/
contributors?page=3>; rel="last"
// ...

String links = response.headers().get("Link");
String nextLink = nextFromGitHubLinks(links);

// https://api.github.com/repositories/892275/contributors?page=2
```

新的标注 `@Url`，允许你直接传入一个请求的 URL。
---

```java
interface GitHubService {
  @GET("/repos/{owner}/{repo}/contributors")
  Call<List<Contributor>> repoContributors(@Path("owner") String owner, @Path("repo") String repo);

  @GET
  Call<List<Contributor>> repoContributorsPaginate(@Url String url);
}
```

> 这样的话，我们就能通过调用 repoContributorsPaginate 来获取第二页内容，然后通过第二页的 header 来请求第三页。你可能很多的 API 都见到过类似的设计，这在 Retrofit 1 里确实是个困扰很多人的大麻烦。


API 接口应该通过功能实现分组
---

> 接口的声明是要语意化的

