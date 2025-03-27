import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';

class AlertWithNoAction extends BaseAlertDialog {
  AlertWithNoAction({
    this.alertTitle,
    required this.alertContent,
    this.alertBarrierDismissible = true,
    Key? key,
  });

  final String? alertTitle;
  final String alertContent;
  final bool alertBarrierDismissible;

  @override
  String? get titleText => alertTitle;

  @override
  String get contentText => alertContent;

  @override
  bool get barrierDismissible => alertBarrierDismissible;

  @override
  bool get isBottomDividerExists => false;

  @override
  Widget actionButtons(BuildContext context) => Container();
}
