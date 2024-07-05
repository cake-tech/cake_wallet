import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';

const utils = const MethodChannel('com.cake_wallet/native_utils');

Future<Uint8List> secRandom(int count) async {
  try {
    if (Platform.isWindows || Platform.isLinux) {
      // Used method to get securely generated random bytes from cake backups
      const byteSize = 256;
      final rng = Random.secure();
      return Uint8List.fromList(List<int>.generate(count, (_) => rng.nextInt(byteSize)));
    }
    return await utils.invokeMethod<Uint8List>('sec_random', {'count': count}) ?? Uint8List.fromList([]);
  } on PlatformException catch (_) {
    return Uint8List.fromList([]);
  }
}
