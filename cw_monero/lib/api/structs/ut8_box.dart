import 'dart:ffi';
import 'package:ffi/ffi.dart';

class Utf8Box extends Struct {
  Pointer<Utf8> value;

  String getValue() => Utf8.fromUtf8(value);
}
