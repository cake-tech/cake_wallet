import 'package:crypto/crypto.dart';
import 'package:cw_bitcoin/address_to_output_script.dart';
import 'package:bitcoin_base/bitcoin_base.dart' as bitcoin;

String scriptHash(String address, {required bitcoin.BasedUtxoNetwork network}) {
  final outputScript = addressToOutputScript(address, network);
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
