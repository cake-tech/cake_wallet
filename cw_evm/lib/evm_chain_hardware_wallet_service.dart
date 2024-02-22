import 'package:ledger_flutter/ledger_flutter.dart';

abstract class EVMChainHardwareWalletService {
  EVMChainHardwareWalletService(this.device);

  final Ledger ledger = Ledger(options: LedgerOptions());
  final LedgerDevice device;

  Future<List<String>> getAvailableAccounts({int index = 0, int limit = 5});
}
