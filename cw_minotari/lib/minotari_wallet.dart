import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/exceptions/cake_exception.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:cw_minotari/minotari_balance.dart';
import 'package:cw_minotari/minotari_ffi.dart';
import 'package:cw_minotari/minotari_transaction_history.dart';
import 'package:cw_minotari/minotari_transaction_info.dart';
import 'package:cw_minotari/minotari_transaction_priority.dart';
import 'package:cw_minotari/minotari_wallet_addresses.dart';
import 'package:cw_minotari/pending_minotari_transaction.dart';
import 'package:cw_minotari/src/rust/api/base_node.dart' as base_node;
import 'package:cw_minotari/src/rust/api/height.dart' show estimateHeightAtTime;
import 'package:cw_minotari/src/rust/api/network.dart';
import 'package:cw_minotari/src/rust/api/scanner.dart';
import 'package:cw_minotari/src/rust/api/transactions.dart';
import 'package:mobx/mobx.dart';

part 'minotari_wallet.g.dart';

/// The Tari network stored in [WalletInfo.network]; wallets without one are mainnet.
TariNetwork minotariNetworkFromName(String? name) =>
    TariNetwork.values.firstWhere((n) => n.name == name, orElse: () => TariNetwork.mainNet);

/// The create/restore "testnet" choice: Cake ships the mainnet-group bundle, whose only
/// test network is stagenet.
TariNetwork minotariNetworkFor({bool? isTestnet}) =>
    isTestnet == true ? TariNetwork.stageNet : TariNetwork.mainNet;

/// cw's offline estimate assumes the target block time and runs high (about 17 days of
/// blocks by September 2026, growing), so a restore or rescan starts 30 days of blocks earlier.
const _heightEstimateMarginBlocks = 30 * 24 * 30;

/// A safe restore or rescan start for [date], without asking a node.
Future<int> minotariHeightByDate(DateTime date, {required TariNetwork network}) async {
  await MinotariFfi.ensureRustLibInitialized();
  final estimate = estimateHeightAtTime(
    network: network,
    epochSecs: BigInt.from(date.millisecondsSinceEpoch ~/ 1000),
  ).toInt();
  return max(0, estimate - _heightEstimateMarginBlocks);
}

/// A random wallet-database passphrase; it lives only in the encrypted .keys file.
String randomMinotariPassphrase() {
  const allowedChars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%-=_+[]{}|;:,.<>?';
  final random = Random.secure();
  return List.generate(32, (_) => allowedChars[random.nextInt(allowedChars.length)]).join();
}

/// One cw recipient per output. A send-all pays its single recipient everything, so it
/// cannot be combined with other outputs.
List<SendRecipient> minotariRecipients(List<OutputInfo> outputs) {
  if (outputs.isEmpty) {
    throw TransactionGenerationException('No outputs specified for transaction.');
  }
  if (outputs.length > 1 && outputs.any((output) => output.sendAll)) {
    throw TransactionGenerationException('Send all cannot be combined with other recipients.');
  }

  return outputs.map((output) {
    final address =
        output.isParsedAddress ? output.extractedAddress ?? output.address : output.address;
    if (address.isEmpty) {
      throw TransactionGenerationException('Recipient address is empty.');
    }

    final amount = output.sendAll ? BigInt.zero : output.cryptoAmount.amount;
    if (!output.sendAll && amount <= BigInt.zero) {
      throw TransactionGenerationException('Invalid amount specified.');
    }

    final note = output.note;
    return SendRecipient(
      address: address,
      amount: amount,
      paymentId: note != null && note.isNotEmpty ? note : null,
    );
  }).toList();
}

/// The sync status a scan event moves the wallet to, or null when it leaves it unchanged.
///
/// Only a caught-up scan is synced; a scan that was stopped or replaced leaves the wallet
/// not connected rather than synced or failed.
SyncStatus? minotariSyncStatusFor(ScanEventDto event, {required int startHeight}) =>
    switch (event) {
      ScanEventDto_Started() => SyncronizingSyncStatus(),
      ScanEventDto_Progress(:final currentHeight, :final tipHeight) =>
        SyncingSyncStatus.fromHeightValues(tipHeight.toInt(), startHeight, currentHeight.toInt()),
      ScanEventDto_Waiting() || ScanEventDto_Completed() => SyncedSyncStatus(),
      ScanEventDto_Cancelled() ||
      ScanEventDto_Superseded() ||
      ScanEventDto_BudgetExhausted() =>
        NotConnectedSyncStatus(),
      ScanEventDto_Error() => FailedSyncStatus(),
      ScanEventDto_MoreBlocksAvailable() ||
      ScanEventDto_TransactionsReady() ||
      ScanEventDto_TransactionsUpdated() ||
      ScanEventDto_ReorgDetected() =>
        null,
    };

class MinotariWallet = MinotariWalletBase with _$MinotariWallet;

abstract class MinotariWalletBase
    extends WalletBase<MinotariBalance, MinotariTransactionHistory, MinotariTransactionInfo>
    with Store, WalletKeysFile {
  MinotariWalletBase(
    WalletInfo walletInfo,
    DerivationInfo derivationInfo, {
    required String password,
    required String dbPassphrase,
    required this.encryptionFileUtils,
    this.viewPrivateKeyHex,
    this.spendPublicKeyHex,
  })  : _password = password,
        _dbPassphrase = dbPassphrase,
        balance = ObservableMap.of({
          CryptoCurrency.xtm: MinotariBalance(
            available: 0,
            pendingIncoming: 0,
            pendingOutgoing: 0,
          )
        }),
        _isTransactionUpdating = false,
        walletAddresses = MinotariWalletAddresses(walletInfo),
        syncStatus = NotConnectedSyncStatus(),
        super(walletInfo, derivationInfo) {
    transactionHistory = MinotariTransactionHistory();
  }

  MinotariFfi? _ffi;
  bool _isUnlocked = false;
  bool _isTransactionUpdating;
  Node? _currentNode;

  /// The scan this wallet started last; events of earlier scans are ignored.
  ScanHandle? _scanHandle;
  int _scanStartHeight = 0;

  /// Fee quotes per priority for [_feeQuoteAmount], refreshed whenever the scan catches up.
  final Map<TransactionPriority, int> _estimatedFees = {};
  int? _feeQuoteAmount;

  String _password;
  String _dbPassphrase;
  final EncryptionFileUtils encryptionFileUtils;

  @override
  MinotariWalletAddresses walletAddresses;

  @override
  @observable
  SyncStatus syncStatus;

  @override
  @observable
  ObservableMap<CryptoCurrency, MinotariBalance> balance;

  /// The mnemonic is never held by the wallet; [loadSeed] reads it for the seed page.
  @override
  String? get seed => null;

  /// password - for encrypting/decrypting the .keys file
  @override
  String get password => _password;

  final String? viewPrivateKeyHex;
  final String? spendPublicKeyHex;

  @override
  WalletKeysData get walletKeysData => WalletKeysData(
        passphrase: _dbPassphrase,
        scanSecret: viewPrivateKeyHex,
        spendPubkey: spendPublicKeyHex,
      );

  @override
  Object get keys => {};

  @override
  bool get hasRescan => true;

  @override
  bool canSend() => !walletInfo.isWatchOnly;

  @override
  bool get canSignMessages => !walletInfo.isWatchOnly;

  String get address => walletAddresses.address;

  MinotariFfi get _requireFfi {
    final ffi = _ffi;
    if (ffi == null) throw Exception('Wallet not initialized.');
    return ffi;
  }

  String get _nodeUrl {
    final node = _currentNode;
    if (node == null) throw Exception('No node connected. Call connectToNode first.');
    return node.uri.toString();
  }

  Future<void> init() async {
    final network = minotariNetworkFromName(walletInfo.network);
    await MinotariFfi.ensureProcessNetwork(network);

    final dbPath = '${await pathForWalletTypeDir(type: walletInfo.type)}/wallet.db';
    final ffi = MinotariFfi(dataPath: dbPath, walletName: walletInfo.name, network: network);
    await ffi.unlock(passphrase: _dbPassphrase);
    try {
      walletAddresses.setAddress(await ffi.getAddress());
    } catch (_) {
      await ffi.lock();
      rethrow;
    }
    _ffi = ffi;
    _isUnlocked = true;

    await updateBalance();
    await updateTransactions();
  }

  @override
  Future<void> connectToNode({required Node node}) async {
    syncStatus = ConnectingSyncStatus();
    _currentNode = node;

    // Never throws: an unreachable node or a transport error is just unhealthy.
    if (!await checkNodeHealth()) {
      syncStatus = FailedSyncStatus();
      return;
    }

    syncStatus = ConnectedSyncStatus();
  }

  @override
  Future<void> startSync() => _scan();

  @override
  Future<void> rescan({required int height}) => _scan(fromHeight: height);

  /// Starts a continuous scan, replacing this wallet's previous one. Errors (including
  /// transport errors) end as [FailedSyncStatus]; the connection check reconnects and
  /// starts the scan again.
  Future<void> _scan({int? fromHeight}) async {
    try {
      syncStatus = AttemptingSyncStatus();
      final ffi = _requireFfi;
      final handle = ffi.createScanHandle();
      _scanHandle = handle;
      ffi.scan(handle: handle, baseNodeUrl: _nodeUrl, fromHeight: fromHeight).listen(
        (event) {
          if (_scanHandle == handle) _onScanEvent(event);
        },
        onError: (Object error) {
          if (_scanHandle != handle) return;
          printV('Minotari scan failed: $error');
          syncStatus = FailedSyncStatus();
        },
      );
    } catch (e) {
      printV('Minotari scan could not start: $e');
      syncStatus = FailedSyncStatus();
    }
  }

  void _onScanEvent(ScanEventDto event) {
    switch (event) {
      case ScanEventDto_Started(:final fromHeight):
        _scanStartHeight = fromHeight.toInt();
      case ScanEventDto_Waiting() || ScanEventDto_Completed():
        unawaited(updateBalance());
        for (final priority in MinotariTransactionPriority.all) {
          unawaited(updateEstimatedFeesParams(priority));
        }
      case ScanEventDto_TransactionsReady(:final field0):
        _processNewTransactions(field0.transactions);
        unawaited(updateBalance());
      case ScanEventDto_TransactionsUpdated(:final field0):
        _processNewTransactions(field0.updatedTransactions);
        unawaited(updateBalance());
      case ScanEventDto_ReorgDetected():
        transactionHistory.clear();
        unawaited(updateTransactions());
        unawaited(updateBalance());
      case ScanEventDto_Error(:final field0):
        printV('Minotari scan error: $field0');
      default:
        break;
    }

    final status = minotariSyncStatusFor(event, startHeight: _scanStartHeight);
    if (status != null) syncStatus = status;
  }

  @override
  Future<void> stopSync() async {
    final handle = _scanHandle;
    if (handle != null) await _ffi?.stopScan(handle);
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    final creds = credentials as MinotariTransactionCredentials;
    final ffi = _requireFfi;
    final nodeUrl = _nodeUrl;
    final recipients = minotariRecipients(creds.outputs);
    final sendAll = creds.outputs.first.sendAll;

    final int amount;
    final int fee;
    if (sendAll) {
      final quote = await ffi.estimateSendAllFee(
        recipientAddress: recipients.single.address,
        paymentId: recipients.single.paymentId,
      );
      amount = quote.amountAfterFee.toInt();
      fee = quote.fee.toInt();
    } else {
      amount = recipients.fold(0, (sum, recipient) => sum + recipient.amount.toInt());
      final quote = await ffi.estimateFee(
        amount: BigInt.from(amount),
        numOutputs: recipients.length,
        priority: _feePriority(creds.priority),
        baseNodeUrl: nodeUrl,
      );
      fee = quote.estimatedFee.toInt();
    }

    Future<void> send() async {
      var broadcasted = false;
      await for (final event in ffi.sendTransaction(
        recipients: recipients,
        sendAll: sendAll,
        baseNodeUrl: nodeUrl,
      )) {
        if (event.stage == TransactionStage.broadcasted) broadcasted = true;
      }
      if (!broadcasted) throw Exception('Transaction stream ended before the broadcast.');

      // Recorded as pending; the scanner's TransactionsUpdated confirms it.
      await updateBalance();
      await updateTransactions();
    }

    return PendingMinotariTransaction(
      amount: Money.fromInt(amount, CryptoCurrency.xtm),
      fee: Money.fromInt(fee, CryptoCurrency.xtm),
      send: send,
    );
  }

  @override
  Future<void> save() async {
    // Wallet state is saved by the Rust layer; the .keys file holds the database passphrase.
    if (!(await WalletKeysFile.hasKeysFile(walletInfo.name, walletInfo.type))) {
      await saveKeysFile(password, encryptionFileUtils);
      await saveKeysFile(password, encryptionFileUtils, true);
    }
  }

  @override
  Future<void> renameWalletFiles(String newWalletName) async {
    final currentWalletPath = await pathForWallet(name: walletInfo.name, type: walletInfo.type);
    final currentDirPath = await pathForWalletDir(name: walletInfo.name, type: walletInfo.type);
    final newWalletPath = await pathForWallet(name: newWalletName, type: walletInfo.type);

    final typeDir = await pathForWalletTypeDir(type: walletInfo.type);
    final ffi = MinotariFfi(
      dataPath: '$typeDir/wallet.db',
      walletName: walletInfo.name,
      network: minotariNetworkFromName(walletInfo.network),
    );
    await ffi.rename(newWalletName: newWalletName);

    final currentKeysFile = File('$currentWalletPath.keys');
    if (currentKeysFile.existsSync()) {
      await currentKeysFile.copy('$newWalletPath.keys');
    }

    final currentKeysBackupFile = File('$currentWalletPath.keys.backup');
    if (currentKeysBackupFile.existsSync()) {
      await currentKeysBackupFile.copy('$newWalletPath.keys.backup');
    }

    await Directory(currentDirPath).delete(recursive: true);
  }

  /// Re-encrypts the wallet database under a fresh passphrase and the .keys files under
  /// [password]. Nothing changes if the database step fails; if writing the .keys files
  /// fails the database goes back to the old passphrase.
  @override
  Future<void> changePassword(String password) async {
    final ffi = _requireFfi;
    final oldPassphrase = _dbPassphrase;
    final newPassphrase = randomMinotariPassphrase();
    await ffi.changePassphrase(oldPassphrase: oldPassphrase, newPassphrase: newPassphrase);

    final keysPath = await makeKeysFilePath();
    final data = WalletKeysData(
      passphrase: newPassphrase,
      scanSecret: viewPrivateKeyHex,
      spendPubkey: spendPublicKeyHex,
    ).toJSON();
    try {
      // The backup first: it is only read when the main file cannot be.
      await encryptionFileUtils.write(path: '$keysPath.backup', password: password, data: data);
      await encryptionFileUtils.write(path: keysPath, password: password, data: data);
    } catch (_) {
      await ffi.changePassphrase(oldPassphrase: newPassphrase, newPassphrase: oldPassphrase);
      rethrow;
    } finally {
      // change_passphrase stops this wallet's scan.
      if (_currentNode != null) unawaited(startSync());
    }

    _dbPassphrase = newPassphrase;
    _password = password;
  }

  @override
  Future<void> close({bool shouldCleanup = false}) async {
    await stopSync();
    if (_isUnlocked) {
      _isUnlocked = false;
      await _ffi?.lock();
    }
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) {
    if (amount != _feeQuoteAmount) {
      _feeQuoteAmount = amount;
      unawaited(updateEstimatedFeesParams(priority));
    }
    return _estimatedFees[priority] ?? 0;
  }

  /// Quotes [priority] for the last amount asked of [calculateEstimatedFee]; an amount
  /// covering the whole balance is quoted as a send-all.
  @override
  Future<void> updateEstimatedFeesParams(TransactionPriority? priority) async {
    final ffi = _ffi;
    if (ffi == null || _currentNode == null || priority == null) return;

    final amount = _feeQuoteAmount ?? 0;
    try {
      if (amount > 0 && amount >= balance[CryptoCurrency.xtm]!.available.amount.toInt()) {
        final quote = await ffi.estimateSendAllFee(recipientAddress: address);
        _estimatedFees[priority] = quote.fee.toInt();
      } else {
        final quote = await ffi.estimateFee(
          amount: BigInt.from(amount),
          numOutputs: 1,
          priority: _feePriority(priority),
          baseNodeUrl: _nodeUrl,
        );
        _estimatedFees[priority] = quote.estimatedFee.toInt();
      }
    } catch (e) {
      printV('Minotari fee estimate failed: $e');
    }
  }

  FeePriority _feePriority(TransactionPriority? priority) => switch (priority) {
        MinotariTransactionPriority.slow => FeePriority.slow,
        MinotariTransactionPriority.fast => FeePriority.fast,
        _ => FeePriority.medium,
      };

  @override
  Future<bool> checkNodeHealth() async {
    final node = _currentNode;
    if (node == null) return false;
    await MinotariFfi.ensureRustLibInitialized();
    return base_node.checkNodeHealth(baseUrl: node.uri.toString());
  }

  /// The node's chain tip height.
  Future<int> currentHeight() async {
    final tip = await base_node.getTipInfo(baseUrl: _nodeUrl);
    if (tip == null) throw Exception('The node reports no chain tip yet.');
    return tip.bestBlockHeight.toInt();
  }

  /// The mnemonic, read from the wallet database for the seed page; null for wallets
  /// imported from keys.
  Future<String?> loadSeed() async {
    try {
      return (await _requireFfi.seedWords(passphrase: _dbPassphrase)).join(' ');
    } catch (e) {
      printV('Minotari seed unavailable: $e');
      return null;
    }
  }

  @override
  Future<Map<String, MinotariTransactionInfo>> fetchTransactions() async {
    final txDtos = await _ffi?.getTransactions();
    if (txDtos == null) return {};

    return {for (final txDto in txDtos) txDto.id: _dtoToTransactionInfo(txDto)};
  }

  @override
  Future<String> signMessage(String message, {String? address}) => _requireFfi.signMessage(message);

  @override
  Future<bool> verifyMessage(String message, String signature, {String? address}) async {
    await MinotariFfi.ensureRustLibInitialized();
    return MinotariFfi.verifyMessage(
      message: message,
      signature: signature,
      address: address ?? this.address,
    );
  }

  @override
  Future<void> updateBalance() async {
    try {
      final balanceData = await _ffi?.getBalance();
      if (balanceData != null) {
        balance[CryptoCurrency.xtm] = MinotariBalance(
          available: balanceData.available.toInt(),
          pendingIncoming: balanceData.unconfirmed.toInt(),
          pendingOutgoing: balanceData.locked.toInt(),
        );
      }
    } catch (e) {
      printV('Error updating balance: $e');
    }
  }

  Future<void> updateTransactions() async {
    try {
      if (_isTransactionUpdating) return;

      _isTransactionUpdating = true;

      final transactions = await fetchTransactions();
      transactionHistory.transactions.addAll(transactions);
      await transactionHistory.save();

      _isTransactionUpdating = false;
    } catch (e) {
      _isTransactionUpdating = false;
      printV('Error updating transactions: $e');
    }
  }

  MinotariTransactionInfo _dtoToTransactionInfo(DisplayedTransactionDto txDto) {
    final direction = txDto.direction == DisplayedTransactionDirection.incoming
        ? TransactionDirection.incoming
        : TransactionDirection.outgoing;

    final isPending = txDto.status != DisplayedTransactionStatus.confirmed;
    final date = DateTime.tryParse(txDto.blockchain.timestamp) ?? DateTime.now();
    final fee = txDto.fee?.amount;

    final txInfo = MinotariTransactionInfo(
      id: txDto.id,
      amount: Money(txDto.amount, CryptoCurrency.xtm),
      date: date,
      direction: direction,
      isPending: isPending,
      fee: fee == null ? null : Money(fee, CryptoCurrency.xtm),
      height: txDto.blockchain.blockHeight.toInt(),
      confirmations: txDto.blockchain.confirmations.toInt(),
      payrefs: txDto.payrefs,
    );

    txInfo.additionalInfo['source'] = txDto.source.name;
    txInfo.additionalInfo['status'] = txDto.status.name;
    txInfo.additionalInfo['amountDisplay'] = txDto.amountDisplay;

    if (txDto.message != null && txDto.message!.isNotEmpty) {
      txInfo.additionalInfo['message'] = txDto.message!;
    }

    if (txDto.fee != null) {
      txInfo.additionalInfo['feeDisplay'] = txDto.fee!.amountDisplay;
    }

    if (txDto.counterparty != null) {
      txInfo.additionalInfo['counterpartyAddress'] = txDto.counterparty!.address;
      txInfo.additionalInfo['counterpartyEmoji'] = txDto.counterparty!.addressEmoji;
    }

    return txInfo;
  }

  void _processNewTransactions(List<DisplayedTransactionDto> transactions) {
    for (final txDto in transactions) {
      transactionHistory.transactions[txDto.id] = _dtoToTransactionInfo(txDto);
    }
  }
}
