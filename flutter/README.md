Flutter 是一套 UI 框架。

Flutter 的优势
---
* Fast Development
    * Hot Reload
* Expressive and Flexible UI
* Native Performance

## 响应式
```dart
class CounterState extends State<Counter> {
    int counter = 0;

    void increment() {
        // Tells the Flutter framework that state has changed,
        // so the framework can run build() and update the display.
        setState(() {
            counter++;
        });
    }

    Widget build(BuildContext context) {
        // This method is rerun every time setState is called.
        // The Flutter framework has been optimized to make rerunning
        // build methods fast, so that you can just rebuild anything that
        // needs updating rather than having to individually change
        // instances of widgets.
        return new Row(
            children: <Widget>[
                new RaisedButton(
                    onPressed: increment,
                    child: new Text('Increment'),
                ),
                new Text('Count: $counter'),
            ],
        );
    }
}
```

## Native互调

```dart
Future<Null> getBatteryLevel() async {
    var batteryLevel = 'unknown';
    try {
        int result = await methodChannel.invokeMethod('getBatteryLevel');
        batteryLevel = 'Battery level: $result%';
    } on PlatformException {
        batteryLevel = 'Failed to get battery level.';
    }
    setState(() {
        _batteryLevel = batteryLevel;
    });
}
```

## 工程化

### Build
* Beautiful app UIs
* Fluid coding experience
* Full-fetuares apps

### Optimize
* Test
    * Unit testing
    * Integration testing
    * On-device testing
* Debug
    * IDE debugger
    * Web-based debugger
    * async/await aware
    * Expression evaluator
* Profile
    * Timeline
    * CPU and memory
    * In-app perf charts

### Deploy
* Compile
* Distribution
