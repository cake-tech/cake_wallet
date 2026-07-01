import 'dart:async';

import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:ledger_ethereum/ledger_ethereum.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';

class EVMChainLedgerService extends HardwareWalletService {
  EVMChainLedgerService(this.ledgerConnection);

  final LedgerConnection ledgerConnection;

  @override
  Future<List<HardwareAccountData>> getAvailableAccounts(
      {int index = 0, int limit = 5}) async {
    final ethereumLedgerApp = EthereumLedgerApp(ledgerConnection);

    await ethereumLedgerApp.getVersion();

    final accounts = <HardwareAccountData>[];
    final indexRange = List.generate(limit, (i) => i + index);

    for (final i in indexRange) {
      final derivationPath = "m/44'/60'/$i'/0/0";
      final address = await ethereumLedgerApp.getAccounts(
          accountsDerivationPath: derivationPath);

      accounts.add(HardwareAccountData(
        address: address.first,
        accountIndex: i,
        derivationPath: derivationPath,
      ));
    }

    return accounts;
  }
}
