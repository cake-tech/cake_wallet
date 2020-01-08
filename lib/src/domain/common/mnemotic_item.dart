class MnemoticItem {
  MnemoticItem({String text, this.dic}) : _text = text;

  String get text => _text;
  final List<String> dic;

  String _text;

  bool isCorrect() => dic.contains(text);

  void changeText(String text) {
    _text = text;
  }

  @override
  String toString() => text;
}
