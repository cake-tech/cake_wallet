import 'package:bitcoin_base/bitcoin_base.dart';

String addressFromOutputScript(Script script, BasedUtxoNetwork network) {
  try {
    switch (script.getType()) {
      case ScriptType.P2PK:
        return P2pkAddress.fromScriptPubkey(script: script).toAddress(network);
      case ScriptType.P2PKH:
        return P2pkhAddress.fromScriptPubkey(script: script).toAddress(network);
      case ScriptType.P2SH:
        return P2shAddress.fromScriptPubkey(script: script).toAddress(network);
      case ScriptType.P2WPKH:
        return P2wpkhAddress.fromScriptPubkey(script: script).toAddress(network);
      case ScriptType.P2WSH:
        return P2wshAddress.fromScriptPubkey(script: script).toAddress(network);
      case ScriptType.P2TR:
        return P2trAddress.fromScriptPubkey(script: script).toAddress(network);
      default:
    }
  } catch (_) {}

  return '';
}
