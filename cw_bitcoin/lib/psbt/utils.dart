import 'dart:convert';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/bitcoin_wallet.dart';
import 'package:cw_bitcoin/psbt/v0_deserialize.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:ledger_bitcoin/psbt.dart';
import 'package:ledger_bitcoin/src/utils/uint8list_extension.dart';

String getTxIdFromPsbtV0(String psbt) {
  final psbtV2 = PsbtV2()..deserializeV0(base64.decode(psbt));

  return BtcTransaction.fromRaw(BytesUtils.toHexString(psbtV2.extract())).txId();
}

String getOutputAmountFromPsbt(String psbtV0, BitcoinWalletBase wallet) {
  printV(psbtV0);
  final psbt = PsbtV2()..deserializeV0(base64.decode(psbtV0));
  int amount = 0;
  for (var i = 0; i < psbt.getGlobalOutputCount(); i++) {
    final script = psbt.getOutputScript(i);
    if (wallet.isMine(Script.fromRaw(byteData: script))) {
      amount += psbt.getOutputAmount(i);
    }
  }
  return amount.toString();
}

String getReceiverNetAmountFromPsbt(String psbtV0, BitcoinWalletBase wallet) {
  final psbt = PsbtV2()..deserializeV0(base64.decode(psbtV0));

  int outputsToWallet = 0;
  for (var i = 0; i < psbt.getGlobalOutputCount(); i++) {
    final script = psbt.getOutputScript(i);
    if (wallet.isMine(Script.fromRaw(byteData: script))) {
      outputsToWallet += psbt.getOutputAmount(i);
    }
  }

  int inputsFromWallet = 0;
  for (var i = 0; i < psbt.getGlobalInputCount(); i++) {
    final witnessUtxo = psbt.getInputWitnessUtxo(i);
    if (witnessUtxo == null) continue;
    final scriptBytes = witnessUtxo.$2;
    if (wallet.isMine(Script.fromRaw(byteData: scriptBytes))) {
      inputsFromWallet += witnessUtxo.$1.readUint64LE(0);
    }
  }

  final net = outputsToWallet - inputsFromWallet;
  return net < 0 ? '0' : net.toString();
}

String getOutputAmountFromTx(String originalTx, BitcoinWalletBase wallet) {
  final tx = BtcTransaction.fromRaw(originalTx);
  BigInt amount = BigInt.zero;
  for (final output in tx.outputs) {
    if (wallet.isMine(output.scriptPubKey)) {
      amount += output.amount;
    }
  }
  printV(amount);
  return amount.toString();
}
