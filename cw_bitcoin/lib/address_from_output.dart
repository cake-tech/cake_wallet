import 'dart:typed_data';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:bitcoin_flutter/src/payments/index.dart' show PaymentData;

String addressFromOutput(Uint8List script, bitcoin.NetworkType networkType) {
  try {
    return bitcoin.P2PKH(
        data: PaymentData(output: script),
        network: networkType)
      .data
      .address!;
  } catch (_) {}

  try {
    return bitcoin.P2WPKH(
        data: PaymentData(output: script),
        network: networkType)
      .data
      .address!;
  } catch(_) {}

  return '';
}