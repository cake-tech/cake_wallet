import 'dart:ffi';
import 'package:ffi/ffi.dart';

void handleErrorAndPointers({
  required Pointer<Char> fn(),
  required List<Pointer> ptrsToFree,
}) {
  final err = fn();
  freePointers(ptrsToFree);
  checkError(err);
}

void freePointers(List<Pointer> ptrsToFree) {
  for (final ptr in ptrsToFree) {
    malloc.free(ptr);
  }
}

void checkError(Pointer<Char> error) {
  if (error.isNull) return;
  throw Exception(error.toDartString());
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
