import "package:cake_wallet/routes.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/widgets.dart";

void openWalletAfterSeedFlow(BuildContext context, WalletType walletType) {
  if (walletType == WalletType.bitcoin) {
    Navigator.of(context).pushNamed(Routes.lightningUsernamePage, arguments: true);
    return;
  }

  Navigator.of(context).popUntil((route) => route.isFirst);
}
