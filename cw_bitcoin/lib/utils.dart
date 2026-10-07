import 'dart:typed_data';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

ECPrivate generateECPrivate({
  required Bip32Slip10Secp256k1 hd,
  required BasedUtxoNetwork network,
  required int index,
}) =>
    ECPrivate(hd.childKey(Bip32KeyIndex(index)).privateKey);

/// Classifies [address] into its [BitcoinBaseAddress] type for [network].
///
/// Dash is P2PKH-only, but the pinned `bitcoin_base` fork's
/// `RegexUtils.addressTypeFromStr` has no `DashNetwork` branch: every Dash regex
/// misses, so it falls through to `P2wpkhAddress.fromAddress`, which throws on
/// `DashNetwork.p2wpkhHrp` ("network does not support P2WPKH/P2WSH"). Route Dash
/// to P2PKH here instead of forking the dependency.
BitcoinBaseAddress addressTypeFromStr(String address, BasedUtxoNetwork network) {
  if (network is DashNetwork) {
    return P2pkhAddress.fromAddress(address: address, network: network);
  }

  return RegexUtils.addressTypeFromStr(address, network);
}

/// Electrum script hash of [address]: sha256 of its output script, byte-reversed, hex.
///
/// Dash cannot use `BitcoinAddressUtils.scriptHash` because that resolves the address
/// type through the dependency's `addressTypeFromStr` and fails the same way.
String scriptHashOfAddress(String address, BasedUtxoNetwork network) {
  if (network is DashNetwork) {
    final script = P2pkhAddress.fromAddress(address: address, network: network)
        .toScriptPubKey()
        .toBytes();
    return BytesUtils.toHexString(QuickCrypto.sha256Hash(script).reversed.toList());
  }

  return BitcoinAddressUtils.scriptHash(address, network: network);
}

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
