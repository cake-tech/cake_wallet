import 'dart:ffi';
import 'package:ffi/ffi.dart';

class CoinsInfoRow extends Struct {
  @Int64()
  external int blockHeight;

  external Pointer<Utf8> hash;

  @Uint64()
  external int internalOutputIndex;

  @Uint64()
  external int globalOutputIndex;

  @Int8()
  external int spent;

  @Int8()
  external int frozen;

  @Uint64()
  external int spentHeight;

  @Uint64()
  external int amount;

  @Int8()
  external int rct;

  @Int8()
  external int keyImageKnown;

  @Uint64()
  external int pkIndex;

  @Uint32()
  external int subaddrIndex;

  @Uint32()
  external int subaddrAccount;

  external Pointer<Utf8> address;

  external Pointer<Utf8> addressLabel;

  external Pointer<Utf8> keyImage;

  @Uint64()
  external int unlockTime;

  @Int8()
  external int unlocked;

  external Pointer<Utf8> pubKey;

  @Int8()
  external int coinbase;

  external Pointer<Utf8> description;

  String getHash() => hash.toDartString();

  String getAddress() => address.toDartString();

  String getAddressLabel() => addressLabel.toDartString();

  String getKeyImage() => keyImage.toDartString();

  String getPubKey() => pubKey.toDartString();

  String getDescription() => description.toDartString();
}
