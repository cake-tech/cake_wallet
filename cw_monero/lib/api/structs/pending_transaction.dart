import 'dart:ffi';
import 'package:ffi/ffi.dart';

class PendingTransactionRaw extends Struct {
  @Int64()
  external int amount;

  @Int64()
  external int fee;

  external Pointer<Utf8> hash;

  external Pointer<Utf8> hex;

  external Pointer<Utf8> txKey;

  String getHash() => hash.toDartString();

  String getHex() => hex.toDartString();

  String getKey() => txKey.toDartString();
}

class PendingTransactionDescription {
  PendingTransactionDescription({
    required this.amount,
    required this.fee,
    required this.hash,
    required this.hex,
    required this.txKey,
    required this.pointerAddress});

  final int amount;
  final int fee;
  final String hash;
  final String hex;
  final String txKey;
  final int pointerAddress;
}