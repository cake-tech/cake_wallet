import 'package:cw_core/hardware/hardware_signing_stage.dart';
import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:cw_zcash/src/zcash_ledger_service.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/get_height_by_date_zec.dart';
import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:cw_zcash/cw_zcash.dart';
import 'package:cw_zcash/src/util/crc32.dart';
import 'package:cw_zcash/src/zcash_mempool.dart';
import 'package:cw_zcash/src/zcash_taddress_rotation.dart';
import 'package:cw_zcash/src/zcash_wallet_addresses.dart';
import 'package:cw_zcash/src/zcash_network.dart';
import 'package:cw_zcash/src/zkool_compat.dart';
import 'package:cw_zcash/src/zkooltx.dart';
import 'package:mobx/mobx.dart';
import 'package:mutex/mutex.dart';
import 'package:zkool/src/rust/api/account.dart' as zkool_account;
import 'package:zkool/src/rust/api/coin.dart' as zkool_coin;
import 'package:zkool/src/rust/api/mempool.dart' as zkool_mempool;
import 'package:zkool/src/rust/api/sync.dart' as zkool_sync;
import 'package:zkool/src/rust/api/pay.dart' as zkool_pay;
import 'package:zkool/src/rust/api/migrate.dart' as zkool_migrate;
import 'package:zkool/src/rust/api/network.dart' as zkool_network;
import 'package:zkool/src/rust/pay.dart' as zkool_paydart;
import 'package:zkool/src/rust/frb_generated.dart' as zkool_frb;

part 'zcash_wallet.g.dart';

class ZcashWallet = ZcashWalletBase with _$ZcashWallet;

abstract class ZcashWalletBase
    extends WalletBase<ZcashBalance, ZcashTransactionHistory, ZcashTransactionInfo>
    with Store {
  ZcashWalletBase(super.walletInfo, super.derivationInfo, {required this.accountId}) {
    transactionHistory = ZcashTransactionHistory();
    walletsByAccountId[accountId] = this;
  }

  static final Map<int, ZcashWalletBase> walletsByAccountId = {};

  static Future<void> refreshWalletForAccount(final int accountId) async {
    final wallet = walletsByAccountId[accountId];
    if (wallet == null) {
      return;
    }
    await wallet.updateTransactions();
    await wallet.updateBalance();
  }

  int accountId;

  /// Set while a Ledger is connected. A wallet paired with one holds no
  /// spending key, so every transaction is signed through this service.
  HardwareWalletService? hardwareWalletService;

  bool get isLedgerWallet => walletInfo.hardwareWalletType == HardwareWalletType.ledger;

  /// `accounts.hw` code the backend uses for the Official Ledger app.
  static const int zkoolHwOfficialLedger = 2;

  /// Floor under which a manual shield is not offered, same as auto-shield.
  static const int _manualShieldMinSweep = _autoShieldMinSweep;

  /// Set once a manual shield is broadcast: the swept notes still read as
  /// unspent until it confirms, so the balance and the shield card stop
  /// counting them meanwhile.
  bool _shieldSweepPending = false;
  String? _pendingShieldTxId;

  final Map<String, BigInt> _pendingOutgoingAmounts = {};

  void rememberPendingOutgoingAmount(final String txId, final Money amount) {
    if (amount.isZero) {
      return;
    }
    _pendingOutgoingAmounts[ZcashWalletService.normalizeTxId(txId)] = amount.amount;
  }

  @override
  @observable
  SyncStatus syncStatus = NotConnectedSyncStatus();

  @override
  ObservableMap<CryptoCurrency, ZcashBalance> balance = ObservableMap.of({
    CryptoCurrency.zec: ZcashBalance.zero(),
  });

  @observable
  bool _orchardMigratable = false;

  static const int _autoShieldMinSweep = 30000;

  // zkool's migrate::MIN_SD.
  static const int _ironwoodMigrateMinNote = 500000;

  static int _minSweepThreshold({required final bool ironwood}) =>
      ironwood ? _ironwoodMigrateMinNote : _autoShieldMinSweep;

  Money _feeFromTxPlan(
    final zkool_pay.PcztPackage txPlan,
    final TransactionPriority priority,
    final int tryReduceFeeAmount, {
    final zkool_coin.Coin? coin,
  }) {
    try {
      return Money(zkool_pay.toPlan(package: txPlan, c: coin ?? c).fee, currency);
    } catch (_) {
      return Money.fromInt(
        tryReduceFeeAmount != 0
            ? tryReduceFeeAmount
            : internalCalculateEstimatedFee(priority, null),
        currency,
      );
    }
  }

  static int internalCalculateEstimatedFee(final TransactionPriority priority, final int? amount) {
    const baseFee = 10000;
    switch (priority) {
      case MoneroTransactionPriority.slow:
      case MoneroTransactionPriority.automatic:
        return baseFee;
      case MoneroTransactionPriority.medium:
        return baseFee * 2;
      case MoneroTransactionPriority.fast:
        return baseFee * 4;
      case MoneroTransactionPriority.fastest:
        return baseFee * 10;
    }
    ;
    return internalCalculateEstimatedFee(MoneroTransactionPriority.automatic, amount);
  }

  @override
  int calculateEstimatedFee(final TransactionPriority priority, final int? amount) {
    return internalCalculateEstimatedFee(priority, amount);
  }

  @override
  Future<void> changePassword(final String password) async {
    // throw UnimplementedError();
  }

  static bool isNodeWorking = true;

  @override
  Future<bool> checkNodeHealth() {
    return Future.value(isNodeWorking);
  }

  @override
  Future<void> close({final bool shouldCleanup = false}) async {
    _syncLoopRunning = false;
    walletsByAccountId.remove(accountId);
  }

  Node? lastNode;
  @override
  @action
  Future<void> connectToNode({required final Node node}) async {
    lastNode = node;
    printV("connecting to node: ${node.uriRaw}");
    syncStatus = ConnectingSyncStatus();
    try {
      String lwdUrl = node.uriRaw;
      if (!lwdUrl.startsWith('http://') && !lwdUrl.startsWith('https://')) {
        final protocol = node.useSSL == true ? 'https://' : 'http://';
        lwdUrl = '$protocol$lwdUrl';
      }
      printV("Setting LWD URL to: $lwdUrl");
      c = c.setLwd(url: lwdUrl, serverType: 0);
      syncStatus = ConnectedSyncStatus();
      unawaited(ZcashMempoolService.instance.ensureRunning(c));
      unawaited(_updateIronwoodActive());
      _ensureSyncLoopRunning();
      unawaited(_refreshSyncStatus());
      unawaited(_oneshotSync());
    } catch (e) {
      printV("Connection error: $e");
      syncStatus = FailedSyncStatus(error: e.toString());
      rethrow;
    }
  }

  bool _syncLoopRunning = false;

  void _ensureSyncLoopRunning() {
    if (_syncLoopRunning) {
      return;
    }
    _syncLoopRunning = true;
    unawaited(_runSyncLoop());
  }

  static const _syncedPollInterval = Duration(seconds: 5);
  static const _activePollInterval = Duration(seconds: 1);

  Future<void> _runSyncLoop() async {
    var pollInterval = _activePollInterval;
    while (_syncLoopRunning) {
      await Future.delayed(pollInterval);
      try {
        final alreadySynced = await _oneshotSync();
        pollInterval = alreadySynced ? _syncedPollInterval : _activePollInterval;
      } catch (e) {
        printV("zcash sync failed: $e");
        pollInterval = _activePollInterval;
      }
    }
  }

  int _syncCheckpointHeight = 0;

  bool get isSyncing {
    return _isSyncing;
  }

  set isSyncing(final bool value) {
    _isSyncing = value;
  }

  bool _isSyncing = false;

  static int oneshotSyncCount = 0;

  Future<int> _getLowestSyncHeight() async {
    final accounts = await zkool_account.listAccounts(c: c);
    var lowest = await _getWalletDbHeight();
    for (final acc in accounts) {
      if (acc.id == accountId) continue;
      c = await c.setAccount(account: acc.id);
      lowest = min(lowest, await _getWalletDbHeight());
    }
    c = await c.setAccount(account: accountId);
    return lowest;
  }

  Future<bool> _anyAccountNeedsSync(final int currentHeight) =>
      withSharedCoinLock(() => _anyAccountNeedsSyncUnlocked(currentHeight));

  Future<bool> _anyAccountNeedsSyncUnlocked(final int currentHeight) async {
    final accounts = await zkool_account.listAccounts(c: c);
    for (final acc in accounts) {
      c = await c.setAccount(account: acc.id);
      if (currentHeight > await _getWalletDbHeight()) {
        c = await c.setAccount(account: accountId);
        return true;
      }
    }
    c = await c.setAccount(account: accountId);
    return false;
  }

  @action
  void _applySyncProgress(final int currentHeight, final int walletHeight) {
    final blocksLeft = (currentHeight - walletHeight).clamp(0, currentHeight);
    _syncCheckpointHeight = walletHeight;
    if (blocksLeft <= 0) {
      syncStatus = _isSyncing ? SyncingSyncStatus(1, 0.999) : SyncedSyncStatus();
      return;
    }
    final ptc = currentHeight > 0 ? (walletHeight / currentHeight).clamp(0.0, 1.0) : 0.0;
    syncStatus = SyncingSyncStatus(blocksLeft, ptc);
  }

  void _broadcastSyncProgress(final int currentHeight, final int walletHeight) {
    runInAction(() {
      for (final wallet in walletsByAccountId.values) {
        wallet._applySyncProgress(currentHeight, walletHeight);
      }
    });
  }

  Future<int> _getWalletDbHeight() async {
    try {
      return (await zkool_sync.getDbHeight(c: c)).height;
    } catch (_) {
      final accounts = await zkool_account.listAccounts(c: c);
      final account = accounts.where((final a) => a.id == accountId).firstOrNull;
      if (account != null) {
        return account.height;
      }
      rethrow;
    }
  }

  void _onSyncCheckpoint(final int currentHeight, final int checkpointHeight) {
    final height = checkpointHeight > _syncCheckpointHeight
        ? checkpointHeight
        : _syncCheckpointHeight;
    _broadcastSyncProgress(currentHeight, height);
  }

  @action
  Future<void> _refreshSyncStatus() async {
    try {
      await withSharedCoinLock(() async {
        c = await c.setAccount(account: accountId);
        final currentHeight = await zkool_network.getCurrentHeight(c: c);
        final walletDbHeight = await _getWalletDbHeight();
        _broadcastSyncProgress(currentHeight, walletDbHeight);
      });
    } catch (e) {
      printV("refresh sync status: $e");
    }
  }

  @action
  Future<bool> _oneshotSync() async {
    try {
      if (isSyncing) {
        return syncStatus is SyncedSyncStatus;
      }
      isSyncing = true;
      late final int currentHeight;
      late final int walletDbHeight;
      await withSharedCoinLock(() async {
        c = await c.setAccount(account: accountId);
        currentHeight = await zkool_network.getCurrentHeight(c: c);
        walletDbHeight = await _getWalletDbHeight();
      });
      if (!await _anyAccountNeedsSync(currentHeight)) {
        _syncCheckpointHeight = walletDbHeight;
        if (syncStatus is! SyncedSyncStatus) {
          syncStatus = SyncedSyncStatus();
        }
        isSyncing = false;
        return true;
      }
      await zkool_sync.cancelSync();
      late final List<int> accountList;
      late final int lagHeight;
      await withSharedCoinLock(() async {
        final accounts = await zkool_account.listAccounts(c: c);
        accountList = accounts.map((final a) => a.id).toList()
          ..removeWhere((final a) => a == c.account);
        c = await c.setAccount(account: accountId);
        lagHeight = await _getLowestSyncHeight();
      });
      _broadcastSyncProgress(currentHeight, lagHeight);
      final sync = zkool_sync.synchronize(
        accounts: [c.account, ...accountList],
        currentHeight: currentHeight,
        actionsPerSync: 10000,
        transparentLimit: 100,
        checkpointAge: 200,
        c: c,
        fast: false,
      );
      await withSharedCoinLock(() async {
        c = await c.setAccount(account: accountId);
      });
      final randInt = CRC32.compute("${DateTime.now().microsecondsSinceEpoch}").toRadixString(16);
      oneshotSyncCount++;
      final completer = Completer<void>();
      var lastLoggedHeight = walletDbHeight;
      var chainTip = currentHeight;
      late final StreamSubscription<zkool_sync.SyncProgress> subscription;
      subscription = sync.listen(
        (final syncProgress) {
          if (syncProgress.height > chainTip) {
            chainTip = syncProgress.height;
          }
          if (syncProgress.height >= lastLoggedHeight + 5000) {
            lastLoggedHeight = syncProgress.height;
            printV(
              "[${c.account} ($accountList)] [$oneshotSyncCount/$randInt] sync: ${syncProgress.height}",
            );
            unawaited(
              zkool_network.getCurrentHeight(c: c).then((final tip) {
                if (tip > chainTip) {
                  chainTip = tip;
                  _onSyncCheckpoint(chainTip, syncProgress.height);
                }
              }),
            );
          }
          _onSyncCheckpoint(chainTip, syncProgress.height);
        },
        onError: (final e) {
          printV("[${c.account} ($accountList)] [$oneshotSyncCount/$randInt] error syncing: $e");
          runInAction(() {
            syncStatus = FailedSyncStatus(
              error:
                  e.toString().replaceAll("AnyhowException(", "").split("\n").firstOrNull ??
                  "Unknown error",
            );
          });
          isSyncing = false;
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onDone: () async {
          printV("[${c.account} ($accountList)] [$oneshotSyncCount/$randInt] synchronized");
          oneshotSyncCount--;
          isSyncing = false;
          try {
            await withSharedCoinLock(() async {
              c = await c.setAccount(account: accountId);
              if (await _anyAccountNeedsSyncUnlocked(currentHeight)) {
                final lagHeight = await _getLowestSyncHeight();
                _broadcastSyncProgress(currentHeight, lagHeight);
                return;
              }
              runInAction(() {
                for (final wallet in walletsByAccountId.values) {
                  wallet.syncStatus = SyncedSyncStatus();
                }
              });
              for (final wallet in walletsByAccountId.values) {
                unawaited(wallet.updateBalance());
                unawaited(wallet.updateTransactions());
                unawaited(
                  ZcashTaddressRotation.updateCache(mainAccountId: wallet.accountId)
                      .catchError((final e) {
                        printV("rotation cache refresh: $e");
                      }),
                );
              }
            });
          } catch (e) {
            printV("sync done height refresh: $e");
          }
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );
      await completer.future;
      await subscription.cancel();
      return syncStatus is SyncedSyncStatus;
    } catch (e) {
      syncStatus = FailedSyncStatus(error: e.toString());
      isSyncing = false;
      printV("error syncing: $e");
      return false;
    }
  }

  final _ledgerStages = StreamController<HardwareSigningStage>.broadcast();

  /// Where a Ledger send or shield is, from planning through finalizing.
  ///
  /// Emits from the start of [createTransaction] or [createShieldTransaction]
  /// on a Ledger wallet until they return. The device shows its review only
  /// at [HardwareSigningStage.awaitingDevice]; the earlier stages are the
  /// phone's own work, so a screen can say what is being waited on instead
  /// of pointing at a device that has nothing to show yet.
  Stream<HardwareSigningStage> get ledgerSigningStages => _ledgerStages.stream;

  void _ledgerStage(final HardwareSigningStage stage) {
    if (isLedgerWallet && !_ledgerStages.isClosed) {
      _ledgerStages.add(stage);
    }
  }

  /// Signs on the Ledger without holding the shared coin lock.
  ///
  /// The device review waits on the user, for minutes if they step away, and
  /// sync, balance and history refreshes all queue behind that lock. The
  /// signer only reads this account's keys and addresses from the database,
  /// so it runs on its own handle once the transaction has been planned under
  /// the lock.
  Future<zkool_pay.PcztPackage> _signOnLedgerOutsideCoinLock(
    final zkool_pay.PcztPackage txPlan,
  ) async {
    var coin = zkool_coin.Coin();
    coin = await coin.openDatabase(dbFilepath: c.dbFilepath);
    coin = await coin.setAccount(account: accountId);
    return signOnLedger(txPlan, coin);
  }

  /// Has the Ledger review and sign a transaction plan: the device returns
  /// the spend authorizations, then the backend proves and finalizes the
  /// transaction, ready for [PendingZcashTransaction.commit] to broadcast.
  /// The device has to be connected; the send page prompts for that first,
  /// and a lost connection surfaces as a plain "not connected" message so the
  /// app can ask to reconnect.
  Future<zkool_pay.PcztPackage> signOnLedger(
    final zkool_pay.PcztPackage txPlan,
    final zkool_coin.Coin coin,
  ) async {
    final service = hardwareWalletService;
    if (service is! ZcashLedgerService) {
      throw ZcashLedgerException(
        "The Ledger is not connected. Connect it and try again.",
      );
    }
    zkool_pay.PcztPackage? signed;
    await for (final event in service.sign(txPlan, coin)) {
      switch (event) {
        case zkool_pay.SigningEvent_Progress(:final field0):
          printV("ledger: $field0");
          // The signer reports each step; the screen only needs to know
          // when the device is waiting on the user and when it is past that.
          if (field0 == "Sending to Ledger") {
            _ledgerStage(HardwareSigningStage.sendingToDevice);
          } else if (field0 == "Confirm on your Ledger") {
            _ledgerStage(HardwareSigningStage.awaitingDevice);
          } else if (field0.startsWith("Signed")) {
            // Reported after a signature comes back, so the user has approved.
            _ledgerStage(HardwareSigningStage.signing);
          } else if (field0 == "Finalizing transaction") {
            _ledgerStage(HardwareSigningStage.finalizing);
          }
        case zkool_pay.SigningEvent_Result(:final field0):
          signed = field0;
      }
    }
    if (signed == null) {
      throw Exception("The Ledger returned no signed transaction");
    }
    return signed;
  }

  @override
  Future<PendingTransaction> createTransaction(final Object credentials) =>
      _createTransaction(credentials);

  Future<PendingTransaction> _createTransaction(
    final Object credentials, {
    final int tryReduceFeeAmount = 0,
  }) async {
    final creds = credentials as ZcashTransactionCredentials;
    _ledgerStage(HardwareSigningStage.preparing);
    await updateBalance();

    final zcashBalance = balance[CryptoCurrency.zec];
    final availableBalance = zcashBalance?.available ?? Money.zero(currency);

    final recipients = <zkool_paydart.Recipient>[];

    bool receipientPaysFee = false;

    for (final output in creds.outputs) {
      receipientPaysFee = receipientPaysFee || output.sendAll;
      var amount = output.cryptoAmount;
      if (output.sendAll) {
        amount = availableBalance - Money.fromInt(tryReduceFeeAmount, currency);
      }
      final recipientAddress = output.isParsedAddress ? output.extractedAddress! : output.address;
      recipients.add(
        zkool_paydart.Recipient(
          assetBase: zecBase,
          address: recipientAddress,
          amount: amount.amount,
          userMemo: output.memo,
        ),
      );
    }

    final sendAmount = creds.outputs
        .map((final out) => out.cryptoAmount)
        .reduce((final a, final b) => a + b);

    if (availableBalance == sendAmount) {
      receipientPaysFee = true;
    }

    // pools parameter: bitmask for which pools to use for sending
    // 1=Transparent, 2=Sapling, 4=Orchard, 8=Ironwood
    try {
      final (txPlan, txFee) = await runWithCoin(
        accountId: accountId,
        func: (coin) async {
          final ironwood = await zkool_network.isIronwoodActive(c: coin);
          final txPlan = await zkool_pay.prepare(
            recipients: recipients,
            options: zkool_pay.PaymentOptions(
              srcPools: ironwood ? 8 : 4,
              recipientPaysFee: receipientPaysFee,
              smartTransparent: false,
              ),
            c: coin,
          );
          final txFee = _feeFromTxPlan(txPlan, creds.priority, tryReduceFeeAmount, coin: coin);
          return (txPlan, txFee);
        },
      );
      // A Ledger reviews and signs here, while the transaction is being
      // prepared, so the confirmation sheet that follows shows a signed
      // transaction and the slide only broadcasts it: the same order as the
      // other hardware wallets, and what the user expects.
      _ledgerStage(HardwareSigningStage.sendingToDevice);
      final signed = isLedgerWallet ? await _signOnLedgerOutsideCoinLock(txPlan) : null;
      return PendingZcashTransaction(
        zcashWallet: this as ZcashWallet,
        credentials: creds,
        txPlan: txPlan,
        signedPackage: signed,
        fee: txFee,
        availableBalance: availableBalance,
      );
    } catch (e) {
      if (tryReduceFeeAmount != 0) rethrow;
      final estr = e.toString();
      // The planner found no spendable notes at all. Right after a send this
      // means the change is still unconfirmed and not yet recorded, which
      // deserves a sentence rather than a Rust backtrace.
      if (estr.contains("No feasible note selection found")) {
        throw Exception(
          "No confirmed funds are available to spend yet. If you just sent a "
          "transaction, its change becomes spendable once the network picks "
          "it up, usually within a minute or two.",
        );
      }
      const prefix = "Not enough funds, ";
      const suffix = " more ZEC required";
      if (estr.contains(prefix) && estr.contains(suffix)) {
        final start = estr.indexOf(prefix) + prefix.length;
        final end = estr.indexOf(suffix, start);
        final amtStr = estr.substring(start, end);
        final amt = double.tryParse(amtStr);
        if (amt == null) rethrow;
        final feeInt = (amt * 100000000).ceil();
        return _createTransaction(credentials, tryReduceFeeAmount: feeInt);
      }
      rethrow;
    }
  }

  static const _dispPhrase = "Received to disposable address";

  bool _hasExternalOutputs(final ZkoolTx tx, final Set<String> ownedAddresses) =>
      tx.outputsWithAddress.any((final o) => !_isOwnedAddress(o.address, ownedAddresses));

  bool _isIronwoodMigrationTx(final ZkoolTx tx, final Set<String> ownedAddresses) {
    // zkool classifies migration as selfTransfer with fee-sized net value.
    if (tx.type != TxType.selfTransfer) {
      return false;
    }
    final orchardSpent = tx.orchardSpent;
    final spentFromOrchard = orchardSpent > BigInt.zero ||
        tx.spendPools.contains(NotePool.orchard.index);
    if (!spentFromOrchard) {
      return false;
    }
    if (tx.ironwoodReceived > BigInt.zero ||
        tx.notePools.contains(NotePool.ironwood.index)) {
      return true;
    }
    // Orchard → Orchard split step (SD notes created, all outputs are ours).
    if (tx.orchardReceived > BigInt.zero && !_hasExternalOutputs(tx, ownedAddresses)) {
      return true;
    }
    // Orchard → Ironwood before the IW note is attached to tx details.
    return orchardSpent > tx.value;
  }

  BigInt _migrationDisplayAmount(final ZkoolTx tx) {
    if (tx.ironwoodReceived > BigInt.zero) {
      return tx.ironwoodReceived;
    }
    if (tx.orchardReceived > BigInt.zero) {
      return tx.orchardReceived;
    }
    return tx.orchardSpent;
  }

  ZcashTransactionInfo _zcashInfoFromMempoolTx(
    final zkool_mempool.MempoolTx tx,
    final int accountId,
  ) {
    final accountNotes = tx.notes.where((final n) => n.account == accountId);
    final txHash = ZcashWalletService.normalizeTxId(tx.txid);
    final pendingAmount = _pendingOutgoingAmounts[txHash];
    final netValue = accountNotes.fold<BigInt>(
      BigInt.zero,
      (final sum, final note) => sum + BigInt.from(note.value),
    );
    final direction = pendingAmount != null || netValue < BigInt.zero
        ? TransactionDirection.outgoing
        : TransactionDirection.incoming;
    final displayAmount = pendingAmount ?? netValue.abs();
    final memo = accountNotes
        .map((final n) => n.memo)
        .whereType<String>()
        .where((final m) => m.isNotEmpty)
        .firstOrNull;
    final recipientAddresses = const <String>[];

    final info = ZcashTransactionInfo(
      id: txHash,
      amount: Money(displayAmount, currency),
      fee: Money.zero(currency),
      direction: direction,
      isPending: true,
      date: DateTime.now(),
      height: 0,
      confirmations: 0,
      to: recipientAddresses.isEmpty ? '' : recipientAddresses.first,
      memo: memo,
    );
    if (recipientAddresses.isNotEmpty) {
      info.outputAddresses = recipientAddresses;
    }
    return info;
  }

  ZcashTransactionInfo _zcashInfoFromZkoolTx(
    final ZkoolTx tx,
    final int currentHeight, {
    final String? extraMemo,
    final bool isRotationReceive = false,
    final bool isShieldAction = false,
    final TransactionDirection? directionOverride,
    final BigInt? amountOverride,
    required final Set<String> ownedAddresses,
  }) {
    final confirmations = tx.height > 0 && currentHeight >= tx.height
        ? currentHeight - tx.height + 1
        : 0;
    final memo = extraMemo != null ? "${tx.memo ?? ''}\n$extraMemo".trim() : tx.memo;
    final isMigration = directionOverride == null && _isIronwoodMigrationTx(tx, ownedAddresses);
    final direction = directionOverride ??
        (isMigration ? TransactionDirection.outgoing : tx.direction);
    final amount = amountOverride ??
        (isMigration ? _migrationDisplayAmount(tx) : tx.value);
    final recipientAddresses = direction == TransactionDirection.outgoing
        ? _outgoingRecipientAddresses(tx, ownedAddresses: ownedAddresses)
        : const <String>[];
    final info = ZcashTransactionInfo(
      id: tx.txHash,
      amount: Money(amount, currency),
      fee: Money(
        direction == TransactionDirection.outgoing ? tx.fee : BigInt.zero,
        currency,
      ),
      direction: direction,
      isPending: tx.height == 0,
      date: tx.time,
      height: tx.height,
      confirmations: confirmations,
      to: recipientAddresses.isEmpty ? '' : recipientAddresses.first,
      memo: memo?.isNotEmpty == true ? memo : null,
      txType: tx.type,
      isRotationReceive: isRotationReceive,
      isShieldAction: isShieldAction,
      isIronwoodMigration: isMigration,
    );
    if (recipientAddresses.isNotEmpty) {
      info.outputAddresses = recipientAddresses;
    }
    return info;
  }

  bool _isShieldActionTx(
    final ZkoolTx tx, {
    required final Set<String> rotationSweepHashes,
    required final Set<String> ownedAddresses,
  }) {
    if (ZcashWalletService.isAutoshieldTx(tx.txHash)) {
      return true;
    }
    if (rotationSweepHashes.contains(tx.txHash)) {
      return true;
    }
    if (_isPayToSelfAutoshield(tx, ownedAddresses)) {
      return true;
    }
    if (tx.direction == TransactionDirection.outgoing &&
        (tx.type == TxType.shield || tx.type == TxType.transparentSelfTransfer)) {
      return true;
    }
    return false;
  }

  bool _isPayToSelfAutoshield(final ZkoolTx tx, final Set<String> ownedAddresses) {
    if (tx.type != TxType.shield && tx.type != TxType.transparentSelfTransfer) {
      return false;
    }
    if (tx.transparentOrSaplingSpent <= BigInt.zero) {
      return false;
    }
    if (tx.shieldedReceived <= BigInt.zero) {
      return false;
    }
    for (final dest in tx.outputAddresses) {
      if (_isOwnedAddress(dest, ownedAddresses)) {
        return true;
      }
    }
    return tx.shieldedReceived > BigInt.zero;
  }

  bool _shouldSplitAutoshieldTx(
    final ZkoolTx tx, {
    required final bool isShield,
    required final Set<String> ownedAddresses,
  }) {
    if (!isShield) {
      return false;
    }
    if (ZcashWalletService.isAutoshieldTx(tx.txHash) ||
        _isPayToSelfAutoshield(tx, ownedAddresses)) {
      // Shown as two entries, what left the transparent side and what
      // arrived shielded, so the history never reads as "only a fee went
      // out". The shielded side is Ironwood once that pool is active.
      return tx.transparentOrSaplingSpent > BigInt.zero && tx.shieldedReceived > BigInt.zero;
    }
    return false;
  }

  static String _txResultKey(final String txHash, {final String suffix = ''}) =>
      'tx_$txHash$suffix';

  static int _txDisplayPriority(final ZcashTransactionInfo info) {
    if (info.additionalInfo['isIronwoodMigration'] == true) {
      return 4;
    }
    if (info.additionalInfo['isAutoShield'] == true) {
      return 3;
    }
    if (info.additionalInfo['isRotationReceive'] == true) {
      return 2;
    }
    return 1;
  }

  void _offerTx(final Map<String, ZcashTransactionInfo> byHash, final ZcashTransactionInfo info) {
    final hash = info.txHash;
    final existing = byHash[hash];
    if (existing == null) {
      byHash[hash] = info;
      return;
    }
    final infoPriority = _txDisplayPriority(info);
    final existingPriority = _txDisplayPriority(existing);
    if (infoPriority > existingPriority) {
      byHash[hash] = info;
      return;
    }
    if (infoPriority == existingPriority &&
        (info.additionalInfo['isAutoShield'] == true ||
            info.additionalInfo['isIronwoodMigration'] == true) &&
        info.direction == TransactionDirection.outgoing &&
        existing.direction == TransactionDirection.incoming) {
      byHash[hash] = info;
    }
  }

  Future<Set<String>> _ownedAddressSet(final zkool_coin.Coin coin) async {
    final owned = <String>{};
    for (final address in await zkool_account.listOwnedAddresses(c: coin)) {
      if (address.isEmpty) {
        continue;
      }
      owned.add(address);
      if (address.startsWith('u')) {
        owned.addAll(_uaReceivers(address));
      }
    }
    final addrs = walletAddresses;
    for (final infos in addrs.addressInfos.values) {
      for (final info in infos) {
        owned.add(info.address);
      }
    }
    owned.addAll(addrs.hiddenAddresses);
    owned.addAll(addrs.usedAddresses);
    return owned;
  }

  bool _isOwnedAddress(final String addr, final Set<String> ownedAddresses) =>
      ownedAddresses.contains(addr);

  List<String> _outgoingRecipientAddresses(
    final ZkoolTx tx, {
    required final Set<String> ownedAddresses,
  }) {
    var outputs = tx.outputsWithAddress
        .where((final o) => !_isOwnedAddress(o.address, ownedAddresses))
        .toList();
    if (outputs.isEmpty) {
      return [];
    }

    final transparent =
        outputs.where((final o) => o.pool == NotePool.transparent.index).toList();
    if (transparent.length >= 2) {
      outputs = transparent;
    }

    return _dedupeAddresses(outputs.map((final o) => o.address));
  }

  List<String> _dedupeAddresses(final Iterable<String> raw) {
    final seen = <String>{};
    return [
      for (final address in raw)
        if (address.trim().isNotEmpty && seen.add(address.trim())) address.trim(),
    ];
  }

  Set<String> _uaReceivers(final String ua) {
    try {
      final receivers = zkool_account.receiversFromUa(ua: ua, c: ZcashWalletBase.c);
      return {
        for (final address in [receivers.taddr, receivers.saddr, receivers.oaddr])
          if (address != null && address.isNotEmpty) address,
      };
    } catch (_) {
      return {};
    }
  }

  @override
  Future<Map<String, ZcashTransactionInfo>> fetchTransactions() async {
    await ZcashWalletService.loadShieldTxs();
    final (txs, currentHeight, ownedAddresses) = await runWithCoin(
      accountId: accountId,
      func: (coin) async {
        final owned = await _ownedAddressSet(coin);
        final txsI = await zkool_account.listTxHistory(c: coin);
        final txsA = await Future.wait(
          txsI.map((final tx) => zkool_account.getTxDetails(idTx: tx.id, c: coin)),
        );
        final txs = <ZkoolTx>[];
        for (int i = 0; i < txsI.length; i++) {
          txs.add(ZkoolTx(txsI[i], txsA[i]));
        }
        txs.sort((final a, final b) => a.height.compareTo(b.height));
        var currentHeight = 1;
        try {
          currentHeight = await zkool_network.getCurrentHeight(c: coin);
        } catch (e) {
          printV("failed to get height: $e");
        }
        return (txs, currentHeight, owned);
      },
    );
    final Map<String, ZcashTransactionInfo> byHash = {};
    final rotationTxs = ZcashTaddressRotation.rotationTxsForMainAccount(accountId);
    final rotationSweepHashes = <String>{
      for (final tx in rotationTxs)
        if (tx.direction == TransactionDirection.outgoing) tx.txHash,
    };

    for (final tx in rotationTxs) {
      if (tx.direction == TransactionDirection.incoming) {
        _offerTx(
          byHash,
          _zcashInfoFromZkoolTx(
            tx,
            currentHeight,
            extraMemo: _dispPhrase,
            isRotationReceive: true,
            ownedAddresses: ownedAddresses,
          ),
        );
        continue;
      }
      _offerTx(
        byHash,
        _zcashInfoFromZkoolTx(
          tx,
          currentHeight,
          isShieldAction: true,
          ownedAddresses: ownedAddresses,
        ),
      );
    }

    final Map<String, ZcashTransactionInfo> splitEntries = {};
    for (final tx in txs) {
      _pendingOutgoingAmounts.remove(ZcashWalletService.normalizeTxId(tx.txHash));
      if (_pendingShieldTxId != null &&
          tx.height > 0 &&
          ZcashWalletService.normalizeTxId(tx.txHash) ==
              ZcashWalletService.normalizeTxId(_pendingShieldTxId!)) {
        _shieldSweepPending = false;
        _pendingShieldTxId = null;
      }
      if (tx.height > 0) {
        ZcashMempoolService.instance.removeTx(tx.txHash);
      }
      final isShield = _isShieldActionTx(
        tx,
        rotationSweepHashes: rotationSweepHashes,
        ownedAddresses: ownedAddresses,
      );
      if (_shouldSplitAutoshieldTx(tx, isShield: isShield, ownedAddresses: ownedAddresses)) {
        byHash.remove(tx.txHash);
        splitEntries[_txResultKey(tx.txHash, suffix: '_shield')] = _zcashInfoFromZkoolTx(
          tx,
          currentHeight,
          isShieldAction: true,
          directionOverride: TransactionDirection.outgoing,
          amountOverride: tx.transparentOrSaplingSpent,
          ownedAddresses: ownedAddresses,
        );
        splitEntries[_txResultKey(tx.txHash, suffix: '_recv')] = _zcashInfoFromZkoolTx(
          tx,
          currentHeight,
          directionOverride: TransactionDirection.incoming,
          amountOverride: tx.shieldedReceived,
          ownedAddresses: ownedAddresses,
        );
        continue;
      }
      _offerTx(
        byHash,
        _zcashInfoFromZkoolTx(
          tx,
          currentHeight,
          isShieldAction: isShield,
          ownedAddresses: ownedAddresses,
        ),
      );
    }

    final knownHashes = {
      for (final tx in txs) ZcashWalletService.normalizeTxId(tx.txHash),
      for (final hash in byHash.keys) ZcashWalletService.normalizeTxId(hash),
    };
    for (final mempoolTx in ZcashMempoolService.instance.txsForAccount(accountId)) {
      final hash = ZcashWalletService.normalizeTxId(mempoolTx.txid);
      if (knownHashes.contains(hash)) {
        ZcashMempoolService.instance.removeTx(hash);
        _pendingOutgoingAmounts.remove(hash);
        continue;
      }
      final info = _zcashInfoFromMempoolTx(mempoolTx, accountId);
      if (info.amount.isZero) {
        continue;
      }
      _offerTx(byHash, info);
    }

    return {
      for (final entry in byHash.entries) _txResultKey(entry.key): entry.value,
      ...splitEntries,
    };
  }

  Future<void> _initKeys() async {
    try {
      c = await c.setAccount(account: accountId);
      final ufvk = await zkool_account.getAccountUfvk(account: accountId, c: c, pools: 7);

      keys = {
        "privateViewKey": ufvk,
        if (lastKnownRestoreHeight != null) "restoreHeight": lastKnownRestoreHeight.toString(),
      };
    } catch (e) {
      keys = {"privateViewKey": e.toString()};
    }
    try {
      c = await c.setAccount(account: accountId);
      final s = (await zkool_account.getAccountSeed(account: accountId, c: c));

      if (s == null) {
        throw Exception("seed not found");
      }
      final seedPhrase = s.mnemonic.split(" ");
      if ([13, 25].contains(seedPhrase.length)) {
        passphrase = seedPhrase.removeLast();
      } else {
        passphrase = s.phrase;
      }
      seed = s.mnemonic.trim();
    } catch (e) {
      seed = e.toString();
    }
  }

  @override
  Object keys = {};

  @override
  String get password => _password!;

  @override
  Future<void> renameWalletFiles(final String newWalletName) async {
    await renameWalletFilesForName(fromName: name, toName: newWalletName);
  }

  static Future<void> renameWalletFilesForName({
    required final String fromName,
    required final String toName,
  }) async {
    if (fromName == toName) {
      return;
    }
    final currentWalletDir = Directory(await pathForWalletDir(name: fromName, type: _type));
    if (!currentWalletDir.existsSync()) {
      throw Exception('Wallet directory not found: $fromName');
    }
    final newWalletDirPath = '${await pathForWalletTypeDir(type: _type)}/$toName';
    if (Directory(newWalletDirPath).existsSync()) {
      throw Exception('Cannot rename wallet: "$toName" already exists');
    }
    await currentWalletDir.rename(newWalletDirPath);
    for (final suffix in const ['', '.v2']) {
      final oldFile = File('$newWalletDirPath/$fromName$suffix');
      if (oldFile.existsSync()) {
        await oldFile.rename('$newWalletDirPath/$toName$suffix');
      }
    }
  }

  @override
  bool get hasRescan => true;

  static int? lastKnownRestoreHeight = null;

  static int zashiAnnouncedBlockHeight = 2419420;

  Future<dynamic> _getAddressesForAccount(final int id) async {
    return runWithCoin(
      accountId: id,
      func: (final coin) => zkool_account.getAddresses(c: coin, uaPools: 7),
    );
  }

  bool _addressesMatch(final dynamic old, final dynamic new_) {
    return old.ua == new_.ua &&
        old.oaddr == new_.oaddr &&
        old.saddr == new_.saddr &&
        old.taddr == new_.taddr;
  }

  Future<void> _switchToAccount(final int newAccountId, final int height) async {
    walletsByAccountId.remove(accountId);
    accountId = newAccountId;
    walletsByAccountId[newAccountId] = this;
    walletAddresses.accountId = newAccountId;
    c = await c.setAccount(account: newAccountId);
    lastKnownRestoreHeight = height;
    await walletAddresses.init();
    await _initKeys();
  }

  @override
  @action
  Future<void> rescan({required final int height}) async {
    syncStatus = StartingScanSyncStatus(height);
    try {
      await zkool_sync.cancelSync();
      isSyncing = false;

      await runWithCoin(
        accountId: accountId,
        func: (final coin) async {
          await zkool_account.updateAccount(
            update: zkool_account.AccountUpdate(
              coin: coin.coin,
              id: accountId,
              birth: height,
              folder: 0,
            ),
            c: coin,
          );

          final accounts = await zkool_account.listAccounts(c: coin);
          final updated =
              accounts.where((final a) => a.id == accountId).firstOrNull;
          if (updated == null) {
            throw Exception('account $accountId not found after update');
          }
          if (updated.birth != height) {
            throw Exception(
              'birth height did not persist: wanted $height, '
              'database still has ${updated.birth}',
            );
          }

          await zkool_account.resetSync(id: accountId, c: coin);
        },
      );

      lastKnownRestoreHeight = height;
      await save();

      syncStatus = ConnectedSyncStatus();
      unawaited(startSync());
    } catch (e) {
      printV('Zcash rescan failed: $e');
      syncStatus = FailedSyncStatus(error: e.toString());
    }
    // try {
    //   syncStatus = StartingScanSyncStatus(height);
    //   printV("rescanning from: $height");
    //   await zkool_sync.cancelSync();
    //   isSyncing = false;

    //   await runWithCoinMutex.acquire();
    //   try {
    //     final oldAddresses = await _getAddressesForAccount(accountId);

    //     c = await c.setAccount(account: accountId);
    //     final accountSeed = await zkool_account.getAccountSeed(account: accountId, c: c);
    //     if (accountSeed == null) {
    //       throw Exception('Cannot rescan: seed not available');
    //     }

    //     final newAccountId = await restoreZcashWalletFromSeed(
    //       name: name,
    //       seed: accountSeed.mnemonic,
    //       passphrase: accountSeed.phrase,
    //       birthHeight: height,
    //     );

    //     final newAddresses = await _getAddressesForAccount(newAccountId);
    //     if (!_addressesMatch(oldAddresses, newAddresses)) {
    //       throw Exception('Rescan address verification failed');
    //     }

    //     await saveAccountId(name, newAccountId);
    //     await _switchToAccount(newAccountId, height);
    //   } finally {
    //     runWithCoinMutex.release();
    //   }

    //   syncStatus = ConnectedSyncStatus();
    // } catch (e) {
    //   printV("Rescan error: $e");
    //   syncStatus = FailedSyncStatus(error: e.toString());
    //   rethrow;
    // }
  }

  bool _isTransactionUpdating = false;
  bool _transactionUpdateQueued = false;

  Future<void> updateTransactions() async {
    if (_isTransactionUpdating) {
      _transactionUpdateQueued = true;
      return;
    }

    _isTransactionUpdating = true;
    try {
      do {
        _transactionUpdateQueued = false;
        final transactions = await fetchTransactions();

        final currentIds = transactionHistory.transactions.keys.toSet();
        final newIds = transactions.keys.toSet();

        currentIds
            .difference(newIds)
            .forEach((final id) => transactionHistory.transactions.remove(id));

        transactions.forEach((final key, final tx) {
          transactionHistory.transactions[key] = tx;
        });
        await transactionHistory.save();
      } while (_transactionUpdateQueued);
    } catch (e, stackTrace) {
      printV("Update transactions error: $e");
      printV("Stack trace: $stackTrace");
    } finally {
      _isTransactionUpdating = false;
    }
  }

  @override
  Future<void> save() async {}

  Future<void> init() async {
    try {
      await ZcashTaddressRotation.init();
      await walletAddresses.init();

      await updateBalance();
      await updateTransactions();
      unawaited(
        ZcashTaddressRotation.updateCache(mainAccountId: accountId)
            .catchError((final e) => printV("rotation cache refresh: $e")),
      );
      await _initKeys();
    } catch (e) {
      printV("Wallet init error: $e");
    }
  }

  @override
  String? seed = "";

  @override
  String? passphrase = "";

  @override
  Future<String> signMessage(final String message, {final String? address = null}) {
    throw UnimplementedError();
  }

  @override
  @action
  Future<void> startSync() async {
    if (syncStatus is AttemptingSyncStatus ||
        syncStatus is SyncronizingSyncStatus ||
        syncStatus is SyncingSyncStatus) {
      return;
    }
    try {
      _ensureSyncLoopRunning();
      unawaited(_oneshotSync());
    } catch (e) {
      isNodeWorking = false;
      printV("Sync error: $e");
      syncStatus = FailedSyncStatus(error: e.toString());
      rethrow;
    }
  }

  static Mutex warpSyncMutex = Mutex();

  static final autoShieldMutex = Mutex();
  static DateTime? _lastAutoShieldAt;
  static final ironwoodMigrateMutex = Mutex();
  static DateTime? _lastIronwoodMigrateAt;
  /// Transparent funds a hardware wallet holds but cannot sweep unattended;
  /// zero while a shield it broadcast is still confirming.
  Future<BigInt> shieldableBalance() async {
    if (_shieldSweepPending) {
      return BigInt.zero;
    }
    return runWithCoin(
      accountId: accountId,
      func: (final coin) async {
        final sweepable = await _sweepableTotal(coin);
        if (sweepable <= BigInt.from(_manualShieldMinSweep)) {
          return BigInt.zero;
        }
        return sweepable;
      },
    );
  }

  /// Builds a transaction sweeping transparent funds into the shielded pool,
  /// for a wallet that cannot sign it unattended.
  ///
  /// Shielding normally happens during sync, which a hardware wallet cannot
  /// do: every transaction is a device review. A Ledger reviews and signs the
  /// sweep right here, so the returned transaction only has to be broadcast.
  Future<PendingTransaction> createShieldTransaction() async {
    _ledgerStage(HardwareSigningStage.preparing);
    final destination = walletAddresses.orchardAddress!;
    final (txPlan, sweepable, fee) = await runWithCoin(
      accountId: accountId,
      func: (final coin) async {
        final sweepable = await _sweepableTotal(coin);
        final ironwood = await zkool_network.isIronwoodActive(c: coin);
        if (sweepable <= BigInt.from(_manualShieldMinSweep)) {
          throw Exception('There is nothing to shield.');
        }
        final txPlan = await zkool_pay.prepare(
          recipients: [
            zkool_paydart.Recipient(
              assetBase: zecBase,
              address: destination,
              amount: sweepable,
              pools: ironwood ? ironwoodPoolMask : null,
            ),
          ],
          options: zkool_pay.PaymentOptions(
            srcPools: 3,
            recipientPaysFee: true,
            smartTransparent: false,
          ),
          c: coin,
        );
        final fee = _feeFromTxPlan(txPlan, MoneroTransactionPriority.automatic, 0, coin: coin);
        return (txPlan, sweepable, fee);
      },
    );
    _ledgerStage(HardwareSigningStage.sendingToDevice);
    final signed = isLedgerWallet ? await _signOnLedgerOutsideCoinLock(txPlan) : null;
    return PendingZcashTransaction(
      zcashWallet: this as ZcashWallet,
      isShield: true,
      credentials: ZcashTransactionCredentials(
        // Describes the sweep for the confirmation screens: every sweepable
        // note, less the fee.
        outputs: [
          OutputInfo(
            address: destination,
            sendAll: true,
            isParsedAddress: false,
            cryptoAmount: Money(sweepable, currency),
          ),
        ],
        priority: MoneroTransactionPriority.automatic,
        currency: currency,
      ),
      txPlan: txPlan,
      signedPackage: signed,
      fee: fee,
      availableBalance: Money(sweepable, currency),
    );
  }

  /// Records a manual shield that was just broadcast.
  ///
  /// History splits a shield into the transparent spend and the shielded
  /// receipt; without the mark it reads as a transfer whose value is only the
  /// fee. The swept notes also still read as unspent until this confirms, so
  /// the balance and the shield card stop counting them until then.
  Future<void> markShieldBroadcast(final String txId) async {
    await ZcashWalletService.addShieldedTx(txId);
    _shieldSweepPending = true;
    _pendingShieldTxId = txId;
  }

  Future<void> _autoShield() async {
    if (_lastAutoShieldAt != null &&
        _lastAutoShieldAt!.isAfter(DateTime.now().subtract(const Duration(seconds: 75)))) {
      return;
    }
    try {
      await autoShieldMutex.acquire();
      await _$autoShield();
    } catch (e, s) {
      printV("shielding failed: $e");
      s.toString().split("\n").forEach(printV);
    } finally {
      autoShieldMutex.release();
    }
  }

  /// Total of transparent + sapling notes at or above the per-note spendable floor.
  static Future<BigInt> _sweepableTotal(final zkool_coin.Coin coin) async {
    final notes = await zkool_account.listNotes(c: coin);
    BigInt sweepable = BigInt.zero;
    for (int i = 0; i < notes.length; i++) {
      final note = notes[i];
      if (note.pool < 0 || note.pool >= NotePool.values.length) {
        continue;
      }
      final noteType = NotePool.values[note.pool];
      if ((noteType == NotePool.transparent || noteType == NotePool.sapling) &&
          note.value >= BigInt.from(ZcashTaddressRotation.minSpendableNote)) {
        sweepable += note.value;
      }
    }
    return sweepable;
  }

  /// Orchard notes that migration will actually split or move to Ironwood.
  static Future<BigInt> _migratableOrchardTotal(final zkool_coin.Coin coin) async {
    final notes = await zkool_account.listNotes(c: coin);
    BigInt migratable = BigInt.zero;
    for (int i = 0; i < notes.length; i++) {
      final note = notes[i];
      if (note.pool != NotePool.orchard.index || note.locked) {
        continue;
      }
      if (note.value >= BigInt.from(_ironwoodMigrateMinNote)) {
        migratable += note.value;
      }
    }
    return migratable;
  }

  bool hasOrchardMigratableBalance() => _orchardMigratable;

  Future<void> _$autoShield() async {
    if (syncStatus is! SyncedSyncStatus) {
      return;
    }
    // Shielding signs locally. A Ledger wallet has no spending key, and a
    // background sync is no place to prompt on the device, so its transparent
    // funds are left alone and spent directly (see _sourcePools).
    if (isHardwareWallet) {
      return;
    }
    final txId = await runWithCoin(
      accountId: accountId,
      func: (coin) async {
        final sweepable = await _sweepableTotal(coin);
        final ironwood = await zkool_network.isIronwoodActive(c: coin);

        if (sweepable <= BigInt.from(_minSweepThreshold(ironwood: ironwood))) {
          return null;
        }
        final txPlan = await zkool_pay.prepare(
          recipients: [
            zkool_paydart.Recipient(
              assetBase: zecBase,
              address: walletAddresses.orchardAddress!,
              amount: sweepable,
              pools: ironwood ? ironwoodPoolMask : null,
            ),
          ],
          options: zkool_pay.PaymentOptions(
            srcPools: 3,
            recipientPaysFee: true,
            smartTransparent: false,
          ),
          c: coin,
        );

        final signTx = await zkool_pay.signTransaction(pczt: txPlan, c: coin);
        final txBytes = await zkool_pay.extractTransaction(package: signTx);
        final currentHeight = await zkool_network.getCurrentHeight(c: coin);
        return await zkool_pay.broadcastTransaction(
          height: currentHeight,
          txBytes: txBytes,
          c: coin,
        );
      },
    );
    if (txId == null) {
      return;
    }

    await ZcashWalletService.addShieldedTx(txId);
    _lastAutoShieldAt = DateTime.now();
    printV("shielded: $txId");
    await updateTransactions();
    await _refreshBalance(runAutoShield: false, runIronwoodMigrate: false);
  }

  Future<void> _ironwoodMigrate() async {
    if (_lastIronwoodMigrateAt != null &&
        _lastIronwoodMigrateAt!.isAfter(DateTime.now().subtract(const Duration(seconds: 75)))) {
      return;
    }
    try {
      await ironwoodMigrateMutex.acquire();
      await _$ironwoodMigrate();
    } catch (e, s) {
      printV("ironwood migration failed: $e");
      s.toString().split("\n").forEach(printV);
    } finally {
      ironwoodMigrateMutex.release();
    }
  }

  Future<void> _$ironwoodMigrate() async {
    if (syncStatus is! SyncedSyncStatus) {
      return;
    }
    // Same as shielding: migrating needs the device, and a Ledger account only
    // ever holds transparent and Ironwood funds anyway.
    if (isHardwareWallet) {
      return;
    }
    final event = await runWithCoin(
      accountId: accountId,
      func: (coin) async {
        if (!await zkool_network.isIronwoodActive(c: coin)) {
          return null;
        }
        final bal = await zkool_sync.balance(c: coin);
        if (bal.field0.length <= 2 || bal.field0[2] <= BigInt.zero) {
          return null;
        }
        return zkool_migrate.stepMigration(c: coin);
      },
    );
    if (event == null) {
      return;
    }
    switch (event) {
      case zkool_migrate.MigrationEvent_Complete():
      case zkool_migrate.MigrationEvent_NothingToDo():
        return;
      case zkool_migrate.MigrationEvent_SplitComplete(:final fee):
        printV("ironwood split step complete, fee: $fee");
      case zkool_migrate.MigrationEvent_MigrateComplete(:final fee):
        printV("ironwood migrate step complete, fee: $fee");
      case zkool_migrate.MigrationEvent_Error(:final message):
        printV("ironwood migration error: $message");
        return;
    }

    _lastIronwoodMigrateAt = DateTime.now();
    await updateTransactions();
    await _refreshBalance(runAutoShield: false, runIronwoodMigrate: false);
  }

  Future<void> _updateIronwoodActive() async {
    bool? active;
    try {
      active = await runWithCoin(
        accountId: accountId,
        func: (final coin) => zkool_network.isIronwoodActive(c: coin),
      );
    } catch (e) {
      printV("isIronwoodActive: $e");
    }

    if (active == null && networkFor(walletInfo) == ZcashNetwork.regtest) {
      try {
        final height = await runWithCoin(
          accountId: accountId,
          func: (final coin) => zkool_network.getCurrentHeight(c: coin),
        );
        active = height >= ZcashNetwork.regtestNu63Height;
        printV("regtest ironwood inferred from height $height: $active");
      } catch (e) {
        printV("regtest height check failed: $e");
      }
    }

    if (active == null) {
      return;
    }

    ironwoodActive = active;
    runInAction(() => walletAddresses.setIronwoodActive(active!));
    printV("ironwoodActive=$active (account $accountId)");
  }

  Future<void> _refreshBalance({
    required final bool runAutoShield,
    final bool runIronwoodMigrate = true,
  }) async {
    try {
      await _updateIronwoodActive();
      if (runAutoShield) {
        await _autoShield();
      }
      if (runIronwoodMigrate) {
        await _ironwoodMigrate();
      }

      final (bal, sweepable, migratableOrchard) = await runWithCoin(
        accountId: accountId,
        func: (final coin) async => (
          await zkool_sync.balance(c: coin),
          await _sweepableTotal(coin),
          await _migratableOrchardTotal(coin),
        ),
      );

      // 0 - transparent, 1 - sapling, 2 - orchard, 3 - ironwood
      final orchard = bal.field0.length > 2 ? bal.field0[2] : BigInt.zero;
      final ironwood = bal.field0.length > 3 ? bal.field0[3] : BigInt.zero;
      // A just-broadcast shield has already swept these notes; do not keep
      // showing them as awaiting shielding.
      final sweepableEff = _shieldSweepPending ? BigInt.zero : sweepable;

      // After NU6.3, Orchard notes are migrated to Ironwood - show them as unconfirmed.
      // Unavailable uses the same per-note totals and thresholds as auto-shield/migration guards.
      final BigInt availableAmount;
      final BigInt unavailableAmount;
      if (ironwoodActive == true && orchard > BigInt.zero) {
        final sweepableUnavailable = sweepableEff <= BigInt.from(_ironwoodMigrateMinNote)
            ? BigInt.zero
            : sweepableEff;
        availableAmount = ironwood;
        unavailableAmount = migratableOrchard + sweepableUnavailable;
      } else {
        final minSweep = _minSweepThreshold(ironwood: ironwoodActive == true);
        availableAmount = orchard + ironwood;
        unavailableAmount = sweepableEff <= BigInt.from(minSweep) ? BigInt.zero : sweepableEff;
      }

      runInAction(() {
        _orchardMigratable =
            ironwoodActive == true && migratableOrchard > BigInt.zero;
        balance[currency] = ZcashBalance(
          Money(availableAmount, currency),
          Money(unavailableAmount, currency),
          frozen: Money.zero(currency),
        );
      });
    } catch (e, stackTrace) {
      printV("Balance update error: $e");
      printV("Stack trace: $stackTrace");
    }
  }

  @override
  @action
  Future<void> updateBalance() async {
    await _refreshBalance(runAutoShield: true);
  }

  @override
  Future<bool> verifyMessage(
    final String message,
    final String signature, {
    final String? address = null,
  }) {
    throw UnimplementedError();
  }

  @override
  late ZcashWalletAddresses walletAddresses = ZcashWalletAddresses(accountId, walletInfo);

  static Future<ZcashWallet> create(final WalletCredentials credentials) async {
    final network = networkForCredentials(credentials);
    await $init(network: network);
    credentials.walletInfo?.network = network.value;
    final newWalletCredentials = credentials as ZcashNewWalletCredentials;

    String mnemonic;
    if (newWalletCredentials.mnemonic?.isNotEmpty == true) {
      mnemonic = newWalletCredentials.mnemonic!;
    } else {
      final strength = (newWalletCredentials.seedPhraseLength == 24) ? 256 : 128;
      mnemonic = bip39.generateMnemonic(strength: strength);
    }

    final birthHeight = await birthHeightForNetwork(network);

    final accountId = await restoreZcashWalletFromSeed(
      name: credentials.name,
      seed: mnemonic,
      passphrase: newWalletCredentials.passphrase,
      birthHeight: birthHeight,
    );
    await saveAccountId(credentials.name, accountId);
    final wallet = await open(
      name: credentials.name,
      password: credentials.password!,
      walletInfo: credentials.walletInfo!,
    );
    await wallet.init();
    return wallet;
  }

  static Future<ZcashWallet> restore(final WalletCredentials credentials) async {
    final network = networkForCredentials(credentials);
    await $init(network: network);
    credentials.walletInfo?.network = network.value;
    final fromSeedCredentials = credentials as ZcashFromSeedWalletCredentials;
    final String? seed = fromSeedCredentials.seed;
    if (seed == null || seed.isEmpty) {
      throw Exception('Seed phrase is required for wallet restoration');
    }

    final accountId = await restoreZcashWalletFromSeed(
      name: credentials.name,
      seed: seed,
      passphrase: fromSeedCredentials.passphrase,
      birthHeight: credentials.height!,
    );
    await saveAccountId(credentials.name, accountId);
    final wallet = await open(
      name: credentials.name,
      password: credentials.password!,
      walletInfo: credentials.walletInfo!,
    );
    await wallet.init();
    return wallet;
  }

  static Future<ZcashWallet> restoreKeys(final WalletCredentials credentials) async {
    final network = networkForCredentials(credentials);
    await $init(network: network);
    credentials.walletInfo?.network = network.value;
    final fromKeysCredentials = credentials as ZcashFromKeysWalletCredentials;
    final String? keys = fromKeysCredentials.privateKey;
    if (keys == null || keys.isEmpty) {
      throw Exception('Key is required for wallet restoration');
    }

    final zcashSecretExtendedKeyRegex = RegExp(r'^secret-extended-key-main1[a-z0-9]+$');
    if (!zcashSecretExtendedKeyRegex.hasMatch(keys)) {
      throw Exception('Key is not in secret-extended-key-main1 format');
    }

    final accountId = await restoreZcashWalletFromSeed(
      name: credentials.name,
      seed: keys,
      passphrase: fromKeysCredentials.passphrase,
      birthHeight: credentials.height!,
    );
    await saveAccountId(credentials.name, accountId);
    final wallet = await open(
      name: credentials.name,
      password: credentials.password!,
      walletInfo: credentials.walletInfo!,
    );
    await wallet.init();
    printV("height: ${credentials.height}");
    return wallet;
  }

  static Future<ZcashWallet> open({
    required final String name,
    required final String password,
    required final WalletInfo walletInfo,
  }) async {
    final network = networkFor(walletInfo);
    await $init(network: network);
    // if (password.isNotEmpty) {
    //   setDbPasswd(coin, password);
    // }
    final accountId = await getZcashAccountIdForName(name);
    if (accountId == null) {
      throw Exception("accountId is null");
    }
    c = await c.setAccount(account: accountId);
    final wallet = ZcashWallet(
      walletInfo,
      await walletInfo.getDerivationInfo(),
      accountId: accountId,
    );
    await wallet._initKeys();
    return wallet;
  }

  static Future<int> restoreZcashWalletFromSeed({
    required final String name,
    required final String seed,
    required final String? passphrase,
    required final int birthHeight,
  }) async {
    // if (passphrase?.isNotEmpty == true) {
    //   passphrase = passphrase!.replaceAll(" ", "_");
    //   seed = "${seed} ${passphrase}";
    // }

    final accountId = await newAccount(
      name: name,
      height: birthHeight,
      seed: seed,
      passphrase: passphrase ?? '',
    );
    return accountId;
  }

  static Future<int?> getLegacyZcashAccountIdForName(final String name) async {
    final wPath = (await pathForWallet(name: name, type: _type));
    final f = File(wPath);
    if (!f.existsSync()) {
      final accs = await zkool_account.listAccounts(c: c);
      for (final acc in accs) {
        if (acc.name == name) {
          return acc.id;
        }
      }
    }
    final content = f.readAsStringSync();
    return int.tryParse(content.trim());
  }

  static Future<int?> getZcashAccountIdForName(final String name) async {
    final wPath = (await pathForWallet(name: name, type: _type)) + ".v2";
    final f = File(wPath);
    if (!f.existsSync()) {
      final accs = await zkool_account.listAccounts(c: c);
      for (final acc in accs) {
        if (acc.name == name) {
          return acc.id;
        }
      }
    }
    final content = f.readAsStringSync();
    return int.tryParse(content.trim());
  }

  static Future<void> saveAccountId(final String name, final int accountId) async {
    final wPath = (await pathForWallet(name: name, type: _type)) + ".v2";
    final dirName = Directory(wPath).parent.path;
    if (!Directory(dirName).existsSync()) {
      Directory(dirName).createSync(recursive: true);
    }
    final f = File(wPath);
    f.writeAsStringSync(accountId.toString());
  }

  static WalletType get _type => WalletType.zcash;

  static ZcashNetwork networkFor(final WalletInfo? walletInfo) =>
      ZcashNetwork.fromName(walletInfo?.network ?? ZcashNetwork.mainnet.value);

  static ZcashNetwork networkForCredentials(final WalletCredentials credentials) {
    if (credentials is ZcashNewWalletCredentials) {
      return ZcashNetwork.fromIndex(credentials.network);
    }
    if (credentials is ZcashFromSeedWalletCredentials) {
      return ZcashNetwork.fromIndex(credentials.network);
    }
    if (credentials is ZcashFromKeysWalletCredentials) {
      return ZcashNetwork.fromIndex(credentials.network);
    }
    if (credentials is ZcashRestoreWalletFromHardware) {
      return ZcashNetwork.fromIndex(credentials.network);
    }
    return ZcashNetwork.mainnet;
  }

  static Future<int> birthHeightForNetwork(final ZcashNetwork network) async {
    if (network != ZcashNetwork.mainnet) {
      return 1;
    }
    return ZcashHeight.getBlockHeightByTime(DateTime.now());
  }

  static Future<String> getDbDataPath({final ZcashNetwork network = ZcashNetwork.mainnet}) async {
    final pathForWalletType = await pathForWalletTypeDir(type: _type);
    final dbDataPath = "${pathForWalletType}/${network.dbFileName}";
    if (!Directory(pathForWalletType).existsSync()) {
      Directory(pathForWalletType).createSync(recursive: true);
    }
    return dbDataPath;
  }

  static Future<String> getDbDataPathLegacyYwallet() async {
    final pathForWalletType = await pathForWalletTypeDir(type: _type);
    final dbDataPath = "${pathForWalletType}/zec.db";
    if (!Directory(pathForWalletType).existsSync()) {
      Directory(pathForWalletType).createSync(recursive: true);
    }
    return dbDataPath;
  }

  static bool _initialized = false;
  static bool _rustInitialized = false;
  static ZcashNetwork? _activeNetwork;

  static void unlockDatabase(final String password) {
    _password = password;
  }

  static var c = zkool_coin.Coin();

  static String? _password;
  /// Loads the native library without opening a database, for callers that
  /// only need pure key or device operations before any wallet exists.
  static Future<void> ensureRustLib() async {
    if (!_rustInitialized) {
      await zkool_frb.RustLib.init();
      _rustInitialized = true;
    }
  }

  static Future<void> $init({final ZcashNetwork network = ZcashNetwork.mainnet}) async {
    await ensureRustLib();
    if (_initialized && _activeNetwork == network) {
      return;
    }
    printV(r".$init($network)");
    ZcashMempoolService.instance.onAccountsUpdated = (final accountIds) {
      for (final accountId in accountIds) {
        unawaited(refreshWalletForAccount(accountId));
      }
    };
    final dbFile = File(await getDbDataPath(network: network));
    final ywalletDbFile = File(await getDbDataPathLegacyYwallet());
    await zkool_network.initDatadir(directory: dbFile.parent.path);
    c = await c.openDatabase(dbFilepath: dbFile.path, password: null);
    printV("initWallet: ${dbFile.path}");
    if (_password == null) {
      throw Exception("Zcash wallet locked! Please contact support");
    }
    if (!dbFile.existsSync()) {
      //TODO(mrcyjanek): copy-encrypt
    }
    if (!ywalletDbFile.existsSync()) {
      //TODO(mrcyjanek): migrate to zkool
    }

    _activeNetwork = network;
    _initialized = true;
  }

  static Future<int> getHeightByDate(final DateTime date) async {
    final height = await ZcashHeight.getBlockHeightByTime(date);
    return height;
  }

  static Future<int> newAccount({
    required final String name,
    required final int height,
    required final String seed,
    required final String passphrase,
    final int hw = 0,
    final int aindex = 0,
    final int? pools,
  }) async {
    final id = await zkool_account.newAccount(
      na: zkool_account.NewAccount(
        name: name,
        restore: true,
        passphrase: passphrase,
        // For a hardware account this is the unified viewing key the device
        // exported; the backend stores it as a watch-only account.
        key: seed,
        // The device derives its keys at this ZIP-32 index and refuses to
        // sign for any other, so it is carried through verbatim.
        aindex: aindex,
        birth: height,
        folder: '',
        useInternal: true,
        internal: false,
        pools: pools,
        hw: hw,
      ),
      c: c,
    );
    return id;
  }

  /// Pairs a Ledger running the Official Zcash app as a watch-only wallet.
  ///
  /// The unified viewing key is exported by the device here, approved on its
  /// screen, then stored as an Official Ledger account: the backend tracks
  /// transparent and Ironwood funds and builds transactions from it, while
  /// signing goes back to the device.
  static Future<ZcashWallet> restoreFromLedger(
    final ZcashRestoreWalletFromHardware credentials,
  ) async {
    final network = networkForCredentials(credentials);
    await $init(network: network);
    credentials.walletInfo?.network = network.value;

    final service = credentials.hardwareWalletService;
    if (service is! ZcashLedgerService) {
      throw Exception("A Ledger connection is required to restore a Zcash hardware wallet");
    }
    final accounts = await service.getAvailableAccounts(
      index: credentials.accountIndex,
      limit: 1,
      network: network,
    );
    final ufvk = accounts.firstOrNull?.xpub;
    if (ufvk == null || ufvk.isEmpty) {
      throw Exception("The Ledger did not return a viewing key");
    }

    // The key crossed the link unauthenticated. The device now shows the
    // address it derives itself, and the user compares that screen with the
    // address the app derived from the key it received: a substituted key
    // gives a different address. The device's reply is checked too, which
    // catches an honest mismatch (a different account or path) outright.
    final expected = accounts.first.address;
    credentials.onVerifyAddress?.call(expected);
    final shown = await service.showAddressOnDevice(
      aindex: credentials.accountIndex,
      network: network,
    );
    if (shown != expected) {
      throw ZcashLedgerException(
        "The address the Ledger shows is not the one derived from the viewing key it "
        "exported. Do not use this wallet; check the device and connection and pair again.",
      );
    }

    // Without a date from the user, start at Sapling activation: nothing a
    // Ledger account can hold predates it, and Ledger Live has held
    // transparent ZEC since then.
    final height = (credentials.height ?? 0) > 0
        ? credentials.height!
        : (network == ZcashNetwork.mainnet ? 419200 : 280000);

    final accountId = await newAccount(
      name: credentials.name,
      height: height,
      seed: ufvk,
      passphrase: '',
      hw: zkoolHwOfficialLedger,
      aindex: credentials.accountIndex,
    );
    await saveAccountId(credentials.name, accountId);
    final wallet = await open(
      name: credentials.name,
      password: credentials.password!,
      walletInfo: credentials.walletInfo!,
    );
    wallet.hardwareWalletService = service;
    await wallet.init();
    printV("ledger account $accountId paired from height $height");
    return wallet;
  }

  static final runWithCoinMutex = Mutex();
  static int runWithCoinCount = 0;

  static Future<T> withSharedCoinLock<T>(final FutureOr<T> Function() func) async {
    await runWithCoinMutex.acquire();
    try {
      return await func();
    } finally {
      runWithCoinMutex.release();
    }
  }

  static FutureOr<T> runWithCoin<T>({
    required final int accountId,
    required final FutureOr<T> Function(zkool_coin.Coin c) func,
  }) async {
    await runWithCoinMutex.acquire();
    var newC = zkool_coin.Coin();
    newC = await newC.openDatabase(dbFilepath: c.dbFilepath);
    newC = await newC.setAccount(account: accountId);
    newC = await newC.setLwd(serverType: c.serverType, url: c.url);
    // Same route to the server as the shared coin (direct, Tor, proxy).
    newC = newC.setTransport(transport: c.transport).setProxy(proxy: c.proxy);

    runWithCoinCount++;
    printV("run with coin: $runWithCoinCount");
    try {
      newC = await newC.setAccount(account: accountId);
      return await func(newC);
    } finally {
      runWithCoinMutex.release();
      runWithCoinCount--;
    }
  }
}
