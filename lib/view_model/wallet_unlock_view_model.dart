import 'package:cake_wallet/core/execution_state.dart';

abstract class WalletUnlockViewModel {
  String get walletName;
  String get password;
  void setPassword(String password);
  ExecutionState get state;
  Future<void> unlock();
  void success();
  void failure(dynamic e);
}
