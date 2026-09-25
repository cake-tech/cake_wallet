import 'dart:async';
import 'dart:convert';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cw_bitcoin/bitcoin_mnemonics_bip39.dart';
import 'package:cw_bitcoin/bitcoin_transaction_credentials.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/electrum.dart' as electrum;
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_bitcoin/electrum_wallet_snapshot.dart';
import 'package:cw_bitcoin/exceptions.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_pivx/src/pivx_transaction_priority.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/sync_status.dart' as core_sync;
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:synchronized/synchronized.dart';

import 'pivx_exchange_address.dart';
import 'pivx_network.dart';
import 'pivx_wallet_addresses.dart';
import 'pending_pivx_shielded_transaction.dart';
import 'sapling/sapling_constants.dart';
import 'sapling/pivx_sapling_electrumx.dart';
import 'sapling/sapling_factories.dart';
import 'sapling/sapling_note_storage.dart';

part 'pivx_wallet.g.dart';

/// ElectrumWallet plus Sapling. Balance carries transparent as primary and
/// shielded as second*. Routes: t->t, t->z, z->z, z->t.
class PivxWallet = PivxWalletBase with _$PivxWallet;

abstract class PivxWalletBase extends ElectrumWallet with Store {
  static const int _shieldedRestoreAddressReuseScanLimit = 1000;
  static const int _shieldedBirthdayRewindBlocks = 1440;

  static String sanitizeShieldSyncError(Object error) {
    final text = error.toString().toLowerCase();

    if (text.contains('tree cursor') ||
        text.contains('global output positions')) {
      return 'PIVX Sapling sync requires a Sapling v1 ElectrumX node with global output positions. Switch nodes and retry.';
    }
    if (text.contains('advertises v1') ||
        text.contains('release contract features')) {
      return 'Current PIVX node advertises incomplete Sapling v1 support. Switch to a fully upgraded Sapling v1 node and retry.';
    }
    if (text.contains('incomplete range') ||
        text.contains('partial_index') ||
        text.contains('index_not_ready') ||
        text.contains('backend_timeout')) {
      return 'Current PIVX node did not return a complete Sapling block range yet. Wait for the node to finish indexing and retry.';
    }
    if (text.contains('block scanning') ||
        text.contains('get_block_range') ||
        text.contains('rpc method unavailable')) {
      return 'Current PIVX node does not support Sapling block scanning. Switch to a Sapling-capable node and retry.';
    }
    if (text.contains('network mismatch')) {
      return 'Current PIVX node is on the wrong network for this wallet. Switch nodes and retry.';
    }
    if (text.contains('activation height mismatch')) {
      return 'Current PIVX node reports an unexpected Sapling activation height. Switch nodes and retry.';
    }

    return 'PIVX Sapling sync failed. Check node capability and retry.';
  }

  PivxWalletBase({
    required String mnemonic,
    required String password,
    required WalletInfo walletInfo,
    required DerivationInfo derivationInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required Uint8List seedBytes,
    required EncryptionFileUtils encryptionFileUtils,
    String? passphrase,
    BitcoinAddressType? addressPageType,
    List<BitcoinAddressRecord>? initialAddresses,
    ElectrumBalance? initialBalance,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
    electrum.ElectrumClient? electrumClient,
  }) : super(
          mnemonic: mnemonic,
          password: password,
          walletInfo: walletInfo,
          derivationInfo: derivationInfo,
          unspentCoinsInfo: unspentCoinsInfo,
          network: PivxNetwork.mainnet,
          initialAddresses: initialAddresses,
          initialBalance: initialBalance,
          seedBytes: seedBytes,
          currency: CryptoCurrency.pivx,
          encryptionFileUtils: encryptionFileUtils,
          passphrase: passphrase,
          electrumClient: electrumClient,
        ) {
    walletAddresses = PivxWalletAddresses(
      walletInfo,
      initialAddresses: initialAddresses,
      initialRegularAddressIndex: initialRegularAddressIndex,
      initialChangeAddressIndex: initialChangeAddressIndex,
      mainHdByTypeAndAccount: mainHdByTypeAndAccount,
      sideHdByTypeAndAccount: sideHdByTypeAndAccount,
      accountIndexes: [currentAccountIndex],
      currentAccountIndex: currentAccountIndex,
      legacyMainHd: mainHd,
      legacySideHd: sideHd,
      network: PivxNetwork.mainnet,
      // P2PKH only; dev's resolver otherwise defaults to p2wpkh.
      initialAddressPageType: addressPageType ?? P2pkhAddressType.p2pkh,
      isHardwareWallet: walletInfo.isHardwareWallet,
    );
    autorun((_) {
      this.walletAddresses.isEnabledAutoGenerateSubaddress =
          this.isEnabledAutoGenerateSubaddress;
    });
  }

  @override
  Future<void> init() async {
    await super.init();
    await tryInitializeSapling();
    _ensureShieldedHeaderSyncSubscription();
  }

  // Capabilities (byte order, features) are per node, and close() drops the
  // subjects behind both subscriptions without closing them.
  @override
  Future<void> connectToNode({required Node node}) async {
    await _shieldedHeaderSyncSubscription?.cancel();
    _shieldedHeaderSyncSubscription = null;
    await _mempoolSubscription?.cancel();
    _mempoolSubscription = null;
    // A pass left running would finish against the new socket and a cleared
    // capability cache; startSync would also skip while it holds the flag.
    // The pass checks the stop flag between ranges; one range fetch is capped
    // at kSaplingBlockRangeFetchTimeout, so this outlasts it. Cost: a switch
    // during a stalled range waits up to 35s.
    _shieldSyncEngine?.requestStop();
    await _awaitShieldSyncStop(
        kSaplingBlockRangeFetchTimeout + const Duration(seconds: 5));
    _shieldSyncEngine?.saplingClient.invalidateCapabilities();
    await super.connectToNode(node: node);
  }

  Future<void> _awaitShieldSyncStop(Duration cap) async {
    final deadline = DateTime.now().add(cap);
    while (isShieldSyncing && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  Future<void> close({bool shouldCleanup = false}) async {
    await _shieldedHeaderSyncSubscription?.cancel();
    _shieldedHeaderSyncSubscription = null;
    await _mempoolSubscription?.cancel();
    _mempoolSubscription = null;
    _shieldedSyncPollTimer?.cancel();
    _shieldedSyncPollTimer = null;
    // A pass still running would write this wallet's state after close.
    // Closing the client fails its RPCs and blocks new ones, so it exits.
    // Cost: up to 5s; past that the disposed-handle guard throws inside the
    // pass, safe as all FFI runs on this isolate.
    _shieldSyncEngine?.requestStop();
    await electrumClient.close();
    await _awaitShieldSyncStop(const Duration(seconds: 5));
    _shieldSyncEngine?.storage.release();
    for (final dispose in [
      _saplingTxBuilder?.dispose,
      _shieldSyncEngine?.dispose,
      _saplingKeyManager?.dispose,
    ]) {
      try {
        dispose?.call();
      } catch (_) {}
    }
    _saplingTxBuilder = null;
    _shieldSyncEngine = null;
    _saplingKeyManager = null;
    await super.close(shouldCleanup: shouldCleanup);
  }

  SaplingKeyManager? _saplingKeyManager;
  ShieldSyncEngine? _shieldSyncEngine;
  SaplingTransactionBuilder? _saplingTxBuilder;

  /// Serializes balance updates and shielded builds (note selection).
  final _balanceLock = Lock();

  /// A mempool push and the poll share the peek engine.
  final _mempoolLock = Lock();
  bool _transparentBalanceStale = false;
  final _historyLock = Lock();

  StreamSubscription<Object>? _shieldedHeaderSyncSubscription;
  DateTime? _lastHeaderTriggeredShieldSync;

  /// 0-conf push feed; null means the poll is the only source.
  StreamSubscription<SaplingMempoolResult>? _mempoolSubscription;

  /// The header subscription goes stale after a mobile reconnect; this keeps
  /// receives and confirmations live without a restart.
  Timer? _shieldedSyncPollTimer;

  /// Set while shielded catch-up owns [syncStatus], so completion restores it.
  bool _shieldSyncDrivesStatus = false;

  // Throttle for catch-up progress. A range completes every ~100 blocks, out of
  // order across 12 parallel fetches; every SyncingSyncStatus appends to Cake's
  // ETA history, which the UI re-sorts on each rebuild, so unthrottled it lags.
  DateTime? _lastShieldProgressAt;
  int? _lastShieldBlocksLeft;

  @observable
  bool saplingEnabled = true;

  /// Shielded balance in zatoshis (1 PIV = 1e8).
  @observable
  int shieldedBalance = 0;

  /// Unconfirmed shielded balance in zatoshis.
  @observable
  int pendingShieldedBalance = 0;

  /// Display-only 0-conf receives; dropped once mined or evicted.
  List<MempoolIncomingNote> _mempoolIncoming = <MempoolIncomingNote>[];

  /// Until a snapshot arrives, absence from [_mempoolIncoming] proves nothing.
  bool _mempoolSnapshotSeen = false;

  int get _mempoolIncomingTotal {
    // A stale snapshot after mining would double-count a landed note.
    final known = _shieldSyncEngine?.storage.notes.map((n) => n.txid).toSet() ??
        const <String>{};
    return _mempoolIncoming
        .where((n) => !known.contains(n.txid))
        .fold<int>(0, (sum, n) => sum + n.value);
  }

  int get _displayPendingShielded =>
      pendingShieldedBalance + _mempoolIncomingTotal;

  @observable
  int lastShieldSyncedBlock = 0;

  @observable
  bool isShieldSyncing = false;

  // Last successful split per scripthash; addressRecord.balance folds both.
  final Map<String, int> _lastConfirmedBySh = {};
  final Map<String, int> _lastUnconfirmedBySh = {};

  @observable
  String? currentShieldedAddress;

  Money _pivxMoney(int amount) => Money.fromInt(amount, CryptoCurrency.pivx);

  Money get _zeroPivxMoney => Money.zero(CryptoCurrency.pivx);

  @override
  bool get hasRescan => true;

  @override
  Future<void> rescan({required int height, bool? doSingleScan}) async {
    _rescanning = true;
    try {
      await _rescan(height);
    } finally {
      _rescanning = false;
    }
  }

  // Base startSync gates on its own private flag, not the status, so it would
  // run its transparent refresh alongside this one and could report Synced
  // while the shielded rescan is still going; startSync checks this instead.
  bool _rescanning = false;

  Future<void> _rescan(int height) async {
    // The reconnect timer keys off the connection states, so never mask or
    // strand them.
    bool offline() =>
        syncStatus is core_sync.NotConnectedSyncStatus ||
        syncStatus is core_sync.LostConnectionSyncStatus ||
        syncStatus is core_sync.ConnectingSyncStatus;
    if (!offline()) syncStatus = core_sync.SyncronizingSyncStatus();

    // Not super.rescan(): it starts silent-payment scanning the PIVX server
    // cannot answer. Transparent state is live, so refresh it instead.
    var failed = false;
    try {
      await updateTransactions();
      await updateAllUnspents();
      await updateBalance();
    } catch (e) {
      failed = true;
      printV('[PIVX] transparent refresh during rescan failed: $e');
    }

    var shieldFailed = false;
    try {
      if (saplingEnabled) await rescanShielded(fromHeight: height);
    } catch (e) {
      shieldFailed = true;
      printV('[PIVX] rescan failed: ${sanitizeShieldSyncError(e)}');
    }
    // A pass that ended short without progress met Syncronizing, which the
    // shielded status rule leaves alone; far behind that is not Synced.
    if (saplingEnabled && _shieldedBlocksBehindIndex > 100) shieldFailed = true;
    // Transparent failure is a connection problem: Failed, and the base
    // reconnects. A shielded-only failure is Attempting (no reconnect). A
    // Syncing or Attempting the shielded pass still owns is left to it.
    if (!offline()) {
      final current = syncStatus;
      if (failed) {
        _shieldSyncDrivesStatus = false;
        syncStatus = core_sync.FailedSyncStatus();
      } else if (current is core_sync.SyncingSyncStatus ||
          current is core_sync.AttemptingSyncStatus) {
        // owned by the shielded pass
      } else if (shieldFailed) {
        _shieldSyncDrivesStatus = true;
        syncStatus = core_sync.AttemptingSyncStatus();
      } else {
        syncStatus = core_sync.SyncedSyncStatus();
      }
    }
  }

  /// Seed bytes are zeroed after use; a failure leaves no key manager behind.
  Future<void> initializeSapling() async {
    if (_saplingKeyManager != null) return;

    SaplingKeyManager? tempKeyManager;
    Uint8List? saplingSeeds;

    try {
      final mnemonic = seed;
      if (mnemonic == null) {
        throw StateError('Cannot initialize Sapling without mnemonic seed');
      }
      saplingSeeds = MnemonicBip39.toSeed(mnemonic, passphrase: passphrase);
      tempKeyManager = SaplingKeyManager.fromSeed(saplingSeeds);
      final address = tempKeyManager.defaultAddress;

      _saplingKeyManager = tempKeyManager;
      currentShieldedAddress = address;
      _setSaplingEnabled(true);
    } catch (e) {
      try {
        tempKeyManager?.dispose();
      } catch (_) {}
      _setSaplingEnabled(false);
      rethrow;
    } finally {
      saplingSeeds?.fillRange(0, saplingSeeds.length, 0);
    }
  }

  /// Never throws: a missing native lib disables Sapling.
  Future<bool> tryInitializeSapling() async {
    if (_saplingKeyManager != null) return true;
    if (!saplingEnabled) return false;

    try {
      await initializeSapling();
    } catch (e) {
      printV('[PIVX] Sapling initialization failed');
      _setSaplingEnabled(false);
      return false;
    }

    // Stored balance and history show before the first sync (which can fail on
    // a flaky node); notes go back into the native engine so they are spendable.
    try {
      await _ensureShieldSyncEngineInitialized();
      await _reconcileShieldedBalance();
    } catch (e) {
      printV('[PIVX] Failed to restore shielded state from storage');
    }
    return true;
  }

  /// The receive page offers the shielded option only when Sapling works.
  void _setSaplingEnabled(bool enabled) {
    saplingEnabled = enabled;
    final addresses = walletAddresses;
    if (addresses is PivxWalletAddresses) addresses.saplingEnabled = enabled;
  }

  int get _shieldConfirmationHeight => _shieldSyncEngine!.confirmationHeight;

  /// Lets an auto-selected z-to-z fall back to t-to-z instead of failing.
  bool _isInsufficientShieldedFunds(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('insufficient shielded balance') ||
        message.contains('insufficient balance after fee') ||
        message.contains('could not select sufficient notes') ||
        message.contains('no spendable shielded notes');
  }

  /// Recompute shielded balance and history from stored notes. Call after any
  /// sync, broadcast or note mutation.
  Future<void> _reconcileShieldedBalance() async {
    if (_shieldSyncEngine == null) return;

    await _balanceLock.synchronized(() async {
      try {
        final refHeight = _shieldConfirmationHeight;
        shieldedBalance = _shieldSyncEngine!.balanceAt(refHeight);
        pendingShieldedBalance = _shieldSyncEngine!.pendingBalanceAt(refHeight);
        // Always, even when the observables match: onProgress updates them but
        // not the map the UI reads.
        _applyShieldedBalanceToMap();
      } catch (e) {
        printV('[PIVX] Balance reconciliation failed');
      }
    });

    try {
      await _refreshShieldedTransactionHistory();
    } catch (e) {
      printV('[PIVX] Shielded tx history refresh failed');
    }

    // Separate route so 0-conf shows even before the first confirmed note.
    try {
      await _refreshShieldedMempoolHistory();
    } catch (e) {
      printV('[PIVX] Shielded mempool history refresh failed');
    }
  }

  /// One snapshot is one miss: a receive it leaves out stays until it is mined
  /// (a stored note takes over), misses _kEvictionConfirmations complete
  /// snapshots in a row, or the canary check evicts it. The snapshot count
  /// still evicts on a fresh wallet with no mined note to act as canary.
  List<MempoolIncomingNote> _mergeMempoolSnapshot(
      List<MempoolIncomingNote> fresh) {
    // One entry per txid: a repeated record would double the pending balance.
    final seen = <String>{};
    fresh = [for (final n in fresh) if (seen.add(n.txid)) n];
    final freshTxids = seen;
    final storedTxids =
        _shieldSyncEngine?.storage.notes.map((n) => n.txid).toSet() ??
            const <String>{};
    final kept = <MempoolIncomingNote>[...fresh];
    for (final txid in freshTxids) {
      _mempoolAbsentStreak.remove(txid);
    }
    // After a restart the in-memory list is empty but saved 0-conf rows are
    // not; seed from them so the first snapshot is one miss, not a deletion.
    final priors = _mempoolSnapshotSeen
        ? _mempoolIncoming
        : [
            ..._mempoolIncoming,
            for (final tx in transactionHistory.transactions.values)
              if (tx.additionalInfo['pivxRoute'] == 'z-mempool' &&
                  !_mempoolIncoming.any((n) => n.txid == tx.id))
                MempoolIncomingNote(
                  txid: tx.id,
                  value: tx.amount.amount.toInt(),
                  firstSeen: tx.date.millisecondsSinceEpoch ~/ 1000,
                ),
          ];
    for (final prior in priors) {
      if (freshTxids.contains(prior.txid) || storedTxids.contains(prior.txid)) {
        continue;
      }
      final misses = (_mempoolAbsentStreak[prior.txid] ?? 0) + 1;
      if (misses >= _kEvictionConfirmations) {
        _mempoolAbsentStreak.remove(prior.txid);
        continue;
      }
      _mempoolAbsentStreak[prior.txid] = misses;
      kept.add(prior);
    }
    _mempoolAbsentStreak
        .removeWhere((txid, _) => !kept.any((n) => n.txid == txid));
    return kept;
  }

  final Map<String, int> _mempoolAbsentStreak = {};

  /// Runs every sync even when subscribed: a reconnect silently drops the push
  /// feed with no replay. null keeps the prior snapshot.
  Future<void> _refreshShieldedMempool() async {
    if (_shieldSyncEngine == null) return;
    try {
      await _mempoolLock.synchronized(() async {
        final result = await _shieldSyncEngine!.scanMempool();
        if (result != null) {
          _mempoolIncoming = _mergeMempoolSnapshot(result);
          _mempoolSnapshotSeen = true;
        }
      });
    } catch (e) {
      printV('[PIVX Sapling] Mempool peek failed (non-fatal)');
    }
  }

  /// Push latency (~5s) instead of the poll cadence. Full-state replacement.
  Future<void> _ensureShieldedMempoolSubscription() async {
    if (_mempoolSubscription != null ||
        !saplingEnabled ||
        _shieldSyncEngine == null) {
      return;
    }
    SaplingRpcCapabilities caps;
    try {
      caps = await _shieldSyncEngine!.saplingClient.probeCapabilities();
    } catch (_) {
      return;
    }
    if (!caps.supportsMempoolSubscribe) return;
    final stream = _shieldSyncEngine!.saplingClient.mempoolSubscribe();
    if (stream == null) return;
    _mempoolSubscription = stream.listen((snapshot) async {
      if (!saplingEnabled ||
          _shieldSyncEngine == null ||
          _saplingKeyManager == null) {
        return;
      }
      try {
        await _mempoolLock.synchronized(() async {
          _mempoolIncoming = _mergeMempoolSnapshot(
              await _shieldSyncEngine!.decryptMempoolSnapshot(snapshot));
          _mempoolSnapshotSeen = true;
        });
        await _reconcileShieldedBalance();
      } catch (e) {
        printV('[PIVX Sapling] Mempool push apply failed (non-fatal)');
      }
    },
        // Drop a dead feed so the next sync re-subscribes.
        onError: (Object _) => _resetMempoolSubscription(),
        onDone: _resetMempoolSubscription,
        cancelOnError: false);
    printV('[PIVX Sapling] Subscribed to mempool push feed');
  }

  void _resetMempoolSubscription() {
    _mempoolSubscription?.cancel();
    _mempoolSubscription = null;
  }

  /// A valid PIVX tx mines within a few 60s blocks; past this an unmined tx the
  /// node no longer has was evicted or replaced.
  static const Duration _kPendingSpendEvictionGrace = Duration(minutes: 15);

  /// Consecutive missing observations before a pending send's notes release.
  static const int _kEvictionConfirmations = 3;

  final Map<String, int> _shieldedSpendMissStreak = {};
  final Map<String, int> _mempoolMissStreak = {};
  final Map<String, int> _orphanMissStreak = {};

  int _orphanCheckCursor = 0;

  /// Empty verbose also means a network failure, so fund-side callers pair this
  /// with the canary + grace + streak.
  Future<bool> _shieldedTxMissingFromNode(String txid) async {
    try {
      final verbose = await electrumClient.getTransactionVerbose(hash: txid);
      return verbose.isEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Evicted, replaced or reorged-out txs never resolve on their own: clean up
  /// stuck-pending history, locked notes and stale 0-conf.
  Future<void> _reconcileDisappearedShieldedTxs() async {
    if (_shieldSyncEngine == null || !electrumClient.isConnected) return;
    final storage = _shieldSyncEngine!.storage;
    final now = DateTime.now();
    var historyChanged = false;
    var balanceDirty = false;
    var releasedNotes = false;

    // Empty verbose also means a failing node; checked once, only if needed.
    bool? healthy;
    Future<bool> nodeHealthy() async {
      if (healthy != null) return healthy!;
      final canaries = <String>{};
      for (final note in storage.notes) {
        if (note.height > 0) {
          canaries.add(note.txid);
          if (canaries.length >= 3) break;
        }
      }
      for (final canary in canaries) {
        if (!await _shieldedTxMissingFromNode(canary)) return healthy = true;
      }
      return healthy = false;
    }

    // 1. Pending spends. Guarded hard (canary found, past grace, missing on
    // several cycles); a wrong release only costs a failed respend.
    final spendPendingAt = <String, DateTime?>{};
    for (final note in storage.notes) {
      final txid = note.pendingSpendingTxid;
      if (txid == null || note.isSpent) continue;
      final at = note.pendingSpendAt;
      final current = spendPendingAt[txid];
      if (!spendPendingAt.containsKey(txid) ||
          (at != null && (current == null || at.isBefore(current)))) {
        spendPendingAt[txid] = at;
      }
    }
    _shieldedSpendMissStreak
        .removeWhere((txid, _) => !spendPendingAt.containsKey(txid));
    if (spendPendingAt.isNotEmpty) {
      // Any of a few mined txs found = healthy node; one could be reorg-stale.
      if (await nodeHealthy()) {
        for (final entry in spendPendingAt.entries) {
          final at = entry.value;
          if (at == null || now.difference(at) < _kPendingSpendEvictionGrace) {
            _shieldedSpendMissStreak.remove(entry.key);
            continue;
          }
          if (!await _shieldedTxMissingFromNode(entry.key)) {
            _shieldedSpendMissStreak.remove(entry.key);
            continue;
          }
          final streak = (_shieldedSpendMissStreak[entry.key] ?? 0) + 1;
          _shieldedSpendMissStreak[entry.key] = streak;
          if (streak < _kEvictionConfirmations) continue;
          _shieldedSpendMissStreak.remove(entry.key);
          final released = await storage.releasePendingSpend(entry.key);
          if (released <= 0) continue;
          balanceDirty = true;
          releasedNotes = true;
          final tx = transactionHistory.transactions[entry.key];
          if (tx != null &&
              tx.direction == TransactionDirection.outgoing &&
              tx.isPending) {
            transactionHistory.transactions.remove(entry.key);
            historyChanged = true;
          }
        }
      }
    }

    // 2. 0-conf receives the node no longer has (re-added if they reappear).
    // Same bar as spends minus the grace: healthy node, several misses in a row.
    _mempoolMissStreak.removeWhere(
        (txid, _) => !_mempoolIncoming.any((note) => note.txid == txid));
    if (_mempoolIncoming.isNotEmpty && await nodeHealthy()) {
      final kept = <MempoolIncomingNote>[];
      for (final note in _mempoolIncoming) {
        if (!await _shieldedTxMissingFromNode(note.txid)) {
          _mempoolMissStreak.remove(note.txid);
          kept.add(note);
          continue;
        }
        final streak = (_mempoolMissStreak[note.txid] ?? 0) + 1;
        _mempoolMissStreak[note.txid] = streak;
        if (streak < _kEvictionConfirmations) {
          kept.add(note);
          continue;
        }
        _mempoolMissStreak.remove(note.txid);
      }
      if (kept.length != _mempoolIncoming.length) {
        _mempoolIncoming = kept;
        balanceDirty = true;
      }
    }

    // 3. z-receive entries with no backing note (reorged out).
    final noteTxids = storage.notes.map((n) => n.txid).toSet();
    final orphans = transactionHistory.transactions.entries
        .where((e) =>
            e.value.additionalInfo['isPivxShielded'] == true &&
            e.value.additionalInfo['pivxRoute'] == 'z-receive' &&
            !noteTxids.contains(e.key))
        .map((e) => e.key)
        .toList();
    _orphanMissStreak.removeWhere((txid, _) => !orphans.contains(txid));
    // Rows lose their note mid-rescan too; only a healthy node missing the tx
    // on several cycles proves a reorg.
    if (orphans.isNotEmpty && await nodeHealthy()) {
      // Rotating window caps node queries without starving later entries.
      const window = 15;
      final start =
          orphans.length <= window ? 0 : _orphanCheckCursor % orphans.length;
      for (var i = 0; i < orphans.length && i < window; i++) {
        final txid = orphans[(start + i) % orphans.length];
        if (!await _shieldedTxMissingFromNode(txid)) {
          _orphanMissStreak.remove(txid);
          continue;
        }
        final streak = (_orphanMissStreak[txid] ?? 0) + 1;
        _orphanMissStreak[txid] = streak;
        if (streak < _kEvictionConfirmations) continue;
        _orphanMissStreak.remove(txid);
        transactionHistory.transactions.remove(txid);
        historyChanged = true;
      }
      _orphanCheckCursor = (start + window) % orphans.length;
    }

    // Native restore skipped them while pending; the builder cannot select them
    // until they are re-added.
    if (releasedNotes) {
      try {
        _shieldSyncEngine!.restoreNotesFromStorage();
      } catch (e) {
        printV('[PIVX Sapling] Re-restore after spend release failed');
      }
    }

    if (historyChanged) await _saveHistory();
    if (balanceDirty) await _reconcileShieldedBalance();
  }

  // No network, unlike updateBalance().
  void _applyShieldedBalanceToMap() {
    final current = balance[currency];
    balance[currency] = ElectrumBalance(
      confirmed: current?.confirmed ?? _zeroPivxMoney,
      unconfirmed: current?.unconfirmed ?? _zeroPivxMoney,
      frozen: current?.frozen ?? _zeroPivxMoney,
      secondConfirmed: _pivxMoney(shieldedBalance),
      secondUnconfirmed: _pivxMoney(_displayPendingShielded),
    );
  }

  // Mined means at least one confirmation, even while the tip lags.
  int _confsAt(int height) {
    if (height <= 0) return 0;
    final confirmations = _shieldConfirmationHeight - height + 1;
    return confirmations < 1 ? 1 : confirmations;
  }

  void _markShieldedMined(ElectrumTransactionInfo tx, int height) {
    tx.height = height;
    tx.confirmations = _confsAt(height);
    tx.isPending = false;
  }

  ElectrumTransactionInfo _shieldedEntry({
    required String id,
    required int amount,
    int fee = 0,
    required TransactionDirection direction,
    required String route,
    int height = 0,
    DateTime? date,
    String? to,
    String? memo,
  }) {
    final confirmations = _confsAt(height);
    return ElectrumTransactionInfo(
      WalletType.pivx,
      id: id,
      height: height,
      amount: _pivxMoney(amount),
      fee: _pivxMoney(fee),
      direction: direction,
      isPending: direction == TransactionDirection.outgoing ||
          confirmations < PivxShieldedConfirmationPolicy.receiveConfirmations,
      date: date ?? DateTime.now(),
      confirmations: confirmations,
      to: to,
      additionalInfo: {
        'isPivxShielded': true,
        'pivxPool': 'shielded',
        'pivxRoute': route,
        'pivxRequiredConfirmations':
            PivxShieldedConfirmationPolicy.receiveConfirmations,
        if (memo != null) 'memo': memo,
      },
    );
  }

  Future<void> _refreshShieldedTransactionHistory() async {
    if (_shieldSyncEngine == null) return;

    final storage = _shieldSyncEngine!.storage;
    final byTxid = <String, List<StoredSaplingNote>>{};
    for (final note in storage.notes) {
      byTxid.putIfAbsent(note.txid, () => <StoredSaplingNote>[]).add(note);
    }

    // A transient-empty store (mid-rescan, failed load) must not rewrite
    // history. Orphaned z-receives are pruned node-checked elsewhere.
    if (byTxid.isEmpty) return;

    var changed = false;

    // Own sends (at broadcast via pendingSpendingTxid, after mining via
    // spendingTxid). Notes they create are change, never receives.
    final mySpendTxids = <String>{};
    final mySpendHeightsByTxid = <String, int>{};
    for (final note in storage.notes) {
      final spendingTxid = note.spendingTxid;
      if (spendingTxid != null) {
        mySpendTxids.add(spendingTxid);
        final spendingHeight = note.spendingHeight;
        if (spendingHeight != null && spendingHeight > 0) {
          final previous = mySpendHeightsByTxid[spendingTxid];
          if (previous == null || spendingHeight < previous) {
            mySpendHeightsByTxid[spendingTxid] = spendingHeight;
          }
        }
      }
      if (note.pendingSpendingTxid != null) {
        mySpendTxids.add(note.pendingSpendingTxid!);
      }
    }

    bool isShieldedOutgoing(ElectrumTransactionInfo? tx) =>
        tx != null &&
        tx.additionalInfo['isPivxShielded'] == true &&
        tx.direction == TransactionDirection.outgoing;

    for (final spend in mySpendHeightsByTxid.entries) {
      final existing = transactionHistory.transactions[spend.key];
      if (isShieldedOutgoing(existing)) {
        _markShieldedMined(existing!, spend.value);
        changed = true;
      }
    }

    for (final entry in byTxid.entries) {
      final notes = entry.value;
      final height =
          notes.map((note) => note.height).reduce((a, b) => a < b ? a : b);
      final existing = transactionHistory.transactions[entry.key];

      // Outgoing recorded at broadcast keeps its sent amount; the mined change
      // note only supplies its height.
      if (isShieldedOutgoing(existing)) {
        if (height > 0) {
          _markShieldedMined(existing!, height);
          changed = true;
        }
        continue;
      }
      final isShieldedIncoming =
          existing != null && existing.additionalInfo['isPivxShielded'] == true;
      if (mySpendTxids.contains(entry.key)) {
        if (isShieldedIncoming) {
          transactionHistory.transactions.remove(entry.key);
          changed = true;
        }
        continue;
      }

      final amount = notes.fold<int>(0, (sum, note) => sum + note.value);
      final memo = notes
          .map((note) => note.memo)
          .firstWhere((m) => m != null && m.isNotEmpty, orElse: () => null);
      if (existing == null) {
        transactionHistory.addOne(_shieldedEntry(
          id: entry.key,
          height: height,
          amount: amount,
          direction: TransactionDirection.incoming,
          route: 'z-receive',
          date: _shieldedNoteDate(notes),
          memo: memo,
        ));
        changed = true;
      } else if (isShieldedIncoming) {
        existing.height = height;
        existing.amount = _pivxMoney(amount);
        existing.confirmations = _confsAt(height);
        existing.isPending = existing.confirmations <
            PivxShieldedConfirmationPolicy.receiveConfirmations;
        // Promoting a z-mempool entry: re-date off the block, and the route
        // change keeps the mempool prune off it.
        existing.date = _shieldedNoteDate(notes);
        existing.additionalInfo['pivxRoute'] = 'z-receive';
        if (memo != null) existing.additionalInfo['memo'] = memo;
        changed = true;
      }
    }

    if (changed) await _saveHistory();
  }

  /// 0-conf receives live under 'z-mempool' until pruned (gone from the
  /// snapshot) or mined (the z-receive entry takes the same txid).
  Future<void> _refreshShieldedMempoolHistory() async {
    final storage = _shieldSyncEngine?.storage;
    final knownTxids = storage?.notes.map((n) => n.txid).toSet() ?? <String>{};
    final liveTxids = _mempoolIncoming.map((n) => n.txid).toSet();
    var changed = false;

    final stale = transactionHistory.transactions.entries
        .where((entry) =>
            entry.value.additionalInfo['pivxRoute'] == 'z-mempool' &&
            ((_mempoolSnapshotSeen && !liveTxids.contains(entry.key)) ||
                knownTxids.contains(entry.key)))
        .map((entry) => entry.key)
        .toList();
    for (final txid in stale) {
      transactionHistory.transactions.remove(txid);
      changed = true;
    }

    // One row per txid, summed in case a snapshot repeats one.
    final valueByTxid = <String, int>{};
    final firstSeenByTxid = <String, int?>{};
    for (final note in _mempoolIncoming) {
      if (knownTxids.contains(note.txid)) continue;
      valueByTxid[note.txid] = (valueByTxid[note.txid] ?? 0) + note.value;
      firstSeenByTxid.putIfAbsent(note.txid, () => note.firstSeen);
    }
    for (final entry in valueByTxid.entries) {
      final txid = entry.key;
      final existing = transactionHistory.transactions[txid];
      if (existing == null) {
        final firstSeen = firstSeenByTxid[txid];
        transactionHistory.addOne(_shieldedEntry(
          id: txid,
          amount: entry.value,
          direction: TransactionDirection.incoming,
          route: 'z-mempool',
          date: firstSeen != null
              ? DateTime.fromMillisecondsSinceEpoch(firstSeen * 1000)
              : null,
        ));
        changed = true;
      } else if (existing.additionalInfo['pivxRoute'] == 'z-mempool' &&
          existing.amount.amount.toInt() != entry.value) {
        existing.amount = _pivxMoney(entry.value);
        changed = true;
      }
    }

    if (changed) await _saveHistory();
  }

  /// Block time, else earliest scan time for notes stored before blockTime.
  DateTime _shieldedNoteDate(List<StoredSaplingNote> notes) {
    for (final note in notes) {
      final blockTime = note.blockTime;
      if (blockTime != null && blockTime > 0) {
        return DateTime.fromMillisecondsSinceEpoch(blockTime * 1000);
      }
    }
    return notes
        .map((note) => note.discoveredAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  Future<void> _recordPendingShieldedOutgoing({
    required String txid,
    required int amount,
    required int fee,
    required String toAddress,
    required String route,
    String? memo,
  }) async {
    // The sender's copy of a memo exists only here: the note it rides on
    // belongs to the recipient, so no sync ever brings it back.
    transactionHistory.addOne(_shieldedEntry(
      id: txid,
      amount: amount,
      fee: fee,
      direction: TransactionDirection.outgoing,
      route: route,
      to: toAddress,
      memo: memo,
    ));
    await _saveHistory();
  }

  // Every history save under the lock updateTransactions holds: a save
  // serializes after an await, so an older overlapping save could land last
  // and drop a shielded row that exists only in this file.
  Future<void> _saveHistory() =>
      _historyLock.synchronized(transactionHistory.save);

  /// Creating the engine loads storage and restores notes into native.
  Future<void> _ensureShieldSyncEngineInitialized() async {
    await initializeSapling();
    _shieldSyncEngine ??= await ShieldSyncEngine.create(
      keyManager: _saplingKeyManager!,
      walletId: walletInfo.id,
      electrumClient: electrumClient,
      encryptionFileUtils: encryptionFileUtils,
      password: password,
    );
    _restoreCurrentShieldedAddressFromStorage();
  }

  void _restoreCurrentShieldedAddressFromStorage() {
    final addresses = _shieldSyncEngine?.storage.addresses;
    if (addresses == null || addresses.isEmpty) return;

    final current = currentShieldedReceiveAddressFromStorage(addresses);
    _showShieldedAddress(current.address);
  }

  void _showShieldedAddress(String address) {
    currentShieldedAddress = address;
    final addresses = walletAddresses;
    if (addresses is PivxWalletAddresses &&
        addresses.selectedShieldedAddress != null) {
      addresses.selectedShieldedAddress = address;
    }
  }

  @visibleForTesting
  static StoredShieldedAddress currentShieldedReceiveAddressFromStorage(
    List<StoredShieldedAddress> addresses,
  ) {
    if (addresses.isEmpty) {
      throw StateError('No stored PIVX shielded receive addresses');
    }

    return addresses
        .reduce((a, b) => a.diversifierIndex >= b.diversifierIndex ? a : b);
  }

  Future<void> _ensureSaplingRpcSupportsShieldedSync() async {
    await _ensureShieldSyncEngineInitialized();
    final capabilities =
        await _shieldSyncEngine!.saplingClient.probeCapabilities();
    if (!capabilities.supportsBlockRange) {
      throw StateError(
          'Current PIVX node does not support Sapling block scanning');
    }
  }

  Future<void> _ensureSaplingRpcSupportsShieldedSend() async {
    await _ensureSaplingRpcSupportsShieldedSync();
    final capabilities =
        await _shieldSyncEngine!.saplingClient.probeCapabilities();
    if (!capabilities.supportsBestAnchor || !capabilities.supportsWitness) {
      throw StateError(
          'Current PIVX node cannot provide Sapling anchors/witnesses for shielded sends.');
    }
  }

  /// [fromHeight] defaults to the last synced height.
  Future<void> syncShielded({
    int? fromHeight,
    void Function(SyncStatus)? onProgress,
  }) async {
    if (isShieldSyncing) return;
    // Set before the first await: header, poll and post-broadcast callers
    // would otherwise all pass the check and run the engine together.
    isShieldSyncing = true;
    var reachedTarget = false;
    var threw = false;
    int? cursorBefore;

    try {
      await _ensureShieldSyncEngineInitialized();
      cursorBefore = _shieldSyncEngine!.storage.lastSyncedHeight;

      // The header subscription and the poll retry once connected.
      if (!electrumClient.isConnected) return;

      await _ensureSaplingRpcSupportsShieldedSync();

      final initialRestoreHeight = await _initialShieldSyncHeight();

      reachedTarget = await _shieldSyncEngine!.startSync(
        startHeight: fromHeight ?? initialRestoreHeight,
        onProgress: (status) async {
          lastShieldSyncedBlock = status.lastSyncedBlock;

          // At most once a second and only when blocks left drops. Zero reports
          // (the bootstrap event and completion) always pass and never seed the
          // throttle, or the bootstrap 0 would swallow every later update.
          if (status.blocksRemaining > 0) {
            final now = DateTime.now();
            final lastLeft = _lastShieldBlocksLeft;
            final lastAt = _lastShieldProgressAt;
            if ((lastLeft != null && status.blocksRemaining >= lastLeft) ||
                (lastAt != null &&
                    now.difference(lastAt) < const Duration(seconds: 1))) {
              return;
            }
            _lastShieldProgressAt = now;
            _lastShieldBlocksLeft = status.blocksRemaining;
          }

          // Set the status before the first await: startSync doesn't await this
          // callback, so a late status write could land after the finally
          // clears it and leave the wallet stuck on Syncing. Only a multi-range
          // catch-up reports blocks remaining, so the 20s poll never touches it.
          // Connection states win: the base reconnect timer keys off them.
          final current = syncStatus;
          if (isShieldSyncing &&
              status.blocksRemaining > 0 &&
              current is! core_sync.NotConnectedSyncStatus &&
              current is! core_sync.LostConnectionSyncStatus &&
              current is! core_sync.ConnectingSyncStatus) {
            _shieldSyncDrivesStatus = true;
            syncStatus = core_sync.SyncingSyncStatus(
                status.blocksRemaining, status.progress);
          }
          onProgress?.call(status);

          await _balanceLock.synchronized(() async {
            final refHeight = _shieldConfirmationHeight;
            shieldedBalance = _shieldSyncEngine!.balanceAt(refHeight);
            pendingShieldedBalance =
                _shieldSyncEngine!.pendingBalanceAt(refHeight);
          });
        },
      );

      // Must not skip the reconcile below, or a stored note never reaches the
      // balance map or history.
      try {
        await _advanceShieldedDiversifierIndexPastObservedNotes();
      } catch (e) {
        printV('[PIVX Sapling] Diversifier advance failed (non-fatal)');
      }
      await _ensureShieldedMempoolSubscription();
      // Peek before reconcile so 0-conf shows in balance and history this cycle.
      await _refreshShieldedMempool();
      await _reconcileShieldedBalance();
      try {
        await _reconcileDisappearedShieldedTxs();
      } catch (e) {
        printV('[PIVX Sapling] Disappeared-tx reconcile failed (non-fatal)');
      }
    } catch (_) {
      threw = true;
      rethrow;
    } finally {
      isShieldSyncing = false;
      _lastShieldProgressAt = null;
      _lastShieldBlocksLeft = null;
      // Reached the index: Synced. Short but advanced: Syncing. Failed or
      // stalled without moving: Attempting, which holds no wakelock and, unlike
      // Failed (a NotConnectedSyncStatus), triggers no 5s reconnect on a node
      // whose transparent side is fine. The 20s poll retries every case.
      final advanced = cursorBefore != null &&
          (_shieldSyncEngine?.storage.lastSyncedHeight ?? 0) > cursorBefore;
      final shieldStatus = reachedTarget
          ? null
          : (advanced && !threw)
              ? core_sync.SyncingSyncStatus(_shieldedBlocksBehindIndex, 0.0)
              : core_sync.AttemptingSyncStatus();
      if (_shieldSyncDrivesStatus) {
        final current = syncStatus;
        if (current is! core_sync.SyncingSyncStatus &&
            current is! core_sync.AttemptingSyncStatus) {
          // Something else (base transparent sync) took the status; the rule
          // below may still need to reclaim it.
          _shieldSyncDrivesStatus = false;
        } else if (shieldStatus == null) {
          _shieldSyncDrivesStatus = false;
          syncStatus = core_sync.SyncedSyncStatus();
        } else if (!advanced || threw) {
          syncStatus = shieldStatus;
        }
      }
      // The 100-block tolerance needs a known index; with none, the lag is
      // measured from the chain tip and can hide a pass that never scanned.
      if (!_shieldSyncDrivesStatus &&
          shieldStatus != null &&
          (_shieldedBlocksBehindIndex > 100 ||
              _shieldSyncEngine?.saplingClient.liveIndexHeight == null)) {
        // Short before the first range reported progress (probe, tree cursor,
        // first batch). Far behind, that must not sit under the transparent
        // Synced; near the index a miss is header-race noise.
        final current = syncStatus;
        if (current is core_sync.SyncedSyncStatus ||
            current is core_sync.ConnectedSyncStatus) {
          _shieldSyncDrivesStatus = true;
          syncStatus = shieldStatus;
        }
      }
    }
  }

  /// Against the server's live index, not the chain tip: the index can lag the
  /// tip by more than a window while the store is fully caught up to it. The
  /// tip stands in only when the index is unknown (probe failed). A store that
  /// never synced counts from the restore height, not from zero.
  int get _shieldedBlocksBehindIndex {
    final index = _shieldSyncEngine?.saplingClient.liveIndexHeight ??
        currentChainTip ??
        0;
    final stored = _shieldSyncEngine?.storage.lastSyncedHeight ?? 0;
    final cursor =
        stored > walletInfo.restoreHeight ? stored : walletInfo.restoreHeight;
    return index > cursor ? index - cursor : 0;
  }

  void _ensureShieldedHeaderSyncSubscription() {
    if (_shieldedHeaderSyncSubscription != null || !saplingEnabled) {
      return;
    }

    final subject = electrumClient.chainTipSubscribe();
    if (subject == null) {
      return;
    }

    _shieldedHeaderSyncSubscription = subject.listen((event) async {
      final height =
          event is Map ? int.tryParse(event['height'].toString()) : null;
      if (height != null) {
        currentChainTip = height;
      }

      if (!saplingEnabled ||
          _saplingKeyManager == null ||
          _shieldSyncEngine == null ||
          isShieldSyncing) {
        return;
      }
      if (height != null &&
          lastShieldSyncedBlock > 0 &&
          height <= lastShieldSyncedBlock) {
        return;
      }

      final now = DateTime.now();
      if (!shouldRunShieldedHeaderSync(
        lastSyncAt: _lastHeaderTriggeredShieldSync,
        now: now,
      )) {
        return;
      }

      _lastHeaderTriggeredShieldSync = now;
      try {
        printV('[PIVX Sapling] Header-triggered shielded sync');
        await syncShielded();
      } catch (e) {
        printV(
            '[PIVX Sapling] Header-triggered shielded sync failed: ${sanitizeShieldSyncError(e)}');
      }
    });
  }

  /// Cheap when caught up: syncShielded is re-entrancy guarded and capped at
  /// db_height.
  void _ensureShieldedSyncPoll() {
    if (_shieldedSyncPollTimer != null) {
      return;
    }
    _shieldedSyncPollTimer = Timer.periodic(
      const Duration(seconds: PivxNetwork.shieldedSyncPollInterval),
      (_) async {
        // Base refreshes transparent balance only on scripthash events.
        // Cleared first so the next tick cannot overlap a slow retry.
        if (_transparentBalanceStale) {
          _transparentBalanceStale = false;
          try {
            await updateBalance();
          } catch (e) {
            printV('[PIVX] balance retry failed: $e');
          }
        }
        if (!saplingEnabled ||
            _saplingKeyManager == null ||
            _shieldSyncEngine == null ||
            isShieldSyncing) {
          return;
        }
        try {
          await syncShielded();
        } catch (e) {
          printV(
              '[PIVX Sapling] Polled shielded sync failed: ${sanitizeShieldSyncError(e)}');
        }
      },
    );
  }

  @visibleForTesting
  static bool shouldRunShieldedHeaderSync({
    required DateTime? lastSyncAt,
    required DateTime now,
  }) {
    if (lastSyncAt == null) return true;
    return now.difference(lastSyncAt) >=
        const Duration(seconds: PivxNetwork.shieldedHeaderSyncMinInterval);
  }

  Future<int?> _initialShieldSyncHeight() async {
    if (_shieldSyncEngine!.storage.lastSyncedHeight != 0) {
      return null;
    }

    final activationHeight = _shieldSyncEngine!.saplingClient.activationHeight;
    if (walletInfo.restoreHeight > 0) {
      return walletInfo.restoreHeight < activationHeight
          ? activationHeight
          : walletInfo.restoreHeight;
    }

    if (walletInfo.isRecovery) {
      return null;
    }

    try {
      final tip = await electrumClient.getCurrentBlockChainTip();
      if (tip == null || tip <= activationHeight) {
        return null;
      }

      final birthdayHeight = _estimateShieldedBirthdayHeight(
        chainTip: tip,
        activationHeight: activationHeight,
      );
      await walletInfo.updateRestoreHeight(birthdayHeight);
      return birthdayHeight;
    } catch (_) {
      return null;
    }
  }

  int _estimateShieldedBirthdayHeight({
    required int chainTip,
    required int activationHeight,
  }) {
    final createdAt = DateTime.fromMillisecondsSinceEpoch(walletInfo.timestamp);
    final age = DateTime.now().difference(createdAt);
    final ageInBlocks = age.isNegative ? 0 : age.inMinutes;
    final height = chainTip - ageInBlocks - _shieldedBirthdayRewindBlocks;
    if (height < activationHeight) {
      return activationHeight;
    }
    if (height > chainTip) {
      return chainTip;
    }
    return height;
  }

  // Saving inside the parallel per-address fetch let an older snapshot land
  // after a newer one, so save once here. Locked: base sets its skip flag after
  // an await, so an overlapping rescan skipped or doubled the pass and refilled
  // the failure budget mid-pass. One pass, one budget.
  @override
  Future<void> updateTransactions() => _historyLock.synchronized(() async {
        _discoveryFailureBudget =
            ElectrumWalletAddressesBase.defaultReceiveAddressesCount;
        await super.updateTransactions();
        await transactionHistory.save();
      });

  @override
  @action
  Future<void> startSync() async {
    if (_rescanning) return;
    await super.startSync();
    // Base caught a transparent failure; shielded progress must not turn it
    // back into Syncing and Synced. The 20s poll keeps the shielded side
    // moving and cannot take the status while it is NotConnected.
    // Polls even without Sapling: it also retries a failed transparent balance.
    _ensureShieldedSyncPoll();
    if (saplingEnabled && _saplingKeyManager != null) {
      _ensureShieldedHeaderSyncSubscription();
    }
    if (syncStatus is core_sync.NotConnectedSyncStatus) return;

    if (saplingEnabled && _saplingKeyManager != null) {
      try {
        await syncShielded();
      } catch (e) {
        // Transparent sync stays usable when the shielded side fails.
        printV('[PIVX] Shielded sync failed: ${sanitizeShieldSyncError(e)}');
      }
    }
  }

  /// [fromHeight] null rescans from Sapling activation.
  Future<void> rescanShielded({
    int? fromHeight,
    void Function(SyncStatus)? onProgress,
  }) async {
    await _ensureShieldSyncEngineInitialized();

    // Clearing under a running pass loses the notes: the pass faults on the
    // reset handle and the resync early-returns while it is marked active.
    // No deadline: a pass that ignores the stop hangs here rather than wiping.
    // Re-request each turn, startSync resets _stopRequested on entry.
    while (isShieldSyncing) {
      _shieldSyncEngine!.requestStop();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    // Hold the flag across the clear so a header or poll trigger cannot start
    // scanning the half-cleared store.
    isShieldSyncing = true;
    try {
      if (fromHeight != null) await walletInfo.updateRestoreHeight(fromHeight);
      await _shieldSyncEngine!.storage.clear();
      _shieldSyncEngine!.resetNativeEngine();
    } finally {
      isShieldSyncing = false;
    }
    // No await before this call: syncShielded takes the flag synchronously.
    await syncShielded(fromHeight: fromHeight, onProgress: onProgress);
  }

  Future<void> _advanceShieldedDiversifierIndexPastObservedNotes() async {
    if (_saplingKeyManager == null || _shieldSyncEngine == null) {
      return;
    }

    final observedAddressHexes = <String>{};
    for (final note in _shieldSyncEngine!.storage.notes) {
      final addressHex = _storedSaplingNoteAddressHex(note);
      if (addressHex != null) {
        observedAddressHexes.add(addressHex);
      }
    }
    if (observedAddressHexes.isEmpty) {
      return;
    }

    final nextIndex = await nextShieldedDiversifierIndexAfterObservedAddresses(
      currentNextDiversifierIndex:
          _shieldSyncEngine!.storage.nextDiversifierIndex,
      observedAddressHexes: observedAddressHexes,
      deriveAddressHex: (index) async {
        final address = _deriveShieldedAddress(index);
        return address == null ? null : _decodeSaplingPaymentAddressHex(address);
      },
    );
    await _shieldSyncEngine!.storage
        .advanceNextDiversifierIndexAtLeast(nextIndex);
    await _rotateShieldedAddressIfUsed(observedAddressHexes);
  }

  // About half of diversifier indexes are invalid; the FFI throws for those.
  String? _deriveShieldedAddress(int index) {
    try {
      return _saplingKeyManager!.deriveAddress(index);
    } catch (_) {
      return null;
    }
  }

  // As Monero subaddresses and Litecoin MWEB: once the shown address has
  // received, show the next unused diversified one. All diversified
  // addresses share the viewing key, so their notes still sync and spend.
  Future<void> _rotateShieldedAddressIfUsed(Set<String> observedHexes) async {
    final current = currentShieldedAddress;
    if (current == null) return;
    final currentHex = _decodeSaplingPaymentAddressHex(current)?.toLowerCase();
    if (currentHex == null || !observedHexes.contains(currentHex)) return;

    final storage = _shieldSyncEngine!.storage;
    final defaultAddress = _saplingKeyManager!.defaultAddress;
    // Cap the walk: invalid indexes are ~1 in 2, so 100 tries never all fail.
    final start = storage.nextDiversifierIndex;
    for (var index = start; index < start + 100; index++) {
      final address = _deriveShieldedAddress(index);
      final hex = address == null
          ? null
          : _decodeSaplingPaymentAddressHex(address)?.toLowerCase();
      if (hex == null ||
          address == defaultAddress ||
          observedHexes.contains(hex)) {
        continue;
      }
      await storage.addShieldedAddress(
          StoredShieldedAddress(diversifierIndex: index, address: address!));
      _showShieldedAddress(address);
      return;
    }
  }

  @visibleForTesting
  static Future<int> nextShieldedDiversifierIndexAfterObservedAddresses({
    required int currentNextDiversifierIndex,
    required Set<String> observedAddressHexes,
    required Future<String?> Function(int index) deriveAddressHex,
    int scanLimit = _shieldedRestoreAddressReuseScanLimit,
  }) async {
    final remainingObservedHexes =
        observedAddressHexes.map((address) => address.toLowerCase()).toSet();
    if (remainingObservedHexes.isEmpty) {
      return currentNextDiversifierIndex;
    }

    var highestRecoveredIndex = currentNextDiversifierIndex - 1;
    for (var index = 0;
        index < scanLimit && remainingObservedHexes.isNotEmpty;
        index++) {
      final derivedHex = (await deriveAddressHex(index))?.toLowerCase();
      if (derivedHex != null && remainingObservedHexes.remove(derivedHex)) {
        highestRecoveredIndex = index;
      }
    }

    final nextIndex = highestRecoveredIndex + 1;
    return nextIndex > currentNextDiversifierIndex
        ? nextIndex
        : currentNextDiversifierIndex;
  }

  String? _storedSaplingNoteAddressHex(StoredSaplingNote note) {
    final address = note.address;
    if (address != null && _isHexOfLength(address, 86)) {
      return address.toLowerCase();
    }

    final diversifier = note.diversifier;
    final pkD = note.pkD;
    if (_isHexOfLength(diversifier, 22) && _isHexOfLength(pkD, 64)) {
      return '${diversifier!.toLowerCase()}${pkD!.toLowerCase()}';
    }

    return null;
  }

  bool _isHexOfLength(String? value, int length) {
    if (value == null || value.length != length) {
      return false;
    }
    return RegExp(r'^[0-9a-fA-F]+$').hasMatch(value);
  }

  String? _decodeSaplingPaymentAddressHex(String encodedAddress) {
    try {
      final bytes = Bech32Decoder.decode(
          PivxSaplingNetwork.mainnetPaymentAddressHrp, encodedAddress);
      return bytes.length == kSaplingPaymentAddressSize
          ? BytesUtils.toHexString(bytes)
          : null;
    } catch (_) {
      return null;
    }
  }

  /// [memo] up to 512 bytes, shielded destinations only.
  Future<SaplingTransactionResult> createShieldedTransaction({
    required String toAddress,
    required int amount,
    String? memo,
    bool spendAllShieldedInputs = false,
  }) async {
    await _ensureShieldSyncEngineInitialized();
    await _ensureSaplingRpcSupportsShieldedSend();

    // Concurrent builds could select the same notes.
    return await _balanceLock.synchronized(() async {
      final builder = await _txBuilder();
      return await builder.buildTransaction(
        options: SaplingTransactionOptions(
          toAddress: toAddress,
          amount: amount,
          memo: memo,
          spendAllShieldedInputs: spendAllShieldedInputs,
        ),
      );
    });
  }

  /// t-to-z from confirmed P2PKH UTXOs, change back to a transparent address.
  Future<_BuiltShieldTransaction> _buildShieldTransactionResult({
    required String toAddress,
    int? requestedAmount,
    required bool isSendAll,
    String? memo,
  }) async {
    await _ensureShieldSyncEngineInitialized();
    // The cached list only refreshes on scripthash notifications, so a coin
    // that confirmed since then still reads 0 confirmations here.
    await updateAllUnspents();

    final available = _spendableCoins(toShielded: true);
    if (available.isEmpty) {
      throw Exception('No spendable transparent PIVX coins available.');
    }

    List<BitcoinUnspent> selected;
    int amount;
    ShieldedSpendPlan plan;
    if (isSendAll) {
      selected = available;
      final total = selected.fold<int>(0, (sum, utx) => sum + utx.value);
      final fee = PivxFeePolicy.saplingFee(
        saplingOutputs: 1,
        transparentInputs: selected.length,
      );
      amount = total - fee;
      if (amount < PivxFeePolicy.shieldedDustThreshold) {
        throw Exception('Insufficient transparent balance after PIVX fee.');
      }
      plan = ShieldedSpendPlan(fee: fee, change: 0, canBuild: true);
    } else {
      amount = requestedAmount!;
      if (amount < PivxFeePolicy.shieldedDustThreshold) {
        throw Exception('Amount below PIVX shielded dust threshold');
      }
      selected = <BitcoinUnspent>[];
      var total = 0;
      plan = ShieldedSpendPlan(fee: 0, change: 0, canBuild: false);
      for (final utx in available) {
        selected.add(utx);
        total += utx.value;
        plan = SaplingTransactionBuilder.planShieldSpend(
          totalInput: total,
          amount: amount,
          transparentInputs: selected.length,
        );
        if (plan.canBuild) break;
      }
      if (!plan.canBuild) {
        throw Exception('Insufficient transparent balance for shield amount.');
      }
    }

    final utxoMaps = selected.map((utx) {
      final record = utx.bitcoinAddressRecord;
      final privateKey = _transparentSigningKeyHexFor(record);
      return <String, dynamic>{
        'txid': utx.hash,
        'vout': utx.vout,
        'value': utx.value,
        'script_pubkey': BytesUtils.toHexString(
            BitcoinAddressUtils.addressToOutputScript(
                address: record.address, network: network)),
        'private_key': privateKey,
      };
    }).toList(growable: false);

    // walletAddresses.address can be the selected ps1 address, which the Rust
    // builder cannot base58-decode.
    final changeAddress = plan.change > 0
        ? (await walletAddresses.getChangeAddress()).address
        : null;

    final result = await _balanceLock.synchronized(() async {
      return (await _txBuilder()).buildShieldTransaction(
        utxos: utxoMaps,
        toAddress: toAddress,
        amount: amount,
        memo: memo,
        fee: plan.fee,
        changeAddress: changeAddress,
        change: plan.change,
      );
    });

    return _BuiltShieldTransaction(result, amount);
  }

  /// Rust fails closed on a key/script mismatch, so only return a key that
  /// re-derives record.address; stale branch metadata tries the other branch.
  String _transparentSigningKeyHexFor(BaseBitcoinAddressRecord record) {
    final candidates = <Bip32Slip10Secp256k1>[
      record.isHidden
          ? (sideHdByTypeAndAccount[0]?[record.type] ?? sideHd)
          : (mainHdByTypeAndAccount[0]?[record.type] ?? mainHd),
      record.isHidden ? sideHd : mainHd,
      record.isHidden
          ? (mainHdByTypeAndAccount[0]?[record.type] ?? mainHd)
          : (sideHdByTypeAndAccount[0]?[record.type] ?? sideHd),
      record.isHidden ? mainHd : sideHd,
    ];

    for (final hd in candidates) {
      final derived = walletAddresses.getAddress(
          index: record.index, hd: hd, addressType: record.type);
      if (derived == record.address) {
        return ECPrivate(hd.childKey(Bip32KeyIndex(record.index)).privateKey)
            .toHex();
      }
    }

    throw Exception(
      'PIVX transparent input ${record.address} (index ${record.index}) has no '
      'matching wallet key; refusing to sign with a mismatched key.',
    );
  }

  Future<SaplingTransactionBuilder> _txBuilder() async {
    final builder = _saplingTxBuilder ??= SaplingTransactionBuilder(
      keyManager: _saplingKeyManager!,
      syncEngine: _shieldSyncEngine!,
    );
    if (!builder.hasProvingParams) {
      final appDir = await getApplicationDocumentsDirectory();
      await builder.ensureProvingParams('${appDir.path}/pivx_sapling_params');
    }
    return builder;
  }

  @override
  Future<ElectrumBalance> fetchBalances() async {
    final addresses = walletAddresses.allAddresses
        .where((address) => address.address.isNotEmpty)
        .toList();

    // Discovery can briefly hold one address under two records; summing its
    // scripthash twice would double the balance.
    final validAddresses = <BitcoinAddressRecord>[];
    final validScriptHashes = <String>[];
    final seenScriptHashes = <String>{};
    for (final addressRecord in addresses) {
      final sh = addressRecord.getScriptHash(network);
      if (sh.isEmpty || !seenScriptHashes.add(sh)) continue;
      validAddresses.add(addressRecord);
      validScriptHashes.add(sh);
    }

    var totalFrozen = 0;
    var totalConfirmed = 0;
    var totalUnconfirmed = 0;

    unspentCoinsInfo.values.forEach((info) {
      unspentCoins.forEach((element) {
        if (element.hash == info.hash &&
            element.vout == info.vout &&
            element.bitcoinAddressRecord.address == info.address &&
            element.value == info.value) {
          if (info.isFrozen) {
            totalFrozen += element.value;
          }
        }
      });
    });

    // The server throttles per message, not per method. A failed chunk keeps
    // the chunks already fetched; its own scripthashes read as missed below.
    final balanceBySh = <String, Map<String, dynamic>>{};
    const chunkSize = 150;
    for (var i = 0; i < validScriptHashes.length; i += chunkSize) {
      final end = i + chunkSize < validScriptHashes.length
          ? i + chunkSize
          : validScriptHashes.length;
      try {
        balanceBySh.addAll(await electrumClient
            .getBatchBalance(validScriptHashes.sublist(i, end)));
      } catch (e) {
        printV('[PIVX] batch get_balance failed: $e');
      }
    }

    // A failed scripthash comes back {}; keep its last-known balance. Only a full
    // wipeout means a lost connection.
    var failedCount = 0;
    for (var i = 0; i < validScriptHashes.length; i++) {
      final balance =
          balanceBySh[validScriptHashes[i]] ?? const <String, dynamic>{};
      final addressRecord = validAddresses[i];
      final hasKeys =
          balance['confirmed'] != null && balance['unconfirmed'] != null;

      if (!hasKeys) {
        failedCount++;
        // Last-known split; before any success only the folded record value
        // exists, and pending cannot over-claim.
        final sh = validScriptHashes[i];
        final lastConfirmed = _lastConfirmedBySh[sh];
        totalConfirmed += lastConfirmed ?? 0;
        totalUnconfirmed += lastConfirmed == null
            ? addressRecord.balance
            : (_lastUnconfirmedBySh[sh] ?? 0);
        continue;
      }

      final confirmed = balance['confirmed'] as int? ?? 0;
      final unconfirmed = balance['unconfirmed'] as int? ?? 0;
      totalConfirmed += confirmed;
      totalUnconfirmed += unconfirmed;
      _lastConfirmedBySh[validScriptHashes[i]] = confirmed;
      _lastUnconfirmedBySh[validScriptHashes[i]] = unconfirmed;

      addressRecord.balance = confirmed + unconfirmed;
      if (confirmed > 0 || unconfirmed > 0) {
        addressRecord.setAsUsed();
      }
    }

    // A timeout behind a dense Sapling range leaves the socket up: keep the
    // last-known balance without reporting a dead connection; the shielded
    // poll retries it.
    // Any miss retries on the poll; only a full wipeout keeps the old total.
    _transparentBalanceStale = failedCount > 0;
    if (validScriptHashes.isNotEmpty &&
        failedCount == validScriptHashes.length) {
      printV('[PIVX] All transparent balance queries failed');
      if (!electrumClient.isConnected) {
        syncStatus = core_sync.LostConnectionSyncStatus();
      }
      final previousBalance = balance[currency];

      return ElectrumBalance(
        confirmed: previousBalance?.confirmed ?? _zeroPivxMoney,
        unconfirmed: previousBalance?.unconfirmed ?? _zeroPivxMoney,
        frozen: previousBalance?.frozen ?? _zeroPivxMoney,
        secondConfirmed: _pivxMoney(shieldedBalance),
        secondUnconfirmed: _pivxMoney(_displayPendingShielded),
      );
    }

    return ElectrumBalance(
      confirmed: _pivxMoney(totalConfirmed),
      unconfirmed: _pivxMoney(totalUnconfirmed),
      frozen: _pivxMoney(totalFrozen),
      secondConfirmed: _pivxMoney(shieldedBalance),
      secondUnconfirmed: _pivxMoney(_displayPendingShielded),
    );
  }

  @override
  Future<bool> checkNodeHealth() async {
    if (!await super.checkNodeHealth()) return false;
    if (!saplingEnabled) return true;
    try {
      await _ensureSaplingRpcSupportsShieldedSync();
      return true;
    } catch (_) {
      return false;
    }
  }

  // The base batch path takes confirmations from BtcTransaction.fromRaw, which
  // cannot parse a Sapling funding tx and drops the coin. PIVX batches itself.
  @override
  bool get shouldUseBatchFetching => false;

  @override
  Future<List<BitcoinUnspent>?> fetchUnspent(
          BitcoinAddressRecord address) async =>
      (await fetchUnspentsForAddresses([address])).first;

  /// ceil(N/150) batched messages instead of N throttled listunspents.
  /// Confirmations come from the UTXO height: fromRaw cannot parse
  /// Sapling-funded txs (z->t, shield change).
  @override
  Future<List<List<BitcoinUnspent>?>> fetchUnspentsForAddresses(
    List<BitcoinAddressRecord> addresses,
  ) async {
    const chunkSize = 150;
    final shByIndex = <String>[];
    final ownerBySh = <String, BitcoinAddressRecord>{};
    for (final address in addresses) {
      final sh = address.getScriptHash(network);
      shByIndex.add(sh);
      if (sh.isNotEmpty) ownerBySh.putIfAbsent(sh, () => address);
    }

    final uniqueSh = ownerBySh.keys.toList();
    if (uniqueSh.isEmpty) {
      return List<List<BitcoinUnspent>?>.filled(
          addresses.length, <BitcoinUnspent>[]);
    }

    // Offline, a short batch or an error item must read as unknown (null):
    // getBatchUnspent maps all three to [], which updateAllUnspents takes as
    // "no coins" and wipes the UTXO set and coin-control rows.
    if (!electrumClient.isConnected) {
      return List<List<BitcoinUnspent>?>.filled(addresses.length, null);
    }
    final tip = await getCurrentChainTip();
    final unspentBySh = <String, List<Map<String, dynamic>>>{};
    final failedSh = <String>{};
    for (var i = 0; i < uniqueSh.length; i += chunkSize) {
      final end =
          i + chunkSize < uniqueSh.length ? i + chunkSize : uniqueSh.length;
      final chunk = uniqueSh.sublist(i, end);
      List<dynamic> results;
      try {
        results = await electrumClient.callBatchWithTimeout(
          method: 'blockchain.scripthash.listunspent',
          paramsList: [for (final sh in chunk) <Object>[sh]],
        );
      } catch (e) {
        // Timeout or drop while connected: keep this chunk's known coins.
        printV('[PIVX] batch unspent fetch failed: $e');
        failedSh.addAll(chunk);
        continue;
      }
      for (var j = 0; j < chunk.length; j++) {
        final result = j < results.length ? results[j] : null;
        if (result is! List ||
            result.any((m) => m is! Map<dynamic, dynamic>)) {
          failedSh.add(chunk[j]);
          continue;
        }
        unspentBySh[chunk[j]] = [
          for (final m in result.cast<Map<dynamic, dynamic>>())
            m.map((k, v) => MapEntry(k.toString(), v)),
        ];
      }
    }

    final coinsBySh = <String, List<BitcoinUnspent>>{};
    for (final sh in uniqueSh) {
      final owner = ownerBySh[sh]!;
      final coins = <BitcoinUnspent>[];
      for (final unspent in unspentBySh[sh] ?? const <Map<String, dynamic>>[]) {
        try {
          final coin = BitcoinUnspent.fromJSON(owner, unspent);
          coin.isChange = owner.isHidden;
          // A mined UTXO stays confirmed when the cached tip lags it.
          final height = unspent['height'] as int?;
          coin.confirmations = (height != null && height > 0)
              ? (tip >= height ? tip - height + 1 : 1)
              : 0;
          coins.add(coin);
        } catch (_) {
          // A coin that will not parse is not a coin that does not exist.
          failedSh.add(sh);
          break;
        }
      }
      coinsBySh[sh] = coins;
    }

    // Duplicate records for one scripthash get an empty list.
    final emitted = <String>{};
    return List<List<BitcoinUnspent>?>.generate(addresses.length, (i) {
      final sh = shByIndex[i];
      if (sh.isEmpty || !emitted.add(sh)) return <BitcoinUnspent>[];
      // Known coins, not null: base keeps only successful results on a partial
      // failure and would delete this address's coin-control rows.
      if (failedSh.contains(sh)) {
        final owner = ownerBySh[sh]!;
        return unspentCoins
            .where((c) => c.bitcoinAddressRecord.address == owner.address)
            .toList();
      }
      return coinsBySh[sh] ?? <BitcoinUnspent>[];
    });
  }

  // The base history path reports any per-address failure to the app error
  // dialog. PIVX skips one bad tx and keeps the rest of the address history.
  @override
  Future<void> fetchTransactionsForAddressType(
    Map<String, ElectrumTransactionInfo> historiesWithDetails,
    BitcoinAddressType type, {
    int? accountIndex, // PIVX has one account
  }) async {
    final addressesByType =
        walletAddresses.allAddresses.where((addr) => addr.type == type);
    final hiddenAddresses =
        addressesByType.where((addr) => addr.isHidden == true);
    final receiveAddresses =
        addressesByType.where((addr) => addr.isHidden == false);
    walletAddresses.hiddenAddresses
        .addAll(hiddenAddresses.map((e) => e.address));
    await walletAddresses.saveAddressesInBox();
    await Future.wait(addressesByType.map((addressRecord) async {
      final history = await _fetchPivxAddressHistory(
          addressRecord, await getCurrentChainTip());
      // null: lookup or detail fetch failed; the next sync retries. An address
      // already known used still drives discovery, or funded later addresses
      // behind one unparseable tx would never be found.
      if (history == null) {
        if (!addressRecord.isUsed || !_spendDiscoveryFailureBudget()) return;
      } else {
        if (history.isEmpty) return;
        addressRecord.txCount = history.length;
        historiesWithDetails.addAll(history);
      }

      final matchedAddresses =
          addressRecord.isHidden ? hiddenAddresses : receiveAddresses;
      final isUsedAddressUnderGap =
          matchedAddresses.toList().indexOf(addressRecord) >=
              matchedAddresses.length -
                  (addressRecord.isHidden
                      ? ElectrumWalletAddressesBase.defaultChangeAddressesCount
                      : ElectrumWalletAddressesBase
                          .defaultReceiveAddressesCount);
      if (!isUsedAddressUnderGap) return;

      final prevLength = walletAddresses.allAddresses.length;
      await walletAddresses.discoverAddresses(
        matchedAddresses.toList(),
        addressRecord.isHidden,
        (address) async {
          await subscribeForUpdates();
          // A failed lookup counts as used so discovery does not stop short of
          // funded addresses. Offline, or past one gap window of failures, it
          // does not: every lookup would fail and discovery would never end.
          final history = await _fetchPivxAddressHistory(
              address, await getCurrentChainTip());
          if (history != null) return history.isNotEmpty ? address.address : null;
          if (!electrumClient.isConnected) return null;
          return _spendDiscoveryFailureBudget() ? address.address : null;
        },
        type: type,
        isLegacyDerivation: false,
      );
      if (walletAddresses.allAddresses.length > prevLength) {
        await fetchTransactionsForAddressType(historiesWithDetails, type);
      }
    }));
  }

  // Shared by every discovery run in one updateTransactions pass, reset there:
  // a counter per run resets on each recursive call, so a server failing every
  // lookup could still derive addresses without end.
  int _discoveryFailureBudget =
      ElectrumWalletAddressesBase.defaultReceiveAddressesCount;

  bool _spendDiscoveryFailureBudget() {
    if (_discoveryFailureBudget <= 0) return false;
    _discoveryFailureBudget--;
    return true;
  }

  /// null when the lookup failed; {} only for an address with no history.
  Future<Map<String, ElectrumTransactionInfo>?> _fetchPivxAddressHistory(
      BitcoinAddressRecord addressRecord, int? currentHeight) async {
    try {
      final historiesWithDetails = <String, ElectrumTransactionInfo>{};
      final sh = addressRecord.getScriptHash(network);
      if (sh.isEmpty) return {};

      // getHistory maps an error reply or a dead socket to [], which reads as
      // an unused address.
      var requestId = 0;
      final raw = await electrumClient.call(
        method: 'blockchain.scripthash.get_history',
        params: [sh],
        idCallback: (id) => requestId = id,
      );
      if (raw is! List || electrumClient.getErrorMessage(requestId).isNotEmpty) {
        return null;
      }
      if (raw.any((item) => item is! Map<String, dynamic>)) return null;
      final history = raw.cast<Map<String, dynamic>>();
      if (history.isEmpty) return {};

      addressRecord.setAsUsed();
      walletAddresses.clearLockIfMatches(
          addressRecord.type, addressRecord.address);

      await Future.wait(history.map((transaction) async {
        final txHash = transaction['tx_hash'] as String;
        try {
          final height = transaction['height'] as int;
          final storedTx = transactionHistory.transactions[txHash];
          if (storedTx != null) {
            if (height > 0) {
              storedTx.height = height;
              // the tx's own block is the first confirmation; a tip that lags
              // the history still counts a mined tx as confirmed once
              final confirmations = (currentHeight ?? 0) - height + 1;
              storedTx.confirmations = confirmations < 1 ? 1 : confirmations;
              storedTx.isPending = storedTx.confirmations == 0;
            }
            historiesWithDetails[txHash] = storedTx;
            return;
          }
          final entry = await fetchTransactionInfo(
              hash: txHash, height: height, retryOnFailure: true);
          if (entry != null) {
            historiesWithDetails[txHash] = entry;
            transactionHistory.addOne(entry);
          }
        } catch (e) {
          printV('[PIVX] skipped tx $txHash in history: $e');
        }
      }));
      // History exists but no detail came back: unknown, not unused.
      if (historiesWithDetails.isEmpty) return null;
      return historiesWithDetails;
    } catch (e) {
      printV('[PIVX] address history fetch failed: $e');
      return null;
    }
  }

  // fromRaw rejects Sapling-bearing txs, so z->t receives come from verbose JSON.
  @override
  Future<ElectrumTransactionInfo?> fetchTransactionInfo(
          {required String hash, int? height, bool? retryOnFailure}) async =>
      await super.fetchTransactionInfo(
          hash: hash, height: height, retryOnFailure: retryOnFailure) ??
      await _buildPivxIncomingFromVerbose(
          hash, height ?? 0, await getCurrentChainTip());

  /// Sats paid to [addresses] by verbose tx JSON. No transparent vin = external
  /// deshield, which can land on a change-branch address. With transparent vin
  /// it may be the wallet's own t->z shield, whose change must not count as incoming.
  @visibleForTesting
  static int verboseReceivedSats(Map<String, dynamic> verbose,
      Iterable<BaseBitcoinAddressRecord> addresses) {
    final vout = verbose['vout'];
    if (vout is! List) return 0;
    final vin = verbose['vin'];
    final hasTransparentInput = vin is List && vin.isNotEmpty;
    final matchAddresses =
        (hasTransparentInput ? addresses.where((a) => !a.isHidden) : addresses)
            .map((a) => a.address)
            .toSet();

    var received = 0;
    for (final out in vout) {
      if (out is! Map) continue;
      final spk = out['scriptPubKey'];
      if (spk is! Map) continue;
      final outAddresses = <String>{};
      final list = spk['addresses'];
      if (list is List) outAddresses.addAll(list.map((e) => e.toString()));
      final single = spk['address'];
      if (single != null) outAddresses.add(single.toString());
      if (outAddresses.any(matchAddresses.contains)) {
        received += stringDoubleToBitcoinAmount((out['value'] ?? 0).toString());
      }
    }
    return received;
  }

  /// Incoming entry from verbose JSON for txs fromRaw cannot parse. null when
  /// nothing pays this wallet, so its own sends never show as a false incoming.
  Future<ElectrumTransactionInfo?> _buildPivxIncomingFromVerbose(
      String txHash, int height, int? currentHeight) async {
    try {
      // The wallet's own z->t send is recorded on the shielded side.
      final shieldedStorage = _shieldSyncEngine?.storage;
      if (shieldedStorage != null &&
          shieldedStorage.notes.any((n) =>
              n.spendingTxid == txHash || n.pendingSpendingTxid == txHash)) {
        return null;
      }

      final verbose = await electrumClient.getTransactionVerbose(hash: txHash);
      if (verbose.isEmpty) return null;
      final received =
          verboseReceivedSats(verbose, walletAddresses.allAddresses);
      if (received <= 0) return null;

      final confirmations = height <= 0
          ? 0
          : (currentHeight != null && currentHeight >= height)
              ? currentHeight - height + 1
              : 1;
      final time = verbose['time'];
      final date = time is int
          ? DateTime.fromMillisecondsSinceEpoch(time * 1000)
          : DateTime.now();

      return ElectrumTransactionInfo(
        WalletType.pivx,
        id: txHash,
        height: height,
        amount: _pivxMoney(received),
        fee: _zeroPivxMoney,
        direction: TransactionDirection.incoming,
        isPending: height <= 0,
        date: date,
        confirmations: confirmations,
      );
    } catch (e) {
      printV('PIVX: verbose incoming fallback failed for $txHash');
      return null;
    }
  }

  // Base treats amount <= this as dust; PIVX Core IsDust is value < 5460.
  @override
  BigInt get networkDustAmount =>
      BigInt.from(PivxFeePolicy.transparentDustThreshold - 1);

  // No estimatefee on PIVX ElectrumX; the base would fire 3 dead requests per
  // sync.
  @override
  Future<void> updateFeeRates() async {}

  // sat/byte like every Electrum coin, so base size * rate math holds. The
  // base rate resolves to 0 without estimatefee, and the network rejects a
  // zero-fee tx.
  @override
  int feeRate(TransactionPriority priority) =>
      priority is PivxTransactionPriority
          ? priority.feeRate
          : PivxFeePolicy.minRelayFeePerKb ~/ 1000;

  @override
  int feeAmountForPriority(
    TransactionPriority priority,
    int inputsCount,
    int outputsCount, {
    int? size,
  }) =>
      feeAmountWithFeeRate(feeRate(priority), inputsCount, outputsCount,
          size: size);

  // Sending, unfrozen coins, deduped like getSendingBalance; t-to-z spends
  // confirmed coins only. Largest first, the order the shield build takes.
  List<BitcoinUnspent> _spendableCoins({required bool toShielded}) {
    final seen = <String>{};
    return unspentCoins
        .where((u) => u.isSending && !u.isFrozen)
        .where((u) => !toShielded || (u.confirmations ?? 0) > 0)
        .where((u) => seen.add('${u.hash}:${u.vout}'))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  // Callers start the engine first: an unstarted engine is not an empty pool.
  List<StoredSaplingNote> get _spendableNotes {
    if (!saplingEnabled) return const [];
    final engine = _shieldSyncEngine;
    if (engine == null) throw StateError('PIVX Sapling engine not started');
    return engine.spendableNotesAt(_shieldConfirmationHeight);
  }

  bool _notesCover(int amount, {required bool toTransparent}) {
    final selected = SaplingTransactionBuilder.selectNotesForAmount(
        [for (final n in _spendableNotes) {'value': n.value}], amount,
        transparentDestination: toTransparent);
    return SaplingTransactionBuilder.planShieldedSpend(
      totalInput: selected.fold(0, (sum, n) => sum + (n['value'] as int)),
      amount: amount,
      saplingInputs: selected.isEmpty ? 1 : selected.length,
      transparentDestination: toTransparent,
    ).canBuild;
  }

  /// The one rule for which pool a send draws on; the send, its previews and
  /// Max all ask here. "any": EXM and send-all with coins stay transparent,
  /// shielded recipients take notes that cover amount and fee, transparent
  /// recipients take notes only when coins fall short. For that last case the
  /// send itself tries the transparent build first, so a preview within one
  /// fee-byte of the boundary can quote shielded where the send stays
  /// transparent.
  UnspentCoinType resolveSendSource({
    required String toAddress,
    required UnspentCoinType source,
    int amount = 0,
    bool sendAll = false,
    TransactionPriority? priority,
  }) {
    if (source != UnspentCoinType.any) return source;
    // Notes are unverified until the pass ends (one can be spent in a block
    // not yet scanned). Send allows "any" while syncing; this keeps it on coins.
    if (PivxExchangeAddress.looksLike(toAddress) ||
        syncStatus is! core_sync.SyncedSyncStatus) {
      return UnspentCoinType.transparent;
    }
    final toShielded = _isShieldedAddress(toAddress);
    final coins = _spendableCoins(toShielded: toShielded);
    final coinsTotal = coins.fold<int>(0, (sum, u) => sum + u.value);
    if (sendAll) {
      // Coins that cannot pay their own sweep fee are dust, not a pool.
      final sweepFee = toShielded
          ? PivxFeePolicy.saplingFee(
              saplingOutputs: 1, transparentInputs: coins.length)
          : feeAmountWithFeeRate(
              feeRate(priority ?? PivxTransactionPriority.medium),
              coins.length,
              1);
      final dust = toShielded
          ? PivxFeePolicy.shieldedDustThreshold
          : PivxFeePolicy.transparentDustThreshold;
      final coinsSweep = coins.isNotEmpty && coinsTotal - sweepFee >= dust;
      return !coinsSweep && _spendableNotes.isNotEmpty
          ? UnspentCoinType.sapling
          : UnspentCoinType.transparent;
    }
    if (toShielded) {
      return _notesCover(amount, toTransparent: false)
          ? UnspentCoinType.sapling
          : UnspentCoinType.transparent;
    }
    final fee = calculateEstimatedFee(
        priority ?? PivxTransactionPriority.slow, amount);
    return coinsTotal < amount + fee &&
            _notesCover(amount, toTransparent: true)
        ? UnspentCoinType.sapling
        : UnspentCoinType.transparent;
  }

  /// What Max and "available" show: the pool a send-all to [toAddress] sweeps.
  Future<int> spendableAmount(
      {required String toAddress, required UnspentCoinType source}) async {
    if (saplingEnabled && source != UnspentCoinType.transparent) {
      await _ensureShieldSyncEngineInitialized();
    }
    final pool =
        resolveSendSource(toAddress: toAddress, source: source, sendAll: true);
    return pool == UnspentCoinType.sapling
        ? _spendableNotes.fold<int>(0, (sum, n) => sum + n.value)
        : _spendableCoins(toShielded: _isShieldedAddress(toAddress))
            .fold<int>(0, (sum, u) => sum + u.value);
  }

  /// Fee the send form previews, planned like the build without proving.
  Future<int> estimatedSendFee(TransactionPriority priority, int amount,
      {required String toAddress,
      required UnspentCoinType source,
      bool sendAll = false}) async {
    if (saplingEnabled && source != UnspentCoinType.transparent) {
      await _ensureShieldSyncEngineInitialized();
    }
    final toShielded = _isShieldedAddress(toAddress);
    final coins = _spendableCoins(toShielded: toShielded)
        .map((u) => u.value)
        .toList();
    final fromShielded = resolveSendSource(
            toAddress: toAddress,
            source: source,
            amount: amount,
            sendAll: sendAll,
            priority: priority) ==
        UnspentCoinType.sapling;
    if (!fromShielded && !toShielded) {
      return calculateEstimatedFee(priority, amount);
    }
    if (fromShielded) {
      final notes = [for (final n in _spendableNotes) {'value': n.value}];
      final selected = SaplingTransactionBuilder.selectNotesForAmount(
          notes, amount,
          spendAll: sendAll, transparentDestination: !toShielded);
      if (sendAll) {
        return PivxFeePolicy.saplingFee(
          saplingInputs: selected.isEmpty ? 1 : selected.length,
          saplingOutputs: toShielded ? 1 : 0,
          transparentOutputs: toShielded ? 0 : 1,
        );
      }
      return SaplingTransactionBuilder.planShieldedSpend(
        totalInput: selected.fold(0, (sum, n) => sum + (n['value'] as int)),
        amount: amount,
        saplingInputs: selected.isEmpty ? 1 : selected.length,
        transparentDestination: !toShielded,
      ).fee;
    }
    // t-to-z: largest confirmed coins first, as _buildShieldTransactionResult.
    if (sendAll) {
      return PivxFeePolicy.saplingFee(
          saplingOutputs: 1, transparentInputs: coins.isEmpty ? 1 : coins.length);
    }
    var plan = SaplingTransactionBuilder.planShieldSpend(
        totalInput: 0, amount: amount, transparentInputs: 1);
    var total = 0;
    for (var i = 0; i < coins.length && !plan.canBuild; i++) {
      total += coins[i];
      plan = SaplingTransactionBuilder.planShieldSpend(
          totalInput: total, amount: amount, transparentInputs: i + 1);
    }
    return plan.fee;
  }

  // Notes are not UTXOs, so base quotes a shielded sweep as 0. Quote the sweep
  // the build makes; the dummy output is transparent, the costlier route.
  @override
  Future<EstimatedTxResult> estimateSendAllTx(
    List<BitcoinOutput> outputs,
    int feeRate, {
    String? memo,
    bool hasSilentPayment = false,
    UnspentCoinType coinTypeToSpendFrom = UnspentCoinType.any,
  }) async {
    // Quote the pool the send itself will sweep.
    var source = coinTypeToSpendFrom;
    if (source == UnspentCoinType.any) {
      source = await _sendAllSourcePool(
          outputs.map((o) => o.address.toAddress(network)));
    } else if (source == UnspentCoinType.sapling && saplingEnabled) {
      await _ensureShieldSyncEngineInitialized();
    }
    if (_shieldSyncEngine == null || source != UnspentCoinType.sapling) {
      return super.estimateSendAllTx(outputs, feeRate,
          memo: memo,
          hasSilentPayment: hasSilentPayment,
          coinTypeToSpendFrom: coinTypeToSpendFrom);
    }
    final amount = _shieldedSendAllAmount(transparentDestination: true);
    final total = _shieldSyncEngine!
        .spendableNotesAt(_shieldConfirmationHeight)
        .fold<int>(0, (sum, n) => sum + n.value);
    return EstimatedTxResult(
      utxos: const [],
      inputPrivKeyInfos: const [],
      publicKeys: const {},
      fee: Money.fromInt(total - amount, currency),
      amount: Money.fromInt(amount, currency),
      hasChange: false,
      isSendAll: true,
      memo: memo,
      spendsSilentPayment: false,
      spendsUnconfirmedTX: false,
    );
  }

  // Base fallback sizes 68-byte segwit inputs; PIVX inputs are 148.
  @override
  int feeAmountWithFeeRate(int feeRate, int inputsCount, int outputsCount,
          {int? size}) =>
      feeRate *
      (size ?? PivxFeePolicy.transparentTxSize(inputsCount, outputsCount));

  static Future<PivxWallet> create({
    required String mnemonic,
    required String password,
    required WalletInfo walletInfo,
    required DerivationInfo derivationInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required EncryptionFileUtils encryptionFileUtils,
    String? passphrase,
    String? addressPageType,
    List<BitcoinAddressRecord>? initialAddresses,
    ElectrumBalance? initialBalance,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
  }) async {
    return PivxWallet(
      mnemonic: mnemonic,
      password: password,
      walletInfo: walletInfo,
      derivationInfo: derivationInfo,
      unspentCoinsInfo: unspentCoinsInfo,
      initialAddresses: initialAddresses,
      initialBalance: initialBalance,
      seedBytes: MnemonicBip39.toSeed(mnemonic, passphrase: passphrase),
      encryptionFileUtils: encryptionFileUtils,
      initialRegularAddressIndex: initialRegularAddressIndex,
      initialChangeAddressIndex: initialChangeAddressIndex,
      addressPageType: P2pkhAddressType.p2pkh,
      passphrase: passphrase,
    );
  }

  static Future<PivxWallet> open({
    required String name,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required String password,
    required EncryptionFileUtils encryptionFileUtils,
  }) async {
    final hasKeysFile = await WalletKeysFile.hasKeysFile(name, walletInfo.type);

    ElectrumWalletSnapshot? snp = null;

    try {
      snp = await ElectrumWalletSnapshot.load(
        encryptionFileUtils,
        name,
        walletInfo.type,
        password,
        PivxNetwork.mainnet,
      );
    } catch (e) {
      if (!hasKeysFile) rethrow;
    }

    final WalletKeysData keysData;
    if (!hasKeysFile) {
      keysData = WalletKeysData(
        mnemonic: snp!.mnemonic,
        xPub: snp.xpub,
        passphrase: snp.passphrase,
      );
    } else {
      keysData = await WalletKeysFile.readKeysFile(
        name,
        walletInfo.type,
        password,
        encryptionFileUtils,
      );
    }

    return PivxWallet(
      mnemonic: keysData.mnemonic!,
      password: password,
      walletInfo: walletInfo,
      derivationInfo: await walletInfo.getDerivationInfo(),
      unspentCoinsInfo: unspentCoinsInfo,
      initialAddresses: snp?.addresses,
      initialBalance: snp?.balance,
      seedBytes: await MnemonicBip39.toSeed(keysData.mnemonic!,
          passphrase: keysData.passphrase),
      encryptionFileUtils: encryptionFileUtils,
      initialRegularAddressIndex: snp?.regularAddressIndex,
      initialChangeAddressIndex: snp?.changeAddressIndex,
      addressPageType: P2pkhAddressType.p2pkh,
      passphrase: keysData.passphrase,
    );
  }

  // The Dogecoin branch parses only P2PKH; PIVX also pays EXM and 6 (P2SH).
  @override
  BitcoinBaseAddress addressFromString(String address) {
    if (PivxExchangeAddress.looksLike(address)) {
      return PivxExchangeAddress.fromAddress(address);
    }
    if (address.startsWith('6')) {
      return P2shAddress.fromAddress(address: address, network: network);
    }
    return super.addressFromString(address);
  }

  // PIVX Core src/util/validation.cpp strMessageMagic. Same 24-byte length as
  // Bitcoin's, so the \x18 length byte carries over.
  @override
  String get messagePrefix => '\x18DarkNet Signed Message:\n';

  /// Send-all from "any": refresh, then the shared rule.
  Future<UnspentCoinType> _sendAllSourcePool(
      Iterable<String> destinations) async {
    await updateAllUnspents();
    if (saplingEnabled) await _ensureShieldSyncEngineInitialized();
    // EXM forces transparent; a shielded recipient sets the coin filter.
    final toAddress = destinations.firstWhere(PivxExchangeAddress.looksLike,
        orElse: () => destinations.firstWhere(_isShieldedAddress,
            orElse: () => destinations.first));
    return resolveSendSource(
        toAddress: toAddress, source: UnspentCoinType.any, sendAll: true);
  }

  BitcoinTransactionCredentials _withSource(
          BitcoinTransactionCredentials c, UnspentCoinType source) =>
      BitcoinTransactionCredentials(
        c.outputs,
        priority: c.priority,
        feeRate: c.feeRate,
        coinTypeToSpendFrom: source,
        payjoinUri: c.payjoinUri,
      );

  bool _isShieldedAddress(String address) {
    final addr = address.toLowerCase().trim();
    return addr.startsWith('ps1') || addr.startsWith('ptestsapling1');
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    var transactionCredentials = credentials as BitcoinTransactionCredentials;

    // Send-all from "any" (QR scan, asset details, payment links) can only
    // sweep one pool: no builder mixes transparent inputs with Sapling spends.
    if (transactionCredentials.coinTypeToSpendFrom == UnspentCoinType.any &&
        transactionCredentials.outputs.any((o) => o.sendAll)) {
      final source = await _sendAllSourcePool(transactionCredentials.outputs
          .map((o) => o.isParsedAddress ? o.extractedAddress! : o.address));
      transactionCredentials = _withSource(transactionCredentials, source);
    }

    final spendFromShielded =
        transactionCredentials.coinTypeToSpendFrom == UnspentCoinType.sapling;

    var hasShieldedOutput = false;
    var hasTransparentOutput = false;
    for (final out in transactionCredentials.outputs) {
      final address = out.isParsedAddress ? out.extractedAddress! : out.address;

      if (_isShieldedAddress(address)) {
        hasShieldedOutput = true;
      } else {
        hasTransparentOutput = true;
      }
    }

    if (hasShieldedOutput && hasTransparentOutput) {
      throw Exception(
          'PIVX cannot send to transparent and shielded recipients in one transaction.');
    }

    // Consensus: bad-txns-exchange-addr-has-sapling. Refused here, at the
    // routing decision, not only inside the shielded builder.
    if (spendFromShielded &&
        transactionCredentials.outputs.any((o) => PivxExchangeAddress.looksLike(
            o.isParsedAddress ? o.extractedAddress! : o.address))) {
      throw Exception(
          'Exchange addresses can only be paid from transparent funds');
    }

    if (spendFromShielded && hasTransparentOutput) {
      return await _createShieldedPendingTransaction(transactionCredentials);
    }

    // "any" to one transparent address: transparent first, which keeps
    // shielded funds private. Only a real transparent build that runs short
    // (fee included) falls back to z-to-t. EXM stays transparent: consensus
    // forbids it in a Sapling tx; z-to-t builds take a single recipient.
    final single = transactionCredentials.outputs.length == 1
        ? transactionCredentials.outputs.first
        : null;
    if (single != null &&
        hasTransparentOutput &&
        transactionCredentials.coinTypeToSpendFrom == UnspentCoinType.any &&
        saplingEnabled &&
        !single.sendAll &&
        !PivxExchangeAddress.looksLike(single.isParsedAddress
            ? single.extractedAddress!
            : single.address)) {
      // A transparent attempt that runs short can still have claimed a change
      // address; hand it back so the fallback leaves no gap.
      final changeIndex = walletAddresses.currentChangeAddressIndex;
      try {
        return await _createTransparentRoute(transactionCredentials);
      } catch (e) {
        final short = e is BitcoinTransactionWrongBalanceException ||
            e is BitcoinTransactionNoInputsException;
        if (!short) rethrow;
        // A Sapling start failure disables it; the transparent error stands.
        try {
          await _ensureShieldSyncEngineInitialized();
        } catch (_) {}
        if (_shieldSyncEngine == null ||
            syncStatus is! core_sync.SyncedSyncStatus ||
            !_notesCover(single.cryptoAmount.amount.toInt(),
                toTransparent: true)) {
          rethrow;
        }
        // Only if nothing else moved it since: a concurrent send shares the
        // index and its step must stand.
        if (walletAddresses.currentChangeAddressIndex == changeIndex + 1) {
          walletAddresses.currentChangeAddressIndex = changeIndex;
        }
        return await _createShieldedPendingTransaction(
          transactionCredentials,
          sourceOverride: UnspentCoinType.sapling,
        );
      }
    }

    if (hasShieldedOutput) {
      var source = transactionCredentials.coinTypeToSpendFrom;
      final autoSelected = source == UnspentCoinType.any;
      if (autoSelected) {
        await _ensureShieldSyncEngineInitialized();
        final out = transactionCredentials.outputs.first;
        source = resolveSendSource(
          toAddress: out.isParsedAddress ? out.extractedAddress! : out.address,
          source: UnspentCoinType.any,
          amount: out.cryptoAmount.amount.toInt(),
          sendAll: out.sendAll,
        );
      }

      // An auto-picked z-to-z whose build still runs short (fee rounding)
      // falls back to t-to-z. An explicit source surfaces it.
      if (autoSelected && source == UnspentCoinType.sapling) {
        try {
          return await _createShieldedPendingTransaction(
            transactionCredentials,
            sourceOverride: UnspentCoinType.sapling,
          );
        } catch (e) {
          if (!_isInsufficientShieldedFunds(e)) rethrow;
          printV(
              '[PIVX] shielded funds cannot cover the fee, falling back to t-to-z');
          return await _createShieldedPendingTransaction(
            transactionCredentials,
            sourceOverride: UnspentCoinType.transparent,
          );
        }
      }

      return await _createShieldedPendingTransaction(
        transactionCredentials,
        sourceOverride: source,
      );
    }

    return _createTransparentRoute(transactionCredentials);
  }

  Future<PendingTransaction> _createTransparentRoute(
      BitcoinTransactionCredentials transactionCredentials) {
    // A memo on an all-transparent send would leak as a public OP_RETURN.
    if (transactionCredentials.outputs.any((o) => o.memo != null)) {
      final stripped = BitcoinTransactionCredentials(
        transactionCredentials.outputs
            .map((o) => OutputInfo(
                  address: o.address,
                  sendAll: o.sendAll,
                  isParsedAddress: o.isParsedAddress,
                  cryptoAmount: o.cryptoAmount,
                  fiatAmount: o.fiatAmount,
                  note: o.note,
                  extractedAddress: o.extractedAddress,
                  memo: null,
                  extra: o.extra,
                ))
            .toList(),
        priority: transactionCredentials.priority,
        feeRate: transactionCredentials.feeRate,
        coinTypeToSpendFrom: transactionCredentials.coinTypeToSpendFrom,
        payjoinUri: transactionCredentials.payjoinUri,
      );
      return _createTransparentTransaction(stripped);
    }
    return _createTransparentTransaction(transactionCredentials);
  }

  // The base dust floor is one value for every output; an exchange output is
  // one byte larger, so PIVX Core's IsDust needs a higher floor for it.
  Future<PendingTransaction> _createTransparentTransaction(
      BitcoinTransactionCredentials credentials) async {
    bool isExchange(OutputInfo o) => PivxExchangeAddress.looksLike(
        o.isParsedAddress ? o.extractedAddress! : o.address);
    const floor = PivxFeePolicy.exchangeDustThreshold;
    if (credentials.outputs.any((o) =>
        !o.sendAll && isExchange(o) && o.cryptoAmount.amount.toInt() < floor)) {
      throw BitcoinTransactionNoDustException();
    }
    final pending = await super.createTransaction(credentials);
    if (credentials.outputs.any((o) => o.sendAll && isExchange(o)) &&
        pending.amount.amount.toInt() < floor) {
      throw BitcoinTransactionNoDustException();
    }
    return pending;
  }

  /// z-to-z, z-to-t or t-to-z.
  Future<PendingTransaction> _createShieldedPendingTransaction(
    BitcoinTransactionCredentials credentials, {
    UnspentCoinType? sourceOverride,
  }) async {
    if (credentials.outputs.length != 1) {
      throw Exception(
          'Shielded transactions currently support only single outputs');
    }

    final output = credentials.outputs.first;
    final toAddress =
        output.isParsedAddress ? output.extractedAddress! : output.address;
    final isSendAll = output.sendAll;
    final transparentDestination = !_isShieldedAddress(toAddress);
    // A transparent destination rejects a memo; drop a stale one.
    final memo = transparentDestination ? null : output.memo;
    // The form counts characters; the Sapling memo field is 512 bytes, and
    // past it the build fails after seconds of proving.
    if (memo != null && utf8.encode(memo).length > 512) {
      throw Exception('PIVX memo is over 512 bytes.');
    }

    final coinType = sourceOverride ?? credentials.coinTypeToSpendFrom;
    if (coinType != UnspentCoinType.sapling) {
      final built = await _buildShieldTransactionResult(
        toAddress: toAddress,
        requestedAmount: isSendAll ? null : output.cryptoAmount.amount.toInt(),
        isSendAll: isSendAll,
        memo: memo,
      );
      return PendingPivxShieldedTransaction(
        result: built.result,
        electrumClient: electrumClient,
        amount: built.amount,
        fee: built.result.fee,
        onCommit: (tx) async {
          // Nothing else records this send; without it the transparent change
          // reads as an incoming payment.
          try {
            await _recordPendingShieldedOutgoing(
              txid: built.result.txId,
              amount: built.amount,
              fee: built.result.fee,
              toAddress: toAddress,
              route: 't-to-z',
              memo: memo,
            );
          } catch (_) {}
          try {
            await updateAllUnspents();
            await updateBalance();
          } catch (_) {}
          try {
            await syncShielded();
          } catch (e) {
            printV(
                '[PIVX Sapling] Shielded post-broadcast sync failed: ${sanitizeShieldSyncError(e)}');
          }
        },
      );
    }

    await _ensureShieldSyncEngineInitialized();

    final amount = isSendAll
        ? _shieldedSendAllAmount(transparentDestination: transparentDestination)
        : output.cryptoAmount.amount.toInt();

    // Fee-aware, the same note plan the build uses; a send-all amount is
    // already net of its fee.
    final hasShieldedFunds = isSendAll ||
        _notesCover(amount, toTransparent: transparentDestination);

    if (hasShieldedFunds) {
      final result = await createShieldedTransaction(
        toAddress: toAddress,
        amount: amount,
        memo: memo,
        spendAllShieldedInputs: isSendAll,
      );

      return PendingPivxShieldedTransaction(
        result: result,
        electrumClient: electrumClient,
        amount: amount,
        fee: result.fee,
        noteStorage: _shieldSyncEngine!.storage,
        onCommit: (tx) async {
          try {
            await _recordPendingShieldedOutgoing(
              txid: result.txId,
              amount: amount,
              fee: result.fee,
              toAddress: toAddress,
              route: transparentDestination ? 'z-to-t' : 'z-to-z',
              memo: memo,
            );
          } catch (e) {
            printV('[PIVX Sapling] Recording pending shielded send failed (non-fatal)');
          }

          if (result.spentNullifiers.isNotEmpty) {
            await _reconcileShieldedBalance();
          } else {
            await updateBalance();
          }

          try {
            await syncShielded();
          } catch (e) {
            printV(
                '[PIVX Sapling] Shielded post-broadcast sync failed: ${sanitizeShieldSyncError(e)}');
          }
        },
      );
    }

    throw Exception(
        'Insufficient shielded balance to cover the amount and PIVX fee.');
  }

  int _shieldedSendAllAmount({bool transparentDestination = false}) {
    final notes =
        _shieldSyncEngine!.spendableNotesAt(_shieldConfirmationHeight);
    if (notes.isEmpty) {
      throw Exception('No spendable shielded notes available.');
    }

    final total = notes.fold<int>(0, (sum, note) => sum + note.value);
    final fee = PivxFeePolicy.saplingFee(
      saplingInputs: notes.length,
      saplingOutputs: transparentDestination ? 0 : 1,
      transparentOutputs: transparentDestination ? 1 : 0,
    );
    final amount = total - fee;
    final dustFloor = transparentDestination
        ? PivxFeePolicy.transparentDustThreshold
        : PivxFeePolicy.shieldedDustThreshold;
    if (amount < dustFloor) {
      throw Exception('Insufficient shielded balance after PIVX fee.');
    }

    return amount;
  }
}

class _BuiltShieldTransaction {
  _BuiltShieldTransaction(this.result, this.amount);

  final SaplingTransactionResult result;
  final int amount;
}
