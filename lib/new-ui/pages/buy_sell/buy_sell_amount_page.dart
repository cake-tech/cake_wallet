import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/buy_sell/buy_sell_selector_modal.dart';
import 'package:cake_wallet/new-ui/widgets/floating_amount_input.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/themes/core/theme_extension.dart';
import 'package:cake_wallet/view_model/buy/buy_sell_view_model.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class NewBuySellAmountPage extends StatefulWidget {
  const NewBuySellAmountPage({super.key, required this.buySellViewModel});

  final BuySellViewModel buySellViewModel;

  @override
  State<NewBuySellAmountPage> createState() => _NewBuySellAmountPageState();
}

class _NewBuySellAmountPageState extends State<NewBuySellAmountPage> {
  bool _customAmountMode = false;
  final customInputController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
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
            ModalTopBar(
              title: _pageTitle,
              leadingIcon: Icon(Icons.close),
              onLeadingPressed: Navigator.of(context, rootNavigator: true).pop,
            ),
            Expanded(
                child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: _customAmountMode
                  ? Observer(
                      builder: (_) => BuySellCustomAmountInput(
                            fiatCurrency: widget.buySellViewModel.fiatCurrency,
                            cryptoCurrency: widget.buySellViewModel.cryptoCurrency,
                            cryptoAmount: widget.buySellViewModel.cryptoAmount,
                            controller: customInputController,
                            onContinuePressed: () {},
                            onChanged: (amount) =>
                                widget.buySellViewModel.changeFiatAmount(amount: amount),
                          ))
                  : BuySellDefaultAmountSelector(
                      key: ValueKey(0),
                      defaultAmounts: widget.buySellViewModel.defaultAmounts,
                      currency: widget.buySellViewModel.fiatCurrency,
                      mode: widget.buySellViewModel.mode,
                      onSelected: (amount) {
                        if (amount == null) {
                          setState(() {
                            _customAmountMode = true;
                          });
                        } else {
                          widget.buySellViewModel.changeFiatAmount(amount: amount);
                        }
                      },
                    ),
            ))
          ],
        ),
      ),
    );
  }

  String get _pageTitle => widget.buySellViewModel.mode == BuySellPageMode.buy
      ? S.current.buy
      : S.current.sell +
          ((widget.buySellViewModel.cryptoCurrencies.length == 1)
              ? " ${widget.buySellViewModel.cryptoCurrencies.first.fullName}"
              : "");
}

class BuySellCustomAmountInput extends StatelessWidget {
  const BuySellCustomAmountInput(
      {super.key,
      required this.fiatCurrency,
      required this.cryptoCurrency,
      required this.cryptoAmount,
      required this.controller,
      required this.onContinuePressed,
      required this.onChanged});

  final FiatCurrency fiatCurrency;
  final CryptoCurrency cryptoCurrency;
  final String cryptoAmount;
  final TextEditingController controller;
  final VoidCallback onContinuePressed;
  final Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox.shrink(),
        Column(
          spacing: 8,
          children: [
            FloatingAmountInput(
              currency: fiatCurrency,
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            )
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(18.0),
          child: NewPrimaryButton(
              onPressed: onContinuePressed,
              text: S.of(context).continue_text,
              color: Theme.of(context).colorScheme.primary,
              textColor: Theme.of(context).colorScheme.onPrimary),
        )
      ],
    );
  }
}

class BuySellDefaultAmountSelector extends StatelessWidget {
  const BuySellDefaultAmountSelector(
      {super.key,
      required this.defaultAmounts,
      required this.currency,
      required this.mode,
      required this.onSelected});

  final List<String> defaultAmounts;
  final FiatCurrency currency;
  final BuySellPageMode mode;
  final Function(String?) onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 24,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          mode == BuySellPageMode.sell
              ? S.of(context).choose_amount_to_sell
              : S.of(context).choose_amount_to_buy,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              // +1 for "custom" option
              itemCount: defaultAmounts.length + 1,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 16, mainAxisExtent: 105),
              itemBuilder: (context, index) {
                final String? item = index == defaultAmounts.length ? null : defaultAmounts[index];

                return BuySellAmountPill(
                  amount: item == null ? null : Money.parse(item, currency),
                  onTap: () => onSelected(item),
                );
              }),
        ),
      ],
    );
  }
}

class BuySellAmountPill extends StatelessWidget {
  const BuySellAmountPill({super.key, this.amount, required this.onTap});

  final Money? amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9999999999),
        border: Border.all(
          width: 1,
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
        ),
        gradient: LinearGradient(
          colors: [
            context.customColors.cardGradientColorPrimary,
            context.customColors.cardGradientColorSecondary
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                spacing: 4,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (amount != null)
                    Text(
                      amount!.toStringWithPrecision(fractionalDigits: 0),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  Text(
                    amount?.currency.symbol ?? S.of(context).custom,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: amount == null
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant),
                  )
                ],
              ),
              if (amount == null)
                Text(
                  S.of(context).enter_amount,
                  style: TextStyle(
                      fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                )
            ],
          ),
        ),
      ),
    );
  }
}
