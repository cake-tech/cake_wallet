import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';

class AlertWithOneAction extends BaseAlertDialog {
  AlertWithOneAction({
    required this.alertTitle,
    required this.alertContent,
    required this.buttonText,
    required this.buttonAction,
    this.alertBarrierDismissible = true,
    this.headerTitleText,
    this.headerImageProfileUrl,
    this.buttonKey,
    Key? key,
  });

  final String alertTitle;
  final String alertContent;
  final String buttonText;
  final VoidCallback buttonAction;
  final bool alertBarrierDismissible;
  final String? headerTitleText;
  final String? headerImageProfileUrl;
  final Key? buttonKey;

  @override
  String get titleText => alertTitle;

  @override
  String get contentText => alertContent;

  @override
  bool get barrierDismissible => alertBarrierDismissible;

  @override
  String? get headerImageUrl => headerImageProfileUrl;

  @override
  String? get headerText => headerTitleText;

  @override
  VoidCallback get actionRight => buttonAction;

  @override
  bool get showLeftButton => false;

  @override
  String get rightActionButtonText => buttonText;

  @override
  Key? get rightActionButtonKey => buttonKey;
}
