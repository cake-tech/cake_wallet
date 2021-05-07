import 'dart:typed_data';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:bs58check/bs58check.dart' as bs58check;
import 'package:bitcoin_flutter/src/utils/constants/op.dart';
import 'package:bitcoin_flutter/src/utils/script.dart' as bscript;
import 'package:bitcoin_flutter/src/address.dart';

Uint8List p2shAddressToOutputScript(String address) {
  final decodeBase58 = bs58check.decode(address);
  final hash = decodeBase58.sublist(1);
  return bscript.compile(<dynamic>[OPS['OP_HASH160'], hash, OPS['OP_EQUAL']]);
}

Uint8List addressToOutputScript(
    String address, bitcoin.NetworkType networkType) {
  try {
    // FIXME: improve validation for p2sh addresses
    // 3 for bitcoin
    // m for litecoin
    if (address.startsWith('3') || address.toLowerCase().startsWith('m')) {
      return p2shAddressToOutputScript(address);
    }

    return Address.addressToOutputScript(address, networkType);
  } catch (err) {
    print(err);
    return Uint8List(0);
  }
}
