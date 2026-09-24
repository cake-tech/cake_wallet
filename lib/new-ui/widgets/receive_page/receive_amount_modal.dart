import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/receive/receive_bloc.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/token_image_widget.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_sheet.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/fiat_currency_picker_sheet.dart";
import "package:cake_wallet/new-ui/widgets/money/currency_symbol_text.dart";
import "package:cake_wallet/new-ui/widgets/money/use_base_unit_provider.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/utils/decimal_input_formatter.dart";
import "package:cw_core/amount/money.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class ReceiveAmountModal extends StatelessWidget {
  const ReceiveAmountModal({required this.bloc, required this.amountAtOpen, super.key});

  final ReceiveBloc bloc;
  final Money? amountAtOpen;

  @override
  Widget build(BuildContext context) => BlocBuilder<ReceiveBloc, ReceiveState>(
        bloc: bloc,
        buildWhen: (_, next) => next is ReceiveLoaded,
        builder: (context, state) {
          if (state is! ReceiveLoaded) {
            return const SizedBox.shrink();
          }

          return _AmountForm(
            key: ValueKey(state.cryptoCurrency),
            bloc: bloc,
            state: state,
            initialAmount: state.amountInInputCurrency ?? amountAtOpen,
            useBaseUnit: BaseUnit.useBaseUnitOf(context, state.inputCurrency),
          );
        },
      );
}

class _AmountForm extends StatefulWidget {
  const _AmountForm({
    required this.bloc,
    required this.state,
    required this.initialAmount,
    required this.useBaseUnit,
    super.key,
  });

  final ReceiveBloc bloc;
  final ReceiveLoaded state;
  final Money? initialAmount;
  final bool useBaseUnit;

  @override
  State<_AmountForm> createState() => _AmountFormState();
}

class _AmountFormState extends State<_AmountForm> {
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount?.toStringWithPrecision(useBaseUnit: widget.useBaseUnit) ?? "",
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int get _inputDecimals => widget.useBaseUnit ? 0 : widget.state.inputCurrency.decimals;

  Money? _parseAmount(String raw) => Money.tryParse(
        raw.replaceAll(",", "."),
        widget.state.inputCurrency,
        isBaseUnit: widget.useBaseUnit,
      );

  Future<void> _pickInputCurrency() => FiatCurrencyPickerSheet.show(
        context: context,
        selected: widget.state.inputCurrency,
        cryptoOption: widget.state.cryptoCurrency,
        onSelected: (fiat) => widget.bloc.add(InputCurrencySelected(fiat)),
        onCryptoSelected: (crypto) => widget.bloc.add(InputCurrencySelected(crypto)),
      );

  Future<void> _pickToken() => CurrencyPickerSheet.show(
        context: context,
        args: CurrencyPickerArgs(
          items: widget.state.receivableTokens,
          selected: widget.state.tokenCurrency,
          onSelected: (currency) => widget.bloc.add(TokenSelected(currency)),
          symbolResolver: (c) => c.title,
        ),
      );

  String get _amountHint {
    if (_inputDecimals <= 0) {
      return "0";
    }
    final hintDecimals = _inputDecimals > 8 ? 8 : _inputDecimals;
    return "0.${"0" * hintDecimals}";
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModalTopBar(
                  title: S.of(context).set_amount,
                  onLeadingPressed: Navigator.of(context).pop,
                  leadingIcon: const Icon(Icons.close),
                  leadingSemanticLabel: S.of(context).close,
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      if (widget.state.hasTokens) ...[
                        // The caption is reused as the picker's semantics label,
                        // so it must not be announced as a separate node.
                        ExcludeSemantics(child: Text(S.of(context).token)),
                        MergeSemantics(
                          child: Semantics(
                            button: true,
                            label: S.of(context).select_token,
                            child: GestureDetector(
                              onTap: _pickToken,
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        spacing: 8,
                                        children: [
                                          ExcludeSemantics(
                                            child: TokenImageWidget(
                                              imageUrl: widget.state.cryptoCurrency.iconPath ?? "",
                                              size: 32,
                                            ),
                                          ),
                                          CurrencySymbolText(widget.state.cryptoCurrency),
                                        ],
                                      ),
                                      const ExcludeSemantics(
                                        child: RotatedBox(
                                          quarterTurns: 2,
                                          child: CakeImageWidget(
                                            imageUrl: "assets/new-ui/dropdown_arrow.svg",
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(),
                      // The caption is reused as the field's semantics label.
                      ExcludeSemantics(child: Text(S.of(context).amount)),
                      Row(
                        children: [
                          Expanded(
                            flex: 75,
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainer,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.surfaceContainer,
                                  width: 2,
                                ),
                              ),
                              child: MergeSemantics(
                                child: Semantics(
                                  label: S.of(context).amount,
                                  child: TextField(
                                    textAlign: TextAlign.left,
                                    textAlignVertical: TextAlignVertical.center,
                                    controller: _amountController,
                                    keyboardType: TextInputType.numberWithOptions(
                                      signed: false,
                                      decimal: _inputDecimals > 0,
                                    ),
                                    inputFormatters: [
                                      DecimalInputFormatter(
                                        maxDecimals: _inputDecimals,
                                      ),
                                    ],
                                    decoration: InputDecoration(
                                      hint: Text(
                                        _amountHint,
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                      border: InputBorder.none,
                                      filled: true,
                                      fillColor: Colors.transparent,
                                    ),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 25,
                            child: MergeSemantics(
                              child: Semantics(
                                button: true,
                                label: S.of(context).select_fiat_currency_title,
                                child: GestureDetector(
                                  onTap: _pickInputCurrency,
                                  child: Container(
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(18),
                                        bottomRight: Radius.circular(18),
                                      ),
                                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      spacing: 4,
                                      children: [
                                        CurrencySymbolText(
                                          widget.state.inputCurrency,
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        ExcludeSemantics(
                                          child: Icon(
                                            Icons.keyboard_arrow_down,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(),
                      NewPrimaryButton(
                        text: S.of(context).continue_text,
                        onPressed: () {
                          final raw = _amountController.text.trim();
                          if (raw.isEmpty) {
                            widget.bloc.add(const AmountChanged(null));
                          } else {
                            final amount = _parseAmount(raw);
                            if (amount != null) {
                              widget.bloc.add(AmountChanged(amount));
                            }
                          }
                          Navigator.of(context).pop();
                        },
                        color: Theme.of(context).colorScheme.primary,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
