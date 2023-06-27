import 'package:cake_wallet/core/execution_state.dart';
import 'package:cw_core/wallet_type.dart';

abstract class WalletUnlockViewModel {
  String get walletName;
  String? get password;
  void setPassword(String password);
  ExecutionState get state;
  Future<dynamic> unlock({String? walletName, WalletType? walletType});
  void success();
}