import "dart:typed_data";

import "package:ledger_bitcoin/src/psbt/constants.dart";
import "package:ledger_bitcoin/src/psbt/psbtv2.dart";
import "package:ledger_bitcoin/src/utils/buffer_writer.dart";
import "package:cw_bitcoin/map_extension.dart";

extension V0Serializer on PsbtV2 {
  Uint8List asPsbtV0() {
    final excludedGlobalKeyTypes = [
      PSBTGlobal.txVersion,
      PSBTGlobal.fallbackLocktime,
      PSBTGlobal.inputCount,
      PSBTGlobal.outputCount,
      PSBTGlobal.txModifiable,
    ].map((e) => e.value.toString());

    final excludedInputKeyTypes = [
      PSBTIn.previousTXID,
      PSBTIn.outputIndex,
      PSBTIn.sequence,
    ].map((e) => e.value.toString());

    final excludedOutputKeyTypes = [
      PSBTOut.amount,
      PSBTOut.script,
    ].map((e) => e.value.toString());

    final buf = BufferWriter()..writeSlice(psbtMagicBytes);

    setGlobalPsbtVersion(0);
    final sGlobalMap = Map.from(globalMap)
      ..removeWhere((k, v) => excludedGlobalKeyTypes.contains(k));

    sGlobalMap["00"] = extractUnsignedTX();

    sGlobalMap.serializeMap(buf);
    for (final map in inputMaps) {
      final sMap = Map.from(map)
        ..removeWhere((k, v) => excludedInputKeyTypes.contains(k));
      sMap.serializeMap(buf);
    }
    for (final map in outputMaps) {
      final sMap = Map.from(map)
        ..removeWhere((k, v) => excludedOutputKeyTypes.contains(k));
      sMap.serializeMap(buf);
    }
    return buf.buffer();
  }

  Uint8List extractUnsignedTX() {
    final tx = BufferWriter()..writeUInt32(getGlobalTxVersion());

    final isSegwit = getInputWitnessUtxo(0) != null;
    if (isSegwit) {
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
}
