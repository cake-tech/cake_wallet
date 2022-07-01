import 'dart:ffi';
import 'package:ffi/ffi.dart';

class SubaddressRow extends Struct {
  @Int64()
  external int id;
  external Pointer<Utf8> address;
  external Pointer<Utf8> label;

  String getLabel() => label.toDartString();
  String getAddress() => address.toDartString();
  int getId() => id;
}
