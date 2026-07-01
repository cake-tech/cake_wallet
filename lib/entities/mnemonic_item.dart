class MnemonicItem {
  MnemonicItem({required String text}) : _text = text;

  String get text => _text;
  String _text;

  void changeText(String text) => _text = text;

  @override
  String toString() => text;
}
