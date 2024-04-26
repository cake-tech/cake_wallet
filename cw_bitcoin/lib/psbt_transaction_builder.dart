import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:convert/convert.dart';
import 'package:ledger_bitcoin/psbt.dart';

class PSBTTransactionBuild {
  final PsbtV2 psbt = PsbtV2();

  PSBTTransactionBuild(
      {required List<PSBTReadyUtxoWithAddress> inputs, required List<BitcoinBaseOutput> outputs}) {
    psbt.setGlobalTxVersion(2);
    psbt.setGlobalInputCount(inputs.length);
    psbt.setGlobalOutputCount(outputs.length);

    for (var i = 0; i < inputs.length; i++) {
      final input = inputs[i];
      final ownerAddress = input.ownerDetails.address;

      // ToDo: (Konsti) Handle Taproot Inputs

      psbt.setInputPreviousTxId(i, Uint8List.fromList(hex.decode(input.utxo.txHash).reversed.toList()));
      psbt.setInputOutputIndex(i, input.utxo.vout);
      psbt.setInputSequence(i, 0xffffffff); // ToDo: (Konsti) Set to lower than UINT_MAX to enable RBF
      psbt.setInputWitnessUtxo(i, Uint8List.fromList(bigIntToUint64LE(input.utxo.value)),
          Uint8List.fromList(ownerAddress.toScriptPubKey().toBytes()));
      psbt.setInputNonWitnessUtxo(i, Uint8List.fromList(hex.decode(input.rawTx)));
      psbt.setInputBip32Derivation(
          i,
          Uint8List.fromList(hex.decode(input.ownerPublicKey)),
          input.ownerMasterFingerprint,
          BIPPath.fromString(input.ownerDerivationPath).toPathArray());
    }

    for (var i = 0; i < outputs.length; i++) {
      final output = outputs[i];

      if (output is BitcoinOutput) {
        psbt.setOutputScript(i, Uint8List.fromList(output.address.toScriptPubKey().toBytes()));
        psbt.setOutputAmount(i, output.value.toInt());
      }
    }
  }


}

class PSBTReadyUtxoWithAddress extends UtxoWithAddress {
  final String rawTx;
  final String ownerDerivationPath;
  final Uint8List ownerMasterFingerprint;
  final String ownerPublicKey;

  PSBTReadyUtxoWithAddress({
    required super.utxo,
    required this.rawTx,
    required super.ownerDetails,
    required this.ownerDerivationPath,
    required this.ownerMasterFingerprint,
    required this.ownerPublicKey,
  });
}
