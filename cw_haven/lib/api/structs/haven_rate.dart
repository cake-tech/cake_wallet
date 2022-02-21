import 'dart:ffi';
import 'package:ffi/ffi.dart';

class HavenRate extends Struct {
  @Int64()
  int rate;
  Pointer<Utf8> assetType;

  int getRate() => rate;
  String getAssetType() => Utf8.fromUtf8(assetType);
}
