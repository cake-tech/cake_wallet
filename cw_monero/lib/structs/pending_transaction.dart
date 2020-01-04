import 'dart:ffi';
import 'package:ffi/ffi.dart';

class PendingTransactionRaw extends Struct {
  @Int64()
  int amount;

  @Int64()
  int fee;

  Pointer<Utf8> hash;

  String getHash() => Utf8.fromUtf8(hash);
}

class PendingTransactionDescription {
  final int amount;
  final int fee;
  final String hash;
  final int pointerAddress;

  PendingTransactionDescription({this.amount, this.fee, this.hash, this.pointerAddress});
}