import 'dart:ffi';
import 'package:ffi/ffi.dart';

class SubaddressRow extends Struct {
  @Int64()
  int id;
  Pointer<Utf8> address;
  Pointer<Utf8> label;

  String getLabel() => label.toDartString();
  String getAddress() => address.toDartString();
  int getId() => id;
}
