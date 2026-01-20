import 'package:cw_minotari/src/rust/api/wallet.dart'
    show WalletCreationDetails, createWallet, restoreWallet;
import 'package:cw_minotari/src/rust/api/balance.dart' as balance;
import 'package:cw_minotari/src/rust/api/address.dart' as address;
import 'package:cw_minotari/src/rust/api/db.dart';
import 'package:cw_minotari/src/rust/api/scanner.dart' as scanner;
import 'package:cw_minotari/src/rust/api/transactions.dart' as transactions;
import 'package:cw_minotari/src/rust/api/network.dart';
import 'package:cw_minotari/src/rust/frb_generated.dart';

/// FFI interface for Minotari wallet using Flutter Rust Bridge
/// Note: The Rust library uses "password" parameter name but it actually means
/// BIP39 passphrase for seed derivation. We use "passphrase" in our Dart code
/// for clarity.
class MinotariFfi {
  final String _walletName = 'default'; // We support a single wallet for now

  final String dataPath;
  TariNetwork? _networkInternal;
  bool _isInitialized = false;

  static bool _rustLibInitialized = false;

  MinotariFfi({required this.dataPath});

  /// Get the network, throws if wallet not initialized
  TariNetwork get _network {
    if (_networkInternal == null) {
      throw Exception('Wallet not initialized - network not set');
    }
    return _networkInternal!;
  }

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

    await initializeDatabase(path: dataPath);

    _networkInternal = network;
    _isInitialized = true;
  }

  /// Create a new wallet
  /// Rust generates mnemonic internally
  /// Returns WalletCreationDetails which contains seed words
  /// [passphrase] is the BIP39 passphrase for seed derivation
  Future<WalletCreationDetails> create(TariNetwork network, {required String passphrase}) async {
    await _ensureRustLibInitialized();

    await initializeDatabase(path: dataPath);

    // Create wallet using FFI - Rust generates mnemonic internally
    // Note: Rust API uses "password" param name but it's actually the BIP39 passphrase
    final details = await createWallet(network: network, password: passphrase);

    _networkInternal = network;
    _isInitialized = true;

    return details;
  }

  /// Restore wallet from mnemonic
  /// Returns WalletCreationDetails which contains seed words
  /// [passphrase] is the BIP39 passphrase for seed derivation
  Future<WalletCreationDetails> restore(
    String mnemonic,
    TariNetwork network, {
    required String passphrase,
  }) async {
    await _ensureRustLibInitialized();

    await initializeDatabase(path: dataPath);

    // Convert mnemonic string to list of words
    final seedWords = mnemonic.split(' ').where((word) => word.isNotEmpty).toList();

    if (seedWords.length != 24) {
      throw Exception('Invalid mnemonic: expected 24 words, got ${seedWords.length}');
    }

    // Restore wallet using FFI
    // Note: Rust API uses "password" param name but it's actually the BIP39 passphrase
    final details = await restoreWallet(
      seedWords: seedWords,
      password: passphrase,
      network: network,
    );

    _networkInternal = network;
    _isInitialized = true;

    return details;
  }

  /// Get wallet address
  /// [passphrase] is the BIP39 passphrase for seed derivation
  Future<String> getAddress({required String passphrase}) async {
    if (!_isInitialized) {
      throw Exception('Wallet not initialized');
    }

    return await address.getAddress(
      walletName: _walletName,
      passphrase: passphrase,
      network: _network,
    );
  }

  /// Get wallet balance
  Future<Map<String, int>> getBalance() async {
    if (!_isInitialized) {
      throw Exception('Wallet not initialized');
    }

    final balanceData = await balance.getBalance(walletName: _walletName);

    // Convert BigInt to int (Minotari uses micro-tari, which fits in int64)
    return {
      'available': balanceData.available.toInt(),
      'pendingIncoming': balanceData.unconfirmed.toInt(),
      'pendingOutgoing': balanceData.locked.toInt(),
    };
  }

  /// Start scanner-based blockchain sync
  /// Returns a stream of scan events for progress updates and transaction discovery
  /// [passphrase] is the BIP39 passphrase for seed derivation
  Stream<scanner.ScanEventDto> startScan({
    required String baseNodeAddress,
    required String passphrase,
    bool continuous = false,
    int batchSize = 1000,
    int pollIntervalSeconds = 60,
  }) {
    if (!_isInitialized) {
      throw Exception('Wallet not initialized');
    }

    // Note: Rust API uses "password" field name but it's actually the BIP39 passphrase
    final config = scanner.ScanConfiguration(
      password: passphrase,
      baseUrl: baseNodeAddress,
      batchSize: BigInt.from(batchSize),
      continuous: continuous,
      pollIntervalSeconds: BigInt.from(pollIntervalSeconds),
    );

    return scanner.startScan(config: config);
  }

  /// Stop the currently running scan
  Future<void> stopScan() async {
    await scanner.stopScan();
  }

  /// Get transaction history from the wallet
  Future<List<transactions.DisplayedTransactionDto>> getTransactions({
    int limit = 100,
    int offset = 0,
  }) async {
    if (!_isInitialized) {
      throw Exception('Wallet not initialized');
    }

    return await transactions.getTransactions(
      walletName: _walletName,
      limit: limit,
      offset: offset,
    );
  }

  /// Dispose of the wallet handle
  Future<void> dispose() async {
    if (_isInitialized) {
      await disconnectDatabase();
      _isInitialized = false;
      _networkInternal = null;
    }
  }
}
