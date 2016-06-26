* **Converter** defines an abstract factory which creates the following converters:
    0. responseBodyConverter
        * `Call<SimpleResponse>` to `SimpleResponse`
    0. requestBodyConverter
        * `@Body`
        * `@Part`
        * `@PartMap`
    0. StringConverter
        * `@Field`
        * `@FieldMap`
        * `@Header`
        * `@HeaderMap`
        * `@Path`
        * `@Query`
        * `@QueryMap`
* CallAdapter.Factory
    * get -> `CallAdatper`
    * getParameterUpperBound -> `Type`
    * getRawType -> `Class<?>`
* Callback
    * onReponse
    * onFailure
* Call
    * execute
    * enqueue
    * isExecuted
    * cancel
    * isCanceled
    * clonse
    * okhttp3.Request
* Platform
    * defaultCallbackExecutor
    * defaultCallAdapterFactory
