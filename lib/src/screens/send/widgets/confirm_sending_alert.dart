import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';

class ConfirmSendingAlert extends BaseAlertDialog {
  ConfirmSendingAlert({
    @required this.alertTitle,
    @required this.amount,
    @required this.amountValue,
    @required this.fiatAmountValue,
    @required this.fee,
    @required this.feeValue,
    @required this.feeFiatAmount,
    @required this.recipientTitle,
    @required this.recipientAddress,
    @required this.leftButtonText,
    @required this.rightButtonText,
    @required this.actionLeftButton,
    @required this.actionRightButton,
    this.alertBarrierDismissible = true
  });

  final String alertTitle;
  final String amount;
  final String amountValue;
  final String fiatAmountValue;
  final String fee;
  final String feeValue;
  final String feeFiatAmount;
  final String recipientTitle;
  final String recipientAddress;
  final String leftButtonText;
  final String rightButtonText;
  final VoidCallback actionLeftButton;
  final VoidCallback actionRightButton;
  final bool alertBarrierDismissible;

  @override
  String get titleText => alertTitle;

  @override
  bool get isDividerExists => true;

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
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              amount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                fontFamily: 'Lato',
                color: Theme.of(context).primaryTextTheme.title.color,
                decoration: TextDecoration.none,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amountValue,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Lato',
                    color: Theme.of(context).primaryTextTheme.title.color,
                    decoration: TextDecoration.none,
                  ),
                ),
                Text(
                  fiatAmountValue,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Lato',
                    color: PaletteDark.pigeonBlue,
                    decoration: TextDecoration.none,
                  ),
                )
              ],
            )
          ],
        ),
        Padding(
          padding: EdgeInsets.only(top: 16),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                fee,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  fontFamily: 'Lato',
                  color: Theme.of(context).primaryTextTheme.title.color,
                  decoration: TextDecoration.none,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    feeValue,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Lato',
                      color: Theme.of(context).primaryTextTheme.title.color,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  Text(
                    feeFiatAmount,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Lato',
                      color: PaletteDark.pigeonBlue,
                      decoration: TextDecoration.none,
                    ),
                  )
                ],
              )
            ],
          )
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(0, 16, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$recipientTitle:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  fontFamily: 'Lato',
                  color: Theme.of(context).primaryTextTheme.title.color,
                  decoration: TextDecoration.none,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  recipientAddress,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Lato',
                    color: PaletteDark.pigeonBlue,
                    decoration: TextDecoration.none,
                  ),
                )
              )
            ],
          ),
        )
      ],
    );
  }
}