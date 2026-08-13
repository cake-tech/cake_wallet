import "dart:convert";
import "dart:typed_data";

import "package:bitcoin_base/bitcoin_base.dart";
import "package:convert/convert.dart";
import "package:cw_core/output_info.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:ledger_bitcoin/psbt.dart";

class PSBTTransactionBuild {
  PSBTTransactionBuild({
    required List<PSBTReadyUtxoWithAddress> inputs,
    required List<PSBTReadyBitcoinOutput> outputs,
    bool enableRBF = true,
  }) {
    psbt.setGlobalTxVersion(2);
    psbt.setGlobalInputCount(inputs.length);
    psbt.setGlobalOutputCount(outputs.length);

    for (var i = 0; i < inputs.length; i++) {
      final input = inputs[i];

      psbt.setInputPreviousTxId(
        i,
        Uint8List.fromList(hex.decode(input.utxo.txHash).reversed.toList()),
      );
      psbt.setInputOutputIndex(i, input.utxo.vout);
      psbt.setInputSequence(i, enableRBF ? 0xfffffffd : 0xffffffff);

      if (input.utxo.isSegwit()) {
        setInputSegwit(i, input);
      } else if (input.utxo.isP2shSegwit()) {
        setInputP2shSegwit(i, input);
      } else if (input.utxo.isP2tr()) {
        // ToDo: (Konsti) Handle Taproot Inputs
      } else {
        setInputP2pkh(i, input);
      }
    }

    for (var i = 0; i < outputs.length; i++) {
      final output = outputs[i];

      psbt.setOutputScript(i, Uint8List.fromList(output.address.toScriptPubKey().toBytes()));
      psbt.setOutputAmount(i, output.value.toInt());

      if (output.isChange &&
          output.changeDerivationPath != null &&
          output.changePublicKey != null &&
          output.changeMasterFingerprint != null) {
        psbt.setOutputBip32Derivation(
          i,
          Uint8List.fromList(hex.decode(output.changePublicKey!)),
          output.changeMasterFingerprint!,
          BIPPath.fromString(output.changeDerivationPath!).toPathArray(),
        );
      }

      if (output.outputInfo != null) {
        try {
          final cwOutput = output.outputInfo!;
          if (cwOutput.extra.containsKey("bip353_name") &&
              cwOutput.extra.containsKey("bip353_proof")) {
            final bip353Name = utf8.encode(cwOutput.extra["bip353_name"] as String);
            final bip353Proof = base64.decode(cwOutput.extra["bip353_proof"] as String);

            if (bip353Name.length > 255) {
              printV("BIP353 name is too long, skipping");
              continue;
            }
            final proof = Uint8List.fromList([
              bip353Name.length,
              ...bip353Name,
              ...bip353Proof,
            ]);

            psbt.setOutputDNSSECProof(i, proof);
          }
        } catch (e) {
          printV("Error setting DNSSEC proof: $e");
        }
      }
    }
  }

  final PsbtV2 psbt = PsbtV2();

  void setInputP2pkh(int i, PSBTReadyUtxoWithAddress input) {
    psbt.setInputNonWitnessUtxo(i, Uint8List.fromList(hex.decode(input.rawTx)));
    psbt.setInputBip32Derivation(
      i,
      Uint8List.fromList(hex.decode(input.ownerPublicKey)),
      input.ownerMasterFingerprint,
      BIPPath.fromString(input.ownerDerivationPath).toPathArray(),
    );
  }

  void setInputSegwit(int i, PSBTReadyUtxoWithAddress input) {
    psbt.setInputNonWitnessUtxo(i, Uint8List.fromList(hex.decode(input.rawTx)));
    psbt.setInputBip32Derivation(
      i,
      Uint8List.fromList(hex.decode(input.ownerPublicKey)),
      input.ownerMasterFingerprint,
      BIPPath.fromString(input.ownerDerivationPath).toPathArray(),
    );

    psbt.setInputWitnessUtxo(
      i,
      Uint8List.fromList(bigIntToUint64LE(input.utxo.value)),
      Uint8List.fromList(input.ownerDetails.address.toScriptPubKey().toBytes()),
    );
  }

  void setInputP2shSegwit(int i, PSBTReadyUtxoWithAddress input) {
    psbt.setInputNonWitnessUtxo(i, Uint8List.fromList(hex.decode(input.rawTx)));
    psbt.setInputBip32Derivation(
      i,
      Uint8List.fromList(hex.decode(input.ownerPublicKey)),
      input.ownerMasterFingerprint,
      BIPPath.fromString(input.ownerDerivationPath).toPathArray(),
    );

    psbt.setInputRedeemScript(
      i,
      Uint8List.fromList(input.ownerDetails.address.toScriptPubKey().toBytes()),
    );
    psbt.setInputWitnessUtxo(
      i,
      Uint8List.fromList(bigIntToUint64LE(input.utxo.value)),
      Uint8List.fromList(input.ownerDetails.address.toScriptPubKey().toBytes()),
    );
  }
}

class PSBTReadyUtxoWithAddress extends UtxoWithAddress {
  PSBTReadyUtxoWithAddress({
    required super.utxo,
    required this.rawTx,
    required super.ownerDetails,
    required this.ownerDerivationPath,
    required this.ownerMasterFingerprint,
    required this.ownerPublicKey,
  });

  final String rawTx;
  final String ownerDerivationPath;
  final Uint8List ownerMasterFingerprint;
  final String ownerPublicKey;
}

class PSBTReadyBitcoinOutput extends BitcoinOutput {
  PSBTReadyBitcoinOutput({
    required super.address,
    required super.value,
    super.isSilentPayment = false,
    super.isChange = false,
    this.changeDerivationPath,
    this.changeMasterFingerprint,
    this.changePublicKey,
    this.outputInfo,
  });

  factory PSBTReadyBitcoinOutput.fromOutput(BitcoinOutput output) => PSBTReadyBitcoinOutput(
    address: output.address,
    value: output.value,
    isSilentPayment: output.isSilentPayment,
    isChange: output.isChange,
  );

  final String? changeDerivationPath;
  final Uint8List? changeMasterFingerprint;
  final String? changePublicKey;
  final OutputInfo? outputInfo;
}
