Use the `::` operator to convert the function to a value.

```kotlin
val getAge = Person::age // memeber reference
```

* member references 
* constructor references
* bound references
    * use the member-references syntax to capture a reference to the method on a specific object instance.

```kotlin
val p = Person("Dmitry", 34)
val personsAgeFunction = Person::age
println(personsAgeFunction(p))

val dmitrysAgeFunction = p::age
println(dmitrysAgeFunction())
```

