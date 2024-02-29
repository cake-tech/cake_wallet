import 'dart:ui';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';
import 'package:flutter/cupertino.dart';

class AlertWithTwoActionsContentOverride extends BaseAlertDialog {
  AlertWithTwoActionsContentOverride({
    required this.alertTitle,
    required this.alertContent,
    required this.leftButtonText,
    required this.rightButtonText,
    required this.actionLeftButton,
    required this.actionRightButton,
    this.alertBarrierDismissible = true,
    this.isDividerExist = false,
  });

  final String alertTitle;
  final Widget alertContent;
  final String leftButtonText;
  final String rightButtonText;
  final VoidCallback actionLeftButton;
  final VoidCallback actionRightButton;
  final bool alertBarrierDismissible;
  // final Color leftActionColor;
  // final Color rightActionColor;
  final bool isDividerExist;

  @override
  String get titleText => alertTitle;
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

  @override
  Widget content(BuildContext context) {
    return alertContent;
  }
  
  @override
  bool get isDividerExists => isDividerExist;
}
