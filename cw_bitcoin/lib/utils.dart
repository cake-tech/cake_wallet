import 'dart:typed_data';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:flutter/foundation.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:bitcoin_flutter/src/payments/index.dart' show PaymentData;
import 'package:hex/hex.dart';
import 'package:bs58check/bs58check.dart' as bs58check;
import 'package:convert/convert.dart';

bitcoin.PaymentData generatePaymentData({
  required bitcoin.HDWallet hd,
  required int index,
}) {
  final pubKey = hd.derive(index).pubKey!;
  return PaymentData(pubkey: Uint8List.fromList(HEX.decode(pubKey)));
}

ECPrivate generateECPrivate({
  required bitcoin.HDWallet hd,
  required BasedUtxoNetwork network,
  required int index,
}) {
  final wif = hd.derive(index).wif!;
  return ECPrivate.fromWif(wif, netVersion: network.wifNetVer);
}

String generateP2WPKHAddress({
  required bitcoin.HDWallet hd,
  required BasedUtxoNetwork network,
  required int index,
}) {
  final pubKey = hd.derive(index).pubKey!;
  return ECPublic.fromHex(pubKey).toP2wpkhAddress().toAddress(network);
}

String generateP2SHAddress({
  required bitcoin.HDWallet hd,
  required BasedUtxoNetwork network,
  required int index,
}) {
  final pubKey = hd.derive(index).pubKey!;
  return ECPublic.fromHex(pubKey).toP2wpkhInP2sh().toAddress(network);
}

String generateP2WSHAddress({
  required bitcoin.HDWallet hd,
  required BasedUtxoNetwork network,
  required int index,
}) {
  final pubKey = hd.derive(index).pubKey!;
  return ECPublic.fromHex(pubKey).toP2wshAddress().toAddress(network);
}

String generateP2PKHAddress({
  required bitcoin.HDWallet hd,
  required BasedUtxoNetwork network,
  required int index,
}) {
  final pubKey = hd.derive(index).pubKey!;
  return ECPublic.fromHex(pubKey).toP2pkhAddress().toAddress(network);
}

String generateP2TRAddress({
  required bitcoin.HDWallet hd,
  required BasedUtxoNetwork network,
  required int index,
}) {
  final pubKey = hd.derive(index).pubKey!;
  return ECPublic.fromHex(pubKey).toTaprootAddress().toAddress(network);
}

enum PrivateKeyType { xprv, zprv, yprv, Yprv, tprv, uprv, Uprv, vprv, Vprv }

enum PublicKeyType { xpub, zpub, ypub, Ypub, tpub, upub, Upub, vpub, Vpub }

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

  static String? changePrivateKeyVersionBytes(
      {required String key, required PrivateKeyType targetType}) {
    if (!prvKeyPrefixes.containsKey(targetType)) throw Exception('Invalid target version');
    return _changeVersionBytes(key: key, prefixes: prvKeyPrefixes, targetType: targetType);
  }

  static String? changePublicKeyVersionBytes(
      {required String key, required PublicKeyType targetType}) {
    if (!pubKeyPrefixes.containsKey(targetType)) throw Exception('Invalid target version');
    return _changeVersionBytes(key: key, prefixes: pubKeyPrefixes, targetType: targetType);
  }

  static String? _changeVersionBytes<T>(
      {required String key, required Map<T, String> prefixes, required T targetType}) {
    try {
      Uint8List data = bs58check.decode(key);
      data = data.sublist(4);
      Uint8List newData = Uint8List.fromList(hex.decode(prefixes[targetType]!) + data);
      return bs58check.encode(newData);
    } catch (e) {
      throw Exception(
          'Invalid extended key! Please double check that you didn\'t accidentally paste extra data.');
    }
  }
}
