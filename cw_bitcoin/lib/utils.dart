import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:flutter/foundation.dart';
import 'package:hex/hex.dart';
import 'package:bs58check/bs58check.dart' as bs58check;
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

/// Enum representing different types of private keys.
enum PrivateKeyType {
  /// BIP32 extended private key (mainnet)
  xprv,

  /// BIP84 extended private key for native SegWit (P2WPKH) (mainnet)
  zprv,

  /// BIP49 extended private key for wrapped SegWit (P2SH-P2WPKH) (mainnet)
  yprv,

  /// BIP49 extended private key (upper Y variant)
  Yprv,

  /// BIP32 extended private key (testnet)
  tprv,

  /// BIP32 extended private key (alternative mainnet prefix)
  uprv,

  /// BIP32 extended private key (alternative mainnet prefix, upper U variant)
  Uprv,

  /// BIP84 extended private key (native SegWit, upper V variant)
  vprv,

  /// BIP84 extended private key (native SegWit, upper V variant, uppercase)
  Vprv
}

/// Enum representing different types of public keys.
enum PublicKeyType {
  /// BIP32 extended public key (mainnet)
  xpub,

  /// BIP84 extended public key for native SegWit (P2WPKH) (mainnet)
  zpub,

  /// BIP49 extended public key for wrapped SegWit (P2SH-P2WPKH) (mainnet)
  ypub,

  /// BIP49 extended public key (upper Y variant)
  Ypub,

  /// BIP32 extended public key (testnet)
  tpub,

  /// BIP32 extended public key (alternative mainnet prefix)
  upub,

  /// BIP32 extended public key (alternative mainnet prefix, upper U variant)
  Upub,

  /// BIP84 extended public key (native SegWit, upper V variant)
  vpub,

  /// BIP84 extended public key (native SegWit, upper V variant, uppercase)
  Vpub
}


class KeysVersionBytesConverter {
  static const prvKeyPrefixes = {
    PrivateKeyType.xprv: '0488ade4',
    PrivateKeyType.yprv: '049d7878',
    PrivateKeyType.Yprv: '0295b005',
    PrivateKeyType.zprv: '04b2430c',
    PrivateKeyType.tprv: '04358394',
    PrivateKeyType.uprv: '044a4e28',
    PrivateKeyType.Uprv: '024285b5',
    PrivateKeyType.vprv: '045f18bc',
    PrivateKeyType.Vprv: '02575048',
  };

  static const pubKeyPrefixes = {
    PublicKeyType.xpub: '0488b21e',
    PublicKeyType.ypub: '049d7cb2',
    PublicKeyType.Ypub: '0295b43f',
    PublicKeyType.zpub: '04b24746',
    PublicKeyType.tpub: '043587cf',
    PublicKeyType.upub: '044a5262',
    PublicKeyType.Upub: '024289ef',
    PublicKeyType.vpub: '045f1cf6',
    PublicKeyType.Vpub: '02575483',
  };

  /// Converts an extended private key to the specified target type by changing its version bytes.
  static String? changePrivateKeyVersionBytes(
      {required String key, required PrivateKeyType targetType}) {
    if (!prvKeyPrefixes.containsKey(targetType)) throw Exception('Invalid target version');
    return _changeVersionBytes(key: key, prefixes: prvKeyPrefixes, targetType: targetType);
  }

  /// Converts an extended public key to the specified target type by changing its version bytes.
  static String? changePublicKeyVersionBytes(
      {required String key, required PublicKeyType targetType}) {
    if (!pubKeyPrefixes.containsKey(targetType)) throw Exception('Invalid target version');
    return _changeVersionBytes(key: key, prefixes: pubKeyPrefixes, targetType: targetType);
  }

  /// Internal method for changing version bytes of an extended key.
  static String? _changeVersionBytes<T>(
      {required String key, required Map<T, String> prefixes, required T targetType}) {
    try {
      Uint8List data = bs58check.decode(key);
      data = data.sublist(4);
      Uint8List newData = Uint8List.fromList(HEX.decode(prefixes[targetType]!) + data);
      return bs58check.encode(newData);
    } catch (e) {
      throw Exception(
          'Invalid extended key! Please double check that you didn\'t accidentally paste extra data.');
    }
  }
}
