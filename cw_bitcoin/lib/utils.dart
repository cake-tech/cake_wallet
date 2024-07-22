import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

ECPrivate generateECPrivate(Bip32Slip10Secp256k1 hd, int index) =>
    ECPrivate(hd.childKey(Bip32KeyIndex(index)).privateKey);

ECPublic generateECPublic(Bip32Slip10Secp256k1 hd, int index) =>
    ECPublic.fromBip32(hd.childKey(Bip32KeyIndex(index)).publicKey);

String generateP2WPKHAddress({
  required Bip32Slip10Secp256k1 hd,
  required int index,
  required BasedUtxoNetwork network,
}) =>
    generateECPublic(hd, index).toP2wpkhAddress().toAddress(network);

String generateP2SHAddress({
  required Bip32Slip10Secp256k1 hd,
  required int index,
  required BasedUtxoNetwork network,
}) =>
    generateECPublic(hd, index).toP2wpkhInP2sh().toAddress(network);

String generateP2WSHAddress({
  required Bip32Slip10Secp256k1 hd,
  required int index,
  required BasedUtxoNetwork network,
}) =>
    generateECPublic(hd, index).toP2wshAddress().toAddress(network);

String generateP2PKHAddress({
  required Bip32Slip10Secp256k1 hd,
  required int index,
  required BasedUtxoNetwork network,
}) =>
    generateECPublic(hd, index).toP2pkhAddress().toAddress(network);

String generateP2TRAddress({
  required Bip32Slip10Secp256k1 hd,
  required int index,
  required BasedUtxoNetwork network,
}) =>
    generateECPublic(hd, index).toTaprootAddress().toAddress(network);
