/// bindings for `libldk_ffi`

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart' as ffi;

// ignore_for_file: unused_import, camel_case_types, non_constant_identifier_names
final DynamicLibrary _dl = _open();
/// Reference to the Dynamic Library, it should be only used for low-level access
final DynamicLibrary dl = _dl;
DynamicLibrary _open() {
  if (Platform.isAndroid) return DynamicLibrary.open('libldk_ffi.so');
  if (Platform.isIOS) return DynamicLibrary.executable();
  throw UnsupportedError('This platform is not supported.');
}

/// C function `error_message_utf8`.
int error_message_utf8(
  Pointer<ffi.Utf8> buf,
  int length,
) {
  return _error_message_utf8(buf, length);
}
final _error_message_utf8_Dart _error_message_utf8 = _dl.lookupFunction<_error_message_utf8_C, _error_message_utf8_Dart>('error_message_utf8');
typedef _error_message_utf8_C = Int32 Function(
  Pointer<ffi.Utf8> buf,
  Int32 length,
);
typedef _error_message_utf8_Dart = int Function(
  Pointer<ffi.Utf8> buf,
  int length,
);

/// C function `ffi_channels`.
void ffi_channels(
  Pointer<NativeFunction<Void Function(Pointer<ffi.Utf8>)>> func,
) {
  _ffi_channels(func);
}
final _ffi_channels_Dart _ffi_channels = _dl.lookupFunction<_ffi_channels_C, _ffi_channels_Dart>('ffi_channels');
typedef _ffi_channels_C = Void Function(
  Pointer<NativeFunction<Void Function(Pointer<ffi.Utf8>)>> func,
);
typedef _ffi_channels_Dart = void Function(
  Pointer<NativeFunction<Void Function(Pointer<ffi.Utf8>)>> func,
);

/// C function `last_error_length`.
int last_error_length() {
  return _last_error_length();
}
final _last_error_length_Dart _last_error_length = _dl.lookupFunction<_last_error_length_C, _last_error_length_Dart>('last_error_length');
typedef _last_error_length_C = Int32 Function();
typedef _last_error_length_Dart = int Function();

/// C function `ldk_channels`.
void ldk_channels(
  Pointer<NativeFunction<Void Function(Pointer<ffi.Utf8>)>> func,
) {
  _ldk_channels(func);
}
final _ldk_channels_Dart _ldk_channels = _dl.lookupFunction<_ldk_channels_C, _ldk_channels_Dart>('ldk_channels');
typedef _ldk_channels_C = Void Function(
  Pointer<NativeFunction<Void Function(Pointer<ffi.Utf8>)>> func,
);
typedef _ldk_channels_Dart = void Function(
  Pointer<NativeFunction<Void Function(Pointer<ffi.Utf8>)>> func,
);

/// Binding to `allo-isolate` crate
void store_dart_post_cobject(
  Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>> ptr,
) {
  _store_dart_post_cobject(ptr);
}
final _store_dart_post_cobject_Dart _store_dart_post_cobject = _dl.lookupFunction<_store_dart_post_cobject_C, _store_dart_post_cobject_Dart>('store_dart_post_cobject');
typedef _store_dart_post_cobject_C = Void Function(
  Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>> ptr,
);
typedef _store_dart_post_cobject_Dart = void Function(
  Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>> ptr,
);

/// C function `test_ldk_async`.
int test_ldk_async(
  int isolate_port,
  Pointer<ffi.Utf8> rpc_info,
  Pointer<ffi.Utf8> ldk_storage_path,
) {
  return _test_ldk_async(isolate_port, rpc_info, ldk_storage_path);
}
final _test_ldk_async_Dart _test_ldk_async = _dl.lookupFunction<_test_ldk_async_C, _test_ldk_async_Dart>('test_ldk_async');
typedef _test_ldk_async_C = Int32 Function(
  Int64 isolate_port,
  Pointer<ffi.Utf8> rpc_info,
  Pointer<ffi.Utf8> ldk_storage_path,
);
typedef _test_ldk_async_Dart = int Function(
  int isolate_port,
  Pointer<ffi.Utf8> rpc_info,
  Pointer<ffi.Utf8> ldk_storage_path,
);

/// C function `test_ldk_block`.
Pointer<ffi.Utf8> test_ldk_block(
  Pointer<ffi.Utf8> path,
  Pointer<NativeFunction<Void Function(Pointer<ffi.Utf8>)>> func,
) {
  return _test_ldk_block(path, func);
}
final _test_ldk_block_Dart _test_ldk_block = _dl.lookupFunction<_test_ldk_block_C, _test_ldk_block_Dart>('test_ldk_block');
typedef _test_ldk_block_C = Pointer<ffi.Utf8> Function(
  Pointer<ffi.Utf8> path,
  Pointer<NativeFunction<Void Function(Pointer<ffi.Utf8>)>> func,
);
typedef _test_ldk_block_Dart = Pointer<ffi.Utf8> Function(
  Pointer<ffi.Utf8> path,
  Pointer<NativeFunction<Void Function(Pointer<ffi.Utf8>)>> func,
);
