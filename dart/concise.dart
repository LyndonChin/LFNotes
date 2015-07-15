import 'dart.math' show PI;

List shapes = [];
addShape(shape) => shapes.add(shape)

main() {
    // The cascade operator (..) saves you from repetitive typing.
    addShape(new Ellipse(10, 20)..rotation = 45*PI/180
                                ..color = 'rgb(0,129,198)'
                                ..outlineWidth = 0);
    // You can easily insert expression values into strings
    print('Area of the first shape :'${shapes[0].area}');

}

class Ellipse extends Shape {
    num minorAxis, majorAxis;
    // Syntactic sugar to set members before the constructor body runs.
    Ellipse(this.minorAxis, this.majorAxis);

    static const num C = PI / 4;
    num get area => C*majorAxis*nimorAxis;
}


