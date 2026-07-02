import 'dart:convert';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/psbt/signer.dart';
import 'package:cw_bitcoin/psbt/v0_deserialize.dart';
import 'package:cw_bitcoin/psbt/v0_finalizer.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:ledger_bitcoin/psbt.dart';
import "package:ledger_bitcoin/src/psbt/constants.dart";

String signPsbtSync(String psbtBase64, List<UtxoWithPrivateKey> utxos) {
  final psbt = PsbtV2()..deserializeV0(base64Decode(psbtBase64));

  final inputCountBefore = psbt.getGlobalInputCount();

  // Log input info before signing
  for (var i = 0; i < inputCountBefore; i++) {
    final txidBytes = psbt.getInputPreviousTxid(i);
    final txid = BytesUtils.toHexString(txidBytes.reversed.toList());
    final vout = psbt.getInputOutputIndex(i);
    final witUtxo = psbt.getInputWitnessUtxo(i);
    final redeemScript = psbt.getInputRedeemScript(i);
    final partialSigs = psbt.getInputKeyDatas(i, PSBTIn.partialSig);
    final isReceiver = utxos.any((e) => e.utxo.txHash == txid && e.utxo.vout == vout);
    String? finalWitHex;
    try { finalWitHex = BytesUtils.toHexString(psbt.getInputFinalScriptwitness(i)); } catch (_) {}
    printV('Input $i: txid=$txid vout=$vout receiver=$isReceiver');
    printV('  witnessUtxo: ${witUtxo != null ? "present" : "null"}');
    printV('  redeemScript: ${redeemScript != null ? BytesUtils.toHexString(redeemScript) : "null"}');
    printV('  finalScriptWitness: $finalWitHex');
    printV('  partialSigs count: ${partialSigs.length}');
  }

  psbt.signWithUTXOSync(utxos, (txDigest, utxo, key, sighash) {
    return utxo.utxo.isP2tr()
        ? key.signTapRoot(
            txDigest,
            sighash: sighash,
            tweak: utxo.utxo.isSilentPayment != true,
          )
        : key.signInput(txDigest, sigHash: sighash);
  });

  // Log partial sigs after signing
  printV('After signing:');
  for (var i = 0; i < inputCountBefore; i++) {
    final partialSigs = psbt.getInputKeyDatas(i, PSBTIn.partialSig);
    final txidBytes = psbt.getInputPreviousTxid(i);
    final txid = BytesUtils.toHexString(txidBytes.reversed.toList());
    final vout = psbt.getInputOutputIndex(i);
    final isReceiver = utxos.any((e) => e.utxo.txHash == txid && e.utxo.vout == vout);
    printV('Input $i: receiver=$isReceiver partialSigs count=${partialSigs.length}');
    for (var j = 0; j < partialSigs.length; j++) {
      final sig = psbt.getInputPartialSig(i, partialSigs[j]);
      printV('  sig[$j]: pubkey=${BytesUtils.toHexString(partialSigs[j])} sig=${sig != null ? BytesUtils.toHexString(sig) : "null"}');
    }
  }

  // Strip partial sigs from sender inputs so finalizeV0 only touches receiver inputs.
  // Sender re-signs via wallet_process_psbt — old sigs unused.
  for (var i = 0; i < inputCountBefore; i++) {
    final txidBytes = psbt.getInputPreviousTxid(i);
    final txid = BytesUtils.toHexString(txidBytes.reversed.toList());
    final vout = psbt.getInputOutputIndex(i);
    final isReceiver = utxos.any((e) =>
        e.utxo.txHash == txid && e.utxo.vout == vout);
    if (!isReceiver) {
      psbt.deleteInputEntries(i, [PSBTIn.partialSig]);
    } else {
      // Log receiver UTXO details for debugging
      final btcUtxo = utxos.firstWhere((e) => e.utxo.txHash == txid && e.utxo.vout == vout).utxo;
      printV('Receiver UTXO: scriptType=${btcUtxo.scriptType.value} isSegwit=${btcUtxo.isSegwit()} isP2tr=${btcUtxo.isP2tr()}');
    }
  }

  psbt.finalizeV0();

  // Log after potential finalize
  printV('After processing:');
  for (var i = 0; i < inputCountBefore; i++) {
    String? finalWitHex;
    try { finalWitHex = BytesUtils.toHexString(psbt.getInputFinalScriptwitness(i)); } catch (_) {}
    final partialSigs = psbt.getInputKeyDatas(i, PSBTIn.partialSig);
    printV('Input $i: partialSigs count=${partialSigs.length} finalScriptWitness=$finalWitHex');
  }

  final result = base64Encode(psbt.asPsbtV0());
  printV('Final PSBT base64: $result');
  return result;
}
