import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/new_wallet/widgets/select_button.dart';
import 'package:flutter/material.dart';

class MobileExchangeCardsSection extends StatelessWidget {
  final Widget firstExchangeCard;
  final Widget secondExchangeCard;
  final bool isBuySellOption;
  final VoidCallback? onBuyTap;
  final VoidCallback? onSellTap;

  const MobileExchangeCardsSection({
    Key? key,
    required this.firstExchangeCard,
    required this.secondExchangeCard,
    this.isBuySellOption = false,
    this.onBuyTap,
    this.onSellTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: isBuySellOption ? 16 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        color: Theme.of(context).colorScheme.surfaceContainer,
      ),
      child: Column(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            padding: EdgeInsets.fromLTRB(24, 105, 24, 24),
            child: Column(
              children: [
                if (isBuySellOption)
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      BuySellOptionButtons(onBuyTap: onBuyTap, onSellTap: onSellTap),
                    ],
                  ),
                firstExchangeCard,
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 20, left: 24, right: 24),
            child: secondExchangeCard,
          )
        ],
      ),
    );
  }
}

class BuySellOptionButtons extends StatefulWidget {
  final VoidCallback? onBuyTap;
  final VoidCallback? onSellTap;

  const BuySellOptionButtons({this.onBuyTap, this.onSellTap});

  @override
  _BuySellOptionButtonsState createState() => _BuySellOptionButtonsState();
}

class _BuySellOptionButtonsState extends State<BuySellOptionButtons> {
  bool isBuySelected = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Expanded(flex: 2, child: SizedBox()),
          Expanded(
            flex: 5,
            child: SelectButton(
              height: 44,
              text: S.of(context).buy,
              isSelected: isBuySelected,
              showTrailingIcon: false,
              textColor: isBuySelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSecondaryContainer,
              padding: EdgeInsets.only(left: 50, right: 30),
              color: isBuySelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainer,
              onTap: () {
                setState(() => isBuySelected = true);
                if (widget.onBuyTap != null) widget.onBuyTap!();
              },
            ),
          ),
          Expanded(child: const SizedBox()),
          Expanded(
            flex: 5,
            child: SelectButton(
              height: 44,
              text: S.of(context).sell,
              isSelected: !isBuySelected,
              showTrailingIcon: false,
              textColor: !isBuySelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSecondaryContainer,
              padding: EdgeInsets.only(left: 50, right: 30),
              color: !isBuySelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainer,
              onTap: () {
                setState(() => isBuySelected = false);
                if (widget.onSellTap != null) widget.onSellTap!();
              },
            ),
          ),
          Expanded(flex: 2, child: SizedBox()),
        ],
      ),
    );
  }
}
