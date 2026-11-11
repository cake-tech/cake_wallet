import 'package:cw_core/root_dir.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_minotari/src/rust/api/wallet.dart' as wallet;
import 'package:cw_minotari/src/rust/api/balance.dart' as balance;
import 'package:cw_minotari/src/rust/api/address.dart' as address;
import 'package:cw_minotari/src/rust/api/db.dart' as db;
import 'package:cw_minotari/src/rust/api/fee.dart' as fee;
import 'package:cw_minotari/src/rust/api/scanner.dart' as scanner;
import 'package:cw_minotari/src/rust/api/signing.dart' as signing;
import 'package:cw_minotari/src/rust/api/transactions.dart' as transactions;
import 'package:cw_minotari/src/rust/api/send_transaction.dart' as send_tx;
import 'package:cw_minotari/src/rust/api/logger.dart' as logger;
import 'package:cw_minotari/src/rust/api/network.dart';
import 'package:cw_minotari/src/rust/frb_generated.dart';
import 'package:path/path.dart' as p;

export 'package:cw_minotari/src/rust/api/send_transaction.dart'
    show SendRecipient, SendResultDto, SendTransactionEvent, TransactionStage;

export 'package:cw_minotari/src/rust/api/fee.dart'
    show FeeEstimate, FeePriority, SendAllFeeEstimate;

/// FFI interface for one Minotari wallet account in the shared wallet database.
///
/// [passphrase] arguments are the wallet's database passphrase (the cw "passphrase"),
/// not a BIP39 passphrase.
class MinotariFfi {
  final String walletName;
  final String dataPath;
  // Mainnet only: Tari has no public stagenet node, and the release bundle (mainnet network
  // group) rejects esmeralda.
  static const network = TariNetwork.mainNet;

  static bool _rustLibInitialized = false;

  MinotariFfi({required this.dataPath, required this.walletName});

  static Future<void> ensureRustLibInitialized() async {
    if (!_rustLibInitialized) {
      await RustLib.init();
      _rustLibInitialized = true;
      // Rust logs go only to a rotating file (<app dir>/minotari/logs). A second engine in
      // the same process (Android background sync) gets Ok without a second logger.
      try {
        logger.initLogger(basePath: p.join((await getAppDir()).path, 'minotari'));
      } catch (e) {
        printV('Minotari logger not started: $e');
      }
    }
  }

  Future<void> _useDatabase() async {
    await ensureRustLibInitialized();
    await db.setDatabasePath(path: dataPath);
  }

  Future<wallet.WalletCreationDetails> create({required String passphrase}) async {
    await _useDatabase();
    return wallet.createWallet(walletName: walletName, network: network, passphrase: passphrase);
  }

  Future<wallet.WalletCreationDetails> restore(String mnemonic,
      {required String passphrase}) async {
    await _useDatabase();
    final seedWords = mnemonic.split(' ').where((word) => word.isNotEmpty).toList();
    if (seedWords.length != 24) {
      throw Exception('Invalid mnemonic: expected 24 words, got ${seedWords.length}');
    }

    return wallet.restoreWallet(
      walletName: walletName,
      seedWords: seedWords,
      passphrase: passphrase,
      network: network,
    );
  }

  Future<wallet.WalletCreationDetails> importViewOnly({
    required String viewPrivateKeyHex,
    required String spendPublicKeyHex,
    required int birthday,
    required String passphrase,
  }) async {
    await _useDatabase();
    return wallet.importViewOnlyWallet(
      walletName: walletName,
      viewPrivateKeyHex: viewPrivateKeyHex,
      spendPublicKeyHex: spendPublicKeyHex,
      birthday: birthday,
      passphrase: passphrase,
      network: network,
    );
  }

  Future<wallet.WalletCreationDetails> importFromKeys({
    required String viewPrivateKeyHex,
    required String spendPrivateKeyHex,
    required int birthday,
    required String passphrase,
  }) async {
    await _useDatabase();
    return wallet.importWalletFromKeys(
      walletName: walletName,
      viewPrivateKeyHex: viewPrivateKeyHex,
      spendPrivateKeyHex: spendPrivateKeyHex,
      birthday: birthday,
      passphrase: passphrase,
      network: network,
    );
  }

  /// Opens a key session for this wallet; every unlock needs one [lock].
  Future<void> unlock({required String passphrase}) async {
    await ensureRustLibInitialized();
    await db.unlockWallet(dbPath: dataPath, walletName: walletName, passphrase: passphrase);
  }

  Future<bool> lock() => db.lockWallet(walletName: walletName);

  Future<void> rename({required String newWalletName}) async {
    await _useDatabase();
    await wallet.renameWallet(currentWalletName: walletName, newWalletName: newWalletName);
  }

  /// Folds the write-ahead log into the database file so a copy of it is consistent.
  Future<void> checkpoint() async {
    await _useDatabase();
    await db.checkpointDatabase();
  }

  Future<bool> exists() async {
    await _useDatabase();
    return (await wallet.listWallets()).contains(walletName);
  }

  Future<void> delete() async {
    await _useDatabase();
    await wallet.deleteWallet(walletName: walletName);
  }

  /// Reads the mnemonic for the seed page; the caller must not keep it longer than needed.
  Future<List<String>> seedWords({required String passphrase}) async {
    await _useDatabase();
    final handle = await wallet.getSeedWords(walletName: walletName, password: passphrase);
    try {
      return await wallet.revealSeedWords(handle: handle);
    } finally {
      // cw zeroizes the words only when the handle is dropped.
      handle.dispose();
    }
  }

  Future<String> getAddress() => address.getAddress(walletName: walletName, network: network);

  Future<balance.AccountBalanceDto> getBalance() => balance.getBalance(walletName: walletName);

  static const backgroundScanDeadline = Duration(seconds: 240);

  scanner.ScanHandle createScanHandle() => scanner.createScanHandle(walletName: walletName);

  /// Scan with [handle]; with [fromHeight] the wallet is rolled back and rescanned from
  /// there. A foreground scan is continuous. A background scan (an Android background sync
  /// slot) is one pass on one thread that stops by [backgroundScanDeadline], well inside the
  /// slot's 10-minute limit so other wallets get a turn; the next slot resumes where it stopped.
  Stream<scanner.ScanEventDto> scan({
    required scanner.ScanHandle handle,
    required String baseNodeUrl,
    required scanner.ScanPriority priority,
    int? fromHeight,
  }) {
    final background = priority == scanner.ScanPriority.background;
    final config = scanner.ScanConfiguration(
      walletName: walletName,
      baseUrl: baseNodeUrl,
      batchSize: BigInt.from(25),
      continuous: !background,
      pollIntervalSeconds: BigInt.from(60),
      requiredConfirmations: BigInt.from(3),
      priority: priority,
      processingThreads: background ? 1 : null,
      eventBuffer: background ? 256 : null,
      deadlineSeconds: background ? BigInt.from(backgroundScanDeadline.inSeconds) : null,
    );

    if (fromHeight == null) return scanner.startScan(handle: handle, config: config);
    return scanner.rescan(handle: handle, fromHeight: BigInt.from(fromHeight), config: config);
  }

  Future<void> stopScan(scanner.ScanHandle handle) => scanner.stopScan(handle: handle);

  Future<List<transactions.DisplayedTransactionDto>> getTransactions({
    int limit = 100,
    int offset = 0,
  }) =>
      transactions.getTransactions(walletName: walletName, limit: limit, offset: offset);

  /// Sends to [recipients], or sweeps the wallet to the single recipient when [sendAll], at
  /// [feePerGram] µT per gram (the rate of the quote the user confirmed). The final Broadcasted
  /// event carries the send's result.
  Stream<send_tx.SendTransactionEvent> sendTransaction({
    required List<send_tx.SendRecipient> recipients,
    required bool sendAll,
    required String baseNodeUrl,
    required BigInt feePerGram,
    String? conflictsWithTransactionId,
  }) =>
      send_tx.sendTransactionAtFee(
        details: sendDetails(
          recipients: recipients,
          sendAll: sendAll,
          baseNodeUrl: baseNodeUrl,
          conflictsWithTransactionId: conflictsWithTransactionId,
        ),
        feePerGram: feePerGram,
      );

  /// What [sendTransaction] sends. With [conflictsWithTransactionId] (an abandoned send's id)
  /// it pays again so that it and the abandoned send can never both be mined.
  send_tx.MultiSendTransactionDetails sendDetails({
    required List<send_tx.SendRecipient> recipients,
    required bool sendAll,
    required String baseNodeUrl,
    String? conflictsWithTransactionId,
  }) =>
      send_tx.MultiSendTransactionDetails(
        network: network,
        baseUrl: baseNodeUrl,
        walletName: walletName,
        recipients: recipients,
        sendAll: sendAll,
        conflictsWithTransactionId: conflictsWithTransactionId,
      );

  /// Gives up a send the node keeps refusing and releases its inputs; returns cw's note on
  /// what abandoning does not do.
  Future<String> abandonSend({required String passphrase, required String transactionId}) =>
      send_tx.abandonSend(
        walletName: walletName,
        passphrase: passphrase,
        transactionId: transactionId,
      );

  /// cw's warnings about sends this wallet abandoned that a node accepted or that were mined
  /// after all.
  Future<List<send_tx.AbandonWarningDto>> abandonWarnings() =>
      send_tx.getAbandonWarnings(walletName: walletName);

  Future<fee.FeeEstimate> estimateFee({
    required BigInt amount,
    required int numOutputs,
    required fee.FeePriority priority,
    required String baseNodeUrl,
  }) =>
      fee.estimateTransactionFeeForOutputs(
        amount: amount,
        numOutputs: numOutputs,
        priority: priority,
        baseUrl: baseNodeUrl,
        walletName: walletName,
      );

  /// The node's fee per gram for [priority], capped by cw; reads no wallet data.
  Future<BigInt> feePerGram({
    required fee.FeePriority priority,
    required String baseNodeUrl,
  }) =>
      fee.getFeePerGram(priority: priority, baseUrl: baseNodeUrl);

  Future<fee.SendAllFeeEstimate> estimateSendAllFee({
    required String recipientAddress,
    required BigInt feePerGram,
  }) =>
      fee.estimateSendAllFeeAt(
        walletName: walletName,
        recipientAddress: recipientAddress,
        network: network,
        feePerGram: feePerGram,
      );

  Future<String> signMessage(String message) =>
      signing.signMessage(walletName: walletName, message: message);

  static Future<bool> verifyMessage({
    required String message,
    required String signature,
    required String address,
  }) =>
      signing.verifyMessage(message: message, signature: signature, address: address);
}
