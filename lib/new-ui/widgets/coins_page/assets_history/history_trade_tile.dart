import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_tile_base.dart';
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

  Widget _getLeadingStack(BuildContext context) {
    double currencyIconSize = 30.0;

    return SizedBox(
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
    );
  }


  @override
  Widget build(BuildContext context) {

    return HistoryTileBase(
      title: "${from.toString()} → ${to.toString()}",
      date: date,
      amount: amount,
      amountFiat: receiveAmount,
      leadingIcon: _getLeadingStack(context),
      roundedTop: roundedTop,
      roundedBottom: roundedBottom,
      bottomSeparator: bottomSeparator,
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
