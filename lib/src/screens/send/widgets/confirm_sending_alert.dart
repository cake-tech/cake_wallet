import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/cake_scrollbar.dart';
import 'package:flutter/scheduler.dart';

class ConfirmSendingAlert extends BaseAlertDialog {
  ConfirmSendingAlert(
      {required this.alertTitle,
      this.paymentId,
      this.paymentIdValue,
      required this.amount,
      required this.amountValue,
      required this.fiatAmountValue,
      required this.fee,
      required this.feeValue,
      required this.feeFiatAmount,
      required this.outputs,
      required this.leftButtonText,
      required this.rightButtonText,
      required this.actionLeftButton,
      required this.actionRightButton,
      this.alertBarrierDismissible = true,
      this.alertLeftActionButtonTextColor,
      this.alertRightActionButtonTextColor,
      this.alertLeftActionButtonColor,
      this.alertRightActionButtonColor});

  final String alertTitle;
  final String? paymentId;
  final String? paymentIdValue;
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
  final Color? alertLeftActionButtonTextColor;
  final Color? alertRightActionButtonTextColor;
  final Color? alertLeftActionButtonColor;
  final Color? alertRightActionButtonColor;

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
  Color? get leftActionButtonTextColor => alertLeftActionButtonTextColor;

  @override
  Color? get rightActionButtonTextColor => alertRightActionButtonTextColor;

  @override
  Color? get leftActionButtonColor => alertLeftActionButtonColor;

  @override
  Color? get rightActionButtonColor => alertRightActionButtonColor;

  @override
  Widget content(BuildContext context) => ConfirmSendingAlertContent(
      paymentId: paymentId,
      paymentIdValue: paymentIdValue,
      amount: amount,
      amountValue: amountValue,
      fiatAmountValue: fiatAmountValue,
      fee: fee,
      feeValue: feeValue,
      feeFiatAmount: feeFiatAmount,
      outputs: outputs);
}

class ConfirmSendingAlertContent extends StatefulWidget {
  ConfirmSendingAlertContent(
      {this.paymentId,
      this.paymentIdValue,
      required this.amount,
      required this.amountValue,
      required this.fiatAmountValue,
      required this.fee,
      required this.feeValue,
      required this.feeFiatAmount,
      required this.outputs});

  final String? paymentId;
  final String? paymentIdValue;
  final String amount;
  final String amountValue;
  final String fiatAmountValue;
  final String fee;
  final String feeValue;
  final String feeFiatAmount;
  final List<Output> outputs;

  @override
  ConfirmSendingAlertContentState createState() => ConfirmSendingAlertContentState(
      paymentId: paymentId,
      paymentIdValue: paymentIdValue,
      amount: amount,
      amountValue: amountValue,
      fiatAmountValue: fiatAmountValue,
      fee: fee,
      feeValue: feeValue,
      feeFiatAmount: feeFiatAmount,
      outputs: outputs);
}

class ConfirmSendingAlertContentState extends State<ConfirmSendingAlertContent> {
  ConfirmSendingAlertContentState(
      {this.paymentId,
      this.paymentIdValue,
      required this.amount,
      required this.amountValue,
      required this.fiatAmountValue,
      required this.fee,
      required this.feeValue,
      required this.feeFiatAmount,
      required this.outputs})
      : recipientTitle = '' {
    recipientTitle = outputs.length > 1
        ? S.current.transaction_details_recipient_address
        : S.current.recipient_address;
  }

  final String? paymentId;
  final String? paymentIdValue;
  final String amount;
  final String amountValue;
  final String fiatAmountValue;
  final String fee;
  final String feeValue;
  final String feeFiatAmount;
  final List<Output> outputs;

  final double backgroundHeight = 160;
  final double thumbHeight = 72;
  ScrollController controller = ScrollController();
  double fromTop = 0;
  String recipientTitle;
  bool showScrollbar = false;

  @override
  Widget build(BuildContext context) {
    controller.addListener(() {
      fromTop = controller.hasClients
          ? (controller.offset /
              controller.position.maxScrollExtent *
              (backgroundHeight - thumbHeight))
          : 0;
      setState(() {});
    });

    SchedulerBinding.instance.addPostFrameCallback((_) {
      setState(() {
        showScrollbar = controller.position.maxScrollExtent > 0;
      });
    });

    return Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
      Container(
          height: 200,
          child: SingleChildScrollView(
              controller: controller,
              child: Column(
                children: <Widget>[
                  if (paymentIdValue != null && paymentId != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: 32),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            paymentId!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              fontFamily: 'Lato',
                              color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                paymentIdValue!,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Lato',
                                  color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
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
                          color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
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
                              color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
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
                  if (feeValue.isNotEmpty && feeValue != "0")
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
                                color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
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
                                    color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
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
                        )),
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
                            color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        outputs.length > 1
                            ? ListView.builder(
                                padding: EdgeInsets.only(top: 0),
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: outputs.length,
                                itemBuilder: (context, index) {
                                  final item = outputs[index];
                                  final _address =
                                      item.isParsedAddress ? item.extractedAddress : item.address;
                                  final _amount = item.cryptoAmount.replaceAll(',', '.');

                                  return Column(
                                    children: [
                                      if (item.isParsedAddress)
                                        Padding(
                                            padding: EdgeInsets.only(top: 8),
                                            child: Text(
                                              item.parsedAddress.name,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Lato',
                                                color: PaletteDark.pigeonBlue,
                                                decoration: TextDecoration.none,
                                              ),
                                            )),
                                      Padding(
                                          padding: EdgeInsets.only(top: 8),
                                          child: Text(
                                            _address,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Lato',
                                              color: PaletteDark.pigeonBlue,
                                              decoration: TextDecoration.none,
                                            ),
                                          )),
                                      Padding(
                                          padding: EdgeInsets.only(top: 8),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                _amount,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Lato',
                                                  color: PaletteDark.pigeonBlue,
                                                  decoration: TextDecoration.none,
                                                ),
                                              )
                                            ],
                                          ))
                                    ],
                                  );
                                })
                            : Column(children: [
                                if (outputs.first.isParsedAddress)
                                  Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text(
                                        outputs.first.parsedAddress.name,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Lato',
                                          color: PaletteDark.pigeonBlue,
                                          decoration: TextDecoration.none,
                                        ),
                                      )),
                                Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Text(
                                      outputs.first.isParsedAddress
                                          ? outputs.first.extractedAddress
                                          : outputs.first.address,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Lato',
                                        color: PaletteDark.pigeonBlue,
                                        decoration: TextDecoration.none,
                                      ),
                                    )),
                              ])
                      ],
                    ),
                  )
                ],
              ))),
      if (showScrollbar)
        CakeScrollbar(
            backgroundHeight: backgroundHeight,
            thumbHeight: thumbHeight,
            fromTop: fromTop,
            rightOffset: -15)
    ]);
  }
}
