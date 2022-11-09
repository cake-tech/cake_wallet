import 'dart:ffi';
import 'package:ffi/ffi.dart';

String convertUTF8ToString({required Pointer<Utf8> pointer}) {
  final str = pointer.toDartString();
  calloc.free(pointer);
  return str;
}