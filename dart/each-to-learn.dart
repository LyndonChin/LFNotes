import 'dart:math' show Random

void main() {                           
    print(new Die(n: 12).roll());
}

class Die {
    static Random shaker = new Random();
    int sides, value;

    String toString() => '$value';

    Die({int n: 6}) {
        if (4 <= n && n <= 20) {
            sides = n;
        } else {
            throw new ArgumentError(/* */);
        }
    }
    int roll() {
        return value = shaker.nextInt(sides) + 1;
    }
}
