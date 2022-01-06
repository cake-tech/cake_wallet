import 'dart:ffi';
import 'package:ffi/ffi.dart';

String convertUTF8ToString({Pointer<Utf8> pointer}) {
  final str = Utf8.fromUtf8(pointer);
  free(pointer);
  return str;
}