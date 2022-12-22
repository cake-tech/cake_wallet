import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:ffi/ffi.dart' as pkgffi;

String convertUTF8ToString({required Pointer<Utf8> pointer}) {
  final str = pointer.toDartString();
  pkgffi.calloc.free(pointer);
  return str;
}
