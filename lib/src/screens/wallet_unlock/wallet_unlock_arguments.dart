import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cw_core/wallet_type.dart';

typedef AuthPasswordHandler = Future<void> Function(String);

class WalletUnlockArguments {
  WalletUnlockArguments(
      {required this.callback,
      this.walletName,
      this.walletType,
      this.authPasswordHandler});

  final OnAuthenticationFinished callback;
  final AuthPasswordHandler? authPasswordHandler;
  final String? walletName;
  final WalletType? walletType;
}
