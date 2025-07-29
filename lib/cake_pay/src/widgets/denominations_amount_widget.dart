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
  final List<String> denominations;
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
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.amountController.text.isNotEmpty
        ? widget.amountController.text
        : widget.denominations.first;
    widget.amountController.text = _selected;
    widget.onAmountChanged(_selected);
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
                  items: widget.denominations,
                  itemPrefix: widget.fiatCurrency,
                  selectedItem: _selected,
                  onItemSelected: (value) {
                    setState(() => _selected = value);
                    widget.amountController.text = value;
                    widget.onAmountChanged(value);
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
