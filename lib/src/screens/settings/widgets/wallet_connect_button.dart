import 'package:cake_wallet/generated/i18n.dart';
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
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Image.asset(
              'assets/images/select_arrow.png',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )
          ],
        ),
      ),
    );
  }
}
