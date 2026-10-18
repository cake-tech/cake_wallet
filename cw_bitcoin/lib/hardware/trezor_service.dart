import 'dart:async';
import 'dart:convert';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/hardware/bitcoin_hardware_wallet_service.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:flutter/foundation.dart';
import 'package:ledger_bitcoin/psbt.dart';
import 'package:ledger_bitcoin/src/utils/uint8list_extension.dart' as ext;
import 'package:trezor_flutter/trezor_flutter.dart' as sdk;

class BitcoinTrezorService extends HardwareWalletService with BitcoinHardwareWalletService {
  BitcoinTrezorService(this.client) : _trezorBitcoin = sdk.TrezorBitcoin(client);

  final sdk.TrezorClient client;
  final sdk.TrezorBitcoin _trezorBitcoin;

  @override
  Future<Uint8List> getMasterFingerprint() async {
    final publicKey = await _trezorBitcoin.getPublicKey(derivationPath: "m/84'/0'/0'");
    final fingerprintBuffer = ByteData(4)..setUint32(0, publicKey.$2);
    return fingerprintBuffer.buffer.asUint8List();
  }

  @override
  Future<List<HardwareAccountData>> getAvailableAccounts({int index = 0, int limit = 5}) async {
    final accounts = <HardwareAccountData>[];
    final indexRange = List.generate(limit, (i) => i + index);

    for (final i in indexRange) {
      final derivationPath = "m/84'/0'/$i'";
      final xPub =
          await _trezorBitcoin.getPublicKey(derivationPath: derivationPath, ignoreXpubMagic: true);
      final hd = Bip32Slip10Secp256k1.fromExtendedKey(xPub.$1).childKey(Bip32KeyIndex(0));

      final address = generateP2WPKHAddress(hd: hd, index: 0, network: BitcoinNetwork.mainnet);

      accounts.add(
        HardwareAccountData(
          address: address,
          accountIndex: i,
          derivationPath: derivationPath,
          xpub: xPub.$1,
        ),
      );
    }

    return accounts;
  }

  @override
  Future<Uint8List> signTransaction({required String transaction}) async {
    final psbt = PsbtV2()..deserialize(base64Decode(transaction));
    final masterFingerprint = await getMasterFingerprint();

    final inputs = <sdk.TrezorTxInput>[];
    final prevTxs = <String, sdk.TrezorPrevTx>{};

    final inputCount = psbt.getGlobalInputCount();
    for (var i = 0; i < inputCount; i++) {
      final rawPrevTx = psbt.getInputNonWitnessUtxo(i);
      if (rawPrevTx == null) {
        throw StateError("PSBT input $i is missing its previous transaction");
      }
      final prevTx = BtcTransaction.fromRaw(hex.encode(rawPrevTx));
      final vout = psbt.getInputOutputIndex(i);

      final txidBytes = psbt.getInputPreviousTxid(i).reversed.toList();

      final pubkey = _firstDerivationPubkey(psbt.inputMaps[i], "06");
      if (pubkey == null) {
        throw StateError("PSBT input $i is missing its BIP32 derivation");
      }

      final derivation = psbt.getInputBip32Derivation(i, pubkey)!;
      final path = derivation.$2;

      if (!listEquals(derivation.$1, masterFingerprint)) {
        throw Exception("Fingerprint missmatch with the PSBT");
      }

      inputs.add(
        sdk.TrezorTxInput(
          addressPath: path,
          prevHash: txidBytes,
          prevIndex: vout,
          amount: prevTx.outputs[vout].amount.toInt(),
          sequence: psbt.getInputSequence(i),
          scriptType: "SPENDWITNESS",
        ),
      );

      prevTxs[hex.encode(txidBytes)] = sdk.TrezorPrevTx(
        meta: sdk.TrezorPrevTxMeta(
          version: Uint8List.fromList(prevTx.version).readUint32LE(0),
          lockTime: Uint8List.fromList(prevTx.locktime).readUint32LE(0),
          inputsCount: prevTx.inputs.length,
          outputsCount: prevTx.outputs.length,
        ),
        inputs: prevTx.inputs
            .map(
              (e) => sdk.TrezorPrevInput(
                prevHash: hex.decode(e.txId),
                prevIndex: e.txIndex,
                scriptSig: e.scriptSig.toBytes(),
                sequence: Uint8List.fromList(e.sequence).readUint32LE(0),
              ),
            )
            .toList(),
        outputs: prevTx.outputs
            .map(
              (e) => sdk.TrezorPrevOutput(
                amount: e.amount.toInt(),
                scriptPubkey: e.scriptPubKey.toBytes(),
              ),
            )
            .toList(),
      );
    }

    final outputs = <sdk.TrezorTxOutput>[];
    final outputCount = psbt.getGlobalOutputCount();
    for (var i = 0; i < outputCount; i++) {
      final amount = psbt.getOutputAmount(i);

      // An output carrying our own BIP32 derivation is change: identify it
      // by path so the device verifies it internally instead of displaying
      // it as a payment.
      final changePubkey = _firstDerivationPubkey(psbt.outputMaps[i], "02");
      if (changePubkey != null) {
        final (fingerprint, path) = psbt.getOutputBip32Derivation(i, changePubkey);
        if (listEquals(fingerprint, masterFingerprint)) {
          outputs.add(sdk.TrezorTxOutput(
            addressPath: path,
            amount: amount,
            scriptType: "PAYTOWITNESS",
          ));
          continue;
        }
      }

      final script = Script.fromRaw(byteData: psbt.getOutputScript(i));
      outputs.add(sdk.TrezorTxOutput(
        address: script.toAddress(),
        amount: amount,
        scriptType: "PAYTOADDRESS",
      ));
    }

    final signed = await _trezorBitcoin.signTransaction(
      inputs: inputs,
      outputs: outputs,
      prevTxs: prevTxs,
      version: psbt.getGlobalTxVersion(),
      lockTime: psbt.getGlobalFallbackLocktime() ?? 0,
    );

    return signed.serializedTx;
  }

  @override
  Future<Uint8List> signMessage({required Uint8List message, String? derivationPath}) =>
      _trezorBitcoin.signMessage(
        derivationPath: derivationPath ?? "m/84'/0'/0'/0/0",
        message: message,
      );

  /// Extracts the pubkey from the first BIP32-derivation record
  /// ([keyTypeHex] `06` for inputs, `02` for outputs) of a PSBT key-value map.
  Uint8List? _firstDerivationPubkey(Map<String, Uint8List> map, String keyTypeHex) {
    final key = map.keys.where((mapKey) => mapKey.startsWith(keyTypeHex)).firstOrNull;
    if (key == null) return null;
    return Uint8List.fromList(hex.decode(key.substring(2)));
  }
}
