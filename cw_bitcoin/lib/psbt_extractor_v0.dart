import 'dart:typed_data';

import 'package:ledger_bitcoin/src/psbt/psbtv2.dart';
import 'package:ledger_bitcoin/src/utils/buffer_writer.dart';

/// This implements the "Transaction Extractor" role of BIP370 (PSBTv2
/// https://github.com/bitcoin/bips/blob/master/bip-0370.mediawiki#transaction-extractor). However
/// the role is partially documented in BIP174 (PSBTv0
/// https://github.com/bitcoin/bips/blob/master/bip-0174.mediawiki#transaction-extractor).
///
extension TransactionExtractor on PsbtV2 {
  Uint8List extractFromV0() {
    final tx = BufferWriter()..writeUInt32(getGlobalTxVersion());

    final isSegwit = getInputWitnessUtxo(0) != null;
    if (isSegwit) {
      tx.writeSlice(Uint8List.fromList([0, 1]));
    }

    final inputCount = getGlobalInputCount();
    tx.writeVarInt(inputCount);

    final witnessWriter = BufferWriter();
    for (var i = 0; i < inputCount; i++) {
      tx
        ..writeSlice(getInputPreviousTxid(i))
        ..writeUInt32(getInputOutputIndex(i))
        ..writeVarSlice(getInputFinalScriptsig(i) ?? Uint8List(0))
        ..writeUInt32(getInputSequence(i));
      if (isSegwit) {
        witnessWriter.writeSlice(getInputFinalScriptwitness(i));
      }
    }

    final outputCount = getGlobalOutputCount();
    tx.writeVarInt(outputCount);
    for (var i = 0; i < outputCount; i++) {
      tx.writeUInt64(getOutputAmount(i));
      tx.writeVarSlice(getOutputScript(i));
    }
    tx.writeSlice(witnessWriter.buffer());
    tx.writeUInt32(getGlobalFallbackLocktime() ?? 0);
    return tx.buffer();
  }
}
