import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';

class XMRAmount extends StatelessWidget {
  const XMRAmount({Key key, @required this.xmrAmount, @required this.fiatAmount}) : super(key: key);

  final double xmrAmount;
  final double fiatAmount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          "${xmrAmount} ${CryptoCurrency.xmr.toString()}",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).primaryTextTheme.title.color,
          ),
        ),
        Text(
          "${fiatAmount} ${FiatCurrency.usd.title}",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).accentTextTheme.subhead.color,
          ),
        ),
      ],
    );
  }
}
