import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';
import 'package:cake_wallet/generated/i18n.dart';

class ConfirmSendingAlert extends BaseAlertDialog {
  ConfirmSendingAlert({
    @required this.alertTitle,
    @required this.amount,
    @required this.amountValue,
    @required this.fiatAmountValue,
    @required this.fee,
    @required this.feeValue,
    @required this.feeFiatAmount,
    @required this.outputs,
    @required this.leftButtonText,
    @required this.rightButtonText,
    @required this.actionLeftButton,
    @required this.actionRightButton,
    this.alertBarrierDismissible = true
  }) {
    itemCount = outputs.length;
    recipientTitle = itemCount > 1
        ? S.current.transaction_details_recipient_address
        : S.current.recipient_address;
  }

  final String alertTitle;
  final String amount;
  final String amountValue;
  final String fiatAmountValue;
  final String fee;
  final String feeValue;
  final String feeFiatAmount;
  final List<Output> outputs;
  final String leftButtonText;
  final String rightButtonText;
  final VoidCallback actionLeftButton;
  final VoidCallback actionRightButton;
  final bool alertBarrierDismissible;

  String recipientTitle;
  int itemCount;

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
    return Container(
      height: 200,
      child: SingleChildScrollView(
        child: Column(
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
              padding: EdgeInsets.only(top: 16),
              child: Column(
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
                  itemCount > 1
                    ? ListView.builder(
                      padding: EdgeInsets.only(top: 0),
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        final item = outputs[index];
                        final _address = item.address;
                        final _amount =
                          item.cryptoAmount.replaceAll(',', '.');

                        return Column(
                          children: [
                            Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  _address,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Lato',
                                    color: PaletteDark.pigeonBlue,
                                    decoration: TextDecoration.none,
                                  ),
                                )
                            ),
                            Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      _amount,
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
                            )
                          ],
                        );
                      }
                    )
                    : Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      outputs.first.address,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Lato',
                        color: PaletteDark.pigeonBlue,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        )
      )
    );
  }
}