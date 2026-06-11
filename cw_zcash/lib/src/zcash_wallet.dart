import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/get_height_by_date_zec.dart';
import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
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
import 'package:cw_zcash/src/zkool_compat.dart';
import 'package:cw_zcash/src/zkooltx.dart';
import 'package:mobx/mobx.dart';
import 'package:mutex/mutex.dart';
import 'package:zkool/src/rust/api/account.dart' as zkool_account;
import 'package:zkool/src/rust/api/coin.dart' as zkool_coin;
import 'package:zkool/src/rust/api/mempool.dart' as zkool_mempool;
import 'package:zkool/src/rust/api/sync.dart' as zkool_sync;
import 'package:zkool/src/rust/api/pay.dart' as zkool_pay;
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

  @override
  @observable
  SyncStatus syncStatus = NotConnectedSyncStatus();

  @override
  ObservableMap<CryptoCurrency, ZcashBalance> balance = ObservableMap.of({
    CryptoCurrency.zec: ZcashBalance.zero(),
  });

  static const int _autoShieldMinSweep = 30000;

  Money _feeFromTxPlan(
    final zkool_pay.PcztPackage txPlan,
    final TransactionPriority priority,
    final int tryReduceFeeAmount,
  ) {
    try {
      return Money(zkool_pay.toPlan(package: txPlan, c: c).fee, currency);
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

  Future<bool> _anyAccountNeedsSync(final int currentHeight) async {
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
    final ptc = currentHeight > 0
        ? (walletHeight / currentHeight).clamp(0.0, 1.0)
        : 0.0;
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
      c = await c.setAccount(account: accountId);
      final currentHeight = await zkool_network.getCurrentHeight(c: c);
      final walletDbHeight = await _getWalletDbHeight();
      _broadcastSyncProgress(currentHeight, walletDbHeight);
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
      c = await c.setAccount(account: accountId);
      final currentHeight = await zkool_network.getCurrentHeight(c: c);
      final walletDbHeight = await _getWalletDbHeight();
      if (!await _anyAccountNeedsSync(currentHeight)) {
        _syncCheckpointHeight = walletDbHeight;
        if (syncStatus is! SyncedSyncStatus) {
          syncStatus = SyncedSyncStatus();
        }
        isSyncing = false;
        return true;
      }
      await zkool_sync.cancelSync();
      final accounts = await zkool_account.listAccounts(c: c);
      final accountList = accounts.map((final a) => a.id).toList()
        ..removeWhere((final a) => a == c.account);
      c = await c.setAccount(account: accountId);
      final lagHeight = await _getLowestSyncHeight();
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
      c = await c.setAccount(account: accountId);
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
              error: e
                      .toString()
                      .replaceAll("AnyhowException(", "")
                      .split("\n")
                      .firstOrNull ??
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
            c = await c.setAccount(account: accountId);
            if (await _anyAccountNeedsSync(currentHeight)) {
              final lagHeight = await _getLowestSyncHeight();
              _broadcastSyncProgress(currentHeight, lagHeight);
            } else {
              runInAction(() {
                for (final wallet in walletsByAccountId.values) {
                  wallet.syncStatus = SyncedSyncStatus();
                }
              });
              for (final wallet in walletsByAccountId.values) {
                unawaited(wallet.updateBalance());
                unawaited(wallet.updateTransactions());
                unawaited(
                  ZcashTaddressRotation.updateCache(mainAccountId: wallet.accountId).then((_) async {
                    await wallet.walletAddresses.init();
                    await wallet.updateTransactions();
                  }).catchError((final e) {
                    printV("rotation cache refresh: $e");
                  }),
                );
              }
            }
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

  @override
  Future<PendingTransaction> createTransaction(final Object credentials) =>
      _createTransaction(credentials);

  Future<PendingTransaction> _createTransaction(
    final Object credentials, {
    final int tryReduceFeeAmount = 0,
  }) async {
    final creds = credentials as ZcashTransactionCredentials;
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
      final recipientAddress =
          output.isParsedAddress ? output.extractedAddress! : output.address;
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
    // 1=Transparent, 2=Sapling, 4=Orchard, 7=All pools
    // Using 7 (all pools) allows spending from any pool type
    try {
      final txPlan = await zkool_pay.prepare(
        recipients: recipients,
        options: zkool_pay.PaymentOptions(
          srcPools: 7,
          recipientPaysFee: receipientPaysFee,
          smartTransparent: false,
        ),
        c: c,
      );
      final txFee = _feeFromTxPlan(txPlan, creds.priority, tryReduceFeeAmount);
      return PendingZcashTransaction(
        zcashWallet: this as ZcashWallet,
        credentials: creds,
        txPlan: txPlan,
        fee: txFee,
        availableBalance: availableBalance,
      );
    } catch (e) {
      if (tryReduceFeeAmount != 0) rethrow;
      final estr = e.toString();
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

  ZcashTransactionInfo _zcashInfoFromMempoolTx(
    final zkool_mempool.MempoolTx tx,
    final int accountId,
  ) {
    final accountNotes = tx.notes.where((final n) => n.account == accountId);
    final netValue = accountNotes.fold<BigInt>(
      BigInt.zero,
      (final sum, final note) => sum + BigInt.from(note.value),
    );
    final direction = netValue >= BigInt.zero
        ? TransactionDirection.incoming
        : TransactionDirection.outgoing;
    final memo = accountNotes
        .map((final n) => n.memo)
        .whereType<String>()
        .where((final m) => m.isNotEmpty)
        .firstOrNull;
    final to = accountNotes
        .map((final n) => n.address)
        .whereType<String>()
        .where((final a) => a.isNotEmpty)
        .firstOrNull;

    return ZcashTransactionInfo(
      id: ZcashWalletService.normalizeTxId(tx.txid),
      amount: Money(netValue.abs(), currency),
      fee: Money.zero(currency),
      direction: direction,
      isPending: true,
      date: DateTime.now(),
      height: 0,
      confirmations: 0,
      to: to ?? "",
      memo: memo,
    );
  }

  ZcashTransactionInfo _zcashInfoFromZkoolTx(
    final ZkoolTx tx,
    final int currentHeight, {
    final String? extraMemo,
    final bool isRotationReceive = false,
    final bool isShieldAction = false,
    final TransactionDirection? directionOverride,
    final BigInt? amountOverride,
  }) {
    final confirmations =
        tx.height > 0 && currentHeight > 0 ? currentHeight - tx.height + 1 : 0;
    final memo = extraMemo != null ? "${tx.memo ?? ''}\n$extraMemo".trim() : tx.memo;
    return ZcashTransactionInfo(
      id: tx.txHash,
      amount: Money(amountOverride ?? tx.value, currency),
      fee: Money.zero(currency),
      direction: directionOverride ?? tx.direction,
      isPending: tx.height == 0,
      date: tx.time,
      height: tx.height,
      confirmations: confirmations,
      to: tx.to ?? "",
      memo: memo?.isNotEmpty == true ? memo : null,
      txType: tx.type,
      isRotationReceive: isRotationReceive,
      isShieldAction: isShieldAction,
    );
  }

  bool _isShieldActionTx(
    final ZkoolTx tx, {
    required final Set<String> rotationSweepHashes,
  }) {
    if (ZcashWalletService.isAutoshieldTx(tx.txHash)) {
      return true;
    }
    if (rotationSweepHashes.contains(tx.txHash)) {
      return true;
    }
    if (_isPayToSelfAutoshield(tx)) {
      return true;
    }
    if (tx.direction == TransactionDirection.outgoing &&
        (tx.type == TxType.shield || tx.type == TxType.transparentSelfTransfer)) {
      return true;
    }
    return false;
  }

  bool _isPayToSelfAutoshield(final ZkoolTx tx) {
    if (tx.type != TxType.shield && tx.type != TxType.transparentSelfTransfer) {
      return false;
    }
    if (tx.transparentOrSaplingSpent <= BigInt.zero) {
      return false;
    }
    if (tx.orchardReceived <= BigInt.zero) {
      return false;
    }
    for (final dest in tx.outputAddresses) {
      if (_addressBelongsToWallet(dest)) {
        return true;
      }
    }
    return tx.orchardReceived > BigInt.zero;
  }

  bool _shouldSplitAutoshieldTx(final ZkoolTx tx, {required final bool isShield}) {
    if (!isShield) {
      return false;
    }
    if (ZcashWalletService.isAutoshieldTx(tx.txHash) || _isPayToSelfAutoshield(tx)) {
      return tx.transparentOrSaplingSpent > BigInt.zero && tx.orchardReceived > BigInt.zero;
    }
    return false;
  }

  static String _txResultKey(final String txHash, {final String suffix = ''}) =>
      'tx_$txHash$suffix';

  static int _txDisplayPriority(final ZcashTransactionInfo info) {
    if (info.additionalInfo['isAutoShield'] == true) {
      return 3;
    }
    if (info.additionalInfo['isRotationReceive'] == true) {
      return 2;
    }
    return 1;
  }

  void _offerTx(
    final Map<String, ZcashTransactionInfo> byHash,
    final ZcashTransactionInfo info,
  ) {
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
        info.additionalInfo['isAutoShield'] == true &&
        info.direction == TransactionDirection.outgoing &&
        existing.direction == TransactionDirection.incoming) {
      byHash[hash] = info;
    }
  }

  bool _addressBelongsToWallet(final String addr) {
    for (final own in [
      walletAddresses.orchardAddress,
      walletAddresses.unifiedAddress,
      walletAddresses.saplingAddress,
      walletAddresses.transparentAddress,
    ]) {
      if (own == null || own.isEmpty) {
        continue;
      }
      if (addr == own || addr.startsWith(own) || own.startsWith(addr)) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<Map<String, ZcashTransactionInfo>> fetchTransactions() async {
    await ZcashWalletService.loadShieldTxs();
    // await ZcashWalletService.runInDbMutex(() => refreshAccountCache(coin, accountId));
    // await ZcashWalletService.runInDbMutex(() => refreshTxsCache(coin, accountId));
    c = await c.setAccount(account: accountId);
    final txsI = await zkool_account.listTxHistory(c: c);
    final txsA = await Future.wait(
      txsI.map((final tx) => zkool_account.getTxDetails(idTx: tx.id, c: c)),
    );
    final txs = <ZkoolTx>[];
    for (int i = 0; i < txsI.length; i++) {
      txs.add(ZkoolTx(txsI[i], txsA[i]));
    }
    // final txs = getCachedTxs(coin, accountId).toList();
    // ShieldedTx{id: 26, txId: 4d1be06ce2c2debec8d98ce4e9434c8aac27c980488b459017d423fdcab37f93, height: 3195705, shortTxId: 4d1be06c, timestamp: 1767730944, name: null, value: 1000000, address: null, memo: , messages: MemoVec{memos: null}}
    // final shieldTx = await getShieldTxForUi();

    // final txIds = txs.map((final tx) => tx.txId!.replaceAll('"', '')).toSet();
    // temporarySentTx[accountId]?.removeWhere(
    //   (final ttx) => txIds.contains(ttx.txId!.replaceAll('"', '')),
    // );
    // txs.addAll(temporarySentTx[accountId] ?? []);

    txs.sort((final a, final b) => a.height.compareTo(b.height));
    final Map<String, ZcashTransactionInfo> byHash = {};
    int currentHeight = 1;
    try {
      currentHeight = await zkool_network.getCurrentHeight(c: ZcashWalletBase.c);
    } catch (e) {
      printV("failed to get height: $e");
    }
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
          ),
        );
        continue;
      }
      _offerTx(
        byHash,
        _zcashInfoFromZkoolTx(tx, currentHeight, isShieldAction: true),
      );
    }

    final Map<String, ZcashTransactionInfo> splitEntries = {};
    for (final tx in txs) {
      final isShield = _isShieldActionTx(tx, rotationSweepHashes: rotationSweepHashes);
      if (_shouldSplitAutoshieldTx(tx, isShield: isShield)) {
        byHash.remove(tx.txHash);
        splitEntries[_txResultKey(tx.txHash, suffix: '_shield')] = _zcashInfoFromZkoolTx(
          tx,
          currentHeight,
          isShieldAction: true,
          directionOverride: TransactionDirection.outgoing,
          amountOverride: tx.transparentOrSaplingSpent,
        );
        splitEntries[_txResultKey(tx.txHash, suffix: '_recv')] = _zcashInfoFromZkoolTx(
          tx,
          currentHeight,
          directionOverride: TransactionDirection.incoming,
          amountOverride: tx.orchardReceived,
        );
        continue;
      }
      _offerTx(
        byHash,
        _zcashInfoFromZkoolTx(tx, currentHeight, isShieldAction: isShield),
      );
    }

    final knownHashes = {
      for (final tx in txs) tx.txHash,
      ...byHash.keys,
    };
    for (final mempoolTx in ZcashMempoolService.instance.txsForAccount(accountId)) {
      final hash = ZcashWalletService.normalizeTxId(mempoolTx.txid);
      if (knownHashes.contains(hash)) {
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
    final legacyWalletPath = await pathForWallet(name: name, type: type);
    final legacyWalletFile = File(legacyWalletPath);
    final currentWalletFile = File(legacyWalletPath + ".v2");
    final newLegacyWalletPath = await pathForWallet(name: newWalletName, type: type);
    if (legacyWalletFile.existsSync()) {
      await legacyWalletFile.copy(newLegacyWalletPath);
    }
    if (currentWalletFile.existsSync()) {
      await currentWalletFile.copy(newLegacyWalletPath + ".v2");
    }
    Directory(legacyWalletPath).deleteSync(recursive: true);
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
    await zkool_sync.rewindSync(height: height, account: accountId, c: c);
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

  Future<void> updateTransactions() async {
    try {
      if (_isTransactionUpdating) {
        return;
      }

      _isTransactionUpdating = true;
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
      _isTransactionUpdating = false;
    } catch (e, stackTrace) {
      printV("Update transactions error: $e");
      printV("Stack trace: $stackTrace");
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
        ZcashTaddressRotation.updateCache(mainAccountId: accountId).then((_) async {
          await walletAddresses.init();
          await updateTransactions();
        }).catchError((final e) => printV("rotation cache refresh: $e")),
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

  Future<void> _$autoShield() async {
    if (syncStatus is! SyncedSyncStatus) {
      return;
    }
    c = await c.setAccount(account: accountId);
    final _notes = await zkool_account.listNotes(c: c);
    final List<zkool_account.TxNote> txNotes = [];
    for (int i = 0; i < _notes.length; i++) {
      final note = _notes[i];
      final noteType = NotePool.values[note.pool];
      if ([NotePool.sapling, NotePool.transparent].contains(noteType)) {
        txNotes.add(note);
      }
    }

    final sweepable = txNotes.isEmpty
        ? BigInt.from(0)
        : txNotes.map((final txn) => txn.value).reduce((final a, final b) => a + b);

    if (sweepable <= BigInt.from(_autoShieldMinSweep)) {
      return;
    }

    final txPlan = await zkool_pay.prepare(
      recipients: [
        zkool_paydart.Recipient(
          assetBase: zecBase,
          address: walletAddresses.orchardAddress!,
          amount: sweepable,
        ),
      ],
      options: zkool_pay.PaymentOptions(
        srcPools: 3,
        recipientPaysFee: true,
        smartTransparent: false,
      ),
      c: c,
    );

    final signTx = await zkool_pay.signTransaction(pczt: txPlan, c: ZcashWalletBase.c);
    final txBytes = await zkool_pay.extractTransaction(package: signTx);
    final currentHeight = await zkool_network.getCurrentHeight(c: ZcashWalletBase.c);
    final _txId = await zkool_pay.broadcastTransaction(
      height: currentHeight,
      txBytes: txBytes,
      c: ZcashWalletBase.c,
    );

    await ZcashWalletService.addShieldedTx(_txId);
    _lastAutoShieldAt = DateTime.now();
    printV("shielded: $_txId");
    await updateTransactions();
    await _refreshBalance(runAutoShield: false);
  }

  Future<void> _refreshBalance({required final bool runAutoShield}) async {
    try {
      c = await c.setAccount(account: accountId);

      final bal = await zkool_sync.balance(c: c);

      // 0 - transparent
      // 1 - sapling
      // 2 - orchard
      final confirmedTotal = bal.field0.reduce((final a, final b) => a + b);

      // int knownOutPending = 0;
      // ZcashWalletBase.temporarySentTx[accountId]?.forEach((final sTx) {
      //   knownOutPending += sTx.value; // it's negative
      // });
      final confirmedSpendable = confirmedTotal - bal.field0[0];

      if (runAutoShield) {
        await _autoShield();
      }

      balance[CryptoCurrency.zec] = ZcashBalance(
        Money(confirmedSpendable, currency),
        Money(confirmedTotal - confirmedSpendable, currency),
        frozen: Money.zero(currency),
      );
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
    await $init();
    final newWalletCredentials = credentials as ZcashNewWalletCredentials;

    String mnemonic;
    if (newWalletCredentials.mnemonic?.isNotEmpty == true) {
      mnemonic = newWalletCredentials.mnemonic!;
    } else {
      final strength = (newWalletCredentials.seedPhraseLength == 24) ? 256 : 128;
      mnemonic = bip39.generateMnemonic(strength: strength);
    }

    final birthHeight = await ZcashHeight.getBlockHeightByTime(DateTime.now());

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
    await $init();
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
    await $init();
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
    await $init();
    // if (password.isNotEmpty) {
    //   setDbPasswd(coin, password);
    // }
    final accountId = await getZcashAccountIdForName(name);
    if (accountId == null) {
      throw Exception("accountId is null");
    }
    c = await c.setAccount(account: accountId);
    if (accountId == null) {
      throw Exception("Wallet account not found for name: $name");
    }
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

  static Future<String> getDbDataPath() async {
    final pathForWalletType = await pathForWalletTypeDir(type: _type);
    final dbDataPath = "${pathForWalletType}/zec.v2.db";
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

  static void unlockDatabase(final String password) {
    _password = password;
  }

  static var c = zkool_coin.Coin();

  static String? _password;
  static Future<void> $init() async {
    if (_initialized) return;
    _initialized = true;
    printV(r".$init()");
    await zkool_frb.RustLib.init();
    ZcashMempoolService.instance.onAccountsUpdated = (final accountIds) {
      for (final accountId in accountIds) {
        unawaited(refreshWalletForAccount(accountId));
      }
    };
    final dbFile = File(await getDbDataPath());
    final ywalletDbFile = File(await getDbDataPathLegacyYwallet());
    await zkool_network.initDatadir(directory: dbFile.parent.path);
    // c = await c.openDatabase(dbFilepath: dbFile.path, password: 'cw_zcash_migration');
    c = await c.openDatabase(dbFilepath: dbFile.path, password: null);
    printV("initWallet");
    if (_password == null) {
      throw Exception("Zcash wallet locked! Please contact support");
    }
    if (!dbFile.existsSync()) {
      //TODO(mrcyjanek): copy-encrypt
    }
    if (!ywalletDbFile.existsSync()) {
      //TODO(mrcyjanek): migrate to zkool
    }

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
  }) async {
    final id = await zkool_account.newAccount(
      na: zkool_account.NewAccount(
        name: name,
        restore: true,
        passphrase: passphrase,
        key: seed,
        aindex: 0,
        birth: height,
        folder: '',
        useInternal: true,
        internal: false,
        ledger: false,
      ),
      c: c,
    );
    return id;
  }

  static final runWithCoinMutex = Mutex();
  static int runWithCoinCount = 0;
  static FutureOr<T> runWithCoin<T>({
    required final int accountId,
    required final FutureOr<T> Function(zkool_coin.Coin c) func,
  }) async {
    var newC = zkool_coin.Coin();
    newC = await newC.openDatabase(dbFilepath: c.dbFilepath);
    newC = await newC.setAccount(account: accountId);
    newC = await newC.setLwd(serverType: c.serverType, url: c.url);
    newC = await newC.setUseTor(useTor: c.useTor);

    runWithCoinCount++;
    printV("run with coin: $runWithCoinCount");
    await runWithCoinMutex.acquire();
    try {
      newC = await newC.setAccount(account: accountId);
      return await func(newC);
    } finally {
      runWithCoinMutex.release();
      runWithCoinCount--;
    }
  }
}
