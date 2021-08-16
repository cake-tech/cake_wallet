import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/get_buy_provider_icon.dart';
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

  final BuyProvider selectedProvider;
  final BuyProvider provider;
  final double sourceAmount;
  final FiatCurrency sourceCurrency;
  final double destAmount;
  final CryptoCurrency destCurrency;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedProvider?.description == provider.description;
    final iconColor = isSelected ? Colors.white : Colors.black;

    final providerIcon = getBuyProviderIcon(provider.description,
          iconColor: iconColor);

    final backgroundColor = isSelected
          ? Palette.greyBlueCraiola
          : Palette.shadowWhite;

    final primaryTextColor = isSelected
          ? Colors.white
          : Palette.darkGray;

    final secondaryTextColor = isSelected
          ? Colors.white
          : Palette.darkBlueCraiola;

    return GestureDetector(
      onTap: () => onTap?.call(),
      child: Container(
        height: 102,
        padding: EdgeInsets.only(
          left: 20,
          //top: 33,
          right: 20
        ),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(25)),
            color: backgroundColor
        ),
        child: Stack(
          children: [
            Positioned(
              top: 33,
              left: 0,
              right: 0,
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
                            color: secondaryTextColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold
                        ),
                      )
                    ],
                  ),
                  Text(
                    '${destAmount?.toString()} ${destCurrency.title}',
                    style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              )
            ),
            Positioned(
              top: 65,
              right: 0,
              child: Text(
                '${sourceAmount?.toString()} ${sourceCurrency.title}',
                style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                ),
              ),
            )
          ],
        )
      )
    );
  }
}