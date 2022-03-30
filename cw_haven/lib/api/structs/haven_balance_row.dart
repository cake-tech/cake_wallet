import 'dart:ffi';
import 'package:ffi/ffi.dart';

class HavenBalanceRow extends Struct {
  @Int64()
  int amount;
  Pointer<Utf8> assetType;

  int getAmount() => amount;
  String getAssetType() => Utf8.fromUtf8(assetType);
}
