abstract class SelectableItem {
  SelectableItem({required this.title});
  final String title;
}

class OptionTitle extends SelectableItem {
  OptionTitle({required String title}) : super(title: title);

}

abstract class SelectableOption extends SelectableItem {
  SelectableOption({required String title}) : super(title: title);

  String get lightIconPath;

  String get darkIconPath;

  String? get description => null;

  String? get topLeftSubTitle => null;

  String? get topLeftSubTitleIconPath => null;

  String? get topRightSubTitle => null;

  String? get topRightSubTitleLightIconPath => null;

  String? get topRightSubTitleDarkIconPath => null;

  String? get bottomLeftSubTitle => null;

  String? get bottomLeftSubTitleIconPath => null;

  String? get bottomRightSubTitle => null;

  String? get bottomRightSubTitleLightIconPath => null;

  String? get bottomRightSubTitleDarkIconPath => null;

  List<String> get badges => [];

  bool get isOptionSelected => false;

  set isOptionSelected(bool isSelected) => false;
}


