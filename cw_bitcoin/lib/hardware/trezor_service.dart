import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/hardware/bitcoin_hardware_wallet_service.dart';
import 'package:cw_bitcoin/psbt/transaction_builder.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:ledger_bitcoin/psbt.dart';
import 'package:trezor_connect/trezor_connect.dart';

class BitcoinTrezorService extends HardwareWalletService with BitcoinHardwareWalletService {
  BitcoinTrezorService(this.connect);

  final TrezorConnect connect;

  @override
  Future<List<HardwareAccountData>> getAvailableAccounts({int index = 0, int limit = 5}) async {
    final indexRange = List.generate(limit, (i) => i + index);
    final requestParams = <TrezorGetPublicKeyParams>[];

    for (final i in indexRange) {
      requestParams.add(TrezorGetPublicKeyParams(path: "m/84'/0'/$i'"));
    }

    final accounts = await connect.getPublicKeyBundle(requestParams);

    return accounts?.map((account) {
          final hd = Bip32Slip10Secp256k1.fromExtendedKey(account.xpub).childKey(Bip32KeyIndex(0));
          final address = generateP2WPKHAddress(hd: hd, index: 0, network: BitcoinNetwork.mainnet);
          return HardwareAccountData(
            address: address,
            xpub: account.xpub,
            accountIndex: account.path[2] - 0x80000000, // unharden the path to get the index
            derivationPath: account.serializedPath,
          );
        }).toList() ??
        [];
  }

  @override
  Future<Uint8List> signTransaction({required String transaction}) async {
    final psbt = PsbtV2()..deserialize(base64Decode(transaction));

    final inputs = <TrezorTxInput>[];
    final inputCount = psbt.getGlobalInputCount();
    for (var i = 0; i < inputCount; i++) {
      final inputTxRaw = psbt.getInputNonWitnessUtxo(i);
      final inputTx = BtcTransaction.fromRaw(hex.encode(inputTxRaw!));
      final inputOutputIndex = psbt.getInputOutputIndex(i);

      final publicKeys = psbt.inputMaps[i].keys.where((e) => e.startsWith("06"));
      final pubkey = Uint8List.fromList(hex.decode(publicKeys.first.substring(2)));

      inputs.add(TrezorTxInput(
          prevHash: hex.encode(psbt.getInputPreviousTxid(i).reversed.toList()),
          prevIndex: inputOutputIndex,
          amount: inputTx.outputs[inputOutputIndex].amount.toInt(),
          addressPath: psbt.getInputBip32Derivation(i, pubkey)!.$2,
          sequence: psbt.getInputSequence(i),
          scriptType: "SPENDWITNESS"));
    }

    final outputs = <TrezorTxOutput>[];
    final outputCount = psbt.getGlobalOutputCount();
    for (var i = 0; i < outputCount; i++) {
      final script = Script.fromRaw(byteData: psbt.getOutputScript(i));
      outputs.add(TrezorTxOutput(
          amount: psbt.getOutputAmount(i),
          address: script.toAddress(),
          scriptType: _getScriptType(script.getAddressType()!)
          // ToDo: addressPath: psbt.getOutputBip32Derivation(i, pubkey).$2, // To highlight change outputs
          ));
    }

    final signedTx = await connect.signTransaction(coin: 'btc', inputs: inputs, outputs: outputs);

    return Uint8List.fromList(BytesUtils.fromHexString(signedTx!.serializedTx));
  }

  @override
  Future<Uint8List> signMessage({required Uint8List message, String? derivationPath}) async {
    final sig = await connect.signMessage(derivationPath ?? "m/84'/0'/0'/0/0",
        message: hex.encode(message), hex: true);
    return base64Decode(sig!.signature);
  }
}

class LitecoinTrezorService extends HardwareWalletService with BitcoinHardwareWalletService, LitecoinHardwareWalletService {
  LitecoinTrezorService(this.connect);

  final TrezorConnect connect;

  @override
  Future<List<HardwareAccountData>> getAvailableAccounts({int index = 0, int limit = 5}) async {
    final indexRange = List.generate(limit, (i) => i + index);
    final requestParams = <TrezorGetPublicKeyParams>[];
    final xpubVersion = Bip44Conf.litecoinMainNet.altKeyNetVer;

    for (final i in indexRange) {
      final derivationPath = "m/84'/2'/$i'";
      requestParams.add(TrezorGetPublicKeyParams(path: derivationPath, coin: "LTC"));
    }

    final accounts = await connect.getPublicKeyBundle(requestParams);

    return accounts?.map((account) {
          final hd = Bip32Slip10Secp256k1.fromExtendedKey(account.xpub, xpubVersion)
              .childKey(Bip32KeyIndex(0));

          final address = generateP2WPKHAddress(hd: hd, index: 0, network: LitecoinNetwork.mainnet);
          return HardwareAccountData(
            address: address,
            xpub: account.xpub,
            accountIndex: account.path[2] - 0x80000000, // unharden the path to get the index
            derivationPath: account.serializedPath,
          );
        }).toList() ??
        [];
  }

  @override
  Future<String> signLitecoinTransaction({
    required List<BitcoinBaseOutput> outputs,
    required List<PSBTReadyUtxoWithAddress> inputs,
    required Map<String, PublicKeyWithDerivationPath> publicKeys,
  }) async {
    final readyInputs = inputs
        .map((input) => TrezorTxInput(
              prevHash: input.utxo.txHash,
              prevIndex: input.utxo.vout,
              amount: input.utxo.value.toInt(),
              addressPath: Bip32PathParser.parse(input.ownerDerivationPath).toList(),
              scriptType: "SPENDWITNESS",
            ))
        .toList();

    final readyOutputs = outputs.map((output) {
      final maybeChangePath = publicKeys[(output as BitcoinOutput).address.pubKeyHash()];

      return TrezorTxOutput(
        amount: output.toOutput.amount.toInt(),
        address: maybeChangePath != null
            ? null
            : output.toOutput.scriptPubKey.toAddress(network: LitecoinNetwork.mainnet),
        scriptType: _getScriptType(output.toOutput.scriptPubKey.getAddressType()!),
        addressPath: maybeChangePath != null
            ? Bip32PathParser.parse(maybeChangePath.derivationPath).toList()
            : null,
      );
    }).toList();

    final signedTx =
        await connect.signTransaction(coin: 'LTC', inputs: readyInputs, outputs: readyOutputs);

    return signedTx!.serializedTx;
  }
}

String _getScriptType(BitcoinAddressType addressType) {
  switch (addressType) {
    case P2pkhAddressType.p2pkh:
      return "PAYTOADDRESS";
    case P2shAddressType.p2wpkhInP2sh:
      return "PAYTOSCRIPTHASH";
    case SegwitAddresType.p2tr:
      return "PAYTOTAPROOT";
    case SegwitAddresType.p2wsh:
      return "PAYTOP2SHWITNESS";
    case SegwitAddresType.p2wpkh:
      return "PAYTOWITNESS";
    default:
      throw Exception("Unknown Address Type");
  }
}
