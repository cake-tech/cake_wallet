import 'dart:async';

import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:ledger_ethereum/ledger_ethereum.dart';
import 'package:ledger_flutter/ledger_flutter.dart';

class EVMChainHardwareWalletService {
  EVMChainHardwareWalletService(this.ledger, this.device);

  final Ledger ledger;
  final LedgerDevice device;

  Future<List<HardwareAccountData>> getAvailableAccounts({int index = 0, int limit = 5}) async {
    final ethereumLedgerApp = EthereumLedgerApp(ledger);

    final version = await ethereumLedgerApp.getVersion(device);

    final accounts = <HardwareAccountData>[];
    final indexRange = List.generate(limit, (i) => i + index);

    for (final i in indexRange) {
      final derivationPath = "m/44'/60'/$i'/0/0";
      final address =
          await ethereumLedgerApp.getAccounts(device, accountsDerivationPath: derivationPath);

      accounts.add(HardwareAccountData(
        address: address.first,
        accountIndex: i,
        derivationPath: derivationPath,
      ));
    }

    return accounts;
  }
}
