abstract class SelectableOption {
  String get title;

  String get iconPath;

  String? get description => null;

  String? get subTitle => null;

  String? get firstBadgeTitle => null;

  String? get secondBadgeTitle => null;

  bool get isOptionSelected => false;

  set isOptionSelected(bool isSelected) => false;
}
