class MnemoticItem {
  String get text => _text;
  final List<String> dic;

  String _text;

  MnemoticItem({String text, this.dic}) {
    _text = text;
  }

  bool isCorrect() => dic.contains(text);

  void changeText(String text) {
    _text = text;
  }

  @override
  String toString() => text;
}