import 'package:flutter/material.dart';
import 'package:cake_wallet/entities/crypto_currency.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';

class TradeRow extends StatelessWidget {
  TradeRow({
    this.provider,
    this.from,
    this.to,
    this.createdAtFormattedDate,
    this.formattedAmount,
    @required this.onTap});

  final VoidCallback onTap;
  final ExchangeProviderDescription provider;
  final CryptoCurrency from;
  final CryptoCurrency to;
  final String createdAtFormattedDate;
  final String formattedAmount;

  @override
  Widget build(BuildContext context) {
    final amountCrypto = from.toString();

    return InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
          color: Colors.transparent,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _getPoweredImage(provider),
              SizedBox(width: 12),
              Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text('${from.toString()} → ${to.toString()}',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).accentTextTheme.
                                    display3.backgroundColor
                                )),
                            formattedAmount != null
                                ? Text(formattedAmount + ' ' + amountCrypto,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).accentTextTheme.
                                    display3.backgroundColor
                                ))
                                : Container()
                          ]),
                      SizedBox(height: 5),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(createdAtFormattedDate,
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).textTheme
                                        .overline.backgroundColor))
                          ])
                    ],
                  )
              )
            ],
          ),
        ));
  }

  Image _getPoweredImage(ExchangeProviderDescription provider) {
    Image image;
    switch (provider) {
      case ExchangeProviderDescription.xmrto:
        image = Image.asset('assets/images/xmrto.png', height: 36, width: 36);
        break;
      case ExchangeProviderDescription.changeNow:
        image = Image.asset('assets/images/changenow.png', height: 36, width: 36);
        break;
      case ExchangeProviderDescription.morphToken:
        image = Image.asset('assets/images/morph.png', height: 36, width: 36);
        break;
      case ExchangeProviderDescription.sideshift:
        image = Image.asset('assets/images/sideshift.png', height: 36, width: 36);
        break;
      default:
        image = null;
    }
    return image;
  }
}