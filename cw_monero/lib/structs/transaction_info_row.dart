import 'dart:ffi';
import 'package:ffi/ffi.dart';

class TransactionInfoRow extends Struct {
  @Uint64()
  int amount;

  @Uint64()
  int fee;

  @Uint64()
  int blockHeight;

  @Uint64()
  int confirmations;

  @Uint32()
  int subaddrAccount;

  @Int8()
  int direction;

  @Int8()
  int isPending;

  Pointer<Utf8> hash;

  Pointer<Utf8> paymentId;

  @Int64()
  int datetime;

  int getDatetime() => datetime;
  int getAmount() => amount >= 0 ? amount : amount * -1;
  bool getIsPending() => isPending != 0;
  String getHash() => Utf8.fromUtf8(hash);
  String getPaymentId() => Utf8.fromUtf8(paymentId);
}
