import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/get_buy_provider_icon.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/palette.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BuyListItem extends StatelessWidget {
  BuyListItem({
    required this.selectedProvider,
    required this.provider,
    required this.sourceAmount,
    required this.sourceCurrency,
    required this.destAmount,
    required this.destCurrency,
    required this.achSourceAmount,
    this.onTap
  });

  final BuyProvider? selectedProvider;
  final BuyProvider provider;
  final double sourceAmount;
  final FiatCurrency sourceCurrency;
  final double destAmount;
  final CryptoCurrency destCurrency;
  final double achSourceAmount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedProvider?.providerDescription == provider.providerDescription;
    final iconColor = isSelected ? Colors.white : Colors.black;

    final providerIcon =  Image.asset('assets/images/wyre-icon.png', width: 36, height: 36);

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
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          top: 28,
          bottom: 28,
          right: 20
        ),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(25)),
            color: backgroundColor
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (providerIcon != null)
                      Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: providerIcon),
                    Text(
                      provider.title,
                      style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    )
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if(achSourceAmount != null)...[
                    Text(
                      '${destAmount?.toString()} ${destCurrency.title}',
                      style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_outlined, 
                          size: 12, 
                          color: primaryTextColor,
                        ),
                        SizedBox(width: 5),
                        Text(
                          '${achSourceAmount?.toString()} ${sourceCurrency.title}',
                          style: TextStyle(
                              color: primaryTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    ],
                    Text(
                      '${destAmount?.toString()} ${destCurrency.title}',
                      style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.creditcard, 
                          size: 12, 
                          color: primaryTextColor,
                        ), 
                        SizedBox(width: 5),
                        Text(
                          '${sourceAmount?.toString()} ${sourceCurrency.title}',
                          style: TextStyle(
                              color: primaryTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      )
    );
  }
}