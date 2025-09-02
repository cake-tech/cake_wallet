import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:bitbox_flutter/bitbox_manager.dart';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/hardware/bitcoin_hardware_wallet_service.dart';
import 'package:cw_bitcoin/psbt/v0_deserialize.dart';
import 'package:cw_bitcoin/psbt/v0_finalizer.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:ledger_bitcoin/psbt.dart';

class BitcoinBitboxService extends HardwareWalletService with BitcoinHardwareWalletService {
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


  @override
  Future<Uint8List> signTransaction({required String transaction}) async {
    final psbt = PsbtV2()..deserialize(base64Decode(transaction));
    log(base64Encode(psbt.asPsbtV0()), name: 'PSBT');
    final signedPsbt = await manager.signBTCPsbt(1, base64Encode(psbt.asPsbtV0()));
    log(signedPsbt, name: 'signed PSBT');
    final transactionRes = PsbtV2()
      ..deserializeV0(base64Decode(signedPsbt))
      ..finalizeV0();
    return transactionRes.extract();
  }

  @override
  Future<Uint8List> signMessage({required Uint8List message, String? derivationPath}) async {
    throw UnimplementedError(); // ToDo (Konsti)
  }

  @override
  Future<Uint8List> getMasterFingerprint() => manager.getMasterFingerprint();
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
