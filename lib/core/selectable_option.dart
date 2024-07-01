abstract class SelectableOption {
  String get title;

  String get iconPath;

  String get description;

  String? get leftSubTitle => null;

  String? get rightSubTitle => null;

  String? get firstBadgeName => null;

  String? get secondBadgeName => null;

  bool get isOptionSelected => false;

  set isOptionSelected(bool isSelected) => false;
}
