import 'package:bitcoin_base/bitcoin_base.dart';

String addressFromOutputScript(Script script, BasedUtxoNetwork network) {
  try {
    switch (script.getAddressType()) {
      case P2pkhAddressType.p2pkh:
        return P2pkhAddress.fromScriptPubkey(script: script).toAddress(network);
      case P2shAddressType.p2pkInP2sh:
        return P2shAddress.fromScriptPubkey(script: script).toAddress(network);
      case SegwitAddresType.p2wpkh:
        return P2wpkhAddress.fromScriptPubkey(script: script).toAddress(network);
      case P2shAddressType.p2pkhInP2sh:
        return P2shAddress.fromScriptPubkey(script: script).toAddress(network);
      case SegwitAddresType.p2wsh:
        return P2wshAddress.fromScriptPubkey(script: script).toAddress(network);
      case SegwitAddresType.p2tr:
        return P2trAddress.fromScriptPubkey(script: script).toAddress(network);
      default:
    }
  } catch (_) {}

  return '';
}
