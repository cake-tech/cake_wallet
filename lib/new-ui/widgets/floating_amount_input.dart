import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/new-ui/widgets/money/currency_symbol_text.dart";
import "package:cw_core/currency.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

class FloatingAmountInput extends StatefulWidget {
  const FloatingAmountInput({
    required this.currency,
    required this.controller,
    super.key,
    this.focusNode,
    this.inputFormatters,
    this.onChanged,
    this.validator,
  });

  final Currency currency;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final Function(String)? onChanged;
  final FormFieldValidator<String>? validator;

  @override
  State<FloatingAmountInput> createState() => _FloatingAmountInputState();
}

class _FloatingAmountInputState extends State<FloatingAmountInput> {
  bool _amountFocused = false;
  late FocusNode focusNode = widget.focusNode ?? FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() => setState(() => _amountFocused = focusNode.hasFocus));
  }

  @override
  void dispose() {
    if (focusNode != widget.focusNode) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Row(
          textDirection: TextDirection.ltr,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            if (_fiatCurrency?.signAfterAmount == false) ...[
              Text(_fiatCurrency!.sign, maxLines: 1, style: _unitStyle(context)),
              if (!_fiatCurrency!.signTouchesAmount) const SizedBox(width: 8),
            ],
            IntrinsicWidth(
              child: TextFormField(
                controller: widget.controller,
                focusNode: focusNode,
                maxLines: 1,
                onChanged: widget.onChanged,
                autovalidateMode: AutovalidateMode.always,
                validator: widget.validator,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: false,
                  decimal: true,
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(
                    RegExp(r"^\d*[.,]?\d*$"),
                  ),
                ],
                decoration: InputDecoration(
                  isDense: true,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                  fillColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  hintText: _amountFocused || widget.controller.text.isNotEmpty ? null : "0.00",
                  hintStyle: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 45,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
            if (_fiatCurrency == null) ...[
              const SizedBox(width: 8),
              CurrencySymbolText(
                widget.currency,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _unitStyle(context),
              ),
            ],
            if (_fiatCurrency?.signAfterAmount == true) ...[
              const SizedBox(width: 8),
              Text(_fiatCurrency!.sign, maxLines: 1, style: _unitStyle(context)),
            ],
          ],
        ),
      );

  FiatCurrency? get _fiatCurrency {
    final currency = widget.currency;

    return currency is FiatCurrency ? currency : null;
  }

  TextStyle? _unitStyle(BuildContext context) =>
      Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w400,
            fontSize: 45,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          );
}
