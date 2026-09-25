import 'package:bitcoin_base/bitcoin_base.dart';

/// A network with output scripts bitcoin_base cannot decode (PIVX exchange
/// addresses) decodes them itself; null falls through to bitcoin_base.
abstract class OutputScriptDecoder {
  BitcoinBaseAddress? decodeOutputScript(Script script);
}

String addressFromOutputScript(Script script, BasedUtxoNetwork network) {
  if (network is OutputScriptDecoder) {
    final address = (network as OutputScriptDecoder).decodeOutputScript(script);
    if (address != null) return address.toAddress(network);
  }
  try {
    return addressFromScript(script, network).toAddress(network);
  } catch (_) {}

  return '';
}

BitcoinBaseAddress addressFromScript(Script script,
    [BasedUtxoNetwork network = BitcoinNetwork.mainnet]) {
  final addressType = script.getAddressType();
  if (addressType == null) {
    throw ArgumentError("Invalid script");
  }

  switch (addressType) {
    case P2pkhAddressType.p2pkh:
      return P2pkhAddress.fromScriptPubkey(script: script, network: BitcoinNetwork.mainnet);
    case P2shAddressType.p2pkhInP2sh:
    case P2shAddressType.p2pkInP2sh:
      return P2shAddress.fromScriptPubkey(script: script, network: BitcoinNetwork.mainnet);
    case SegwitAddresType.p2wpkh:
      return P2wpkhAddress.fromScriptPubkey(script: script, network: BitcoinNetwork.mainnet);
    case SegwitAddresType.p2wsh:
      return P2wshAddress.fromScriptPubkey(script: script, network: BitcoinNetwork.mainnet);
    case SegwitAddresType.p2tr:
      return P2trAddress.fromScriptPubkey(script: script, network: BitcoinNetwork.mainnet);
  }

  throw ArgumentError("Invalid script");
}
