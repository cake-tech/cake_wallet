import 'package:cake_wallet/themes/extensions/filter_theme.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';

class ConfirmSendingBottomSheet extends StatelessWidget {
  ConfirmSendingBottomSheet(
      {required this.titleText,
      this.titleIconPath,
      // this.paymentId,
      // this.paymentIdValue,
      // this.expirationTime,
      required this.amount,
      required this.amountValue,
      required this.fiatAmountValue,
      required this.fee,
      required this.feeValue,
      required this.feeFiatAmount,
      // required this.outputs,
      // this.change,
      // required this.leftButtonText,
      // required this.rightButtonText,
      // required this.actionLeftButton,
      // required this.actionRightButton,
      // this.alertBarrierDismissible = true,
      // this.alertLeftActionButtonTextColor,
      // this.alertRightActionButtonTextColor,
      // this.alertLeftActionButtonColor,
      // this.alertRightActionButtonColor,
      // this.onDispose,
      // this.alertRightActionButtonKey,
      // this.alertLeftActionButtonKey,
      Key? key});

  final String titleText;
  final String? titleIconPath;

  // final String? paymentId;
  // final String? paymentIdValue;
  // final String? expirationTime;
  final String amount;
  final String amountValue;
  final String fiatAmountValue;
  final String fee;
  final String feeValue;
  final String feeFiatAmount;

  // final List<Output> outputs;
  // final PendingChange? change;
  // final String leftButtonText;
  // final String rightButtonText;
  // final VoidCallback actionLeftButton;
  // final VoidCallback actionRightButton;
  // final bool alertBarrierDismissible;
  // final Color? alertLeftActionButtonTextColor;
  // final Color? alertRightActionButtonTextColor;
  // final Color? alertLeftActionButtonColor;
  // final Color? alertRightActionButtonColor;
  // final Function? onDispose;
  // final Key? alertRightActionButtonKey;
  // final Key? alertLeftActionButtonKey;

  Widget title(BuildContext context) {
    return Text(titleText,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 20,
            fontFamily: 'Lato',
            fontWeight: FontWeight.w600,
            color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
            decoration: TextDecoration.none));
  }

  Widget get titleIcon =>
      titleIconPath != null ? Image.asset(titleIconPath!, height: 24, width: 24) : Container();

  Widget expansionTile(
      {required BuildContext context,
      required TextStyle itemTitleTextStyle,
      required TextStyle itemSubTitleTextStyle}) {
    return Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            color: Theme.of(context).extension<FilterTheme>()!.buttonColor),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text('ExpansionTile 1'),
          children: <Widget>[
            Container(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(fee, style: itemTitleTextStyle),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(feeValue, style: itemTitleTextStyle),
                          Text(feeFiatAmount, style: itemSubTitleTextStyle),
                        ],
                      ),
                    ],
                  ),
                ))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemTitleTextStyle = TextStyle(
        fontSize: 16,
        fontFamily: 'Lato',
        fontWeight: FontWeight.w500,
        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
        decoration: TextDecoration.none);

    final itemSubTitleTextStyle = TextStyle(
        fontSize: 10,
        fontFamily: 'Lato',
        fontWeight: FontWeight.w600,
        color: Theme.of(context).extension<SendPageTheme>()!.textFieldHintColor,
        decoration: TextDecoration.none);

    return ClipRRect(
      borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(30.0), topRight: const Radius.circular(30.0)),
      child: Container(
        color: Theme.of(context).dialogBackgroundColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  const Spacer(flex: 4),
                  Expanded(
                      flex: 2,
                      child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4), color: Colors.red))),
                  const Spacer(flex: 4),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                titleIcon,
                const SizedBox(width: 6),
                title(context),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(amount, style: itemTitleTextStyle),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(amountValue, style: itemTitleTextStyle),
                                Text(fiatAmountValue, style: itemSubTitleTextStyle),
                              ],
                            ),
                          ],
                        ),
                      ),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Theme.of(context).extension<FilterTheme>()!.buttonColor)),
                  const SizedBox(height: 8),
                  Container(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(fee, style: itemTitleTextStyle),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(feeValue, style: itemTitleTextStyle),
                                Text(feeFiatAmount, style: itemSubTitleTextStyle),
                              ],
                            ),
                          ],
                        ),
                      ),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Theme.of(context).extension<FilterTheme>()!.buttonColor)),
                  const SizedBox(height: 8),
                  expansionTile(
                      context: context,
                      itemTitleTextStyle: itemTitleTextStyle,
                      itemSubTitleTextStyle: itemSubTitleTextStyle),
                ],
              ),
            ),
            ElevatedButton(
              child: const Text('Close BottomSheet'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
