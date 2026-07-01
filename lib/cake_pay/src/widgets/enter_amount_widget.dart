import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EnterAmountWidget extends StatelessWidget {
  const EnterAmountWidget(
      {required this.minValue,
      required this.maxValue,
      required this.fiatCurrency,
      required this.amountFieldFocus,
      required this.amountController,
      required this.onAmountChanged});

  final String minValue;
  final String maxValue;
  final String fiatCurrency;
  final FocusNode amountFieldFocus;
  final TextEditingController amountController;
  final Function(String) onAmountChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Spacer(flex: 1),
          Text(
            S.of(context).enter_amount,
            style: Theme.of(context).textTheme.titleLarge!,
          ),
          Container(
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        width: 1.0, color: Theme.of(context).colorScheme.onSurfaceVariant))),
            child: BaseTextFormField(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              controller: amountController,
              keyboardType: TextInputType.numberWithOptions(signed: false, decimal: true),
              hintText: '0.00',
              maxLines: 1,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  '$fiatCurrency: ',
                  style: Theme.of(context).textTheme.titleMedium!,
                ),
              ),
              prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(top: 2, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('QTY ', style: Theme.of(context).textTheme.titleMedium!),
                    Text(
                      '1',
                      style: Theme.of(context).textTheme
                          .titleMedium!
                          .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)
                    ),
                  ],
                ),
              ),
              textStyle: Theme.of(context).textTheme.titleMedium!,
              placeholderTextStyle: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp('[\-|\ ]')),
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d+(\.|\,)?\d{0,2}'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(S.of(context).min_amount(minValue) + ' $fiatCurrency',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
              Text(S.of(context).max_amount(maxValue) + ' $fiatCurrency',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
            ],
          ),
          Spacer(flex: 1),
        ],
      ),
    );
  }
}
