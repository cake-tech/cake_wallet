import 'dart:async';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart';
import 'package:cw_bitcoin/litecoin_network.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:ledger_litecoin/ledger_litecoin.dart';

class LitecoinHardwareWalletService {
  LitecoinHardwareWalletService(this.ledger, this.device);

  final Ledger ledger;
  final LedgerDevice device;

  Future<List<HardwareAccountData>> getAvailableAccounts({int index = 0, int limit = 5}) async {
    final litecoinLedgerApp = LitecoinLedgerApp(ledger);

    final version = await litecoinLedgerApp.getVersion(device);
    print(version);

    final accounts = <HardwareAccountData>[];
    final indexRange = List.generate(limit, (i) => i + index);

    for (final i in indexRange) {
      final derivationPath = "m/84'/2'/$i'";
      final xpub = await litecoinLedgerApp.getXPubKey(device,
          accountsDerivationPath: derivationPath, xPubVersion: litecoinNetwork.bip32.public);
      final hd = HDWallet.fromBase58(xpub, network: litecoinNetwork).derive(0);

      final address = generateP2WPKHAddress(hd: hd, index: 0, network: LitecoinNetwork.mainnet);

      accounts.add(HardwareAccountData(
        address: address,
        accountIndex: i,
        derivationPath: derivationPath,
        xpub: xpub,
      ));
    }

    return accounts;
  }
}
