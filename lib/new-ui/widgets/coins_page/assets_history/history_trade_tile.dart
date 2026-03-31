import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_tile_base.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
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
    double currencyIconSize = 22.0;

    return SizedBox(
      height: 50,
      width: 50,
      child: Stack(
        children: [
          CakeImageWidget(imageUrl: _getIconPath(from),
              width: currencyIconSize, height: currencyIconSize),
          Positioned(
              top: currencyIconSize / 2,
              left: currencyIconSize / 2,
              child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                          width: 2,
                          color: Theme.of(context).colorScheme.surfaceContainer),
                      shape: BoxShape.circle),
                  child:CakeImageWidget(imageUrl: _getIconPath(to),
                      width: currencyIconSize, height: currencyIconSize))),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {

    return HistoryTileBase(
      title:
          "${from.toString()}${from == CryptoCurrency.btcln ? "-LN" : ""} → ${to.toString()}${to == CryptoCurrency.btcln ? "-LN" : ""}",
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
    try {
      if (currency.iconPath != null) {
        return currency.iconPath!;
      }

      if (currency.name.isNotEmpty) {
        final c = CryptoCurrency.safeParseCurrencyFromString(currency.name);
        if (c != null && c.iconPath != null) {
          return c.iconPath!;
        }
      }

      if (currency.title.isNotEmpty) {
        final c = CryptoCurrency.safeParseCurrencyFromString(currency.title);
        if (c != null && c.iconPath != null) {
          return c.iconPath!;
        }
      }
    } catch (_) {}

    //TODO approporiate fallback
    return "";
  }
}
