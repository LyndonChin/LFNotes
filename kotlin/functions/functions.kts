fun printSum(vararg numbers: Int) {
    val sum = numbers.sum()
    println(numbers::class.qualifiedName)
    println(sum)
}

printSum(1, 2, 3, 4, 5)
printSum()

fun forEach(op: (Int) -> Unit, vararg numbers: Int) {
    numbers.forEach(op)
}

forEach({ num: Int -> println(num) }, 1, 2, 3, 5 )

