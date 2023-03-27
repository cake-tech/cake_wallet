import 'package:flutter/material.dart';

class AnonpayTransactionRow extends StatelessWidget {
  AnonpayTransactionRow({
    required this.provider,
    required this.createdAt,
    required this.currency,
    required this.onTap,
    required this.amount,
  });

  final VoidCallback? onTap;
  final String provider;
  final String createdAt;
  final String amount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
          color: Colors.transparent,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _getImage(),
              SizedBox(width: 12),
              Expanded(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                    Text(provider,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).accentTextTheme.headline2!.backgroundColor!)),
                    Text(amount + ' ' + currency,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).accentTextTheme.headline2!.backgroundColor!))
                  ]),
                  SizedBox(height: 5),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                    Text(createdAt,
                        style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.overline!.backgroundColor!))
                  ])
                ],
              ))
            ],
          ),
        ));
  }

  Widget _getImage() => ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: Image.asset('assets/images/trocador.png', width: 36, height: 36));
}
