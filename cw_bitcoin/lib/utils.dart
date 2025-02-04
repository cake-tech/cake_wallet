import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

ECPrivate generateECPrivate({
  required Bip32Slip10Secp256k1 hd,
  required BasedUtxoNetwork network,
  required int index,
}) =>
    ECPrivate(hd.childKey(Bip32KeyIndex(index)).privateKey);

String generateP2WPKHAddress({
  required Bip32Slip10Secp256k1 hd,
  required BasedUtxoNetwork network,
  required int index,
}) =>
    ECPublic.fromBip32(hd.childKey(Bip32KeyIndex(index)).publicKey)
        .toP2wpkhAddress()
        .toAddress(network);

String generateP2SHAddress({
  required Bip32Slip10Secp256k1 hd,
  required BasedUtxoNetwork network,
  required int index,
}) =>
    ECPublic.fromBip32(hd.childKey(Bip32KeyIndex(index)).publicKey)
        .toP2wpkhInP2sh()
        .toAddress(network);

String generateP2WSHAddress({
  required Bip32Slip10Secp256k1 hd,
  required BasedUtxoNetwork network,
  required int index,
}) =>
    ECPublic.fromBip32(hd.childKey(Bip32KeyIndex(index)).publicKey)
        .toP2wshAddress()
        .toAddress(network);

String generateP2PKHAddress({
  required Bip32Slip10Secp256k1 hd,
  required BasedUtxoNetwork network,
  required int index,
}) =>
    ECPublic.fromBip32(hd.childKey(Bip32KeyIndex(index)).publicKey)
        .toP2pkhAddress()
        .toAddress(network);

String generateP2TRAddress({
  required Bip32Slip10Secp256k1 hd,
  required BasedUtxoNetwork network,
  required int index,
}) =>
    ECPublic.fromBip32(hd.childKey(Bip32KeyIndex(index)).publicKey)
        .toTaprootAddress()
        .toAddress(network);

BitcoinBaseAddress addressFromScript(Script script) {
  final addressType = script.getAddressType();
  if (addressType == null) {
    throw ArgumentError("Invalid script");
  }

  switch (addressType) {
    case P2pkhAddressType.p2pkh:
      return P2pkhAddress.fromScriptPubkey(
          script: script, network: BitcoinNetwork.mainnet);
    case P2shAddressType.p2pkhInP2sh:
      return P2shAddress.fromScriptPubkey(
          script: script, network: BitcoinNetwork.mainnet);
    case SegwitAddresType.p2wpkh:
      return P2wpkhAddress.fromScriptPubkey(
          script: script, network: BitcoinNetwork.mainnet);
    case SegwitAddresType.p2wsh:
      return P2wshAddress.fromScriptPubkey(
          script: script, network: BitcoinNetwork.mainnet);
    case SegwitAddresType.p2tr:
      return P2trAddress.fromScriptPubkey(
          script: script, network: BitcoinNetwork.mainnet);
  }

  throw ArgumentError("Invalid script");
}
