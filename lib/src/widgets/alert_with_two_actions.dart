import 'dart:ui';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';
import 'package:flutter/cupertino.dart';

class AlertWithTwoActions extends BaseAlertDialog {
  AlertWithTwoActions({
    required this.alertTitle,
    required this.alertContent,
    required this.leftButtonText,
    required this.rightButtonText,
    required this.actionLeftButton,
    required this.actionRightButton,
    this.alertBarrierDismissible = true,
    this.isDividerExist = false,
    // this.leftActionColor,
    // this.rightActionColor,
    this.alertRightActionButtonKey,
    this.alertLeftActionButtonKey,
    this.alertDialogKey,
  });

  final String alertTitle;
  final String alertContent;
  final String leftButtonText;
  final String rightButtonText;
  final VoidCallback actionLeftButton;
  final VoidCallback actionRightButton;
  final bool alertBarrierDismissible;
  // final Color leftActionColor;
  // final Color rightActionColor;
  final bool isDividerExist;
  final Key? alertRightActionButtonKey;
  final Key? alertLeftActionButtonKey;
  final Key? alertDialogKey;

  @override
  String get titleText => alertTitle;
  @override
  String get contentText => alertContent;
  @override
  String get leftActionButtonText => leftButtonText;
  @override
  String get rightActionButtonText => rightButtonText;
  @override
  VoidCallback get actionLeft => actionLeftButton;
  @override
  VoidCallback get actionRight => actionRightButton;
  @override
  bool get barrierDismissible => alertBarrierDismissible;
  // @override
  // Color get leftButtonColor => leftActionColor;
  // @override
  // Color get rightButtonColor => rightActionColor;
  @override
  bool get isDividerExists => isDividerExist;

  @override
  Key? get dialogKey => alertDialogKey;

  @override
  Key? get leftActionButtonKey => alertLeftActionButtonKey;

  @override
  Key? get rightActionButtonKey => alertRightActionButtonKey;
}
