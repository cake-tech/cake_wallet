import 'dart:ffi';
import 'package:ffi/ffi.dart';

class AccountRow extends Struct {
  @Int64()
  int id;
  Pointer<Utf8> label;

  String getLabel() => Utf8.fromUtf8(label);
  int getId() => id;
}
