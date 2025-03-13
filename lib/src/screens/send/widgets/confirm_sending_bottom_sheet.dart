import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/themes/extensions/filter_theme.dart';
import 'package:cake_wallet/themes/extensions/menu_theme.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';

class ConfirmSendingBottomSheet extends StatelessWidget {
  ConfirmSendingBottomSheet(
      {required this.titleText,
      this.titleIconPath,
      required this.currency,
      // this.paymentId,
      // this.paymentIdValue,
      // this.expirationTime,
      required this.amount,
      required this.amountValue,
      required this.fiatAmountValue,
      required this.fee,
      required this.feeValue,
      required this.feeFiatAmount,
      required this.outputs,
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
  final CryptoCurrency currency;

  // final String? paymentId;
  // final String? paymentIdValue;
  // final String? expirationTime;
  final String amount;
  final String amountValue;
  final String fiatAmountValue;
  final String fee;
  final String feeValue;
  final String feeFiatAmount;
  final List<Output> outputs;

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

  @override
  Widget build(BuildContext context) {
    final itemTitleTextStyle = TextStyle(
        fontSize: 16,
        fontFamily: 'Lato',
        fontWeight: FontWeight.w500,
        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
        decoration: TextDecoration.none);

    final itemSubTitleTextStyle = TextStyle(
        fontSize: 12,
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
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.red,
                      ),
                    ),
                  ),
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
            // Wrap the scrollable content with Expanded:
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Theme.of(context).extension<FilterTheme>()!.buttonColor,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(amount, style: itemTitleTextStyle),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('$amountValue ${currency.title}', style: itemTitleTextStyle),
                                Text(fiatAmountValue, style: itemSubTitleTextStyle),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Theme.of(context).extension<FilterTheme>()!.buttonColor,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(fee, style: itemTitleTextStyle),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('$feeValue ${currency.title}', style: itemTitleTextStyle),
                                Text(feeFiatAmount, style: itemSubTitleTextStyle),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          ListView.separated(
                            padding: EdgeInsets.only(top: 0),
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: outputs.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final isBatchSending = outputs.length > 1;
                              final item = outputs[index];
                              final contactName = item.parsedAddress.name;
                              final contactTitle =
                                  '${index + 1}/${outputs.length} - ${contactName.isEmpty ? 'Address' : contactName}';
                              final itemTitle = isBatchSending ? contactTitle : 'Address';
                              final _address =
                                  item.isParsedAddress ? item.extractedAddress : item.address;
                              final _amount = item.cryptoAmount.replaceAll(',', '.');

                              return isBatchSending || contactName.isNotEmpty
                                  ? AddressExpansionTile(
                                      contactType: 'Contact',
                                      name: contactName,
                                      address: _address,
                                      amount: _amount,
                                      isBatchSending: isBatchSending,
                                      itemTitleTextStyle: itemTitleTextStyle,
                                      itemSubTitleTextStyle: itemSubTitleTextStyle)
                                  : AddressTile(
                                      itemTitle: itemTitle,
                                      itemTitleTextStyle: itemTitleTextStyle,
                                      isBatchSending: isBatchSending,
                                      amount: _amount,
                                      currency: currency,
                                      address: _address,
                                      itemSubTitleTextStyle: itemSubTitleTextStyle);
                            },
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      // You can add more widgets here...
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(40, 16, 40, 34),
              child: StandardSlideButton(
                onSlideComplete: () => Navigator.pop(context),
                buttonText: 'Swipe to send',
              ),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 0),
                  ),
                ],
                color: Theme.of(context).extension<FilterTheme>()!.buttonColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddressTile extends StatelessWidget {
  const AddressTile({
    super.key,
    required this.itemTitle,
    required this.itemTitleTextStyle,
    required this.isBatchSending,
    required this.amount,
    required this.currency,
    required this.address,
    required this.itemSubTitleTextStyle,
  });

  final String itemTitle;
  final TextStyle itemTitleTextStyle;
  final bool isBatchSending;
  final String amount;
  final CryptoCurrency currency;
  final String address;
  final TextStyle itemSubTitleTextStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).extension<FilterTheme>()!.buttonColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(itemTitle, style: itemTitleTextStyle),
              if (isBatchSending) Text('$amount ${currency.title}', style: itemTitleTextStyle),
            ],
          ),
          Text(address, style: itemSubTitleTextStyle),
        ],
      ),
    );
  }
}

class AddressExpansionTile extends StatelessWidget {
  const AddressExpansionTile({
    super.key,
    required this.contactType,
    required this.name,
    required this.address,
    required this.amount,
    required this.isBatchSending,
    required this.itemTitleTextStyle,
    required this.itemSubTitleTextStyle,
  });

  final String contactType;
  final String name;
  final String address;
  final String amount;
  final bool isBatchSending;
  final TextStyle itemTitleTextStyle;
  final TextStyle itemSubTitleTextStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        color: Theme.of(context).extension<FilterTheme>()!.buttonColor,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: ExpansionTile(
            childrenPadding: EdgeInsets.zero,
            tilePadding: EdgeInsets.zero,
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(contactType, style: itemTitleTextStyle),
                Text(isBatchSending ? amount : name, style: itemTitleTextStyle),
              ],
            ),
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isBatchSending) Text('Address', style: itemTitleTextStyle),
                      Text(address, style: itemSubTitleTextStyle),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StandardSlideButton extends StatefulWidget {
  final VoidCallback onSlideComplete;
  final String buttonText;
  final double height;

  const StandardSlideButton({
    Key? key,
    required this.onSlideComplete,
    this.buttonText = '',
    this.height = 48.0,
  }) : super(key: key);

  @override
  _StandardSlideButtonState createState() => _StandardSlideButtonState();
}

class _StandardSlideButtonState extends State<StandardSlideButton> {
  // _dragPosition is now the relative position from the left margin.
  double _dragPosition = 0.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double maxWidth = constraints.maxWidth;
      // Define a margin for the left and right edges.
      const double sideMargin = 4.0;
      // Calculate effective width available for the slider by subtracting the margins.
      final double effectiveMaxWidth = maxWidth - 2 * sideMargin;
      const double sliderWidth = 42.0;

      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).extension<CakeMenuTheme>()!.backgroundColor,
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Centered text on the track.
            Center(
              child: Text(
                widget.buttonText,
                style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).extension<CakeTextTheme>()!.titleColor),
              ),
            ),
            // Draggable slider button.
            Positioned(
              // Offset slider's starting point by sideMargin.
              left: sideMargin + _dragPosition,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _dragPosition += details.delta.dx;
                    // Clamp _dragPosition to the effective sliding area.
                    if (_dragPosition < 0) _dragPosition = 0;
                    if (_dragPosition > effectiveMaxWidth - sliderWidth) {
                      _dragPosition = effectiveMaxWidth - sliderWidth;
                    }
                  });
                },
                onHorizontalDragEnd: (details) {
                  if (_dragPosition >= effectiveMaxWidth - sliderWidth - 10) {
                    widget.onSlideComplete();
                  } else {
                    // Reset to initial position if not dragged enough.
                    setState(() {
                      _dragPosition = 0;
                    });
                  }
                },
                child: Container(
                  width: sliderWidth,
                  height: widget.height - 8,
                  // Optional: adjust for vertical padding.
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).extension<FilterTheme>()!.buttonColor,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.arrow_forward,
                      color: Theme.of(context).extension<CakeTextTheme>()!.titleColor),
                ),
              ),
            )
          ],
        ),
      );
    });
  }
}
