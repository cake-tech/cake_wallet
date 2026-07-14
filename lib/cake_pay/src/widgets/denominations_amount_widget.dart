import 'package:cake_wallet/cake_pay/src/models/cake_pay_card.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/number_text_fild_widget.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/view_model/cake_pay/cake_pay_buy_card_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/dropdown_filter_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class DenominationsAmountWidget extends StatefulWidget {
  const DenominationsAmountWidget({
    required this.fiatCurrency,
    required this.denominations,
    required this.amountFieldFocus,
    required this.amountController,
    required this.quantityFieldFocus,
    required this.quantityController,
    required this.cakePayBuyCardViewModel,
    required this.onAmountChanged,
    required this.onQuantityChanged,
  });

  final String fiatCurrency;
  final List<Denomination> denominations;
  final FocusNode amountFieldFocus;
  final TextEditingController amountController;
  final FocusNode quantityFieldFocus;
  final TextEditingController quantityController;
  final CakePayBuyCardViewModel cakePayBuyCardViewModel;
  final Function(String) onAmountChanged;
  final Function(int?) onQuantityChanged;

  @override
  State<DenominationsAmountWidget> createState() => _DenominationsAmountWidgetState();
}

class _DenominationsAmountWidgetState extends State<DenominationsAmountWidget> {
  late (String, int?) _selected;

  @override
  void initState() {
    super.initState();

    final first = widget.denominations.first;
    final amount = widget.amountController.text.isNotEmpty
        ? widget.amountController.text
        : first.value.toString();
    _selected = (amount, first.cardId);
    widget.cakePayBuyCardViewModel.selectedDenomination = _selected;

    widget.amountController.text = _selected.$1;
    widget.onAmountChanged(_selected.$1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownFilterList(
                  items: widget.denominations
                      .map((e) => e.value.toString())
                      .toList(),
                  itemPrefix: widget.fiatCurrency,
                  selectedItem: _selected.$1,
                  onItemSelected: (value) {
                    setState(() => _selected = (value, widget.denominations
                        .firstWhere((e) => e.value.toString() == value)
                        .cardId));
                    widget.amountController.text = value;
                    widget.onAmountChanged(value);
                    widget.cakePayBuyCardViewModel.selectedDenomination = (_selected.$1, _selected.$2);
                  },
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        width: 1.0,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  child: Text(
                    S.of(context).value,
                    maxLines: 2,
                    style: textSmall(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          Spacer(),
          Expanded(
            flex: 5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NumberTextField(
                  controller: widget.quantityController,
                  focusNode: widget.quantityFieldFocus,
                  min: 1,
                  max: 99,
                  onChanged: (value) => widget.onQuantityChanged(value),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        width: 1.0,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  child: Text(
                    S.of(context).quantity,
                    maxLines: 1,
                    style: textSmall(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          Spacer(),
          Expanded(
            flex: 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Observer(
                  builder: (_) => Text(
                    '${widget.fiatCurrency} ${widget.cakePayBuyCardViewModel.totalAmount}',
                    maxLines: 1,
                    style: Theme.of(context).textTheme.titleMedium!,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        width: 1.0,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  child: Text(
                    S.of(context).total,
                    maxLines: 1,
                    style: textSmall(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
