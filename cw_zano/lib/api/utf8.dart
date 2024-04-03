import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

extension Utf8Pointer on Pointer<Utf8> {
  String toDartStringAllowingMalformed({int? length}) {
    //_ensureNotNullptr('toDartString');
    final codeUnits = cast<Uint8>();
    if (length != null) {
      RangeError.checkNotNegative(length, 'length');
    } else {
      length = _length(codeUnits);
    }
    return utf8.decode(codeUnits.asTypedList(length), allowMalformed: true);
  }

  static int _length(Pointer<Uint8> codeUnits) {
    var length = 0;
    while (codeUnits[length] != 0) {
      length++;
    }
    return length;
  }
}