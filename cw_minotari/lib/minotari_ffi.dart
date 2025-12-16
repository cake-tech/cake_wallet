import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:cw_minotari/minotari_ffi_bindings.dart';

/// Main FFI interface for interacting with the Minotari Rust library
class MinotariFfi {
  late MinotariWalletFfiBindings _bindings;
  Pointer<WalletHandle>? _walletHandle;
  final String dataPath;

  MinotariFfi({required this.dataPath}) {
    _bindings = MinotariWalletFfiBindings(_loadLibrary());
    _bindings.minotari_init_logging();
  }

  /// Load the native library
  DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libminotari_wallet_ffi.so');
    } else if (Platform.isIOS) {
      return DynamicLibrary.process();
    } else if (Platform.isMacOS) {
      return DynamicLibrary.open('libminotari_wallet_ffi.dylib');
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('libminotari_wallet_ffi.so');
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('minotari_wallet_ffi.dll');
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Create a new wallet from mnemonic
  Future<void> createFromMnemonic(String mnemonic, {String passphrase = ''}) async {
    final mnemonicPtr = mnemonic.toNativeUtf8();
    final dataPathPtr = dataPath.toNativeUtf8();
    final passphrasePtr = passphrase.isEmpty ? nullptr : passphrase.toNativeUtf8();
    final errorPtr = calloc<Pointer<Char>>();

    try {
      _walletHandle = _bindings.minotari_wallet_create_from_mnemonic(
        mnemonicPtr.cast(),
        dataPathPtr.cast(),
        passphrasePtr.cast(),
        errorPtr,
      );

      if (_walletHandle == nullptr) {
        final errorMsg = errorPtr.value.cast<Utf8>().toDartString();
        _bindings.minotari_string_free(errorPtr.value);
        throw Exception('Failed to create wallet: $errorMsg');
      }
    } finally {
      calloc.free(mnemonicPtr);
      calloc.free(dataPathPtr);
      if (passphrasePtr != nullptr) {
        calloc.free(passphrasePtr);
      }
      calloc.free(errorPtr);
    }
  }

  /// Restore wallet from mnemonic
  Future<void> restore(String mnemonic, {String passphrase = ''}) async {
    final mnemonicPtr = mnemonic.toNativeUtf8();
    final dataPathPtr = dataPath.toNativeUtf8();
    final passphrasePtr = passphrase.isEmpty ? nullptr : passphrase.toNativeUtf8();
    final errorPtr = calloc<Pointer<Char>>();

    try {
      _walletHandle = _bindings.minotari_wallet_restore(
        mnemonicPtr.cast(),
        dataPathPtr.cast(),
        passphrasePtr.cast(),
        errorPtr,
      );

      if (_walletHandle == nullptr) {
        final errorMsg = errorPtr.value.cast<Utf8>().toDartString();
        _bindings.minotari_string_free(errorPtr.value);
        throw Exception('Failed to restore wallet: $errorMsg');
      }
    } finally {
      calloc.free(mnemonicPtr);
      calloc.free(dataPathPtr);
      if (passphrasePtr != nullptr) {
        calloc.free(passphrasePtr);
      }
      calloc.free(errorPtr);
    }
  }

  /// Get wallet address
  Future<String> getAddress() async {
    if (_walletHandle == null) {
      throw Exception('Wallet not initialized');
    }

    final errorPtr = calloc<Pointer<Char>>();

    try {
      final addressPtr = _bindings.minotari_wallet_get_address(_walletHandle!, errorPtr);

      if (addressPtr == nullptr) {
        final errorMsg = errorPtr.value.cast<Utf8>().toDartString();
        _bindings.minotari_string_free(errorPtr.value);
        throw Exception('Failed to get address: $errorMsg');
      }

      final address = addressPtr.cast<Utf8>().toDartString();
      _bindings.minotari_string_free(addressPtr);
      return address;
    } finally {
      calloc.free(errorPtr);
    }
  }

  /// Get wallet balance
  Future<Map<String, int>> getBalance() async {
    if (_walletHandle == null) {
      throw Exception('Wallet not initialized');
    }

    final availablePtr = calloc<Uint64>();
    final pendingIncomingPtr = calloc<Uint64>();
    final pendingOutgoingPtr = calloc<Uint64>();
    final errorPtr = calloc<Pointer<Char>>();

    try {
      final result = _bindings.minotari_wallet_get_balance(
        _walletHandle!,
        availablePtr,
        pendingIncomingPtr,
        pendingOutgoingPtr,
        errorPtr,
      );

      if (result != 0) {
        final errorMsg = errorPtr.value.cast<Utf8>().toDartString();
        _bindings.minotari_string_free(errorPtr.value);
        throw Exception('Failed to get balance: $errorMsg');
      }

      return {
        'available': availablePtr.value,
        'pendingIncoming': pendingIncomingPtr.value,
        'pendingOutgoing': pendingOutgoingPtr.value,
      };
    } finally {
      calloc.free(availablePtr);
      calloc.free(pendingIncomingPtr);
      calloc.free(pendingOutgoingPtr);
      calloc.free(errorPtr);
    }
  }

  /// Sync wallet with base node
  Future<void> sync(String baseNodeAddress) async {
    if (_walletHandle == null) {
      throw Exception('Wallet not initialized');
    }

    final addressPtr = baseNodeAddress.toNativeUtf8();
    final errorPtr = calloc<Pointer<Char>>();

    try {
      final result = _bindings.minotari_wallet_sync(
        _walletHandle!,
        addressPtr.cast(),
        errorPtr,
      );

      if (result != 0) {
        final errorMsg = errorPtr.value.cast<Utf8>().toDartString();
        _bindings.minotari_string_free(errorPtr.value);
        throw Exception('Failed to sync wallet: $errorMsg');
      }
    } finally {
      calloc.free(addressPtr);
      calloc.free(errorPtr);
    }
  }

  /// Get mnemonic (placeholder - needs to be implemented in Rust)
  String? getMnemonic() {
    // TODO: Implement mnemonic retrieval from wallet
    return null;
  }

  /// Dispose of the wallet handle
  void dispose() {
    if (_walletHandle != null) {
      _bindings.minotari_wallet_free(_walletHandle!);
      _walletHandle = null;
    }
  }
}
