import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:crypto/crypto.dart';

String scriptHash(String address, {required BasedUtxoNetwork network}) {
  final outputScript = addressToOutputScript(address: address, network: network);
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
