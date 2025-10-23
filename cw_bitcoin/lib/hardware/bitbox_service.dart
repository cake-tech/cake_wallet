import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:bitbox_flutter/bitbox_manager.dart';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/hardware/bitcoin_hardware_wallet_service.dart';
import 'package:cw_bitcoin/psbt/transaction_builder.dart';
import 'package:cw_bitcoin/psbt/v0_deserialize.dart';
import 'package:cw_bitcoin/psbt/v0_finalizer.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:ledger_bitcoin/psbt.dart';

class BitcoinBitboxService extends HardwareWalletService with BitcoinHardwareWalletService {
  BitcoinBitboxService(this.manager);

  // https://github.com/BitBoxSwiss/bitbox02-api-go/blob/ae070b1d41bf1cf00588fa6f498b4734b5ecd6fc/api/firmware/messages/btc.pb.go#L40
  static const int bitboxCoinType = 0;
  final BitboxManager manager;

  @override
  Future<List<HardwareAccountData>> getAvailableAccounts({int index = 0, int limit = 5}) async {
    final accounts = <HardwareAccountData>[];
    final indexRange = List.generate(limit, (i) => i + index);

    // https://github.com/BitBoxSwiss/bitbox02-api-go/blob/ae070b1d41bf1cf00588fa6f498b4734b5ecd6fc/api/firmware/messages/btc.pb.go#L252
    final keyType = 1; // xPUB
    for (final i in indexRange) {
      final derivationPath = "m/84'/0'/$i'";
      final xPub = await manager.getBTCXPub(bitboxCoinType, derivationPath, keyType);
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
    final signedPsbt = await manager.signBTCPsbt(bitboxCoinType, base64Encode(psbt.asPsbtV0()));
    log(signedPsbt, name: 'signed PSBT');
    final transactionRes = PsbtV2()
      ..deserializeV0(base64Decode(signedPsbt))
      ..finalizeV0();
    return transactionRes.extract();
  }

  @override
  Future<Uint8List> signMessage({required Uint8List message, String? derivationPath}) =>
      manager.signBTCMessage(bitboxCoinType, derivationPath ?? "m/84'/0'/0'/0/0", message);

  @override
  Future<Uint8List> getMasterFingerprint() => manager.getMasterFingerprint();
}

class LitecoinBitboxService extends HardwareWalletService with BitcoinHardwareWalletService, LitecoinHardwareWalletService {
  LitecoinBitboxService(this.manager);

  final BitboxManager manager;

  // https://github.com/BitBoxSwiss/bitbox02-api-go/blob/ae070b1d41bf1cf00588fa6f498b4734b5ecd6fc/api/firmware/messages/btc.pb.go#L40
  static const int bitboxCoinType = 2;

  @override
  Future<List<HardwareAccountData>> getAvailableAccounts({int index = 0, int limit = 5}) async {
    final accounts = <HardwareAccountData>[];
    final indexRange = List.generate(limit, (i) => i + index);

    // https://github.com/BitBoxSwiss/bitbox02-api-go/blob/ae070b1d41bf1cf00588fa6f498b4734b5ecd6fc/api/firmware/messages/btc.pb.go#L252
    final keyType = 1; // xPUB
    for (final i in indexRange) {
      final derivationPath = "m/84'/2'/$i'";
      final xPub = await manager.getBTCXPub(bitboxCoinType, derivationPath, keyType);
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

  @override
  Future<Uint8List> signMessage({required Uint8List message, String? derivationPath}) =>
      manager.signBTCMessage(bitboxCoinType, derivationPath ?? "m/84'/0'/0'/0/0", message);

  @override
  Future<String> signLitecoinTransaction({
    required List<BitcoinBaseOutput> outputs,
    required List<PSBTReadyUtxoWithAddress> inputs,
    required Map<String, PublicKeyWithDerivationPath> publicKeys,
  }) async {
    final psbt = PSBTTransactionBuild(inputs: inputs, outputs: outputs, cwOutputs: []).psbt;

    final signedPsbt = await manager.signBTCPsbt(bitboxCoinType, base64Encode(psbt.asPsbtV0()));
    final transactionRes = PsbtV2()
      ..deserializeV0(base64Decode(signedPsbt))
      ..finalizeV0();

    return hex.encode(transactionRes.extract());
  }

  @override
  Future<Uint8List> getMasterFingerprint() => manager.getMasterFingerprint();
}
