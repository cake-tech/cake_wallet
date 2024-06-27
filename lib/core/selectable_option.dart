abstract class SelectableOption {
  String get title;

  String get iconPath;

  String get description;

  String? get subTitle => null;

  String? get firstBadgeName => null;

  String? get secondBadgeName => null;

  bool get isOptionSelected => false;

  set isOptionSelected(bool isSelected) => false;
}
