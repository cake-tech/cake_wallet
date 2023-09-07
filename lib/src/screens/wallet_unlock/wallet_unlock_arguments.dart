import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cw_core/wallet_type.dart';

class WalletUnlockArguments {
  WalletUnlockArguments({
    required this.callback,
    this.walletName,
    this.walletType});

  final OnAuthenticationFinished callback;
  final String? walletName;
  final WalletType? walletType;
}