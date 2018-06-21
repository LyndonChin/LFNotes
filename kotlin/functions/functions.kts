fun sum(numbers: List<BigDecimal>) = 
    fold(numbers, BigDecimal.ZERO) { acc, num -> acc + num }

fun prod(numbers: List<BigDecimal>) = 
    fold(numbers, BigDecimal.ONE) { acc, num -> acc * num }

private fun fold(
            numbers: List<BigDecimal>,
            start: BigDecimal,
            accumulator: (BigDecimal, BigDecimal) -> BigDecimal
        ): BigDecimal {
            var acc = start
            for (num in numbers) {
                acc = accumulator(acc, num)
            }
            return acc
        }

// Usage
fun BD(i: Long) = BigDecimal.valueOf(i)
val numbers = listOf(BD(1), BD(2), BD(3), BD(4))
println(sum(numbers))
println(prod(numbers))

fun makeErrorHandler(tag: String) = fun (error: Throwable) {
    if (BuildConfig.DEBUG) Log.e(tag, error.message, error)
    toast(error.message)
    // Other methods, like: Crashlytics.logException(error)
}

// Usage in project
val adController = AdController(makeErrorHandler("Ad in MainActivity"))
