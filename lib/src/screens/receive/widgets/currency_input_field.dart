import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CurrencyAmountTextField extends StatelessWidget {
  const CurrencyAmountTextField({
    required this.selectedCurrency,
    required this.amountFocusNode,
    required this.amountController,
    required this.isAmountEditable,
    this.allAmountButton = false,
    this.isPickerEnable = false,
    this.isSelected = false,
    this.currentTheme = ThemeType.dark,
    this.onTapPicker,
    this.padding,
    this.imageArrow,
    this.hintText,
    this.tag,
    this.tagBackgroundColor,
    this.currencyValueValidator,
    this.allAmountCallback,
    this.sendAllButtonKey,
    this.amountTextfieldKey,
    this.currencyPickerButtonKey,
    this.selectedCurrencyTextKey,
    this.selectedCurrencyTagTextKey,
    this.currencyAmountTextFieldWidgetKey,
  }) : super(key: currencyAmountTextFieldWidgetKey);

  final Key? sendAllButtonKey;
  final Key? amountTextfieldKey;
  final Key? currencyPickerButtonKey;
  final Key? selectedCurrencyTextKey;
  final Key? selectedCurrencyTagTextKey;
  final Key? currencyAmountTextFieldWidgetKey;
  final Widget? imageArrow;
  final String selectedCurrency;
  final String? tag;
  final String? hintText;
  final Color? tagBackgroundColor;
  final EdgeInsets? padding;
  final FocusNode? amountFocusNode;
  final TextEditingController amountController;
  final bool isAmountEditable;
  final FormFieldValidator<String>? currencyValueValidator;
  final bool isPickerEnable;
  final ThemeType currentTheme;
  final bool isSelected;
  final bool allAmountButton;
  final VoidCallback? allAmountCallback;
  final VoidCallback? onTapPicker;

  @override
  Widget build(BuildContext context) {
    final textColor = currentTheme == ThemeType.light
        ? Theme.of(context).appBarTheme.titleTextStyle!.color!
        : Colors.white;
    final _prefixContent = Row(
      children: [
        isPickerEnable
            ? Container(
                height: 32,
                child: InkWell(
                  key: currencyPickerButtonKey,
                  onTap: onTapPicker,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: imageArrow ??
                              Image.asset('assets/images/arrow_bottom_purple_icon.png',
                                  color: textColor, height: 8)),
                      Text(
                        key: selectedCurrencyTextKey,
                        selectedCurrency,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Text(
                key: selectedCurrencyTextKey,
                selectedCurrency,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
        if (tag != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: tagBackgroundColor ??
                    Theme.of(context).extension<SendPageTheme>()!.textFieldButtonColor,
                borderRadius: const BorderRadius.all(Radius.circular(6)),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text(
                    key: selectedCurrencyTagTextKey,
                    tag!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).extension<SendPageTheme>()!.textFieldButtonIconColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(right: 4.0),
          child: Text(
            ':',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: textColor,
            ),
          ),
        ),
      ],
    );
    return Padding(
      padding: padding ?? const EdgeInsets.only(top: 0),
      child: Row(
        children: [
          isSelected
              ? Container(
                  child: _prefixContent,
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                      border: Border.all(
                        color: textColor,
                      ),
                      borderRadius: BorderRadius.circular(26),
                      color: Theme.of(context).primaryColor))
              : _prefixContent,
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: FocusTraversalOrder(
                    order: NumericFocusOrder(1),
                    child: BaseTextFormField(
                      key: amountTextfieldKey,
                      focusNode: amountFocusNode,
                      controller: amountController,
                      enabled: isAmountEditable,
                      textAlign: TextAlign.left,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: false,
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp('[\\-|\\ ]')),
                      ],
                      hintText: hintText ?? '0.0000',
                      borderColor: Colors.transparent,
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      placeholderTextStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: currentTheme == ThemeType.light
                            ? Theme.of(context).appBarTheme.titleTextStyle!.color!
                            : Theme.of(context).extension<ExchangePageTheme>()!.hintTextColor,
                      ),
                      validator: isAmountEditable ? currencyValueValidator : null,
                    ),
                  ),
                ),
                if (allAmountButton)
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).extension<SendPageTheme>()!.textFieldButtonColor,
                      borderRadius: const BorderRadius.all(Radius.circular(6)),
                    ),
                    child: InkWell(
                      key: sendAllButtonKey,
                      onTap: allAmountCallback,
                      child: Center(
                        child: Text(
                          S.of(context).all,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .extension<SendPageTheme>()!
                                .textFieldButtonIconColor,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
