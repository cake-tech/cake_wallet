import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:collection/collection.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/bitcoin_wallet.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:ledger_bitcoin/psbt.dart';
import 'package:ledger_bitcoin/src/utils/buffer_writer.dart';

extension PsbtSigner on PsbtV2 {
  Uint8List extractUnsignedTX({bool getSegwit = true}) {
    final tx = BufferWriter()..writeUInt32(getGlobalTxVersion());

    final isSegwit = getInputWitnessUtxo(0) != null;
    if (isSegwit && getSegwit) {
      tx.writeSlice(Uint8List.fromList([0, 1]));
    }

    final inputCount = getGlobalInputCount();
    tx.writeVarInt(inputCount);

    for (var i = 0; i < inputCount; i++) {
      tx
        ..writeSlice(getInputPreviousTxid(i))
        ..writeUInt32(getInputOutputIndex(i))
        ..writeVarSlice(Uint8List(0))
        ..writeUInt32(getInputSequence(i));
    }

    final outputCount = getGlobalOutputCount();
    tx.writeVarInt(outputCount);
    for (var i = 0; i < outputCount; i++) {
      tx.writeUInt64(getOutputAmount(i));
      tx.writeVarSlice(getOutputScript(i));
    }
    tx.writeUInt32(getGlobalFallbackLocktime() ?? 0);
    return tx.buffer();
  }

  Future<void> signWithUTXO(List<UtxoWithPrivateKey> utxos, UTXOSignerCallBack signer,
      [UTXOGetterCallBack? getTaprootPair]) async {
    final reconstructedRaw = extractUnsignedTX(getSegwit: false);
    final raw = BytesUtils.toHexString(reconstructedRaw);
    final tx = BtcTransaction.fromRaw(raw);
    printV('[signWithUTXO] reconstructed unsigned_tx hex=$raw');
    printV('[signWithUTXO] tx.inputs=${tx.inputs.length} utxos=${utxos.length}');
    printV(
        '[signWithUTXO] tx.version=${BytesUtils.toHexString(tx.version)} tx.locktime=${BytesUtils.toHexString(tx.locktime)}');

    /// when the transaction is taproot and we must use getTaproot transaction
    /// digest we need all of inputs amounts and owner script pub keys
    List<BigInt> taprootAmounts = [];
    List<Script> taprootScripts = [];

    final anyP2tr = utxos.any((e) => e.utxo.isP2tr());
    printV('[signWithUTXO] anySenderP2tr=$anyP2tr');
    if (anyP2tr) {
      for (final input in tx.inputs) {
        final utxo = utxos
            .firstWhereOrNull((u) => u.utxo.txHash == input.txId && u.utxo.vout == input.txIndex);

        if (utxo == null) {
          printV(
              '[signWithUTXO] input txid=${input.txId} vout=${input.txIndex} -> not in utxos, fetching taproot pair');
          try {
            final trPair = await getTaprootPair!.call(input.txId, input.txIndex);
            taprootAmounts.add(trPair.value);
            taprootScripts.add(trPair.script);
            printV('[signWithUTXO]   fetched OK; amount=${trPair.value}');
          } catch (e, s) {
            printV('[signWithUTXO]   getTaprootPair FAILED: $e\n$s');
            rethrow;
          }
          continue;
        }
        taprootAmounts.add(utxo.utxo.value);
        taprootScripts.add(_findLockingScript(utxo, true));
      }
      printV('[signWithUTXO] built taprootAmounts.len=${taprootAmounts.length}');
    }

    for (var i = 0; i < tx.inputs.length; i++) {
      final utxo = utxos.firstWhereOrNull((e) =>
          e.utxo.txHash == tx.inputs[i].txId &&
          e.utxo.vout == tx.inputs[i].txIndex); // ToDo: More robust verify
      if (utxo == null) {
        printV(
            '[signWithUTXO] skip in[$i] txid=${tx.inputs[i].txId} vout=${tx.inputs[i].txIndex} (not in utxos)');
        continue;
      }
      printV(
          '[signWithUTXO] signing in[$i] txid=${tx.inputs[i].txId} vout=${tx.inputs[i].txIndex} scriptType=${utxo.utxo.scriptType.value}');

      /// We receive the owner's ScriptPubKey
      final script = _findLockingScript(utxo, false);

      final int sighash = utxo.utxo.isP2tr()
          ? BitcoinOpCodeConst.TAPROOT_SIGHASH_ALL
          : BitcoinOpCodeConst.SIGHASH_ALL;

      /// We generate transaction digest for current input
      final digest =
          _generateTransactionDigest(script, i, utxo.utxo, tx, taprootAmounts, taprootScripts);
      printV('[signWithUTXO]   digest.len=${digest.length}');

      /// now we need sign the transaction digest
      final sig = signer(digest, utxo, utxo.privateKey, sighash);
      printV('[signWithUTXO]   sig.len=${sig.length ~/ 2}');

      if (utxo.utxo.isP2tr()) {
        setInputTapKeySig(i, Uint8List.fromList(BytesUtils.fromHexString(sig)));
      } else {
        setInputPartialSig(i, Uint8List.fromList(BytesUtils.fromHexString(utxo.public().toHex())),
            Uint8List.fromList(BytesUtils.fromHexString(sig)));
      }
    }
    printV('[signWithUTXO] done');
  }

  List<int> _generateTransactionDigest(Script scriptPubKeys, int input, BitcoinUtxo utxo,
      BtcTransaction transaction, List<BigInt> taprootAmounts, List<Script> tapRootPubKeys) {
    final isSegwit = utxo.isSegwit();
    final isP2tr = utxo.isP2tr();
    printV('[digest] in[$input] isSegwit=$isSegwit isP2tr=$isP2tr');
    printV('[digest] in[$input] scriptCode=${BytesUtils.toHexString(scriptPubKeys.toBytes())}');
    printV('[digest] in[$input] amount=${utxo.value} sat');
    printV(
        '[digest] in[$input] tx.version=${BytesUtils.toHexString(transaction.version)} tx.locktime=${BytesUtils.toHexString(transaction.locktime)}');
    printV('[digest] in[$input] tx.inputs.len=${transaction.inputs.length}');
    for (var j = 0; j < transaction.inputs.length; j++) {
      final inp = transaction.inputs[j];
      printV(
          '[digest]   txIn[$j] txid=${inp.txId} vout=${inp.txIndex} seq=${BytesUtils.toHexString(inp.sequence)}');
    }
    printV('[digest] in[$input] tx.outputs.len=${transaction.outputs.length}');
    for (var j = 0; j < transaction.outputs.length; j++) {
      final out = transaction.outputs[j];
      printV(
          '[digest]   txOut[$j] value=${out.amount} script=${BytesUtils.toHexString(out.scriptPubKey.toBytes())}');
    }
    final psbtLocktime = getGlobalFallbackLocktime();
    printV('[digest] in[$input] PSBT fallbackLocktime field=${psbtLocktime ?? "null (→ 0)"}');

    List<int> digest;
    if (isSegwit) {
      if (isP2tr) {
        digest = transaction.getTransactionTaprootDigset(
          txIndex: input,
          scriptPubKeys: tapRootPubKeys,
          amounts: taprootAmounts,
        );
      } else {
        digest = transaction.getTransactionSegwitDigit(
            txInIndex: input, script: scriptPubKeys, amount: utxo.value);
      }
    } else {
      digest = transaction.getTransactionDigest(txInIndex: input, script: scriptPubKeys);
    }
    printV('[digest] in[$input] → digest=${BytesUtils.toHexString(digest)}');
    return digest;
  }

  Script _findLockingScript(UtxoWithAddress utxo, bool isTaproot) {
    if (utxo.isMultiSig()) {
      throw Exception("MultiSig is not supported yet");
    }

    final senderPub = utxo.public();
    switch (utxo.utxo.scriptType) {
      case PubKeyAddressType.p2pk:
        return senderPub.toRedeemScript();
      case SegwitAddresType.p2wsh:
        if (isTaproot) {
          return senderPub.toP2wshAddress().toScriptPubKey();
        }
        return senderPub.toP2wshRedeemScript();
      case P2pkhAddressType.p2pkh:
        return senderPub.toP2pkhAddress().toScriptPubKey();
      case SegwitAddresType.p2wpkh:
        if (isTaproot) {
          return senderPub.toP2wpkhAddress().toScriptPubKey();
        }
        return senderPub.toP2pkhAddress().toScriptPubKey();
      case SegwitAddresType.p2tr:
        return senderPub
            .toTaprootAddress(tweak: utxo.utxo.isSilentPayment != true)
            .toScriptPubKey();
      case SegwitAddresType.mweb:
        return Script(script: []);
      case P2shAddressType.p2pkhInP2sh:
        if (isTaproot) {
          return senderPub.toP2pkhInP2sh().toScriptPubKey();
        }
        return senderPub.toP2pkhAddress().toScriptPubKey();
      case P2shAddressType.p2wpkhInP2sh:
        if (isTaproot) {
          return senderPub.toP2wpkhInP2sh().toScriptPubKey();
        }
        return senderPub.toP2pkhAddress().toScriptPubKey();
      case P2shAddressType.p2wshInP2sh:
        if (isTaproot) {
          return senderPub.toP2wshInP2sh().toScriptPubKey();
        }
        return senderPub.toP2wshRedeemScript();
      case P2shAddressType.p2pkInP2sh:
        if (isTaproot) {
          return senderPub.toP2pkInP2sh().toScriptPubKey();
        }
        return senderPub.toRedeemScript();
    }
    throw Exception("invalid bitcoin address type");
  }

  void signWithUTXOSync(List<UtxoWithPrivateKey> utxos, UTXOSignerCallBack signer) {
    final raw = BytesUtils.toHexString(extractUnsignedTX(getSegwit: false));
    final tx = BtcTransaction.fromRaw(raw);

    List<BigInt> taprootAmounts = [];
    List<Script> taprootScripts = [];

    if (utxos.any((e) => e.utxo.isP2tr())) {
      for (var i = 0; i < tx.inputs.length; i++) {
        final utxo = utxos.firstWhereOrNull(
            (u) => u.utxo.txHash == tx.inputs[i].txId && u.utxo.vout == tx.inputs[i].txIndex);
        if (utxo == null) {
          final witnessUtxo = getInputWitnessUtxo(i);
          if (witnessUtxo != null) {
            final amount = witnessUtxo.$1;
            final scriptPubKey = witnessUtxo.$2;
            taprootAmounts.add(BigintUtils.fromBytes(amount.toList(), byteOrder: Endian.little));
            taprootScripts.add(Script(script: scriptPubKey.toList()));
          } else {
            throw Exception("Missing witness UTXO for P2TR input $i");
          }
        } else {
          taprootAmounts.add(utxo.utxo.value);
          taprootScripts.add(_findLockingScript(utxo, true));
        }
      }
    }

    for (var i = 0; i < tx.inputs.length; i++) {
      final utxo = utxos.firstWhereOrNull(
          (e) => e.utxo.txHash == tx.inputs[i].txId && e.utxo.vout == tx.inputs[i].txIndex);
      if (utxo == null) continue;

      final script = _findLockingScript(utxo, false);
      final int sighash = utxo.utxo.isP2tr()
          ? BitcoinOpCodeConst.TAPROOT_SIGHASH_ALL
          : BitcoinOpCodeConst.SIGHASH_ALL;
      final digest =
          _generateTransactionDigest(script, i, utxo.utxo, tx, taprootAmounts, taprootScripts);
      final sig = signer(digest, utxo, utxo.privateKey, sighash);

      if (utxo.utxo.isP2tr()) {
        setInputTapKeySig(i, Uint8List.fromList(BytesUtils.fromHexString(sig)));
      } else {
        setInputPartialSig(i, Uint8List.fromList(BytesUtils.fromHexString(utxo.public().toHex())),
            Uint8List.fromList(BytesUtils.fromHexString(sig)));
      }
    }
  }
}

typedef UTXOSignerCallBack = String Function(
    List<int> trDigest, UtxoWithAddress utxo, ECPrivate privateKey, int sighash);

typedef UTXOGetterCallBack = Future<TaprootAmountScriptPair> Function(String txId, int vout);

class TaprootAmountScriptPair {
  final BigInt value;
  final Script script;

  const TaprootAmountScriptPair(this.value, this.script);
}

class UtxoWithPrivateKey extends UtxoWithAddress {
  final ECPrivate privateKey;

  UtxoWithPrivateKey({
    required super.utxo,
    required super.ownerDetails,
    required this.privateKey,
  });

  factory UtxoWithPrivateKey.fromUtxo(
      UtxoWithAddress input, List<ECPrivateInfo> inputPrivateKeyInfos) {
    ECPrivateInfo? key;

    if (inputPrivateKeyInfos.isEmpty) {
      throw Exception("No private keys generated.");
    } else {
      key = inputPrivateKeyInfos.firstWhereOrNull((element) {
        final elemPubkey = element.privkey.getPublic().toHex();
        if (elemPubkey == input.public().toHex()) {
          return true;
        } else {
          return false;
        }
      });
    }

    if (key == null) {
      throw Exception("${input.utxo.txHash} No Key found");
    }

    return UtxoWithPrivateKey(
        utxo: input.utxo, ownerDetails: input.ownerDetails, privateKey: key.privkey);
  }

  factory UtxoWithPrivateKey.fromUnspent(BitcoinUnspent input, BitcoinWalletBase wallet) {
    final address = RegexUtils.addressTypeFromStr(input.address, BitcoinNetwork.mainnet);

    final newHd = input.bitcoinAddressRecord.isHidden ? wallet.sideHd : wallet.mainHd;

    ECPrivate privkey;
    if (input.bitcoinAddressRecord is BitcoinSilentPaymentAddressRecord) {
      final unspentAddress = input.bitcoinAddressRecord as BitcoinSilentPaymentAddressRecord;
      privkey = wallet.walletAddresses.silentAddress!.b_spend.tweakAdd(
        BigintUtils.fromBytes(
          BytesUtils.fromHexString(unspentAddress.silentPaymentTweak!),
        ),
      );
    } else {
      privkey = generateECPrivate(
          hd: newHd, index: input.bitcoinAddressRecord.index, network: BitcoinNetwork.mainnet);
    }

    return UtxoWithPrivateKey(
        utxo: BitcoinUtxo(
          txHash: input.hash,
          value: BigInt.from(input.value),
          vout: input.vout,
          scriptType: input.bitcoinAddressRecord.type,
          isSilentPayment: input.bitcoinAddressRecord is BitcoinSilentPaymentAddressRecord,
        ),
        ownerDetails: UtxoAddressDetails(
          publicKey: privkey.getPublic().toHex(),
          address: address,
        ),
        privateKey: privkey);
  }
}
