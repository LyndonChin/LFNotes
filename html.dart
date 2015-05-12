import 'dart:html';
import 'dart:convert' show JSON;

void main() {
    querySelector('#getColors').onClick.listen(showColors); // Event handling.
}

void showColors(Event e) {
    HttpRequest.getString('colors.json')
        .then((String jsonString) {
            UListElement colors = querySelector('#colors');
            List colorList = JSON.decode(jsonString);
            for (int i = 0; i < colorList.length; i++) {
                colors.children.add(
                    new LIElement()..text = colorList[i]
                     ..style.color = colorList[i]
                     ..style.fontFamily = 'Marker Felt');
            }
        })
        .catchError((_) { /* Handle error. */ });
}
