import 'dart:ffi';
import 'package:ffi/ffi.dart';

class PendingTransactionRaw extends Struct {
  @Int64()
  external int amount;

  @Int64()
  external int fee;

  external Pointer<Utf8> hash;

  String getHash() => hash.toDartString();
}

class PendingTransactionDescription {
  PendingTransactionDescription({
    required this.amount,
    required this.fee,
    required this.hash,
    required this.pointerAddress});

  final int amount;
  final int fee;
  final String hash;
  final int pointerAddress;
}