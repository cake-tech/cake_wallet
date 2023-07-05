import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';

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
                            color: Theme.of(context).extension<DashboardPageTheme>()!.textColor)),
                    Text(amount + ' ' + currency,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).extension<DashboardPageTheme>()!.textColor))
                  ]),
                  SizedBox(height: 5),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                    Text(createdAt,
                        style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).extension<CakeTextTheme>()!.dateSectionRowColor))
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
