import 'package:cake_wallet/cake_pay/src/models/cake_pay_card.dart';
import 'package:cake_wallet/view_model/cake_pay/cake_pay_buy_card_view_model.dart';
import 'package:flutter/material.dart';

import 'enter_amount_widget.dart';

class PrepaidRangeAmountWidget extends StatefulWidget {
  const PrepaidRangeAmountWidget({
    required this.fiatCurrency,
    required this.prepaidRanges,
    required this.amountFieldFocus,
    required this.amountController,
    required this.cakePayBuyCardViewModel,
    required this.onAmountChanged,
  });

  final String fiatCurrency;
  final List<PrepaidRange> prepaidRanges;
  final FocusNode amountFieldFocus;
  final TextEditingController amountController;
  final CakePayBuyCardViewModel cakePayBuyCardViewModel;
  final Function(String) onAmountChanged;

  @override
  State<PrepaidRangeAmountWidget> createState() => _PrepaidRangeAmountWidgetState();
}

class _PrepaidRangeAmountWidgetState extends State<PrepaidRangeAmountWidget> {
  late PrepaidRange _selectedRange;

  @override
  void initState() {
    super.initState();
    _selectedRange = widget.prepaidRanges.first;
    _applySelectedRange(forceAmountUpdate: widget.amountController.text.isEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select range:',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge!.color!,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<PrepaidRange>(
          value: _selectedRange,
          isExpanded: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(40),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          items: widget.prepaidRanges
              .map(
                (range) => DropdownMenuItem<PrepaidRange>(
                  value: range,
                  child: Text(_rangeLabel(range)),
                ),
              )
              .toList(),
          onChanged: (range) {
            if (range == null) return;
            setState(() => _selectedRange = range);
            widget.cakePayBuyCardViewModel.onPrepaidRangeChanged(range);
            _applySelectedRange(forceAmountUpdate: true);
          },
        ),
        const SizedBox(height: 12),
        EnterAmountWidget(
          minValue: _formatAmount(_selectedRange.minValue),
          maxValue: _formatAmount(_selectedRange.maxValue),
          fiatCurrency: widget.fiatCurrency,
          amountFieldFocus: widget.amountFieldFocus,
          amountController: widget.amountController,
          onAmountChanged: (value) {
            widget.onAmountChanged(value);
            widget.cakePayBuyCardViewModel.selectedDenomination = (
              value.replaceAll(',', '.'),
              int.tryParse(_selectedRange.rangeId),
            );
          },
        ),
      ],
    );
  }

  void _applySelectedRange({required bool forceAmountUpdate}) {
    final currentAmount = double.tryParse(widget.amountController.text);
    final isCurrentAmountInRange = currentAmount != null &&
        currentAmount >= _selectedRange.minValue &&
        currentAmount <= _selectedRange.maxValue;

    final nextAmount = forceAmountUpdate || !isCurrentAmountInRange
        ? _formatAmount(_selectedRange.minValue)
        : widget.amountController.text;

    widget.amountController.text = nextAmount;
    widget.onAmountChanged(nextAmount);
    widget.cakePayBuyCardViewModel.selectedDenomination = (
      nextAmount.replaceAll(',', '.'),
      int.tryParse(_selectedRange.rangeId),
    );
  }

  String _rangeLabel(PrepaidRange range) {
    return '${widget.fiatCurrency} ${_formatAmount(range.minValue)} - ${_formatAmount(range.maxValue)}';
  }

  String _formatAmount(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
  }
}
