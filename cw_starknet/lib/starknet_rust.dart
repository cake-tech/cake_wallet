import 'dart:async';
import 'dart:io';

import 'package:cw_starknet/src/rust/api/starknet.dart' as rust_api;
import 'package:cw_starknet/src/rust/frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

Completer<void>? _rustInitCompleter;

Future<void> ensureStarknetRustInitialized() {
  final existing = _rustInitCompleter;
  if (existing != null) {
    return existing.future;
  }

  final completer = Completer<void>();
  _rustInitCompleter = completer;

  () async {
    try {
      await _initializeRust();
      completer.complete();
    } catch (error, stackTrace) {
      _rustInitCompleter = null;
      completer.completeError(error, stackTrace);
    }
  }();

  return completer.future;
}

Future<void> _initializeRust() async {
  try {
    await RustLib.init();
    return;
  } catch (error) {
    final fallbackLibraryPath = _findLocalRustLibraryPath();
    if (fallbackLibraryPath == null) {
      rethrow;
    }

    await RustLib.init(
      externalLibrary: ExternalLibrary.open(fallbackLibraryPath),
    );
  }
}

String? _findLocalRustLibraryPath() {
  final candidates = switch (Platform.operatingSystem) {
    'macos' => [
        'rust/target/debug/libcw_starknet_rust.dylib',
        'rust/target/release/libcw_starknet_rust.dylib',
        'cw_starknet/rust/target/debug/libcw_starknet_rust.dylib',
        'cw_starknet/rust/target/release/libcw_starknet_rust.dylib',
      ],
    'linux' => [
        'rust/target/debug/libcw_starknet_rust.so',
        'rust/target/release/libcw_starknet_rust.so',
        'cw_starknet/rust/target/debug/libcw_starknet_rust.so',
        'cw_starknet/rust/target/release/libcw_starknet_rust.so',
      ],
    'windows' => [
        'rust\\target\\debug\\cw_starknet_rust.dll',
        'rust\\target\\release\\cw_starknet_rust.dll',
        'cw_starknet\\rust\\target\\debug\\cw_starknet_rust.dll',
        'cw_starknet\\rust\\target\\release\\cw_starknet_rust.dll',
      ],
    _ => const <String>[],
  };

  for (final candidate in candidates) {
    final file = File(candidate);
    if (file.existsSync()) {
      return file.absolute.path;
    }
  }

  return null;
}

T _unwrapValue<T>(T? value, String? error, String label) {
  if (error != null && error.isNotEmpty) {
    throw Exception(error);
  }

  if (value == null) {
    throw Exception('Missing $label from Starknet Rust response');
  }

  return value;
}

rust_api.DerivedAccountData unwrapDerivedAccountDataResponse(
        rust_api.DerivedAccountDataResponse response) =>
    _unwrapValue(response.value, response.error, 'derived account data');

rust_api.StarknetSignatureData unwrapSignatureResponse(
        rust_api.StarknetSignatureDataResponse response) =>
    _unwrapValue(response.value, response.error, 'signature');

String unwrapStringResponse(rust_api.StringResponse response) =>
    _unwrapValue(response.value, response.error, 'string value');

bool unwrapBoolResponse(rust_api.BoolResponse response) =>
    _unwrapValue(response.value, response.error, 'boolean value');

int unwrapI64Response(rust_api.I64Response response) =>
    _unwrapValue(response.value, response.error, 'integer value').toInt();

List<rust_api.TransferHistoryItem> unwrapTransferHistoryResponse(
    rust_api.TransferHistoryResponse response) {
  if (response.error != null && response.error!.isNotEmpty) {
    throw Exception(response.error);
  }

  return response.items;
}

rust_api.StarknetTokenMetadata unwrapTokenMetadataResponse(
        rust_api.TokenMetadataResponse response) =>
    _unwrapValue(response.value, response.error, 'token metadata');

rust_api.StarknetFeeQuote unwrapFeeQuoteResponse(rust_api.FeeQuoteResponse response) =>
    _unwrapValue(response.value, response.error, 'fee quote');

rust_api.StarknetExecutionPlanData unwrapExecutionPlanResponse(
        rust_api.ExecutionPlanResponse response) =>
    _unwrapValue(response.value, response.error, 'execution plan');

rust_api.StarknetTransactionDetails unwrapTransactionDetailsResponse(
        rust_api.TransactionDetailsResponse response) =>
    _unwrapValue(response.value, response.error, 'transaction details');

List<String> unwrapStringListResponse(rust_api.StringListResponse response) {
  if (response.error != null && response.error!.isNotEmpty) {
    throw Exception(response.error);
  }

  return response.items;
}
