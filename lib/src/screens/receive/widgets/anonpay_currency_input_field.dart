import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cw_core/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnonpayCurrencyInputField extends StatelessWidget {
  const AnonpayCurrencyInputField(
      {super.key,
      required this.onTapPicker,
      required this.selectedCurrency,
      required this.focusNode,
      required this.controller,
      required this.minAmount,
      required this.maxAmount});
  final Function() onTapPicker;
  final Currency selectedCurrency;
  final FocusNode focusNode;
  final TextEditingController controller;
  final String minAmount;
  final String maxAmount;

  @override
  Widget build(BuildContext context) {
    final arrowBottomPurple = Image.asset(
      'assets/images/arrow_bottom_purple_icon.png',
      color: Theme.of(context).colorScheme.primary,
      height: 8,
    );

    return Column(
      children: [
        Container(
          child: Padding(
            padding: EdgeInsets.only(top: 20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.only(right: 8),
                  height: 32,
                  child: InkWell(
                    onTap: onTapPicker,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(right: 5),
                          child: arrowBottomPurple,
                        ),
                        Text(
                          selectedCurrency.name.toUpperCase(),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (selectedCurrency.tag != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 3.0),
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(
                            selectedCurrency.tag!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Text(
                    ':',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: BaseTextFormField(
                          hasUnderlineBorder: true,
                          borderWidth: 0.0,
                          focusNode: focusNode,
                          controller: controller,
                          textInputAction: TextInputAction.next,
                          enabled: true,
                          textAlign: TextAlign.left,
                          keyboardType:
                              TextInputType.numberWithOptions(signed: false, decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.deny(RegExp('[\\-|\\ ]'))],
                          hintText: '0.0000',
                          textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                          placeholderTextStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          validator: null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
        Container(
          height: 15,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(
                S.of(context).min_value(minAmount, selectedCurrency.toString()),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.2,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              SizedBox(width: 10),
              Text(
                S.of(context).max_value(maxAmount, selectedCurrency.toString()),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.2,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
