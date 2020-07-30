import 'package:flutter/material.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/palette.dart';

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
          height: 52,
          color: Colors.transparent,
          padding: EdgeInsets.only(left: 24, right: 24),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _getPoweredImage(provider),
                Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Container(
                        height: 46,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text('${from.toString()} → ${to.toString()}',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white
                                      )),
                                  formattedAmount != null
                                      ? Text(formattedAmount + ' ' + amountCrypto,
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white
                                      ))
                                      : Container()
                                ]),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(createdAtFormattedDate,
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: PaletteDark.darkCyanBlue))
                                ]),
                          ],
                        ),
                      ),
                    ))
              ]),
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
      default:
        image = null;
    }
    return image;
  }
}