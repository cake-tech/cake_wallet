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

  String? get leftSubTitle => null;

  String? get leftSubTitleIconPath => null;

  String? get rightSubTitle => null;

  String? get rightSubTitleLightIconPath => null;

  String? get rightSubTitleDarkIconPath => null;

  List<String> get badges => [];

  bool get isOptionSelected => false;

  set isOptionSelected(bool isSelected) => false;
}


