import 'package:cake_wallet/src/screens/exchange/widgets/mobile_exchange_cards_section.dart';
import 'package:flutter/material.dart';

class DesktopExchangeCardsSection extends StatelessWidget {
  const DesktopExchangeCardsSection({
    Key? key,
    required this.firstExchangeCard,
    required this.secondExchangeCard,
    this.isBuySellOption = false,
    this.onBuyTap,
    this.onSellTap,
  }) : super(key: key);

  final Widget firstExchangeCard;
  final Widget secondExchangeCard;
  final bool isBuySellOption;
  final VoidCallback? onBuyTap;
  final VoidCallback? onSellTap;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 55, left: 24, right: 24),
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
            padding: EdgeInsets.only(top: 29, left: 24, right: 24),
            child: secondExchangeCard,
          ),
        ],
      ),
    );
  }
}
