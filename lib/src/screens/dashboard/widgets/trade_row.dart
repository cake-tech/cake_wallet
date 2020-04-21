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
    final amountCrypto = from.toString();

    return InkWell(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: PaletteDark.historyPanel,
            border: Border.all(
                width: 1,
                color: PaletteDark.historyPanel
            ),
          ),
          padding: EdgeInsets.only(top: 5, bottom: 5, left: 20, right: 20),
          child: Row(children: <Widget>[
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PaletteDark.historyPanelButton
              ),
              child: _getPoweredImage(provider),
            ),
            Expanded(
                child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Column(
                children: <Widget>[
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text('${from.toString()} → ${to.toString()}',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white
                                )),
                        formattedAmount != null
                            ? Text(formattedAmount + ' ' + amountCrypto,
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white
                                ))
                            : Container()
                      ]),
                  SizedBox(height: 5),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(createdAtFormattedDate,
                            style: const TextStyle(
                                fontSize: 14, color: PaletteDark.historyPanelText))
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
