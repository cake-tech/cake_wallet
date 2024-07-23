
import 'dart:ui';

abstract class SelectableOption {
  String get title;

  String get iconPath;

  String? get description => null;

  String? get leftSubTitle => null;

  String? get rightSubTitle => null;

  String? get firstBadgeName => null;

  String? get secondBadgeName => null;

  double? borderRadius = null;

  Color? selectedBackgroundColor = null;

  TextStyle? titleTextStyle = null;

  TextStyle? leftSubTitleTextStyle = null;

  bool get isOptionSelected => false;

  set isOptionSelected(bool isSelected) => false;
}
