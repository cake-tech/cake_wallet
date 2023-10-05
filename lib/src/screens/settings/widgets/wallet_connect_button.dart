import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';
import 'package:flutter/material.dart';

class WalletConnectTile extends StatelessWidget {
  const WalletConnectTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/images/walletconnect_logo.png',
              height: 24,
              width: 24,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                S.current.walletConnect,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                ),
              ),
            ),
            Image.asset(
              'assets/images/select_arrow.png',
              color: Theme.of(context).extension<TransactionTradeTheme>()!.detailsTitlesColor,
            )
          ],
        ),
      ),
    );
  }
}
