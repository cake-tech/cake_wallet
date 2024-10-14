import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/new_wallet/widgets/select_button.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
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
      padding: EdgeInsets.only(bottom: isBuySellOption ? 8 : 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).extension<ExchangePageTheme>()!.firstGradientBottomPanelColor,
            Theme.of(context).extension<ExchangePageTheme>()!.secondGradientBottomPanelColor,
          ],
          stops: [0.35, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).extension<ExchangePageTheme>()!.firstGradientTopPanelColor,
                  Theme.of(context).extension<ExchangePageTheme>()!.secondGradientTopPanelColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.fromLTRB(24, 90, 24, isBuySellOption ? 8 : 32),
            child: Column(
              children: [
                if (isBuySellOption) Column(
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
              textColor: Colors.white,
              image: Image.asset('assets/images/buy.png', height: 25, width: 25),
              padding: EdgeInsets.only(left: 10, right: 30),
              color: isBuySelected
                  ? null
                  : Theme.of(context).extension<SendPageTheme>()!.textFieldButtonColor,
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
              textColor: Colors.white,
              image: Image.asset('assets/images/sell.png', height: 25, width: 25),
              padding: EdgeInsets.only(left: 10, right: 30),
              color: !isBuySelected
                  ? null
                  : Theme.of(context).extension<SendPageTheme>()!.textFieldButtonColor,
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
