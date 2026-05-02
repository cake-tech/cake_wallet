import 'dart:typed_data';
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

/// Generates the address string for the [hd] child at [index] encoded as
/// [type].  Mirrors the dispatch logic in BitcoinWalletAddresses.getAddress().
String generateAddressForType({
  required Bip32Slip10Secp256k1 hd,
  required int index,
  required BitcoinAddressType type,
  required BasedUtxoNetwork network,
}) {
  if (type == P2pkhAddressType.p2pkh)
    return generateP2PKHAddress(hd: hd, index: index, network: network);
  if (type == SegwitAddresType.p2tr)
    return generateP2TRAddress(hd: hd, index: index, network: network);
  if (type == SegwitAddresType.p2wsh)
    return generateP2WSHAddress(hd: hd, index: index, network: network);
  if (type == P2shAddressType.p2wpkhInP2sh)
    return generateP2SHAddress(hd: hd, index: index, network: network);
  return generateP2WPKHAddress(hd: hd, index: index, network: network);
}

/// Searches [candidateHDs] across indices 0..[maxIndex) for a child key whose
/// derived address (encoded as [targetType]) matches [targetAddress].
/// Returns the [ECPrivate] on match, or null if not found.
ECPrivate? bruteForcePrivkeyForAddress({
  required String targetAddress,
  required BitcoinAddressType targetType,
  required Iterable<Bip32Slip10Secp256k1> candidateHDs,
  required BasedUtxoNetwork network,
  int maxIndex = 1000,
}) {
  for (final hd in candidateHDs) {
    for (int i = 0; i < maxIndex; i++) {
      if (generateAddressForType(hd: hd, index: i, type: targetType, network: network) ==
          targetAddress) {
        print('Found address at index $i');
        print(hd.toString());
        return generateECPrivate(hd: hd, index: i, network: network);
      }
    }
  }
  return null;
}