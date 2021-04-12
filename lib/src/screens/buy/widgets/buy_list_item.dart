import 'package:cake_wallet/buy/buy_provider_description.dart';
import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/entities/crypto_currency.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';

class BuyListItem extends StatelessWidget {
  BuyListItem({
    @required this.selectedProvider,
    @required this.provider,
    @required this.sourceAmount,
    @required this.sourceCurrency,
    @required this.destAmount,
    @required this.destCurrency,
    @required this.onTap
  });

  final _wyreIcon =
    Image.asset('assets/images/wyre-icon.png', width: 36, height: 36);
  final _mooonPayIcon =
    Image.asset('assets/images/wyre-icon.png', width: 36, height: 36);

  final BuyProvider selectedProvider;
  final BuyProvider provider;
  final double sourceAmount;
  final FiatCurrency sourceCurrency;
  final double destAmount;
  final CryptoCurrency destCurrency;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final providerIcon = _getProviderIcon(provider.description);

    final backgroundColor = selectedProvider != null
        ? selectedProvider.description == provider.description
          ? Palette.greyBlueCraiola
          : Palette.shadowWhite
        : Palette.shadowWhite;

    final primaryTextColor = selectedProvider != null
        ? selectedProvider.description == provider.description
          ? Colors.white
          : Palette.darkGray
        : Palette.darkGray;

    final secondaryTextColor = selectedProvider != null
        ? selectedProvider.description == provider.description
          ? Colors.white
          : Palette.darkBlueCraiola
        : Palette.darkBlueCraiola;

    return GestureDetector(
      onTap: () => onTap?.call(),
      child: Container(
        height: 102,
        padding: EdgeInsets.only(
          left: 20,
          right: 20
        ),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(25)),
            color: backgroundColor
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (providerIcon != null) Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: providerIcon
                ),
                Text(
                  provider.description.title,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w500
                  ),
                )
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${destAmount?.toString()} ${destCurrency.title}',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w500
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Text(
                    '${sourceAmount?.toString()} ${sourceCurrency.title}',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w500
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      )
    );
  }

  Image _getProviderIcon(BuyProviderDescription providerDescription) {
    switch (providerDescription) {
      case BuyProviderDescription.wyre:
        return _wyreIcon;
      case BuyProviderDescription.moonPay:
        //return _mooonPayIcon;
        return null;
      default:
        return null;
    }
  }
}