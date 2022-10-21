import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';

class InfoAlertDialog extends BaseAlertDialog {
  InfoAlertDialog({
    required this.alertTitle,
    required this.alertContent,
    this.alertTitleColor,
    this.alertContentPadding,
    this.alertBarrierDismissible = true
  });

  final String alertTitle;
  final Color? alertTitleColor;
  final Widget alertContent;
  final EdgeInsets? alertContentPadding;
  final bool alertBarrierDismissible;

  @override
  String get titleText => alertTitle;

  @override
  Widget get contentWidget => alertContent;

  @override
  bool get barrierDismissible => alertBarrierDismissible;

  @override
  bool get isDividerExists => true;

  @override
  Color? get titleColor => alertTitleColor;

  @override
  EdgeInsets? get contentPadding => alertContentPadding;

  @override
  Widget actionButtons(BuildContext context) {
    return const SizedBox();
  }
}