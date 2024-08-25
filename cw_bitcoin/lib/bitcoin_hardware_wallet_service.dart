import 'dart:async';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:ledger_bitcoin/ledger_bitcoin.dart';
import 'package:ledger_flutter/ledger_flutter.dart';

class BitcoinHardwareWalletService {
  BitcoinHardwareWalletService(this.ledger, this.device);

  final Ledger ledger;
  final LedgerDevice device;

  Future<List<HardwareAccountData>> getAvailableAccounts({int index = 0, int limit = 5}) async {
    final bitcoinLedgerApp = BitcoinLedgerApp(ledger);

    final masterFp = await bitcoinLedgerApp.getMasterFingerprint(device);
    print(masterFp);

    final accounts = <HardwareAccountData>[];
    final indexRange = List.generate(limit, (i) => i + index);

    for (final i in indexRange) {
      final derivationPath = "m/84'/0'/$i'";
      final xpub = await bitcoinLedgerApp.getXPubKey(device, derivationPath: derivationPath);
      Bip32Slip10Secp256k1 hd =
          Bip32Slip10Secp256k1.fromExtendedKey(xpub).childKey(Bip32KeyIndex(0));

      final address = generateP2WPKHAddress(hd: hd, index: 0, network: BitcoinNetwork.mainnet);

      accounts.add(HardwareAccountData(
        address: address,
        accountIndex: i,
        derivationPath: derivationPath,
        masterFingerprint: masterFp,
        xpub: xpub,
      ));
    }

    return accounts;
  }
}
