import 'dart:ffi';
import 'package:ffi/ffi.dart';

class AccountRow extends Struct {
  @Int64()
  int id;
  Pointer<Utf8> label;

  String getLabel() => label.toDartString();
  int getId() => id;
}
