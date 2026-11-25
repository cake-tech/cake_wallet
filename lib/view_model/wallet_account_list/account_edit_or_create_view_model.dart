import 'package:cake_wallet/core/execution_state.dart';

abstract class WalletAccountEditOrCreateViewModel {
  bool get isEdit;
  ExecutionState get state;
  String get label;
  set label(String value);
  Future<void> save();
}
