import 'dart:convert';
import 'dart:ffi';

import 'package:cw_pivx/src/sapling/sapling_ffi.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PIVX Sapling FFI memory hygiene', () {
    test('zeros native Uint8 buffers before free', () {
      final pointer = malloc<Uint8>(4);
      try {
        final bytes = pointer.asTypedList(4);
        bytes.setAll(0, [1, 2, 3, 4]);

        zeroNativeUint8Buffer(pointer, bytes.length);

        expect(bytes, everyElement(0));
      } finally {
        malloc.free(pointer);
      }
    });

    test('zeros native UTF-8 strings before free', () {
      const value = 'memo piñata';
      final pointer = value.toNativeUtf8();
      try {
        final bytes =
            pointer.cast<Uint8>().asTypedList(utf8.encode(value).length + 1);
        expect(bytes.any((byte) => byte != 0), isTrue);

        zeroNativeUtf8String(pointer, value);

        expect(bytes, everyElement(0));
      } finally {
        malloc.free(pointer);
      }
    });
  });
}
