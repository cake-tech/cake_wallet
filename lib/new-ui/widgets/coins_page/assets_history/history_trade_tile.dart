import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';

class HistoryTradeTile extends StatelessWidget {
  const HistoryTradeTile(
      {super.key,
      required this.date,
      required this.amount,
      required this.receiveAmount,
      required this.roundedTop,
      required this.roundedBottom,
      required this.bottomSeparator,
      required this.from,
      required this.to,
      required this.swapState});

  final CryptoCurrency from;
  final CryptoCurrency to;
  final String date;
  final String amount;
  final String receiveAmount;
  final bool roundedTop;
  final bool roundedBottom;
  final bool bottomSeparator;
  final TradeState swapState;

  @override
  Widget build(BuildContext context) {
    double currencyIconSize = 30.0;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(roundedTop ? 12.0 : 0.0),
                topRight: Radius.circular(roundedTop ? 12.0 : 0.0),
                bottomLeft: Radius.circular(roundedBottom ? 12.0 : 0.0),
                bottomRight: Radius.circular(roundedBottom ? 12.0 : 0.0),
              )),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 12.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0.0, 0.0, 8.0, 0.0),
                  child: SizedBox(
                    height: 50,
                    width: 50,
                    child: Stack(
                      children: [
                        Image.asset(_getIconPath(from),
                            width: currencyIconSize, height: currencyIconSize),
                        Positioned(
                            top: currencyIconSize / 2,
                            left: currencyIconSize / 2,
                            child: Container(
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        width: 1,
                                        color: Theme.of(context).colorScheme.surfaceContainer),
                                    shape: BoxShape.circle),
                                child: Image.asset(_getIconPath(to),
                                    width: currencyIconSize, height: currencyIconSize))),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${from.toString()} → ${to.toString()}"),
                          Text(date),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("$amount ${from.toString()}"),
                          Text("$receiveAmount ${to.toString()}"),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: SizedBox(
            height: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getIconPath(CryptoCurrency currency) {
    if (currency.iconPath != null) {
      return currency.iconPath!;
    }

    if (currency.name.isNotEmpty) {
      final currencyFromName = CryptoCurrency.fromString(currency.name);
      if (currencyFromName.iconPath != null) {
        return currencyFromName.iconPath!;
      }
    }

    if (currency.title.isNotEmpty) {
      final currencyFromTitle = CryptoCurrency.fromString(currency.title);
      if (currencyFromTitle.iconPath != null) {
        return currencyFromTitle.iconPath!;
      }
    }

    //TODO approporiate fallback
    return "";
  }
}
