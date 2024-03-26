import 'dart:async';

import 'package:ledger_ethereum/ledger_ethereum.dart';
import 'package:ledger_flutter/ledger_flutter.dart';

class EVMChainHardwareWalletService {
  EVMChainHardwareWalletService(this.ledger, this.device);

  final Ledger ledger;
  final LedgerDevice device;

  Future<List<String>> getAvailableAccounts({int index = 0, int limit = 5}) async {
    final ethereumLedgerApp = EthereumLedgerApp(ledger);

    final version = await ethereumLedgerApp.getVersion(device);
    print(version.version); // TODO: (Konsti) remove

    final accounts = <String>[];
    final indexRange = List.generate(limit, (i) => i + index);

    for (final i in indexRange) {
      final derivationPath = "m/44'/60'/$i'/0/0";
      final account = await ethereumLedgerApp.getAccounts(device, accountsDerivationPath: derivationPath);
      accounts.addAll(account);
    }

    return accounts;
  }
}
