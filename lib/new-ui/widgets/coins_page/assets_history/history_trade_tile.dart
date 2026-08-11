import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_tile_base.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cw_core/crypto_amount_format.dart';
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
      this.from,
      this.to,
      required this.swapState,
      required this.provider});

  final CryptoCurrency? from;
  final CryptoCurrency? to;
  final ExchangeProviderDescription provider;
  final String date;
  final String amount;
  final String receiveAmount;
  final bool roundedTop;
  final bool roundedBottom;
  final bool bottomSeparator;
  final TradeState swapState;

  Widget _getLeadingStack(BuildContext context) {
    if (from == null || to == null) {
      return SizedBox(width: 50, height: 50);
    }

    double currencyIconSize = 22.0;

    return SizedBox(
      height: 50,
      width: 50,
      child: Stack(
        children: [
          CakeImageWidget(
              imageUrl: _getIconPath(from!), width: currencyIconSize, height: currencyIconSize),
          Positioned(
            top: currencyIconSize / 2,
            left: currencyIconSize / 2,
            child: Container(
              decoration: BoxDecoration(
                  border:
                      Border.all(width: 2, color: Theme.of(context).colorScheme.surfaceContainer),
                  shape: BoxShape.circle),
              child: CakeImageWidget(
                imageUrl: _getIconPath(to!),
                width: currencyIconSize,
                height: currencyIconSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fromChainIcon = _getChainIcon(from);
    final toChainIcon = _getChainIcon(to);

    return HistoryTileBase(
      // title:
      //     "${from.toString()}${from == CryptoCurrency.btcln ? "-LN" : ""} → ${to.toString()}${to == CryptoCurrency.btcln ? "-LN" : ""}",
      titleWidget: Row(
        spacing: 4,
        children: [
          Text(swapState.title),
          CakeImageWidget(imageUrl: provider.image, width: 14, height: 14)
        ],
      ),
      date: date,
      amountFiatWidget: Row(
        spacing: 4,
        children: [
          Text("-", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(amount.withMaxDecimals(8),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
          if (from?.title != null)
            Text(from!.title,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          if (fromChainIcon?.isNotEmpty ?? false)
            CakeImageWidget(
              imageUrl: fromChainIcon,
              width: 12,
              height: 12,
              colorFilter:
                  ColorFilter.mode(Theme.of(context).colorScheme.onSurfaceVariant, BlendMode.srcIn),
            )
        ],
      ),
      amountWidget: Row(
        spacing: 4,
        children: [
          Text(
            "+",
          ),
          Text(
            receiveAmount.withMaxDecimals(8),
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          if (to != null)
            Text(
              to!.title,
            ),
          if (toChainIcon?.isNotEmpty ?? false)
            CakeImageWidget(
              imageUrl: toChainIcon,
              width: 12,
              height: 12,
              color: Theme.of(context).colorScheme.onSurface,
            )
        ],
      ),
      leadingIcon: _getLeadingStack(context),
      roundedTop: roundedTop,
      roundedBottom: roundedBottom,
      bottomSeparator: bottomSeparator,
    );
  }

  String _getIconPath(CryptoCurrency currency) {
    try {
      if (currency.title.isNotEmpty) {
        final live = CryptoCurrency.safeParseCurrencyFromString(currency.title, tag: currency.tag);
        if (live?.iconPath != null) return live!.iconPath!;
      }

      if (currency.iconPath != null) return currency.iconPath!;

      if (currency.name.isNotEmpty) {
        final byName = CryptoCurrency.safeParseCurrencyFromString(currency.name);
        if (byName?.iconPath != null) return byName!.iconPath!;
      }
    } catch (_) {}

    return "";
  }

  String? _getChainIcon(CryptoCurrency? currency) {
    if (currency == null) return null;
    try {
      if (currency.title.isNotEmpty) {
        final parsedCurrency =
            CryptoCurrency.safeParseCurrencyFromString(currency.title, tag: currency.tag);
        if (parsedCurrency?.chainIconPath != null) return parsedCurrency!.chainIconPath!;
      }

      if (currency.chainIconPath != null) return currency.chainIconPath!;

      if ((currency.tag ?? "").isNotEmpty) {
        final currencyFromTag = CryptoCurrency.fromString(currency.tag!);
        if (currencyFromTag.chainIconPath != null) {
          return currencyFromTag.chainIconPath!;
        }
      }
    } catch (_) {}

    return "";
  }
}
