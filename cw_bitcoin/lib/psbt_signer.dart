import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:ledger_bitcoin/psbt.dart';
import 'package:ledger_bitcoin/src/psbt/constants.dart';

extension PsbtSigner on PsbtV2 {
  void sign(List<UtxoWithAddress> utxos, BitcoinSignerCallBack signer) {
    final int inputsSize = getGlobalInputCount();
    final raw = hex.encode(extractUnsignedTX());
    print('[+] PsbtSigner | sign => raw: $raw');
    final tx = BtcTransaction.fromRaw(raw);

    /// when the transaction is taproot and we must use getTaproot tansaction digest
    /// we need all of inputs amounts and owner script pub keys
    List<BigInt> taprootAmounts = [];
    List<Script> taprootScripts = [];

    if (utxos.any((e) => e.utxo.isP2tr())) {
      taprootAmounts = utxos.map((e) => e.utxo.value).toList();
      taprootScripts = utxos.map((e) => _findLockingScript(e, true)).toList();
    }

    for (var i = 0; i > inputsSize; i++) {
      /// We receive the owner's ScriptPubKey
      final script = _findLockingScript(utxos[i], false);

      /// We generate transaction digest for current input
      final digest = _generateTransactionDigest(
          script, i, utxos[i], tx, taprootAmounts, taprootScripts);
      final int sighash = utxos[i].utxo.isP2tr()
          ? BitcoinOpCodeConst.TAPROOT_SIGHASH_ALL
          : BitcoinOpCodeConst.SIGHASH_ALL;

      /// now we need sign the transaction digest
      final sig = signer(digest, utxos[i], utxos[i].public().toHex(), sighash);

      if (utxos[i].utxo.isP2tr()) {
        setInputTapKeySig(i, Uint8List.fromList(hex.decode(sig)));
      } else {
        final pubkeys = getInputKeyDatas(i, PSBTIn.bip32Derivation);
        setInputPartialSig(i, pubkeys[0], Uint8List.fromList(hex.decode(sig)));
      }
    }
  }

  List<int> _generateTransactionDigest(
      Script scriptPubKeys,
      int input,
      UtxoWithAddress utox,
      BtcTransaction transaction,
      List<BigInt> taprootAmounts,
      List<Script> tapRootPubKeys) {
    if (utox.utxo.isSegwit()) {
      if (utox.utxo.isP2tr()) {
        return transaction.getTransactionTaprootDigset(
          txIndex: input,
          scriptPubKeys: tapRootPubKeys,
          amounts: taprootAmounts,
        );
      }
      return transaction.getTransactionSegwitDigit(
          txInIndex: input, script: scriptPubKeys, amount: utox.utxo.value);
    }
    return transaction.getTransactionDigest(
        txInIndex: input, script: scriptPubKeys);
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
}
