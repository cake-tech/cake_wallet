import 'dart:ffi';
import 'package:ffi/ffi.dart';

class Utf8Box extends Struct {
  external Pointer<Utf8> value;

  String getValue() => value.toDartString();
}
