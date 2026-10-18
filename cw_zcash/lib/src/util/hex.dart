import 'package:flutter/services.dart';

String uint8ListToHex(final Uint8List bytes) {
  return bytes.map((final b) => b.toRadixString(16).padLeft(2, '0')).join();
}
