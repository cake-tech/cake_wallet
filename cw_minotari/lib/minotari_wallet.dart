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
import 'package:cw_core/utils/proxy_wrapper.dart';
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
import 'package:cw_minotari/src/rust/api/scanner.dart';
import 'package:cw_minotari/src/rust/api/transactions.dart';
import 'package:mobx/mobx.dart';
import 'package:path/path.dart' as p;

part 'minotari_wallet.g.dart';

/// Blocks per day at Tari's 2-minute target block time.
const _blocksPerDay = 720;

/// A start height at or below the real height of the block whose offline [estimate] is given.
///
/// cw's offline estimate counts target-time blocks since genesis (so [estimate] / 720 is days
/// since genesis). Real blocks run slower, so it runs high, and the lead grows: about 2,000
/// blocks on 2026-01-01 and 12,240 on 2026-09-01, roughly 42 more a day.
// shortcut: the margin extrapolates that growth: 2 days plus 84 blocks per day since genesis
// (twice the growth rate), which stays at least twice the lead while blocks keep that pace.
// Revisit if block times change or cw's estimate gets a newer anchor.
int minotariSafeStartHeight(int estimate) =>
    max(0, estimate - (2 * _blocksPerDay + estimate * 84 ~/ _blocksPerDay));

/// A safe restore or rescan start for [date], without asking a node.
Future<int> minotariHeightByDate(DateTime date) async {
  await MinotariFfi.ensureRustLibInitialized();
  final estimate = estimateHeightAtTime(
    network: MinotariFfi.network,
    epochSecs: BigInt.from(date.millisecondsSinceEpoch ~/ 1000),
  ).toInt();
  return minotariSafeStartHeight(estimate);
}

/// A random wallet-database passphrase; it lives only in the encrypted .keys file.
String randomMinotariPassphrase() {
  const allowedChars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%-=_+[]{}|;:,.<>?';
  final random = Random.secure();
  return List.generate(32, (_) => allowedChars[random.nextInt(allowedChars.length)]).join();
}

/// The base URL for a Minotari node call. cw's HTTP client can't use the app's built-in Tor,
/// so with Tor running ([torOn]) nothing is sent rather than leak it over clearnet; and node
/// traffic, which carries the wallet's own transactions, must be TLS and direct.
String minotariNodeUrl(Node? node, {required bool torOn}) {
  if (node == null) throw Exception('No node connected. Call connectToNode first.');
  if (torOn) throw const TorUnsupportedException('Minotari cannot use Tor yet.');
  if (!node.isSSL) throw Exception('Minotari nodes must use SSL (https).');
  // cw's HTTP client has no proxy: a node's SOCKS proxy would be silently bypassed.
  if (node.useSocksProxy) throw Exception('Minotari nodes cannot use a SOCKS proxy yet.');
  return node.uri.toString();
}

/// Runs [action], then [restore] whether or not it failed. A failing [restore] is logged and
/// never replaces [action]'s result or error.
Future<T> minotariThenRestore<T>(
  Future<T> Function() action,
  Future<void> Function() restore,
) async {
  try {
    return await action();
  } finally {
    try {
      await restore();
    } catch (e) {
      printV('Minotari restore after an action failed: $e');
    }
  }
}

/// Runs [work] once everything already in [queue] has run. A failure is logged and goes no
/// further, so it can't block later work or fail whoever awaits it (a send that has already
/// broadcast must not report failure because a history refresh did).
Future<void> runAfterMinotariQueue(Future<void> queue, FutureOr<void> Function() work) =>
    queue.then((_) async {
      try {
        await work();
      } catch (e) {
        printV('Error updating Minotari transactions: $e');
      }
    });

/// Writes [data] to the .keys file at [keysPath] and to its backup, each through a temp file
/// and a rename, so a failure or crash leaves every file either as it was or complete.
/// Errors propagate.
Future<void> writeMinotariKeysFiles(
  EncryptionFileUtils encryptionFileUtils, {
  required String keysPath,
  required String password,
  required String data,
}) async {
  final paths = [keysPath, '$keysPath.backup'];
  try {
    for (final path in paths) {
      await encryptionFileUtils.write(path: '$path.tmp', password: password, data: data);
    }
  } catch (_) {
    for (final path in paths) {
      final temp = File('$path.tmp');
      if (temp.existsSync()) await temp.delete();
    }
    rethrow;
  }
  for (final path in paths) {
    await File('$path.tmp').rename(path);
  }
}

/// The cw fee priority for a Cake priority (Medium when none is chosen).
FeePriority minotariFeePriority(TransactionPriority? priority) => switch (priority) {
      MinotariTransactionPriority.slow => FeePriority.slow,
      MinotariTransactionPriority.fast => FeePriority.fast,
      _ => FeePriority.medium,
    };

/// What a send of [amount] at [priority] pays out and costs, and the rate it is built at.
///
/// A normal send is built at the rate of its [estimate]. A send-all asks the node for
/// [priority]'s rate and quotes the sweep at it with [estimateSendAll].
Future<({int amount, int fee, BigInt feePerGram})> quoteMinotariSend({
  required TransactionPriority? priority,
  required bool sendAll,
  required int amount,
  required Future<FeeEstimate> Function(FeePriority priority) estimate,
  required Future<BigInt> Function(FeePriority priority) feePerGram,
  required Future<SendAllFeeEstimate> Function(BigInt feePerGram) estimateSendAll,
}) async {
  final feePriority = minotariFeePriority(priority);
  if (sendAll) {
    final rate = await feePerGram(feePriority);
    final quote = await estimateSendAll(rate);
    return (amount: quote.amountAfterFee.toInt(), fee: quote.fee.toInt(), feePerGram: rate);
  }
  final quote = await estimate(feePriority);
  return (amount: amount, fee: quote.estimatedFee.toInt(), feePerGram: quote.feePerGram);
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

    // No payment id: Cake's note is private, and an address that carries one sends it itself.
    return SendRecipient(address: address, amount: amount);
  }).toList();
}

/// Whether cw refused a background scan because the app is scanning the wallet itself.
/// Matches cw's error text, which is part of its frozen API.
bool minotariForegroundScanActive(Object error) =>
    error.toString().contains('A foreground scan of this wallet is already running');

/// Blocks a caught-up scan may trail the tip by and still count as synced.
const _syncedTipGap = 2;

/// The sync status a scan event moves the wallet to, or null when it leaves it unchanged.
///
/// A scan is first synced when it has caught up (Waiting or Completed); after that
/// ([caughtUp]) it stays synced while it trails the tip by at most [_syncedTipGap] blocks.
/// A scan that was stopped or replaced leaves the wallet not connected rather than synced
/// or failed. A [background] sync slot instead ends paused when it was stopped or ran out
/// of time, and handled by the foreground when the app took the wallet over (or already
/// had it), so the background loop moves on without retrying or calling it synced.
SyncStatus? minotariSyncStatusFor(
  ScanEventDto event, {
  required int startHeight,
  required bool caughtUp,
  bool background = false,
}) =>
    switch (event) {
      ScanEventDto_Started() => SyncronizingSyncStatus(),
      ScanEventDto_Progress(:final currentHeight, :final tipHeight)
          when caughtUp && tipHeight - currentHeight <= BigInt.from(_syncedTipGap) =>
        SyncedSyncStatus(),
      ScanEventDto_Progress(:final currentHeight, :final tipHeight) =>
        SyncingSyncStatus.fromHeightValues(tipHeight.toInt(), startHeight, currentHeight.toInt()),
      ScanEventDto_Waiting() || ScanEventDto_Completed() => SyncedSyncStatus(),
      ScanEventDto_Cancelled() || ScanEventDto_BudgetExhausted() when background =>
        PausedSyncStatus(),
      ScanEventDto_Superseded() when background => HandledByForegroundSyncStatus(),
      ScanEventDto_Error(:final field0) when background && minotariForegroundScanActive(field0) =>
        HandledByForegroundSyncStatus(),
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
        walletAddresses = MinotariWalletAddresses(walletInfo),
        syncStatus = NotConnectedSyncStatus(),
        super(walletInfo, derivationInfo) {
    transactionHistory = MinotariTransactionHistory();
  }

  MinotariFfi? _ffi;
  bool _isUnlocked = false;
  Future<void> _transactionsReload = Future.value();
  bool _reloadTransactionsWhenSynced = false;
  Node? _currentNode;

  /// The scan this wallet started last; events of earlier scans are ignored.
  ScanHandle? _scanHandle;
  ScanPriority _scanPriority = ScanPriority.foreground;
  int _scanStartHeight = 0;
  bool _scanCaughtUp = false;

  /// Set while this wallet's scan runs and the app wants it, so a foreground scan another
  /// engine replaced (Android background sync) is started again. Cleared when the scan is
  /// stopped or fails.
  bool _keepScanning = false;

  bool get isScanning => _keepScanning;

  /// The latest quote per priority: a send screen asking again for the same amount within
  /// [_feeQuoteLifetime] costs no node call, and nothing is quoted unless one asks.
  final Map<TransactionPriority, ({int amount, bool sendAll, int fee, DateTime quotedAt})>
      _feeQuotes = {};
  static const _feeQuoteLifetime = Duration(minutes: 1);

  /// The latest quote request per priority; an older one finishing later is not cached.
  final Map<TransactionPriority, int> _feeQuoteRequests = {};
  final Map<(TransactionPriority, int, bool), Future<int>> _feeQuotesInFlight = {};

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

  /// Every node call goes through here. Tor counts once the user turns it on, not only once
  /// it runs: while it starts, or after it failed to, nothing may go out over clearnet.
  String get _nodeUrl => minotariNodeUrl(_currentNode, torOn: CakeTor.requestedOrStarted);

  Future<void> init() async {
    // Every Minotari wallet is mainnet; refuse anything else rather than open it as mainnet.
    if (walletInfo.network != MinotariFfi.network.name) {
      throw WalletOpenException('Minotari supports mainnet only, not ${walletInfo.network}.');
    }

    final dbPath = p.join(await pathForWalletTypeDir(type: walletInfo.type), 'wallet.db');
    final ffi = MinotariFfi(dataPath: dbPath, walletName: walletInfo.name);
    await ffi.unlock(passphrase: _dbPassphrase);
    try {
      await walletAddresses.setAddress(await ffi.getAddress());
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
    // The old node's scan would otherwise keep reporting synced over a failed connection;
    // forgetting its handle keeps its late Cancelled from overwriting the status set here.
    await stopSync();
    _scanHandle = null;
    syncStatus = ConnectingSyncStatus();
    _currentNode = node;

    // With Tor on, say why rather than just failing.
    if (CakeTor.requestedOrStarted) {
      syncStatus =
          FailedSyncStatus(cause: const TorUnsupportedException('Minotari cannot use Tor yet.'));
      return;
    }

    // Never throws: an unreachable node or a transport error is just unhealthy.
    if (!await checkNodeHealth()) {
      syncStatus = FailedSyncStatus();
      return;
    }

    syncStatus = ConnectedSyncStatus();
  }

  @override
  Future<void> startSync() => _scan();

  /// One budgeted pass at background priority. It never replaces the app's own scan (cw
  /// refuses it) and the app's scan replaces it; both end as [HandledByForegroundSyncStatus].
  /// The DB session was opened when the wallet loaded; [close] stops this scan and locks it.
  @override
  Future<void> startBackgroundSync() => _scan(priority: ScanPriority.background);

  @override
  Future<void> rescan({required int height}) {
    // The rescan rolls the history back; reload all of it once the scan has caught up.
    _reloadTransactionsWhenSynced = true;
    return _scan(fromHeight: height);
  }

  /// Starts a continuous scan, replacing this wallet's previous one. Errors (including
  /// transport errors) end as [FailedSyncStatus]; the connection check reconnects and
  /// starts the scan again.
  Future<void> _scan({
    int? fromHeight,
    ScanPriority priority = ScanPriority.foreground,
  }) async {
    try {
      syncStatus = AttemptingSyncStatus();
      final ffi = _requireFfi;
      final handle = ffi.createScanHandle();
      _scanHandle = handle;
      _scanPriority = priority;
      _scanCaughtUp = false;
      _keepScanning = true;
      ffi
          .scan(handle: handle, baseNodeUrl: _nodeUrl, priority: priority, fromHeight: fromHeight)
          .listen(
        (event) {
          if (_scanHandle == handle) _onScanEvent(event);
        },
        onError: (Object error) {
          if (_scanHandle != handle) return;
          printV('Minotari scan failed: $error');
          _keepScanning = false;
          syncStatus = priority == ScanPriority.background && minotariForegroundScanActive(error)
              ? HandledByForegroundSyncStatus()
              : FailedSyncStatus();
        },
      );
    } catch (e) {
      printV('Minotari scan could not start: $e');
      _keepScanning = false;
      syncStatus = FailedSyncStatus(cause: e);
    }
  }

  void _onScanEvent(ScanEventDto event) {
    switch (event) {
      case ScanEventDto_Started(:final fromHeight):
        _scanStartHeight = fromHeight.toInt();
      case ScanEventDto_Waiting() || ScanEventDto_Completed():
        _scanCaughtUp = true;
        unawaited(updateBalance());
        if (_reloadTransactionsWhenSynced) {
          _reloadTransactionsWhenSynced = false;
          unawaited(updateTransactions());
        }
      case ScanEventDto_TransactionsReady(:final field0):
        _processNewTransactions(field0.transactions);
        unawaited(updateBalance());
      case ScanEventDto_TransactionsUpdated(:final field0):
        _processNewTransactions(field0.updatedTransactions);
        unawaited(updateBalance());
      case ScanEventDto_ReorgDetected():
        unawaited(updateTransactions());
        unawaited(updateBalance());
      case ScanEventDto_Superseded() when _keepScanning && _scanPriority == ScanPriority.foreground:
        // Another engine's scan (Android background sync) replaced the app's; take it back.
        unawaited(_scan());
        return;
      case ScanEventDto_Error(:final field0):
        printV('Minotari scan error: $field0');
        _keepScanning = false;
      default:
        break;
    }

    final status = minotariSyncStatusFor(
      event,
      startHeight: _scanStartHeight,
      caughtUp: _scanCaughtUp,
      background: _scanPriority == ScanPriority.background,
    );
    // Re-reporting synced would make every listener (the send screen's fee) run again.
    if (status != null && !(status is SyncedSyncStatus && syncStatus is SyncedSyncStatus)) {
      syncStatus = status;
    }
  }

  @override
  Future<void> stopSync() async {
    _keepScanning = false;
    final handle = _scanHandle;
    if (handle != null) await _ffi?.stopScan(handle);
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    if (!canSend()) {
      throw TransactionGenerationException('This wallet is view only and cannot send.');
    }
    final creds = credentials as MinotariTransactionCredentials;
    final ffi = _requireFfi;
    final nodeUrl = _nodeUrl;
    final recipients = minotariRecipients(creds.outputs);
    final sendAll = creds.outputs.first.sendAll;

    final total = recipients.fold(0, (sum, recipient) => sum + recipient.amount.toInt());
    final (:amount, :fee, :feePerGram) = await quoteMinotariSend(
      priority: creds.priority,
      sendAll: sendAll,
      amount: total,
      estimate: (priority) => ffi.estimateFee(
        amount: BigInt.from(total),
        numOutputs: recipients.length,
        priority: priority,
        baseNodeUrl: nodeUrl,
      ),
      feePerGram: (priority) => ffi.feePerGram(priority: priority, baseNodeUrl: nodeUrl),
      estimateSendAll: (feePerGram) => ffi.estimateSendAllFee(
        recipientAddress: recipients.single.address,
        feePerGram: feePerGram,
      ),
    );

    Future<void> send() async {
      var broadcasted = false;
      await for (final event in ffi.sendTransaction(
        recipients: recipients,
        sendAll: sendAll,
        // Checked again at broadcast: Tor may have been turned on since the quote.
        baseNodeUrl: _nodeUrl,
        feePerGram: feePerGram,
      )) {
        if (event.stage == TransactionStage.broadcasted) broadcasted = true;
      }
      if (!broadcasted) throw Exception('Transaction stream ended before the broadcast.');

      // Recorded as pending; the scanner's TransactionsUpdated confirms it. Neither refresh
      // throws, so a failed refresh can't report a broadcast send as failed.
      await updateBalance();
      await updateTransactions();
    }

    return PendingMinotariTransaction(
      amount: Money.fromInt(amount, CryptoCurrency.xtm),
      fee: Money.fromInt(fee, CryptoCurrency.xtm),
      send: send,
      isFeeEstimate: !sendAll,
    );
  }

  // Wallet state lives in the cw database; the .keys files are written by [writeKeysFiles].
  @override
  Future<void> save() async {}

  /// Writes the .keys files under [password]; errors propagate.
  ///
  /// [spendPrivateKeyHex] is kept only for wallets imported from a spend private key: cw has
  /// no way to export it, so the .keys file is the user's only backup of it.
  Future<void> writeKeysFiles(String password, {String? spendPrivateKeyHex}) async =>
      writeMinotariKeysFiles(
        encryptionFileUtils,
        keysPath: await makeKeysFilePath(),
        password: password,
        data: WalletKeysData(
          privateKey: spendPrivateKeyHex,
          passphrase: _dbPassphrase,
          scanSecret: viewPrivateKeyHex,
          spendPubkey: spendPublicKeyHex,
        ).toJSON(),
      );

  /// The spend private key of a wallet imported from it, read from the .keys file for the
  /// keys page; the wallet never keeps it.
  Future<String?> loadSpendPrivateKey() async => (await WalletKeysFile.readKeysFile(
        walletInfo.name,
        walletInfo.type,
        _password,
        encryptionFileUtils,
      ))
          .privateKey;

  /// Re-encrypts the .keys files under [password]. The database passphrase is random and
  /// stored only in those files, so it is not rotated: rotating would leave a window where the
  /// database and the files disagree and the wallet can't be unlocked.
  @override
  Future<void> changePassword(String password) async {
    await writeKeysFiles(password, spendPrivateKeyHex: await loadSpendPrivateKey());
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

  /// The latest quote for one output of [amount], or 0; [estimatedFeeFor] fetches it.
  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) {
    final quote = _feeQuotes[priority];
    return quote != null && !quote.sendAll && quote.amount == (amount ?? 0) ? quote.fee : 0;
  }

  /// Asks the node for the fee of one output of [amount], or quotes a send-all.
  @override
  Future<int> estimatedFeeFor(TransactionPriority priority, int? amount,
      {bool sendAll = false}) async {
    final ffi = _ffi;
    final quote = _feeQuotes[priority];
    final requested = sendAll ? 0 : amount ?? 0;
    if (ffi == null || _currentNode == null) return 0;
    if (quote != null &&
        quote.sendAll == sendAll &&
        quote.amount == requested &&
        DateTime.now().difference(quote.quotedAt) < _feeQuoteLifetime) {
      return quote.fee;
    }

    // Identical requests at once (one per send-screen output) share a single node call.
    final key = (priority, requested, sendAll);
    return _feeQuotesInFlight[key] ??=
        _fetchFeeQuote(ffi, priority, requested, sendAll).catchError((Object e) {
      printV('Minotari fee estimate failed: $e');
      return calculateEstimatedFee(priority, amount);
    }).whenComplete(() => _feeQuotesInFlight.remove(key));
  }

  Future<int> _fetchFeeQuote(
      MinotariFfi ffi, TransactionPriority priority, int amount, bool sendAll) async {
    final request = (_feeQuoteRequests[priority] ?? 0) + 1;
    _feeQuoteRequests[priority] = request;
    final int fee;
    if (sendAll) {
      final feePerGram =
          await ffi.feePerGram(priority: minotariFeePriority(priority), baseNodeUrl: _nodeUrl);
      fee = (await ffi.estimateSendAllFee(recipientAddress: address, feePerGram: feePerGram))
          .fee
          .toInt();
    } else {
      fee = (await ffi.estimateFee(
        amount: BigInt.from(amount),
        numOutputs: 1,
        priority: minotariFeePriority(priority),
        baseNodeUrl: _nodeUrl,
      ))
          .estimatedFee
          .toInt();
    }
    if (_feeQuoteRequests[priority] == request) {
      _feeQuotes[priority] = (amount: amount, sendAll: sendAll, fee: fee, quotedAt: DateTime.now());
    }
    return fee;
  }

  @override
  Future<bool> checkNodeHealth() async {
    final String baseUrl;
    try {
      baseUrl = _nodeUrl;
    } catch (e) {
      printV('Minotari node not usable: $e');
      return false;
    }
    await MinotariFfi.ensureRustLibInitialized();
    return base_node.checkNodeHealth(baseUrl: baseUrl);
  }

  /// Gives up a pending send the node keeps refusing and releases its inputs. cw stops this
  /// wallet's scan before it decides, so whether it abandons or refuses, the scan is started
  /// again and the balance and history reloaded. Returns cw's note on what abandoning does
  /// not do.
  Future<String> abandonSend(String transactionId) => minotariThenRestore(
        () => _requireFfi.abandonSend(passphrase: _dbPassphrase, transactionId: transactionId),
        () async {
          if (_keepScanning) unawaited(_scan());
          await updateBalance();
          await updateTransactions();
        },
      );

  /// The mnemonic, read from the wallet database for the seed page; null for wallets
  /// imported from keys (only those keep their keys in the .keys file).
  Future<String?> loadSeed() async {
    if (viewPrivateKeyHex != null) return null;
    return (await _requireFfi.seedWords(passphrase: _dbPassphrase)).join(' ');
  }

  static const _transactionsPageSize = 100;

  /// The whole history, read page by page.
  @override
  Future<Map<String, MinotariTransactionInfo>> fetchTransactions() async {
    final ffi = _ffi;
    if (ffi == null) return {};

    final result = <String, MinotariTransactionInfo>{};
    for (var offset = 0;; offset += _transactionsPageSize) {
      final page = await ffi.getTransactions(limit: _transactionsPageSize, offset: offset);
      for (final txDto in page) {
        result[txDto.id] = _dtoToTransactionInfo(txDto);
      }
      if (page.length < _transactionsPageSize) return result;
    }
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

  /// Replaces the history with the database's. Reloads queue behind a running one, so the
  /// last caller always sees a reload that started after its request.
  Future<void> updateTransactions() =>
      _transactionsReload = runAfterMinotariQueue(_transactionsReload, () async {
        final transactions = await fetchTransactions();
        runInAction(() {
          transactionHistory.transactions.clear();
          transactionHistory.transactions.addAll(transactions);
        });
      });

  MinotariTransactionInfo _dtoToTransactionInfo(DisplayedTransactionDto txDto) {
    final direction = txDto.direction == DisplayedTransactionDirection.incoming
        ? TransactionDirection.incoming
        : TransactionDirection.outgoing;

    // Only sends still on their way; a rejected (or abandoned), cancelled or reorganized one
    // is not pending, and shows its own status instead.
    final isPending = const {
      DisplayedTransactionStatus.pending,
      DisplayedTransactionStatus.unconfirmed,
      DisplayedTransactionStatus.locked,
    }.contains(txDto.status);
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

  /// Queued behind a running full reload, so its older snapshot can't overwrite these.
  void _processNewTransactions(List<DisplayedTransactionDto> transactions) {
    _transactionsReload = runAfterMinotariQueue(
      _transactionsReload,
      () => runInAction(() {
        for (final txDto in transactions) {
          transactionHistory.transactions[txDto.id] = _dtoToTransactionInfo(txDto);
        }
      }),
    );
  }
}
