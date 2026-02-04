import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_minotari/src/rust/api/wallet.dart'
    show WalletCreationDetails, createWallet, restoreWallet;
import 'package:cw_minotari/src/rust/api/balance.dart' as balance;
import 'package:cw_minotari/src/rust/api/address.dart' as address;
import 'package:cw_minotari/src/rust/api/db.dart';
import 'package:cw_minotari/src/rust/api/fee.dart' as fee;
import 'package:cw_minotari/src/rust/api/scanner.dart' as scanner;
import 'package:cw_minotari/src/rust/api/transactions.dart' as transactions;
import 'package:cw_minotari/src/rust/api/send_transaction.dart' as send_tx;
import 'package:cw_minotari/src/rust/api/network.dart';
import 'package:cw_minotari/src/rust/frb_generated.dart';

export 'package:cw_minotari/src/rust/api/send_transaction.dart'
    show SendTransactionEvent, TransactionStage;

export 'package:cw_minotari/src/rust/api/fee.dart'
    show FeeEstimate, FeePriority;

/// FFI interface for Minotari wallet using Flutter Rust Bridge
/// Note: The Rust library uses "password" parameter name but it actually means
/// BIP39 passphrase for seed derivation. We use "passphrase" in our Dart code
/// for clarity.
class MinotariFfi {
  final String walletName;
  final String dataPath;
  TariNetwork? _networkInternal;
  bool _isInitialized = false;

  static bool _rustLibInitialized = false;

  MinotariFfi({required this.dataPath, required this.walletName});

  /// Get the network, throws if wallet not initialized
  TariNetwork get _network {
    if (_networkInternal == null) {
      throw Exception('Wallet not initialized - network not set');
    }
    return _networkInternal!;
  }

  static Future<void> _ensureRustLibInitialized() async {
    if (!_rustLibInitialized) {
      await RustLib.init();
      _rustLibInitialized = true;
    }
  }

  void _ensureWalletInitialized() {
    if (!_isInitialized) {
      throw Exception('Wallet not initialized');
    }
  }

  /// Open an existing wallet
  Future<void> open(TariNetwork network) async {
    await _ensureRustLibInitialized();

    printV('[MinotariFfi] Opening wallet "$walletName" at path: $dataPath');
    try {
      await initializeDatabase(path: dataPath);
      printV('[MinotariFfi] Database initialized successfully for wallet "$walletName"');
    } catch (e) {
      printV('[MinotariFfi] Failed to initialize database: $e');
      rethrow;
    }

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

    final details = await createWallet(walletName: walletName, network: network, passphrase: passphrase);

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

    final details = await restoreWallet(
      walletName: walletName,
      seedWords: seedWords,
      passphrase: passphrase,
      network: network,
    );

    _networkInternal = network;
    _isInitialized = true;

    return details;
  }

  /// Get wallet address
  /// [passphrase] is the BIP39 passphrase for seed derivation
  Future<String> getAddress({required String passphrase}) async {
    _ensureWalletInitialized();

    return await address.getAddress(
      walletName: walletName,
      passphrase: passphrase,
      network: _network,
    );
  }

  /// Get wallet balance
  Future<Map<String, int>> getBalance() async {
    _ensureWalletInitialized();

    printV('[MinotariFfi] Getting balance for wallet "$walletName"');
    final balanceData = await balance.getBalance(walletName: walletName);
    printV('[MinotariFfi] Balance retrieved successfully for wallet "$walletName"');

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
    _ensureWalletInitialized();

    final config = scanner.ScanConfiguration(
      walletName: walletName,
      passphrase: passphrase,
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
    _ensureWalletInitialized();

    return await transactions.getTransactions(
      walletName: walletName,
      limit: limit,
      offset: offset,
    );
  }

  /// Send a transaction to the specified recipient
  /// Returns a stream of transaction events for progress updates
  ///
  /// [seedWords] - The wallet's mnemonic seed words (24 words)
  /// [passphrase] - BIP39 passphrase for seed derivation
  /// [recipientAddress] - The Tari address to send to
  /// [amount] - Amount in microTari
  /// [baseNodeUrl] - The base node URL for broadcasting
  /// [paymentId] - Optional payment ID/message
  Stream<send_tx.SendTransactionEvent> sendTransaction({
    required List<String> seedWords,
    required String passphrase,
    required String recipientAddress,
    required BigInt amount,
    required String baseNodeUrl,
    String? paymentId,
  }) {
    _ensureWalletInitialized();

    final details = send_tx.SendTransactionDetails(
      seedWords: seedWords,
      passphrase: passphrase,
      network: _network,
      baseUrl: baseNodeUrl,
      walletName: walletName,
      recipientAddress: recipientAddress,
      amount: amount,
      paymentId: paymentId,
    );

    return send_tx.sendTransaction(details: details);
  }

  /// Estimate transaction fee based on amount and priority
  ///
  /// [amount] - Amount in microTari to send
  /// [priority] - Fee priority (slow, medium, fast)
  /// [baseNodeUrl] - The base node URL for fee estimation
  Future<fee.FeeEstimate> estimateFee({
    required BigInt amount,
    required fee.FeePriority priority,
    required String baseNodeUrl,
  }) async {
    _ensureWalletInitialized();

    return await fee.estimateTransactionFee(
      amount: amount,
      priority: priority,
      baseUrl: baseNodeUrl,
      walletName: walletName,
    );
  }

  /// Dispose of the wallet handle
  /// Note: We don't call disconnectDatabase() here because it breaks re-initialization
  /// The Rust library handles database connection switching internally via initializeDatabase()
  Future<void> dispose() async {
    printV('[MinotariFfi] Disposing wallet "$walletName" (was initialized: $_isInitialized)');
    if (_isInitialized) {
      _isInitialized = false;
      _networkInternal = null;
    }
  }
}
