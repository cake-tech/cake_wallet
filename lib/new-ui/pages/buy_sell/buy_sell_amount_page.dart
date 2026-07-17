import "dart:async";

import "package:cake_wallet/buy/payment_method.dart";
import "package:cake_wallet/buy/sell_buy_states.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/buy_sell/buy_sell_provider_page.dart";
import "package:cake_wallet/new-ui/widgets/buy_sell/buy_sell_selector_modal.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_sheet.dart";
import "package:cake_wallet/new-ui/widgets/floating_amount_input.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/themes/core/theme_extension.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/view_model/buy/buy_sell_view_model.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_mobx/flutter_mobx.dart";
import "package:mobx/mobx.dart";

class NewBuySellAmountPage extends StatefulWidget {
  const NewBuySellAmountPage({required this.buySellViewModel, super.key});

  final BuySellViewModel buySellViewModel;

  @override
  State<NewBuySellAmountPage> createState() => _NewBuySellAmountPageState();
}

class _NewBuySellAmountPageState extends State<NewBuySellAmountPage> {
  bool _customAmountMode = false;
  bool _isLoadingPaymentMethods = false;
  final customInputController = TextEditingController();
  final customInputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // this is a hack for the "up to" display to show the actual upper limit.
    // limits are loaded alongside quotes, and quotes for some providers only load properly with an amount and payment method selected.
    // it'll be refactored soon anyway, i guess.
    widget.buySellViewModel.changeFiatAmount(amount: "1000");
    widget.buySellViewModel.calculateBestRate();
    when(
        (_) => widget.buySellViewModel.paymentMethodState is PaymentMethodLoaded,
        () => widget.buySellViewModel.selectedPaymentMethod = widget.buySellViewModel.paymentMethods
            .firstWhere((item) => item.paymentMethodType == PaymentType.all),);
  }

  @override
  Widget build(BuildContext context) => PopScope(
      onPopInvokedWithResult: (didPop, result) => Navigator.of(context, rootNavigator: true).pop(),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceDim,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Observer(
                builder: (_) => ModalTopBar(
                  title: _pageTitle,
                  bottomText: !_customAmountMode || widget.buySellViewModel.maxFiatAmount == null
                      ? null
                      : "${S.of(context).up_to} ~${widget.buySellViewModel.maxFiatAmount} ${widget.buySellViewModel.fiatCurrency.title}",
                  leadingIcon: const Icon(Icons.close),
                  onLeadingPressed: Navigator.of(context, rootNavigator: true).pop,
                ),
              ),
              Expanded(
                  child: Observer(
                builder: (_) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _customAmountMode
                      ? BuySellCustomAmountInput(
                          fiatCurrency: widget.buySellViewModel.fiatCurrency,
                          cryptoCurrency: widget.buySellViewModel.cryptoCurrency,
                          cryptoAmount: widget.buySellViewModel.cryptoAmount,
                          isLoading: _isLoadingPaymentMethods,
                          hasCurrencySelector: widget.buySellViewModel.hasMultipleCurrencies,
                          onCurrencySelectorPressed: () => selectCryptoCurrency(context),
                          controller: customInputController,
                          focusNode: customInputFocusNode,
                          onContinuePressed: () {
                            navigateToProviders(context);
                          },
                          onChanged: (amount) =>
                              widget.buySellViewModel.changeFiatAmount(amount: amount),
                        )
                      : BuySellDefaultAmountSelector(
                          key: const ValueKey(0),
                          defaultAmounts: widget.buySellViewModel.defaultAmounts,
                          fiatCurrency: widget.buySellViewModel.fiatCurrency,
                          currentAmount: widget.buySellViewModel.fiatAmount,
                          hasCurrencySelector: widget.buySellViewModel.hasMultipleCurrencies,
                          onCurrencySelectorPressed: () => selectCryptoCurrency(context),
                          cryptoCurrency: widget.buySellViewModel.cryptoCurrency,
                          isLoading: _isLoadingPaymentMethods,
                          mode: widget.buySellViewModel.mode,
                          onSelected: (amount) async {
                            if (amount == null) {
                              // this resets the rate and prevents showing 0 usd = 0.something btc
                              await widget.buySellViewModel.changeFiatAmount(amount: "");
                              setState(() {
                                _customAmountMode = true;
                              });
                              customInputFocusNode.requestFocus();
                            } else {
                              await widget.buySellViewModel.changeFiatAmount(amount: amount);
                              await navigateToProviders(context);
                            }
                          },
                        ),
                ),
              ),),
            ],
          ),
        ),
      ),
    );

  void selectCryptoCurrency(BuildContext context) => CurrencyPickerSheet.show(
      context: context,
      args: CurrencyPickerArgs(
        items: widget.buySellViewModel.activeWalletCurrencies.toList(),
        onSelected: (item) => widget.buySellViewModel.changeCryptoCurrency(currency: item),
        symbolResolver: widget.buySellViewModel.amountParsingProxy.getCryptoSymbol,
      ),);

  String get _pageTitle => widget.buySellViewModel.mode == BuySellPageMode.buy
      ? S.current.buy
      : S.current.sell +
          ((widget.buySellViewModel.cryptoCurrencies.length == 1)
              ? " ${widget.buySellViewModel.cryptoCurrencies.first.fullName}"
              : "");

  Future<void> navigateToProviders(BuildContext context) async {
    if (_isLoadingPaymentMethods) {
      return;
    }

    try {
      setState(() {
        _isLoadingPaymentMethods = true;
      });

      await asyncWhen((_) => [PaymentMethodLoaded, PaymentMethodFailed]
          .contains(widget.buySellViewModel.paymentMethodState.runtimeType),);

      if (widget.buySellViewModel.paymentMethodState is PaymentMethodFailed) {
        await showPopUp(
            context: context,
            builder: (context) => AlertWithOneAction(
                alertTitle: S.of(context).failed_to_load_payment_methods,
                alertContent: S.of(context).please_try_again_later,
                buttonText: "OK",
                buttonAction: Navigator.of(context).pop,),);
        return;
      }

      widget.buySellViewModel.selectedPaymentMethod = widget.buySellViewModel.paymentMethods
          .firstWhere((item) => item.paymentMethodType == PaymentType.all);

      // unawaited because BuySellProviderPage has a nice little "loading rates..." ui thingie
      unawaited(widget.buySellViewModel.calculateBestRate());

      final page = BuySellProviderPage(buySellViewModel: widget.buySellViewModel);
      Navigator.of(context).push(CupertinoPageRoute(
          builder: (context) => Material(color: Colors.transparent, child: page),),);
    } finally {
      setState(() {
        _isLoadingPaymentMethods = false;
      });
    }
  }
}

class BuySellCustomAmountInput extends StatelessWidget {
  const BuySellCustomAmountInput(
      {required this.fiatCurrency, required this.cryptoCurrency, required this.cryptoAmount, required this.controller, required this.onContinuePressed, required this.isLoading, required this.onChanged, required this.focusNode, required this.hasCurrencySelector, required this.onCurrencySelectorPressed, super.key,});

  final FiatCurrency fiatCurrency;
  final CryptoCurrency cryptoCurrency;
  final String cryptoAmount;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final bool hasCurrencySelector;
  final VoidCallback onCurrencySelectorPressed;
  final VoidCallback onContinuePressed;
  final Function(String) onChanged;

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox.shrink(),
          Column(
            spacing: 8,
            children: [
              if (hasCurrencySelector) ...[
                BuySellCurrencyPickerPill(curr: cryptoCurrency, onTap: onCurrencySelectorPressed),
                const SizedBox.shrink(),
              ],
              FloatingAmountInput(
                currency: fiatCurrency,
                focusNode: focusNode,
                controller: controller,
                onChanged: onChanged,
              ),
              Opacity(
                opacity: cryptoAmount.isEmpty ? 0 : 1,
                child: Text(
                  "≈ ${cryptoAmount} ${cryptoCurrency.symbol}",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: NewPrimaryButton(
                onPressed: onContinuePressed,
                isLoading: isLoading,
                text: S.of(context).continue_text,
                color: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,),
          ),
        ],
      ),
    );
}

class BuySellDefaultAmountSelector extends StatelessWidget {
  const BuySellDefaultAmountSelector(
      {required this.defaultAmounts, required this.fiatCurrency, required this.mode, required this.onSelected, required this.isLoading, required this.hasCurrencySelector, required this.onCurrencySelectorPressed, required this.cryptoCurrency, super.key,
      this.currentAmount,});

  final List<String> defaultAmounts;
  final String? currentAmount;
  final bool isLoading;
  final bool hasCurrencySelector;
  final VoidCallback onCurrencySelectorPressed;
  final CryptoCurrency cryptoCurrency;
  final FiatCurrency fiatCurrency;
  final BuySellPageMode mode;
  final Function(String?) onSelected;

  @override
  Widget build(BuildContext context) => Column(
      spacing: 24,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasCurrencySelector)
          BuySellCurrencyPickerPill(curr: cryptoCurrency, onTap: onCurrencySelectorPressed),
        Text(
          mode == BuySellPageMode.sell
              ? S.of(context).choose_amount_to_sell
              : S.of(context).choose_amount_to_buy,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              // +1 for "custom" option
              itemCount: defaultAmounts.length + 1,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 16, mainAxisExtent: 105,),
              itemBuilder: (context, index) {
                final String? item = index == defaultAmounts.length ? null : defaultAmounts[index];

                return BuySellAmountPill(
                  isLoading: isLoading && item == currentAmount,
                  amount: item == null ? null : Money.parse(item, fiatCurrency),
                  onTap: () => onSelected(item),
                );
              },),
        ),
      ],
    );
}

class BuySellAmountPill extends StatelessWidget {
  const BuySellAmountPill({required this.onTap, required this.isLoading, super.key, this.amount});

  final Money? amount;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9999999999),
        border: Border.all(
          width: 1,
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
        ),
        gradient: LinearGradient(
          colors: [
            context.customColors.cardGradientColorPrimary,
            context.customColors.cardGradientColorSecondary,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(9999999999),
        child: InkWell(
          borderRadius: BorderRadius.circular(9999999999),
          onTap: onTap,
          child: isLoading
              ? const CupertinoActivityIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      spacing: 4,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (amount != null)
                          Text(
                            amount!.toStringWithPrecision(fractionalDigits: 0),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        Text(
                          amount?.currency.symbol ?? S.of(context).custom,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: amount == null
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,),
                        ),
                      ],
                    ),
                    if (amount == null)
                      Text(
                        S.of(context).enter_amount,
                        style: TextStyle(
                            fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant,),
                      ),
                  ],
                ),
        ),
      ),
    );
}

class BuySellCurrencyPickerPill extends StatelessWidget {
  const BuySellCurrencyPickerPill({required this.curr, required this.onTap, super.key});

  final CryptoCurrency curr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999999999),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 5, bottom: 5, left: 5, right: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              CakeImageWidget(
                imageUrl: curr.iconPath,
                width: 30,
                height: 30,
              ),
              Text(
                curr.fullName ?? curr.title,
                style: const TextStyle(fontSize: 16),
              ),
              RotatedBox(
                quarterTurns: 2,
                child: CakeImageWidget(
                  imageUrl: "assets/new-ui/dropdown_arrow.svg",
                  width: 8,
                  height: 8,
                  colorFilter:
                      ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
}
