import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider_description.dart';

class TradeRow extends StatelessWidget {
  TradeRow(
      {this.provider,
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
    final amountCrypto = provider == ExchangeProviderDescription.xmrto
        ? to.toString()
        : from.toString();

    return InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.only(top: 14, bottom: 14, left: 20, right: 20),
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: PaletteDark.darkGrey,
                      width: 0.5,
                      style: BorderStyle.solid))),
          child: Row(children: <Widget>[
            _getPoweredImage(provider),
            Expanded(
                child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Column(
                children: <Widget>[
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text('${from.toString()} → ${to.toString()}',
                            style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .subhead
                                    .color)),
                        formattedAmount != null
                            ? Text(formattedAmount + ' ' + amountCrypto,
                                style: const TextStyle(
                                    fontSize: 16, color: Palette.purpleBlue))
                            : Container()
                      ]),
                  SizedBox(height: 6),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(createdAtFormattedDate,
                            style: const TextStyle(
                                fontSize: 13, color: Palette.blueGrey))
                      ]),
                ],
              ),
            ))
          ]),
        ));
  }

  Image _getPoweredImage(ExchangeProviderDescription provider) {
    Image image;
    switch (provider) {
      case ExchangeProviderDescription.xmrto:
        image = Image.asset('assets/images/xmr_btc.png');
        break;
      case ExchangeProviderDescription.changeNow:
        image = Image.asset('assets/images/change_now.png');
        break;
      case ExchangeProviderDescription.morphToken:
        image = Image.asset('assets/images/morph_icon.png');
        break;
      default:
        image = null;
    }
    return image;
  }
}
