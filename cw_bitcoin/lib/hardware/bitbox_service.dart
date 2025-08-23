import 'dart:async';

import 'package:bitbox_flutter/bitbox_manager.dart';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:ledger_bitcoin/ledger_bitcoin.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';

class BitcoinBitboxService extends HardwareWalletService {
  BitcoinBitboxService(this.manager);

  final BitboxManager manager;

  @override
  Future<List<HardwareAccountData>> getAvailableAccounts({int index = 0, int limit = 5}) async {
    final accounts = <HardwareAccountData>[];
    final indexRange = List.generate(limit, (i) => i + index);

    for (final i in indexRange) {
      final derivationPath = "m/84'/0'/$i'";
      final xPub = await manager.getBTCXPub(0, derivationPath, 1);
      final hd = Bip32Slip10Secp256k1.fromExtendedKey(xPub).childKey(Bip32KeyIndex(0));
      final address = generateP2WPKHAddress(hd: hd, index: 0, network: BitcoinNetwork.mainnet);

      accounts.add(HardwareAccountData(
        address: address,
        accountIndex: i,
        derivationPath: derivationPath,
        xpub: xPub,
      ));
    }

    return accounts;
  }
}

class LitecoinBitboxService extends HardwareWalletService {
  LitecoinBitboxService(this.manager);

  final BitboxManager manager;

  @override
  Future<List<HardwareAccountData>> getAvailableAccounts({int index = 0, int limit = 5}) async {
    final accounts = <HardwareAccountData>[];
    final indexRange = List.generate(limit, (i) => i + index);

    for (final i in indexRange) {
      final derivationPath = "m/84'/2'/$i'";
      final xPub = await manager.getBTCXPub(0, derivationPath, 1);
      final hd = Bip32Slip10Secp256k1.fromExtendedKey(xPub).childKey(Bip32KeyIndex(0));
      final address = generateP2WPKHAddress(hd: hd, index: 0, network: LitecoinNetwork.mainnet);

      accounts.add(HardwareAccountData(
        address: address,
        accountIndex: i,
        derivationPath: derivationPath,
        xpub: xPub,
      ));
    }

    return accounts;
  }
}
