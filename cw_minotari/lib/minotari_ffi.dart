import 'package:cw_core/exceptions/cake_exception.dart';
import 'package:cw_minotari/src/rust/api/wallet.dart' as wallet;
import 'package:cw_minotari/src/rust/api/balance.dart' as balance;
import 'package:cw_minotari/src/rust/api/address.dart' as address;
import 'package:cw_minotari/src/rust/api/db.dart' as db;
import 'package:cw_minotari/src/rust/api/fee.dart' as fee;
import 'package:cw_minotari/src/rust/api/scanner.dart' as scanner;
import 'package:cw_minotari/src/rust/api/signing.dart' as signing;
import 'package:cw_minotari/src/rust/api/transactions.dart' as transactions;
import 'package:cw_minotari/src/rust/api/send_transaction.dart' as send_tx;
import 'package:cw_minotari/src/rust/api/network.dart';
import 'package:cw_minotari/src/rust/frb_generated.dart';

export 'package:cw_minotari/src/rust/api/send_transaction.dart'
    show SendRecipient, SendTransactionEvent, TransactionStage;

export 'package:cw_minotari/src/rust/api/fee.dart'
    show FeeEstimate, FeePriority, SendAllFeeEstimate;

/// FFI interface for one Minotari wallet account in the shared wallet database.
///
/// [passphrase] arguments are the wallet's database passphrase (the cw "passphrase"),
/// not a BIP39 passphrase.
class MinotariFfi {
  final String walletName;
  final String dataPath;
  final TariNetwork network;

  static bool _rustLibInitialized = false;

  MinotariFfi({required this.dataPath, required this.walletName, required this.network});

  static Future<void> ensureRustLibInitialized() async {
    if (!_rustLibInitialized) {
      await RustLib.init();
      _rustLibInitialized = true;
    }
  }

  /// cw locks the process to the network of its first wallet call; another network
  /// needs an app restart.
  static Future<void> ensureProcessNetwork(TariNetwork network) async {
    await ensureRustLibInitialized();
    final processNetwork = currentNetwork();
    if (processNetwork != null && processNetwork != network) {
      throw RestartRequiredException('Minotari runs on ${processNetwork.name} in this session; '
          'a ${network.name} wallet needs an app restart.');
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

  Future<void> deleteIfPresent() async {
    await _useDatabase();
    if ((await wallet.listWallets()).contains(walletName)) {
      await wallet.deleteWallet(walletName: walletName);
    }
  }

  Future<void> delete() async {
    await _useDatabase();
    await wallet.deleteWallet(walletName: walletName);
  }

  Future<void> changePassphrase({required String oldPassphrase, required String newPassphrase}) =>
      wallet.changePassphrase(
        walletName: walletName,
        oldPassphrase: oldPassphrase,
        newPassphrase: newPassphrase,
      );

  /// Reads the mnemonic for the seed page; the caller must not keep it longer than needed.
  Future<List<String>> seedWords({required String passphrase}) async {
    final handle = await wallet.getSeedWords(walletName: walletName, password: passphrase);
    return wallet.revealSeedWords(handle: handle);
  }

  Future<String> getAddress() => address.getAddress(walletName: walletName, network: network);

  Future<balance.AccountBalanceDto> getBalance() => balance.getBalance(walletName: walletName);

  scanner.ScanHandle createScanHandle() => scanner.createScanHandle(walletName: walletName);

  /// Continuous scan with [handle]; with [fromHeight] the wallet is rolled back and
  /// rescanned from there.
  Stream<scanner.ScanEventDto> scan({
    required scanner.ScanHandle handle,
    required String baseNodeUrl,
    int? fromHeight,
  }) {
    final config = scanner.ScanConfiguration(
      walletName: walletName,
      baseUrl: baseNodeUrl,
      batchSize: BigInt.from(25),
      continuous: true,
      pollIntervalSeconds: BigInt.from(60),
      requiredConfirmations: BigInt.from(3),
      priority: scanner.ScanPriority.foreground,
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

  /// Sends to [recipients], or sweeps the wallet to the single recipient when [sendAll].
  Stream<send_tx.SendTransactionEvent> sendTransaction({
    required List<send_tx.SendRecipient> recipients,
    required bool sendAll,
    required String baseNodeUrl,
  }) =>
      send_tx.sendTransaction(
        details: send_tx.MultiSendTransactionDetails(
          network: network,
          baseUrl: baseNodeUrl,
          walletName: walletName,
          recipients: recipients,
          sendAll: sendAll,
        ),
      );

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

  Future<fee.SendAllFeeEstimate> estimateSendAllFee({required String recipientAddress}) =>
      fee.estimateSendAllFee(
        walletName: walletName,
        recipientAddress: recipientAddress,
        network: network,
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
