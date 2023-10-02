import 'dart:ffi';
import 'package:ffi/ffi.dart';

class ZanoBalanceRow extends Struct {
  @Int64()
  external int amount;

  external Pointer<Utf8> assetType;

  int getAmount() => amount;
  String getAssetType() => assetType.toDartString();
}
