import 'dart:convert';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/bitcoin_wallet.dart';
import 'package:cw_bitcoin/psbt/v0_deserialize.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:ledger_bitcoin/psbt.dart';

String getTxIdFromPsbtV0(String psbt) {
  final psbtV2 = PsbtV2()..deserializeV0(base64.decode(psbt));

  return BtcTransaction.fromRaw(
          BytesUtils.toHexString(psbtV2.extractUnsignedTX(false)))
      .txId();
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
