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
  var receiverInputCount = 0;
  for (var i = 0; i < inputCountBefore; i++) {
    final txidBytes = psbt.getInputPreviousTxid(i);
    final txid = BytesUtils.toHexString(txidBytes.reversed.toList());
    final vout = psbt.getInputOutputIndex(i);
    if (utxos.any((e) => e.utxo.txHash == txid && e.utxo.vout == vout)) {
      receiverInputCount++;
    }
  }
  printV('signPsbtSync: inputs=$inputCountBefore receiverInputs=$receiverInputCount');

  psbt.signWithUTXOSync(utxos, (txDigest, utxo, key, sighash) {
    return utxo.utxo.isP2tr()
        ? key.signTapRoot(
            txDigest,
            sighash: sighash,
            tweak: utxo.utxo.isSilentPayment != true,
          )
        : key.signInput(txDigest, sigHash: sighash);
  });

  // Strip partial sigs from sender inputs so finalizeV0 only touches receiver
  // inputs. The sender re-signs via wallet_process_psbt later, so any partial
  // sigs it carried from the original PSBT are obsolete and would confuse the
  // finalizer.
  for (var i = 0; i < inputCountBefore; i++) {
    final txidBytes = psbt.getInputPreviousTxid(i);
    final txid = BytesUtils.toHexString(txidBytes.reversed.toList());
    final vout = psbt.getInputOutputIndex(i);
    final isReceiver = utxos.any((e) =>
        e.utxo.txHash == txid && e.utxo.vout == vout);
    if (!isReceiver) {
      psbt.deleteInputEntries(i, [PSBTIn.partialSig]);
    }
  }

  psbt.finalizeV0();

  final result = base64Encode(psbt.asPsbtV0());
  return result;
}
