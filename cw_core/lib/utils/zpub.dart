
import 'dart:typed_data';

import 'package:blockchain_utils/blockchain_utils.dart';

String convertZpubToXpub(String zpub) {
  try {
    final decoded = Base58Decoder.checkDecode(zpub);
    
    if (decoded.length < 4) {
      throw ArgumentError('Invalid extended public key length');
    }
    
    final versionBytes = decoded.sublist(0, 4);
    final zpubVersionBytes = [0x04, 0xb2, 0x47, 0x46]; // zpub mainnet version
    final zpubTestnetVersionBytes = [0x04, 0x5f, 0x1c, 0xf6]; // vpub testnet version
    
    bool isZpub = listEquals(versionBytes, zpubVersionBytes);
    bool isVpub = listEquals(versionBytes, zpubTestnetVersionBytes);
    
    if (!isZpub && !isVpub) {
      return zpub;
    }
    
    final xpubVersionBytes = isZpub ? 
      [0x04, 0x88, 0xb2, 0x1e] : // xpub mainnet
      [0x04, 0x35, 0x87, 0xcf]; // tpub testnet
    
    final newExtendedKey = Uint8List.fromList([
      ...xpubVersionBytes,
      ...decoded.sublist(4),
    ]);
    
    return Base58Encoder.checkEncode(newExtendedKey);
  } catch (e) {
    throw ArgumentError('Failed to convert zpub to xpub: $e');
  }
}

bool listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
