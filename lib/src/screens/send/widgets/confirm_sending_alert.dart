import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';

class ConfirmSendingAlert extends BaseAlertDialog {
  ConfirmSendingAlert({
    @required this.alertTitle,
    @required this.amount,
    @required this.amountValue,
    @required this.fee,
    @required this.feeValue,
    @required this.leftButtonText,
    @required this.rightButtonText,
    @required this.actionLeftButton,
    @required this.actionRightButton,
    this.alertBarrierDismissible = true
  });

  final String alertTitle;
  final String amount;
  final String amountValue;
  final String fee;
  final String feeValue;
  final String leftButtonText;
  final String rightButtonText;
  final VoidCallback actionLeftButton;
  final VoidCallback actionRightButton;
  final bool alertBarrierDismissible;

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
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              amount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryTextTheme.title.color,
                decoration: TextDecoration.none,
              ),
            ),
            Text(
              amountValue,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryTextTheme.title.color,
                decoration: TextDecoration.none,
              ),
            )
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              fee,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryTextTheme.title.color,
                decoration: TextDecoration.none,
              ),
            ),
            Text(
              feeValue,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryTextTheme.title.color,
                decoration: TextDecoration.none,
              ),
            )
          ],
        )
      ],
    );
  }
}