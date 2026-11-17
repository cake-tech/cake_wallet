import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_scaffold.dart";
import "package:cake_wallet/new-ui/widgets/floating_amount_input.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/new-ui/widgets/money/money_text.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cw_core/amount/amount_sanitizer.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/currency.dart";
import "package:flutter/material.dart";

class DefiAmountView extends StatefulWidget {
  const DefiAmountView({
    required this.maxAmount,
    required this.maxLabel,
    required this.maxChipLabel,
    required this.fiatRate,
    required this.onContinue,
    this.hint,
    this.error,
    this.isLoading = false,
    this.disabled = false,
    this.onChanged,
    this.attribution,
    super.key,
  });

  final Money maxAmount;
  final String maxLabel;
  final String maxChipLabel;
  final ExchangeRate? fiatRate;
  final void Function(Money amount, {required bool isMax}) onContinue;
  final String? hint;
  final String? error;
  final bool isLoading;
  final bool disabled;
  final VoidCallback? onChanged;
  final Widget? attribution;

  @override
  State<DefiAmountView> createState() => _DefiAmountViewState();
}

class _DefiAmountViewState extends State<DefiAmountView> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  late Currency _inputCurrency = widget.fiatRate?.quote.currency ?? _asset;

  bool _useMax = false;

  Money? _switchedAmount;

  Currency get _asset => widget.maxAmount.currency;

  Money? get _fixedAmount => _useMax ? widget.maxAmount : _switchedAmount;

  Money? get _typedAmount => Money.tryParse(_controller.text.sanitized(), _inputCurrency);

  Money? get _amount => _inAsset(_fixedAmount ?? _typedAmount);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void didUpdateWidget(DefiAmountView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final fixedAmount = _fixedAmount;
    if (fixedAmount != null &&
        (widget.maxAmount != oldWidget.maxAmount || widget.fiatRate != oldWidget.fiatRate)) {
      _showAmount(fixedAmount);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final amount = _amount;
    final convertsToFiat = _inputCurrency == _asset;
    final shownAmount = amount ?? (_controller.text.isEmpty ? Money.zero(_asset) : null);
    final converted = shownAmount == null || !convertsToFiat
        ? shownAmount
        : widget.fiatRate?.convert(shownAmount);
    final convertedStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurfaceVariant,
    );
    final inputError = _hasTooManyDecimals ? S.of(context).decimal_places_error : null;
    final error = inputError ?? widget.error;

    return DefiScaffold(
      gradient: true,
      child: Column(
        children: [
          ModalTopBar(
            title: S.of(context).enter_amount,
            bottomText: "${widget.maxLabel} (${widget.maxAmount.toLocalStringWithSymbol(
              fractionalDigits: 8,
              locale: locale,
            )})",
            leadingIcon: const Icon(Icons.close),
            leadingSemanticLabel: S.of(context).close,
            onLeadingPressed: Navigator.of(context, rootNavigator: true).pop,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox.shrink(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      spacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 8,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: FloatingAmountInput(
                                  currency: _inputCurrency,
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  onChanged: (_) {
                                    setState(() {
                                      _useMax = false;
                                      _switchedAmount = null;
                                    });
                                    widget.onChanged?.call();
                                  },
                                ),
                              ),
                            ),
                            if (widget.fiatRate != null)
                              ModernButton.svg(
                                size: 28,
                                iconSize: 18,
                                svgPath: "assets/new-ui/switch.svg",
                                semanticLabel: S.of(context).switch_input_currency,
                                onPressed: _switchInputCurrency,
                              ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 8,
                          children: [
                            if (converted != null)
                              Flexible(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  // the switch button already offers this to screen readers
                                  excludeFromSemantics: true,
                                  onTap: _switchInputCurrency,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text("≈ ", style: convertedStyle),
                                      Flexible(
                                        child: MoneyText(
                                          converted,
                                          isHiddenAmount: false,
                                          fractionalDigits: convertsToFiat ? 2 : 8,
                                          trimZeros: !convertsToFiat,
                                          overflow: TextOverflow.ellipsis,
                                          style: convertedStyle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            _MaxChip(label: widget.maxChipLabel, onPressed: _fillMax),
                          ],
                        ),
                        if (error != null)
                          Text(
                            error,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.error),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      spacing: 8,
                      children: [
                        if (widget.attribution != null) widget.attribution!,
                        if (widget.hint != null)
                          Text(
                            widget.hint!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        NewPrimaryButton(
                          onPressed: () => widget.onContinue(amount!, isMax: _useMax),
                          isLoading: widget.isLoading,
                          disabled: widget.disabled ||
                              inputError != null ||
                              amount == null ||
                              amount.sign <= 0,
                          text: S.of(context).continue_text,
                          color: theme.colorScheme.primary,
                          textColor: theme.colorScheme.onPrimary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Money? _inAsset(Money? amount) {
    if (amount == null || amount.currency == _asset) {
      return amount;
    }

    final fiatRate = widget.fiatRate;
    if (fiatRate == null) {
      return null;
    }

    final asset = fiatRate.convert(amount);
    return fiatRate.convert(asset) < amount ? asset + Money(BigInt.one, _asset) : asset;
  }

  bool get _hasTooManyDecimals {
    final parts = _controller.text.split(RegExp("[.,]"));
    return parts.length == 2 && parts.last.length > _inputCurrency.decimals;
  }

  void _showAmount(Money amount) {
    final display = amount.currency == _inputCurrency ? amount : widget.fiatRate?.convert(amount);
    if (display == null) {
      return;
    }

    final text = display.toStringWithPrecision(fractionalDigits: 8);
    if (_controller.text != text) {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  void _fillMax() {
    if (_inputCurrency != _asset && widget.fiatRate == null) {
      return;
    }

    _showAmount(widget.maxAmount);
    setState(() => _useMax = true);
    widget.onChanged?.call();
  }

  void _switchInputCurrency() {
    final fiatRate = widget.fiatRate;
    if (fiatRate == null) {
      return;
    }

    final amount = _fixedAmount ?? _typedAmount;
    setState(() {
      _inputCurrency = _inputCurrency == _asset ? fiatRate.quote.currency : _asset;
      _switchedAmount = amount;
    });
    if (amount == null) {
      _controller.clear();
    } else {
      _showAmount(amount);
    }
  }
}

class _MaxChip extends StatelessWidget {
  const _MaxChip({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: Semantics(
          button: true,
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: onPressed,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
            ),
          ),
        ),
      );
}
