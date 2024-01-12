import 'dart:typed_data';
import 'package:bitcoin_base/bitcoin_base.dart';

String addressFromOutput(Uint8List script, BasedUtxoNetwork network) {
  try {
    return P2pkhAddress.fromScriptPubkey(script: Script.fromRaw(byteData: script))
        .toAddress(network);
  } catch (_) {}

  try {
    return P2wpkhAddress.fromScriptPubkey(script: Script.fromRaw(byteData: script))
        .toAddress(network);
  } catch (_) {}

  try {
    return P2wshAddress.fromScriptPubkey(script: Script.fromRaw(byteData: script))
        .toAddress(network);
  } catch (_) {}

  try {
    return P2trAddress.fromScriptPubkey(script: Script.fromRaw(byteData: script))
        .toAddress(network);
  } catch (_) {}

  return '';
}
