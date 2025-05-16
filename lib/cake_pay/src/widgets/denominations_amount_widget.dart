import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/number_text_fild_widget.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/view_model/cake_pay/cake_pay_buy_card_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/dropdown_filter_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class DenominationsAmountWidget extends StatelessWidget {
  const DenominationsAmountWidget({
    required this.fiatCurrency,
    required this.denominations,
    required this.amountFieldFocus,
    required this.amountController,
    required this.quantityFieldFocus,
    required this.quantityController,
    required this.cakePayBuyCardViewModel,
    required this.onAmountChanged,
    required this.onQuantityChanged
  });

  final String fiatCurrency;
  final List<String> denominations;
  final FocusNode amountFieldFocus;
  final TextEditingController amountController;
  final FocusNode quantityFieldFocus;
  final TextEditingController quantityController;
  final CakePayBuyCardViewModel cakePayBuyCardViewModel;
  final Function(String) onAmountChanged;
  final Function(int?) onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Expanded(
                  child: DropdownFilterList(
                    items: denominations,
                    itemPrefix: fiatCurrency,
                    selectedItem: denominations.first,
                    textStyle: textMediumSemiBold(
                        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor),
                    onItemSelected: (value) {
                      amountController.text = value;
                      onAmountChanged(value);
                    },
                    caption: '',
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                            width: 1.0,
                            color:
                            Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor),
                      ),
                    ),
                    child: Text(S.of(context).choose_card_value + ':',
                        maxLines: 2,
                        style: textSmall(
                            color:
                            Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: const SizedBox()),
          Expanded(
            flex: 8,
            child: Column(
              children: [
                Expanded(
                  child: NumberTextField(
                    controller: quantityController,
                    focusNode: quantityFieldFocus,
                    min: 1,
                    max: 99,
                    onChanged: (value) => onQuantityChanged(value),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                            width: 1.0,
                            color:
                            Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor),
                      ),
                    ),
                    child: Text(S.of(context).quantity + ':',
                        maxLines: 1,
                        style: textSmall(
                            color:
                            Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: const SizedBox()),
          Expanded(
              flex: 12,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                        alignment: Alignment.bottomCenter,
                        child: Observer(
                            builder: (_) => AutoSizeText(
                                '$fiatCurrency ${cakePayBuyCardViewModel.totalAmount}',
                                maxLines: 1,
                                style: textMediumSemiBold(
                                    color: Theme.of(context)
                                        .extension<CakeTextTheme>()!
                                        .titleColor)))),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                              width: 1.0,
                              color:
                              Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor),
                        ),
                      ),
                      child: Text(S.of(context).total + ':',
                          maxLines: 1,
                          style: textSmall(
                              color: Theme.of(context)
                                  .extension<CakeTextTheme>()!
                                  .secondaryTextColor)),
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }
}