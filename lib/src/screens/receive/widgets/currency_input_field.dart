import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cw_core/crypto_amount_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CurrencyAmountTextField extends StatelessWidget {
  const CurrencyAmountTextField({
    required this.selectedCurrency,
    required this.selectedCurrencyDecimals,
    required this.amountFocusNode,
    required this.amountController,
    required this.isAmountEditable,
    this.allAmountButton = false,
    this.isPickerEnable = false,
    this.isSelected = false,
    this.currentThemeType = ThemeType.dark,
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
    this.fillColor,
    this.borderColor,
    this.hasUnderlineBorder = false,
    this.borderWidth = 1.0,
  }) : super(key: currencyAmountTextFieldWidgetKey);

  final Key? sendAllButtonKey;
  final Key? amountTextfieldKey;
  final Key? currencyPickerButtonKey;
  final Key? selectedCurrencyTextKey;
  final Key? selectedCurrencyTagTextKey;
  final Key? currencyAmountTextFieldWidgetKey;
  final Widget? imageArrow;
  final String selectedCurrency;
  final int selectedCurrencyDecimals;
  final String? tag;
  final String? hintText;
  final Color? tagBackgroundColor;
  final EdgeInsets? padding;
  final FocusNode? amountFocusNode;
  final TextEditingController amountController;
  final bool isAmountEditable;
  final FormFieldValidator<String>? currencyValueValidator;
  final bool isPickerEnable;
  final ThemeType currentThemeType;
  final bool isSelected;
  final bool allAmountButton;
  final VoidCallback? allAmountCallback;
  final VoidCallback? onTapPicker;
  final Color? fillColor;
  final Color? borderColor;
  final bool hasUnderlineBorder;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
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
                            Image.asset(
                              'assets/images/arrow_bottom_purple_icon.png',
                              color: Theme.of(context).colorScheme.primary,
                              height: 8,
                            ),
                      ),
                      Text(
                        key: selectedCurrencyTextKey,
                        selectedCurrency,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                color: tagBackgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.all(Radius.circular(6)),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text(
                    key: selectedCurrencyTagTextKey,
                    tag!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: textColor,
                ),
          ),
        ),
      ],
    );
    return Padding(
      padding: padding ?? const EdgeInsets.only(top: 20),
      child: Row(
        children: [
          isSelected
              ? Container(
                  child: _prefixContent,
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: textColor,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : _prefixContent,
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: FocusTraversalOrder(
                    order: NumericFocusOrder(1),
                    child: BaseTextFormField(
                      hasUnderlineBorder: hasUnderlineBorder,
                      borderWidth: borderWidth,
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
                      fillColor: fillColor,
                      textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                      placeholderTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      validator: isAmountEditable ? currencyValueValidator : null,
                      onChanged: (value) {
                        final sanitized =
                            value.replaceAll(',', '.').withMaxDecimals(selectedCurrencyDecimals);
                        if (sanitized != amountController.text) {
                          // Update text while preserving a sane cursor position to avoid auto-selection
                          amountController.value = amountController.value.copyWith(
                            text: sanitized,
                            selection: TextSelection.collapsed(offset: sanitized.length),
                            composing: TextRange.empty,
                          );
                        }
                      },
                    ),
                  ),
                ),
                if (allAmountButton)
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.all(Radius.circular(6)),
                    ),
                    child: InkWell(
                      key: sendAllButtonKey,
                      onTap: allAmountCallback,
                      child: Center(
                        child: Text(
                          S.of(context).all,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
