import 'package:cw_minotari/src/rust/api/wallet.dart' as wallet_api;
import 'package:cw_minotari/src/rust/api/balance.dart' as balance_api;
import 'package:cw_minotari/src/rust/api/address.dart' as address_api;
import 'package:cw_minotari/src/rust/api/db.dart' as db_api;
import 'package:cw_minotari/src/rust/api/network.dart';
import 'package:cw_minotari/src/rust/frb_generated.dart';

/// FFI interface for Minotari wallet using Flutter Rust Bridge
class MinotariFfi {
  final String _walletName = 'default'; // We support a single wallet for now

  final String dataPath;
  TariNetwork? _network;
  bool _isInitialized = false;

  static bool _rustLibInitialized = false;

  MinotariFfi({required this.dataPath});

  /// Ensure Rust library is initialized (lazy initialization)
  static Future<void> _ensureRustLibInitialized() async {
    if (!_rustLibInitialized) {
      await RustLib.init();
      _rustLibInitialized = true;
    }
  }

  /// Create a new wallet
  /// Rust generates mnemonic internally
  Future<void> create({TariNetwork network = TariNetwork.mainNet}) async {
    await _ensureRustLibInitialized();

    await db_api.initializeDatabase(path: dataPath);

    // Create wallet using FFI - Rust generates mnemonic internally
    await wallet_api.createWallet(network: network);

    _network = network;
    _isInitialized = true;
  }

  /// Restore wallet from mnemonic
  Future<void> restore(
    String mnemonic, {
    String passphrase = '',
    TariNetwork network = TariNetwork.mainNet,
  }) async {
    await _ensureRustLibInitialized();

    await db_api.initializeDatabase(path: dataPath);

    // Convert mnemonic string to list of words
    final seedWords = mnemonic.split(' ').where((word) => word.isNotEmpty).toList();

    if (seedWords.length != 24) {
      throw Exception('Invalid mnemonic: expected 24 words, got ${seedWords.length}');
    }

    // Restore wallet using FFI
    await wallet_api.restoreWallet(
      seedWords: seedWords,
      passphrase: passphrase.isEmpty ? null : passphrase,
      network: network,
    );

    _network = network;
    _isInitialized = true;
  }

  /// Get wallet address
  Future<String> getAddress() async {
    if (!_isInitialized) {
      throw Exception('Wallet not initialized');
    }

    return await address_api.getAddress(
      walletName: _walletName,
      network: _network,
    );
  }

  /// Get wallet balance
  Future<Map<String, int>> getBalance() async {
    if (!_isInitialized) {
      throw Exception('Wallet not initialized');
    }

    final balance = await balance_api.getBalance(walletName: _walletName);

    // Convert BigInt to int (Minotari uses micro-tari, which fits in int64)
    return {
      'available': balance.available.toInt(),
      'pendingIncoming': balance.unconfirmed.toInt(),
      'pendingOutgoing': balance.locked.toInt(),
    };
  }

  /// Sync wallet with base node
  /// Note: The current Rust FFI uses a scanner-based approach
  /// This is a compatibility stub that will be replaced with proper scanner integration
  Future<void> sync(String baseNodeAddress) async {
    if (!_isInitialized) {
      throw Exception('Wallet not initialized');
    }

    // TODO: Implement scanner-based sync
    // For now, just update balance to trigger a refresh
    await getBalance();
  }

  /// Get mnemonic
  /// Note: This needs to be implemented in the Rust layer
  String? getMnemonic() {
    // TODO: Implement mnemonic retrieval from Rust wallet
    return null;
  }

  /// Dispose of the wallet handle
  Future<void> dispose() async {
    if (_isInitialized) {
      await db_api.disconnectDatabase();
      _isInitialized = false;
      _network = null;
    }
  }
}
