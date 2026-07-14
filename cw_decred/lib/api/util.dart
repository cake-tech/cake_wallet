import 'dart:ffi';
import "package:cw_core/exceptions/cake_exception.dart";
import 'package:ffi/ffi.dart';
import 'dart:convert';

class PayloadResult {
  final String payload;
  final String err;
  final int errCode;

  const PayloadResult(this.payload, this.err, this.errCode);
}

class DecredPayloadExecutionException extends CakeException {
  const DecredPayloadExecutionException(super.message);
}

// Executes the provided fn and converts the string response to a PayloadResult.
// Returns payload, error code, and error.
PayloadResult executePayloadFn({
  required Pointer<Char> fn(),
  required List<Pointer> ptrsToFree,
  bool skipErrorCheck = false,
}) {
  final jsonStr = fn().toDartString();
  freePointers(ptrsToFree);
  if (jsonStr == null) throw DecredPayloadExecutionException("no json return from wallet library");
  final decoded = json.decode(jsonStr);

  final err = decoded["error"] ?? "";
  if (!skipErrorCheck && (err as String? ?? "").isNotEmpty) {
    throw DecredPayloadExecutionException(err as String);
  }

  final payload = decoded["payload"] ?? "";
  final errCode = decoded["errorcode"] ?? -1;
  return new PayloadResult(payload, err, errCode);
}

void freePointers(List<Pointer> ptrsToFree) {
  for (final ptr in ptrsToFree) {
    malloc.free(ptr);
  }
}


extension StringUtil on String {
  Pointer<Char> toCString() => toNativeUtf8().cast<Char>();
}

extension CStringUtil on Pointer<Char> {
  bool get isNull => address == nullptr.address;

  free() {
    malloc.free(this);
  }

  String? toDartString() {
    if (isNull) return null;

    final str = cast<Utf8>().toDartString();
    free();
    return str;
  }
}
