import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:crypto/crypto.dart';

String scriptHash(String address, {required bitcoin.NetworkType networkType}) {
  final outputScript =
      bitcoin.Address.addressToOutputScript(address, networkType);
  final parts = sha256.convert(outputScript).toString().split('');
  var res = '';

  for (var i = parts.length - 1; i >= 0; i--) {
    final char = parts[i];
    i--;
    final nextChar = parts[i];
    res += nextChar;
    res += char;
  }

  return res;
}
