import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:crypto/crypto.dart';

String scriptHash(String address) {
  final outputScript = bitcoin.Address.addressToOutputScript(address);
  final splitted = sha256.convert(outputScript).toString().split('');
  var res = '';

  for (var i = splitted.length - 1; i >= 0; i--) {
    final char = splitted[i];
    i--;
    final nextChar = splitted[i];
    res += nextChar;
    res += char;
  }

  return res;
}