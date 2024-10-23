import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/cake_scrollbar.dart';
import 'package:flutter/scheduler.dart';

class ConfirmSendingAlert extends BaseAlertDialog {
  ConfirmSendingAlert({
    required this.alertTitle,
    this.paymentId,
    this.paymentIdValue,
    this.expirationTime,
    required this.amount,
    required this.amountValue,
    required this.fiatAmountValue,
    required this.fee,
    this.feeRate,
    required this.feeValue,
    required this.feeFiatAmount,
    required this.outputs,
    this.change,
    required this.leftButtonText,
    required this.rightButtonText,
    required this.actionLeftButton,
    required this.actionRightButton,
    this.alertBarrierDismissible = true,
    this.alertLeftActionButtonTextColor,
    this.alertRightActionButtonTextColor,
    this.alertLeftActionButtonColor,
    this.alertRightActionButtonColor,
    this.onDispose,
    this.alertLeftActionButtonKey,
    this.alertRightActionButtonKey,
    Key? key,
  });

  final String alertTitle;
  final String? paymentId;
  final String? paymentIdValue;
  final String? expirationTime;
  final String amount;
  final String amountValue;
  final String fiatAmountValue;
  final String fee;
  final String? feeRate;
  final String feeValue;
  final String feeFiatAmount;
  final List<Output> outputs;
  final PendingChange? change;
  final String leftButtonText;
  final String rightButtonText;
  final VoidCallback actionLeftButton;
  final VoidCallback actionRightButton;
  final bool alertBarrierDismissible;
  final Color? alertLeftActionButtonTextColor;
  final Color? alertRightActionButtonTextColor;
  final Color? alertLeftActionButtonColor;
  final Color? alertRightActionButtonColor;
  final Function? onDispose;
  final Key? alertRightActionButtonKey;
  final Key? alertLeftActionButtonKey;

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
  Key? get leftActionButtonKey => alertLeftActionButtonKey;

  @override
  Key? get rightActionButtonKey => alertLeftActionButtonKey;

  @override
  Widget content(BuildContext context) => ConfirmSendingAlertContent(
      paymentId: paymentId,
      paymentIdValue: paymentIdValue,
      expirationTime: expirationTime,
      amount: amount,
      amountValue: amountValue,
      fiatAmountValue: fiatAmountValue,
      fee: fee,
      feeRate: feeRate,
      feeValue: feeValue,
      feeFiatAmount: feeFiatAmount,
      outputs: outputs,
      change: change,
      onDispose: onDispose);
}

class ConfirmSendingAlertContent extends StatefulWidget {
  ConfirmSendingAlertContent(
      {this.paymentId,
      this.paymentIdValue,
      this.expirationTime,
      required this.amount,
      required this.amountValue,
      required this.fiatAmountValue,
      required this.fee,
      this.feeRate,
      required this.feeValue,
      required this.feeFiatAmount,
      required this.outputs,
      this.change,
      required this.onDispose}) {}

  final String? paymentId;
  final String? paymentIdValue;
  final String? expirationTime;
  final String amount;
  final String amountValue;
  final String fiatAmountValue;
  final String fee;
  final String? feeRate;
  final String feeValue;
  final String feeFiatAmount;
  final List<Output> outputs;
  final PendingChange? change;
  final Function? onDispose;

  @override
  ConfirmSendingAlertContentState createState() => ConfirmSendingAlertContentState(
      paymentId: paymentId,
      paymentIdValue: paymentIdValue,
      expirationTime: expirationTime,
      amount: amount,
      amountValue: amountValue,
      fiatAmountValue: fiatAmountValue,
      fee: fee,
      feeRate: feeRate,
      feeValue: feeValue,
      feeFiatAmount: feeFiatAmount,
      outputs: outputs,
      change: change,
      onDispose: onDispose);
}

class ConfirmSendingAlertContentState extends State<ConfirmSendingAlertContent> {
  ConfirmSendingAlertContentState(
      {this.paymentId,
      this.paymentIdValue,
      this.expirationTime,
      required this.amount,
      required this.amountValue,
      required this.fiatAmountValue,
      required this.fee,
      this.feeRate,
      required this.feeValue,
      required this.feeFiatAmount,
      required this.outputs,
      this.change,
      this.onDispose})
      : recipientTitle = '' {
    recipientTitle = outputs.length > 1
        ? S.current.transaction_details_recipient_address
        : S.current.recipient_address;
  }

  final String? paymentId;
  final String? paymentIdValue;
  final String? expirationTime;
  final String amount;
  final String amountValue;
  final String fiatAmountValue;
  final String fee;
  final String? feeRate;
  final String feeValue;
  final String feeFiatAmount;
  final List<Output> outputs;
  final PendingChange? change;
  final Function? onDispose;

  final double backgroundHeight = 160;
  final double thumbHeight = 72;
  ScrollController controller = ScrollController();
  double fromTop = 0;
  String recipientTitle;
  bool showScrollbar = false;

  @override
  void dispose() {
    if (onDispose != null) onDispose!();
    super.dispose();
  }

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
          height: feeRate != null ? 250 : 200,
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
                              Container(
                                width: 160,
                                child: Text(
                                  paymentIdValue!,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Lato',
                                    color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  if (widget.expirationTime != null)
                    ExpirationTimeWidget(expirationTime: widget.expirationTime!),
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
                            key: ValueKey('confirm_sending_dialog_amount_text_value_key'),
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
                  if (feeRate != null && feeRate!.isNotEmpty)
                    Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              S.current.send_estimated_fee,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                fontFamily: 'Lato',
                                color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            Text(
                              "$feeRate sat/byte",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Lato',
                                color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                                decoration: TextDecoration.none,
                              ),
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
                        ListView.builder(
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
                                  AddressText(text: item.parsedAddress.name),
                                AddressText(text: _address, fontSize: 10),
                                if (stealthAddressText(item.stealthAddress) != null)
                                  AddressText(
                                      text: stealthAddressText(item.stealthAddress)!, fontSize: 10),
                                AmountText(text: _amount),
                              ],
                            );
                          },
                        )
                      ],
                    ),
                  ),
                  if (change != null)
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Column(
                        children: [
                          Text(
                            S.of(context).send_change_to_you,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              fontFamily: 'Lato',
                              color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          Column(
                            children: [
                              AddressText(text: change!.address, fontSize: 10),
                              AmountText(text: change!.amount),
                            ],
                          )
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

class ExpirationTimeWidget extends StatelessWidget {
  const ExpirationTimeWidget({
    required this.expirationTime,
  });

  final String expirationTime;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 32),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            S.current.offer_expires_in,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              fontFamily: 'Lato',
              color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
              decoration: TextDecoration.none,
            ),
          ),
          Text(
            expirationTime,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Lato',
              color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
              decoration: TextDecoration.none,
            ),
          )
        ],
      ),
    );
  }
}

class AddressText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final TextAlign? textAlign;

  const AddressText({
    required this.text,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w600,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: 'Lato',
          color: PaletteDark.pigeonBlue,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class AmountText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final TextAlign? textAlign;

  const AmountText({
    required this.text,
    this.fontSize = 10,
    this.fontWeight = FontWeight.w600,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(top: 8),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
                fontFamily: 'Lato',
                color: PaletteDark.pigeonBlue,
                decoration: TextDecoration.none,
              ),
            )
          ],
        ));
  }
}

String? stealthAddressText(String? stealthAddress) {
  if (stealthAddress == null) {
    return null;
  }

  return stealthAddress.isNotEmpty ? "-> $stealthAddress" : null;
}
