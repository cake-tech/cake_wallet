import 'dart:ffi';
import 'package:ffi/ffi.dart';

class SubaddressRow extends Struct {
  @Int64()
  int id;
  Pointer<Utf8> address;
  Pointer<Utf8> label;

  String getLabel() => Utf8.fromUtf8(label);
  String getAddress() => Utf8.fromUtf8(address);
  int getId() => id;
}