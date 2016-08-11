Excluding Tasks
---

```bash
> gradle dist - x test
```

Lazy dependsOn
---

```groovy
task hello << {
  println 'Hello world!'
}

task intro(dependsOn: hello) << {
  println "I'm Gradle"
}
```
<pre>
 |
 |
\|/
</pre>

```groovy
task taskX(dependsOn: 'taskY') << {
  println 'taskX'
}

task taskY << {
  println 'taskY'
}
```

* The `<<` operator is simply an alias for `doLast`.
