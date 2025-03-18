import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/extensions/filter_theme.dart';
import 'package:cake_wallet/themes/extensions/menu_theme.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:flutter_svg/svg.dart';

class ConfirmSendingBottomSheet extends StatelessWidget {
  ConfirmSendingBottomSheet({
    required this.titleText,
    this.titleIconPath,
    required this.currency,
    this.paymentId,
    this.paymentIdValue,
    this.expirationTime,
    required this.amount,
    required this.amountValue,
    required this.fiatAmountValue,
    required this.fee,
    required this.feeValue,
    required this.feeFiatAmount,
    required this.outputs,
    required this.onSlideComplete,
    this.change,
    Key? key,
  }) : super(key: key);

  final String titleText;
  final String? titleIconPath;
  final CryptoCurrency currency;
  final String? paymentId;
  final String? paymentIdValue;
  final String? expirationTime;
  final String amount;
  final String amountValue;
  final String fiatAmountValue;
  final String fee;
  final String feeValue;
  final String feeFiatAmount;
  final List<Output> outputs;
  final VoidCallback onSlideComplete;
  final PendingChange? change;

  static const headerHeight = 80;
  static const footerHeight = 94;

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

  Widget _buildHeader(BuildContext context) => Container(
        child: Column(
          children: [
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
                        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
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
            const SizedBox(height: 13),
          ],
        ),
      );

  Widget _buildContent(
          BuildContext context, TextStyle itemTitleTextStyle, TextStyle itemSubTitleTextStyle) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Column(
          children: [
            if (paymentId != null)
              Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: StandardTile(
                      itemTitle: 'Payment ID',
                      itemValue: paymentIdValue!,
                      itemTitleTextStyle: itemTitleTextStyle,
                      itemSubTitleTextStyle: itemSubTitleTextStyle)),
            StandardTile(
                itemTitle: amount,
                itemValue: amountValue + ' ${currency.title}',
                itemTitleTextStyle: itemTitleTextStyle,
                itemSubTitle: fiatAmountValue,
                itemSubTitleTextStyle: itemSubTitleTextStyle),
            const SizedBox(height: 8),
            StandardTile(
                itemTitle: fee,
                itemValue: feeValue,
                itemTitleTextStyle: itemTitleTextStyle,
                itemSubTitle: feeFiatAmount,
                itemSubTitleTextStyle: itemSubTitleTextStyle),
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
                    final batchContactTitle =
                        '${index + 1}/${outputs.length} - ${contactName.isEmpty ? 'Address' : contactName}';

                    final _address = item.isParsedAddress ? item.extractedAddress : item.address;
                    final _amount = item.cryptoAmount.replaceAll(',', '.') + ' ${currency.title}';

                    return isBatchSending || contactName.isNotEmpty
                        ? AddressExpansionTile(
                            contactType: 'Contact',
                            name: isBatchSending ? batchContactTitle : contactName,
                            address: _address,
                            amount: _amount,
                            isBatchSending: isBatchSending,
                            itemTitleTextStyle: itemTitleTextStyle,
                            itemSubTitleTextStyle: itemSubTitleTextStyle)
                        : AddressTile(
                            itemTitle: 'Address',
                            itemTitleTextStyle: itemTitleTextStyle,
                            isBatchSending: isBatchSending,
                            amount: _amount,
                            address: _address,
                            itemSubTitleTextStyle: itemSubTitleTextStyle);
                  },
                ),
                if (change != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: AddressExpansionTile(
                      contactType: 'Change',
                      name: S.of(context).send_change_to_you,
                      address: change!.address,
                      amount: change!.amount + ' ${currency.title}',
                      isBatchSending: true,
                      itemTitleTextStyle: itemTitleTextStyle,
                      itemSubTitleTextStyle: itemSubTitleTextStyle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      );

  Widget _buildFooter(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(40, 12, 40, 34),
        child: StandardSlideButton(
          onSlideComplete: onSlideComplete,
          buttonText: 'Swipe to send',
        ),
        decoration: BoxDecoration(
          boxShadow: [
            // BoxShadow(
            //   color: Colors.black.withOpacity(0.5),
            //   spreadRadius: 2,
            //   blurRadius: 10,
            //   offset: const Offset(0, 0),
            // ),
          ],
          color: Theme.of(context).dialogBackgroundColor,
        ),
      );

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

    final double maxHeight = MediaQuery.of(context).size.height * 0.7;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(30.0), topRight: const Radius.circular(30.0)),
        child: Wrap(
          children: [
            Container(
              color: Theme.of(context).dialogBackgroundColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildHeader(context),
                  _buildContent(context, itemTitleTextStyle, itemSubTitleTextStyle),
                  _buildFooter(context),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class StandardTile extends StatelessWidget {
  const StandardTile({
    super.key,
    required this.itemTitle,
    required this.itemValue,
    required this.itemTitleTextStyle,
    this.itemSubTitle,
    required this.itemSubTitleTextStyle,
  });

  final String itemTitle;
  final String itemValue;
  final TextStyle itemTitleTextStyle;
  final String? itemSubTitle;
  final TextStyle itemSubTitleTextStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).extension<FilterTheme>()!.buttonColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(itemTitle, style: itemTitleTextStyle),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(itemValue, style: itemTitleTextStyle),
              itemSubTitle == null
                  ? Container()
                  : Text(itemSubTitle!, style: itemSubTitleTextStyle),
            ],
          ),
        ],
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
    required this.address,
    required this.itemSubTitleTextStyle,
  });

  final String itemTitle;
  final TextStyle itemTitleTextStyle;
  final bool isBatchSending;
  final String amount;
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
              if (isBatchSending) Text(amount, style: itemTitleTextStyle),
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
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: isBatchSending ? 0 : 8),
          child: ExpansionTile(
            childrenPadding: EdgeInsets.zero,
            tilePadding: EdgeInsets.zero,
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isBatchSending ? name : contactType, style: itemTitleTextStyle),
                Text(isBatchSending ? amount : name, style: itemTitleTextStyle),
              ],
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(address, style: itemSubTitleTextStyle, softWrap: true),
                      ],
                    ),
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
  double _dragPosition = 0.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double maxWidth = constraints.maxWidth;
      const double sideMargin = 4.0;
      final double effectiveMaxWidth = maxWidth - 2 * sideMargin;
      const double sliderWidth = 42.0;

      return Container(
        height: widget.height,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).extension<CakeMenuTheme>()!.backgroundColor),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Center(
                child: Text(widget.buttonText,
                    style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor))),
            Positioned(
              left: sideMargin + _dragPosition,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _dragPosition += details.delta.dx;
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
                    setState(() => _dragPosition = 0);
                  }
                },
                child: Container(
                  width: sliderWidth,
                  height: widget.height - 8,
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

class ConfirmSendingBottomSheetPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(30.0),
        topRight: const Radius.circular(30.0),
      ),
      child: Container(
        height: 400,
        color: Theme.of(context).dialogBackgroundColor,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class TransactionSuccessBottomSheet extends StatelessWidget {
  TransactionSuccessBottomSheet(
      {required this.titleText,
      required this.currentTheme,
      this.contentImage,
      this.content,
      required this.context,
      this.isTwoAction = false,
      this.showDontAskMeCheckbox = false,
      this.onCheckboxChanged,
      this.actionButtonText,
      this.actionButton,
      this.actionButtonKey,
      this.leftButtonText,
      this.rightButtonText,
      this.actionLeftButton,
      this.actionRightButton,
      this.rightActionButtonKey,
      this.leftActionButtonKey,
      Key? key});

  final String titleText;
  final ThemeBase currentTheme;
  final String? contentImage;
  final String? content;
  final BuildContext context;
  final bool isTwoAction;
  final bool showDontAskMeCheckbox;
  final Function(bool)? onCheckboxChanged;
  final String? actionButtonText;
  final VoidCallback? actionButton;
  final Key? actionButtonKey;
  final String? leftButtonText;
  final String? rightButtonText;
  final VoidCallback? actionLeftButton;
  final VoidCallback? actionRightButton;
  final Key? rightActionButtonKey;
  final Key? leftActionButtonKey;

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

  @override
  Widget build(BuildContext context) {
    Widget _buildHeader(BuildContext context) => Container(
          child: Column(
            children: [
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
                          color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                        ),
                      ),
                    ),
                    const Spacer(flex: 4),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              title(context),
              const SizedBox(height: 13),
            ],
          ),
        );

    Widget _buildBottomTwoActionPanel() => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.only(right: 8.0, top: 8.0),
                      child: PrimaryButton(
                          key: leftActionButtonKey,
                          onPressed: actionLeftButton,
                          text: leftButtonText ?? '',
                          color: Theme.of(context).extension<CakeMenuTheme>()!.backgroundColor,
                          textColor: currentTheme.type == ThemeType.dark
                              ? Theme.of(context).extension<DashboardPageTheme>()!.textColor
                              : Theme.of(context).extension<CakeTextTheme>()!.buttonTextColor),
                    ),
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                      child: PrimaryButton(
                        key: rightActionButtonKey,
                        onPressed: actionRightButton,
                        text: rightButtonText ?? '',
                        color: Theme.of(context).primaryColor,
                        textColor: currentTheme.type == ThemeType.dark
                            ? Theme.of(context).extension<DashboardPageTheme>()!.textColor
                            : Theme.of(context).extension<CakeTextTheme>()!.buttonTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        );

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(30.0),
        topRight: const Radius.circular(30.0),
      ),
      child: Container(
        height: 400,
        color: Theme.of(context).dialogBackgroundColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildHeader(context),
            Expanded(flex: 4, child: contentImage != null ? getImage(contentImage!) : Container()),
            if (content != null)
              Expanded(
                flex: 2,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(flex: 2),
                    Expanded(
                      flex: 6,
                      child: Text(
                        content!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            if (showDontAskMeCheckbox)
            Padding(
              padding: const EdgeInsets.only(left: 34.0),
              child: Row(
                children: [
                  SimpleCheckbox(currentTheme: currentTheme, onChanged: onCheckboxChanged),
                  const SizedBox(width: 8),
                  Text(
                    'Don’t ask me next time',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            isTwoAction
                ? _buildBottomTwoActionPanel()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 34),
                    child: LoadingPrimaryButton(
                      key: actionButtonKey,
                      onPressed: actionButton ?? () {},
                      text: actionButtonText ?? '',
                      color: Theme.of(context).primaryColor,
                      textColor: Colors.white,
                      isLoading: false,
                      isDisabled: false,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget getImage(String imagePath, {Color? imageColor}) {
    final bool isSvg = imagePath.endsWith('.svg');
    if (isSvg) {
      return SvgPicture.asset(
        imagePath,
        colorFilter: imageColor != null ? ColorFilter.mode(imageColor, BlendMode.srcIn) : null,
      );
    } else {
      return Image.asset(imagePath);
    }
  }
}

class SimpleCheckbox extends StatefulWidget {
  SimpleCheckbox({required this.currentTheme, this.onChanged});

  final ThemeBase currentTheme;
  final Function(bool)? onChanged;

  @override
  State<SimpleCheckbox> createState() => _SimpleCheckboxState();
}

class _SimpleCheckboxState extends State<SimpleCheckbox> {
  bool initialValue = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24.0,
      width: 24.0,
      child: Checkbox(
        value: initialValue,
        onChanged: (value) => setState(() {
          initialValue = value!;
          widget.onChanged?.call(value);
        }),
        checkColor: Colors.white,
        activeColor: Colors.transparent,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: WidgetStateBorderSide.resolveWith(
            (states) => BorderSide(color: Colors.white, width: 1.0)),
      ),
    );
  }
}

// class SimplCheckbox extends StatelessWidget {
//   SimplCheckbox({required this.value,
//     this.borderColor,
//     this.iconColor,
//     required this.onChanged});
//
//   final bool value;
//   final Color? borderColor;
//   final Color? iconColor;
//   final Function(bool) onChanged;
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () => onChanged(!value),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         mainAxisAlignment: MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: <Widget>[
//           Container(
//             height: 24.0,
//             width: 24.0,
//             decoration: BoxDecoration(
//                 border: Border.all(
//                   color: value
//                       ? Theme
//                       .of(context)
//                       .extension<CakeTextTheme>()!
//                       .secondaryTextColor
//                       : borderColor ?? Theme
//                       .of(context)
//                       .extension<CakeTextTheme>()!
//                       .secondaryTextColor,
//                   width: 1.0,
//                 )
//             ),
//
//             child: value
//                 ? Icon(
//               Icons.check,
//               color: iconColor ?? Theme
//                   .of(context)
//                   .primaryColor,
//               size: 20.0,
//             )
//                 : Offstage(),
//           ),
//           if (caption.isNotEmpty)
//             Flexible(
//               child: Padding(
//                 padding: EdgeInsets.only(left: 10),
//                 child: Text(
//                   caption,
//                   softWrap: true,
//                   style: TextStyle(
//                     fontSize: 16.0,
//                     fontFamily: 'Lato',
//                     fontWeight: FontWeight.normal,
//                     color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
//                     decoration: TextDecoration.none,
//                   ),
//                 ),
//               ),
//             )
//         ],
//       ),
//     );
//   }
// }
