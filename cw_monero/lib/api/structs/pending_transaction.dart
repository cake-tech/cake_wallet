import 'dart:ffi';
import 'package:ffi/ffi.dart';

class PendingTransactionRaw extends Struct {
  @Int64()
  int amount;

  @Int64()
  int fee;

  Pointer<Utf8> hash;

  Pointer<Utf8> hex;

  Pointer<Utf8> txKey;

  String getHash() => Utf8.fromUtf8(hash);

  String getHex() => Utf8.fromUtf8(hex);

  String getKey() => Utf8.fromUtf8(txKey);
}

class PendingTransactionDescription {
  PendingTransactionDescription({
    this.amount,
    this.fee,
    this.hash,
    this.hex,
    this.txKey,
    this.pointerAddress});

  final int amount;
  final int fee;
  final String hash;
  final String hex;
  final String txKey;
  final int pointerAddress;
}