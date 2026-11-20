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
    P2trAddress.fromProgram(
      program: taprootOutputKeyHex(
        ECPublic.fromBip32(hd.childKey(Bip32KeyIndex(index)).publicKey).publicKey.point
            as ProjectiveECCPoint,
      ),
    ).toAddress(network);

/// The key-path output key of [ECPublic.toTaprootAddress], computed without its two modular
/// square roots: liftX recomputes a y the point already has, and the address re-parses the
/// x-only result into a public key that is never used.
String taprootOutputKeyHex(ProjectiveECCPoint point) {
  final p = Curves.curveSecp256k1.p;
  final y = point.y;
  final evenY = ProjectiveECCPoint(
    curve: Curves.curveSecp256k1,
    x: point.x,
    y: y.isEven ? y : p - y,
    z: BigInt.one,
  );
  final tweak = BigintUtils.fromBytes(P2TRUtils.calculateTweek(point));
  final outputKey = evenY + Curves.generatorSecp256k1 * tweak;
  return BytesUtils.toHexString(
    BigintUtils.toBytes(outputKey.x, length: Curves.curveSecp256k1.baselen),
  );
}
