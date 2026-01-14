import 'package:cw_minotari/src/rust/api/wallet.dart' as wallet_api;
import 'package:cw_minotari/src/rust/api/balance.dart' as balance_api;
import 'package:cw_minotari/src/rust/api/address.dart' as address_api;
import 'package:cw_minotari/src/rust/api/db.dart' as db_api;
import 'package:cw_minotari/src/rust/api/scanner.dart' as scanner_api;
import 'package:cw_minotari/src/rust/api/transactions.dart' as transactions_api;
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

  /// Open an existing wallet
  Future<void> open(TariNetwork network) async {
    await _ensureRustLibInitialized();

    await db_api.initializeDatabase(path: dataPath);

    _network = network;
    _isInitialized = true;
  }

  /// Create a new wallet
  /// Rust generates mnemonic internally
  Future<void> create(TariNetwork network) async {
    await _ensureRustLibInitialized();

    await db_api.initializeDatabase(path: dataPath);

    // Create wallet using FFI - Rust generates mnemonic internally
    await wallet_api.createWallet(network: network);

    _network = network;
    _isInitialized = true;
  }

  /// Restore wallet from mnemonic
  Future<void> restore(
    String mnemonic,
    TariNetwork network, {
    String passphrase = '',
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

  /// Start scanner-based blockchain sync
  /// Returns a stream of scan events for progress updates and transaction discovery
  Stream<scanner_api.ScanEventDto> startScan({
    required String baseNodeAddress,
    String password = '',
    bool continuous = false,
    int batchSize = 1000,
    int pollIntervalSeconds = 60,
  }) {
    if (!_isInitialized) {
      throw Exception('Wallet not initialized');
    }

    final config = scanner_api.ScanConfiguration(
      password: password,
      baseUrl: baseNodeAddress,
      batchSize: BigInt.from(batchSize),
      continuous: continuous,
      pollIntervalSeconds: BigInt.from(pollIntervalSeconds),
    );

    return scanner_api.startScan(config: config);
  }

  /// Stop the currently running scan
  Future<void> stopScan() async {
    await scanner_api.stopScan();
  }

  /// Get transaction history from the wallet
  Future<List<transactions_api.DisplayedTransactionDto>> getTransactions({
    int limit = 100,
    int offset = 0,
  }) async {
    if (!_isInitialized) {
      throw Exception('Wallet not initialized');
    }

    return await transactions_api.getTransactions(
      walletName: _walletName,
      limit: limit,
      offset: offset,
    );
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
