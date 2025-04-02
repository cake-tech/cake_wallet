class WCConnectionModel {
  final String? title;
  final String? text;
  final List<String>? elements;
  final Map<String, void Function()>? elementActions;

  WCConnectionModel({
    this.title,
    this.text,
    this.elements,
    this.elementActions,
  });

  @override
  String toString() {
    return 'WalletConnectRequestModel(title: $title, text: $text, elements: $elements, elementActions: $elementActions)';
  }
}
