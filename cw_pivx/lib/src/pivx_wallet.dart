import 'dart:async';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:bech32/bech32.dart';
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
import 'package:cw_core/sync_status.dart' as core_sync;
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:synchronized/synchronized.dart';

import 'pivx_network.dart';
import 'pivx_wallet_addresses.dart';
import 'pending_pivx_shielded_transaction.dart';
import 'sapling/sapling_constants.dart';
import 'sapling/pivx_sapling_electrumx.dart';
import 'sapling/sapling_factories.dart';
import 'sapling/sapling_note_storage.dart';

part 'pivx_wallet.g.dart';

const bool _debugClearPendingShieldedSpends =
    bool.fromEnvironment('PIVX_CLEAR_PENDING_SHIELDED_SPENDS');

/// PIVX wallet with Sapling shielded support, built on ElectrumWallet.
///
/// Transparent layer: BIP44 coin type 119, P2PKH 'D' addresses, PIVX Core
/// dust threshold, coinstake-aware balances. Shielded layer: Sapling notes,
/// 'ps' addresses on mainnet, zero-knowledge proofs. Balance splits
/// transparent (UTXO) and shielded (unspent notes); total is the sum.
/// Routes: t->t, t->z (shield), z->z, z->t (deshield).
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
    PivxNetwork pivxNetwork = PivxNetwork.mainnet,
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
          network: pivxNetwork,
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
      mainHdByType: mainHdByType,
      sideHdByType: sideHdByType,
      legacyMainHd: mainHd,
      legacySideHd: sideHd,
      network: pivxNetwork,
      initialAddressPageType: addressPageType,
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
    // Won't throw if the native Sapling lib is unavailable.
    await tryInitializeSapling();
    _ensureShieldedHeaderSyncSubscription();
  }

  @override
  Future<void> close({bool shouldCleanup = false}) async {
    await _shieldedHeaderSyncSubscription?.cancel();
    _shieldedHeaderSyncSubscription = null;
    await _mempoolSubscription?.cancel();
    _mempoolSubscription = null;
    _shieldedSyncPollTimer?.cancel();
    _shieldedSyncPollTimer = null;
    // Free native Sapling handles (prover, sync engine, key manager).
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

  /// Lazily initialized on first Sapling access.
  SaplingKeyManagerWrapper? _saplingKeyManager;

  /// Lazily initialized when Sapling sync starts.
  ShieldSyncEngineWrapper? _shieldSyncEngine;
  bool _shieldSyncEngineInitialized = false;

  /// Lazily initialized when building shielded transactions.
  SaplingTransactionBuilderWrapper? _saplingTxBuilder;

  /// Serializes balance updates against races.
  final _balanceLock = Lock();

  /// Serializes the shared peek-engine mempool decrypt so a push and the poll
  /// safety-net can't interleave on it.
  final _mempoolLock = Lock();

  StreamSubscription<Object>? _shieldedHeaderSyncSubscription;
  DateTime? _lastHeaderTriggeredShieldSync;

  /// Push feed for 0-conf mempool receives, when the node supports it. Replaces
  /// the poll for one subscription per session; null means poll fallback.
  StreamSubscription<SaplingMempoolResult>? _mempoolSubscription;

  /// Periodic fallback that keeps shielded state live even when the header
  /// subscription goes stale (e.g. after a mobile connection drop/reconnect,
  /// which is why incoming notes and confirmations only updated on restart).
  Timer? _shieldedSyncPollTimer;

  @observable
  bool saplingEnabled = true;

  /// Shielded balance in zatoshis (1 PIV = 1e8).
  @observable
  int shieldedBalance = 0;

  /// Unconfirmed shielded balance in zatoshis.
  @observable
  int pendingShieldedBalance = 0;

  /// 0-conf shielded receives seen in the mempool. display-only, not spendable;
  /// dropped once mined (moves to a confirmed note) or evicted. refreshed by
  /// _refreshShieldedMempool on the sync cadence.
  List<MempoolIncomingNote> _mempoolIncoming = <MempoolIncomingNote>[];

  int get _mempoolIncomingTotal {
    // exclude any that already landed as a confirmed note; a stale snapshot
    // after mining would otherwise double-count against pendingShieldedBalance.
    final known =
        _shieldSyncEngine?.storage.notes.map((n) => n.txid).toSet() ??
            const <String>{};
    return _mempoolIncoming
        .where((n) => !known.contains(n.txid))
        .fold<int>(0, (sum, n) => sum + n.value);
  }

  /// pending shielded shown to the user: confirmed-but-immature notes plus the
  /// 0-conf mempool total.
  int get _displayPendingShielded =>
      pendingShieldedBalance + _mempoolIncomingTotal;

  @observable
  int lastShieldSyncedBlock = 0;

  @observable
  bool isShieldSyncing = false;

  @observable
  String? currentShieldedAddress;

  /// Whether the active node passed the Sapling RPC capability probe.
  @observable
  bool saplingRpcAvailable = false;

  /// Sanitized shielded sync error for UI/support state.
  @observable
  String? lastShieldSyncError;

  Money _pivxMoney(int amount) => Money.fromInt(amount, CryptoCurrency.pivx);

  Money get _zeroPivxMoney => Money.zero(CryptoCurrency.pivx);

  int get transparentBalance {
    final electrumBalance = balance[currency];
    return electrumBalance?.confirmed.amount.toInt() ?? 0;
  }

  int get totalBalance => transparentBalance + shieldedBalance;

  double get totalBalancePivx => totalBalance / 100000000.0;

  double get shieldedBalancePivx => shieldedBalance / 100000000.0;

  /// PIVX supports rescan for both transparent and shielded balances.
  @override
  bool get hasRescan => true;

  /// Rescan transparent then shielded from [height].
  @override
  Future<void> rescan({required int height, bool? doSingleScan}) async {
    syncStatus = core_sync.SyncronizingSyncStatus();

    // don't call super.rescan(): it flips on Bitcoin silent-payment scanning and
    // starts a scan stream the pivx server can't answer, throwing a generic
    // error dialog. transparent balance/history is always live, so re-fetch it,
    // then rescan the shielded pool from height.
    try {
      await updateTransactions();
      await updateAllUnspents();
      await updateBalance();
    } catch (e) {
      printV('[PIVX] transparent refresh during rescan failed: $e');
    }

    await rescanShielded(fromHeight: height);

    syncStatus = core_sync.SyncedSyncStatus();
  }

  /// Initialize Sapling. Seed bytes are zeroed after use; errors leave the
  /// wallet in a clean state.
  Future<void> initializeSapling() async {
    if (_saplingKeyManager != null) return;

    SaplingKeyManagerWrapper? tempKeyManager;
    SaplingAddressResult? tempAddress;
    Uint8List? saplingSeeds;

    try {
      final mnemonic = seed;
      if (mnemonic == null) {
        throw StateError('Cannot initialize Sapling without mnemonic seed');
      }
      saplingSeeds = MnemonicBip39.toSeed(mnemonic, passphrase: passphrase);

      tempKeyManager = await SaplingKeyManagerFactory.create(
        seed: saplingSeeds,
        isTestnet: network == PivxNetwork.testnet,
        accountIndex: 0,
      );
      await tempKeyManager.initialize();

      tempAddress = await tempKeyManager.getDefaultAddress();

      // Commit only after everything succeeds.
      _saplingKeyManager = tempKeyManager;
      currentShieldedAddress = tempAddress.encoded;
      saplingEnabled = true;
      _applySaplingReceiveOptions();
    } catch (e) {
      if (tempKeyManager != null) {
        try {
          tempKeyManager.dispose();
        } catch (_) {
          // ignore disposal errors
        }
      }

      // Native lib not loaded, or other error.
      saplingEnabled = false;
      _applySaplingReceiveOptions();
      rethrow;
    } finally {
      // zero seed bytes
      if (saplingSeeds != null) {
        saplingSeeds.fillRange(0, saplingSeeds.length, 0);
      }
    }
  }

  Future<bool> tryInitializeSapling() async {
    if (_saplingKeyManager != null) return true;
    if (!saplingEnabled) return false;

    try {
      await initializeSapling();

      await _loadShieldedBalanceFromStorage();

      // Restore notes to the native engine so they're spendable after restart.
      await _restoreNotesToNativeEngine();

      // rebuild shielded history from restored notes on startup; don't wait for
      // a successful sync (can fail on a flaky node), or balance shows but
      // history stays empty.
      try {
        await _refreshShieldedTransactionHistory();
      } catch (e) {
        printV('[PIVX] Startup shielded history refresh failed');
      }

      return true;
    } catch (e) {
      printV('[PIVX] Sapling initialization failed');
      saplingEnabled = false;
      _applySaplingReceiveOptions();
      return false;
    }
  }

  /// push saplingEnabled to the address list so the receive page offers the
  /// shielded option only when Sapling is available.
  void _applySaplingReceiveOptions() {
    final addresses = walletAddresses;
    if (addresses is PivxWalletAddresses) {
      addresses.setSaplingEnabled(saplingEnabled);
    }
  }

  /// Restore notes from storage to the native engine; Rust SYNC_STATES is
  /// empty after restart.
  Future<void> _restoreNotesToNativeEngine() async {
    if (_saplingKeyManager == null) return;

    try {
      _shieldSyncEngine ??= await ShieldSyncEngineFactory.create(
        keyManager: _saplingKeyManager!,
        walletId: walletInfo.id,
        isTestnet: network == PivxNetwork.testnet,
        electrumClient: electrumClient,
        encryptionFileUtils: encryptionFileUtils,
        password: password,
      );
      if (!_shieldSyncEngineInitialized) {
        await _shieldSyncEngine!.initialize();
        _shieldSyncEngineInitialized = true;
      }
      _restoreCurrentShieldedAddressFromStorage();

      await _debugClearPendingShieldedSpendReservations();

      await _shieldSyncEngine!.restoreNotesFromStorage();
      printV('[PIVX] Restored spendable notes to native engine');
    } catch (e) {
      printV('[PIVX] Failed to restore notes to native engine');
      // Don't fail init; notes can be restored during sync.
    }
  }

  /// Load shielded balance from storage to restore it without a full sync.
  Future<void> _loadShieldedBalanceFromStorage() async {
    try {
      final storage = SaplingNoteStorage(
        walletId: walletInfo.id,
        isTestnet: network == PivxNetwork.testnet,
        encryptionFileUtils: encryptionFileUtils,
        password: password,
      );
      await storage.load();

      final storedBalance = storage.spendableBalanceAt(
        chainHeight: storage.lastSyncedHeight,
      );
      final storedPendingBalance = storage.pendingReceivedBalanceAt(
        chainHeight: storage.lastSyncedHeight,
      );

      shieldedBalance = storedBalance;
      pendingShieldedBalance = storedPendingBalance;
      // Update the balance map directly with shielded balance, including zero,
      // so stale shielded display state cannot survive storage reloads.
      final currentBalance = balance[currency];
      if (currentBalance != null) {
        balance[currency] = ElectrumBalance(
          confirmed: currentBalance.confirmed,
          unconfirmed: currentBalance.unconfirmed,
          frozen: currentBalance.frozen,
          secondConfirmed: _pivxMoney(storedBalance),
          secondUnconfirmed: _pivxMoney(storedPendingBalance),
        );
      } else {
        balance[currency] = ElectrumBalance(
          confirmed: _zeroPivxMoney,
          unconfirmed: _zeroPivxMoney,
          frozen: _zeroPivxMoney,
          secondConfirmed: _pivxMoney(storedBalance),
          secondUnconfirmed: _pivxMoney(storedPendingBalance),
        );
      }
    } catch (e) {
      printV('[PIVX] Failed to load shielded balance from storage');
    }
  }

  /// Chain height to count shielded confirmations against. Uses the daemon tip
  /// when it leads the Sapling index cursor (the index lags the tip by a small
  /// processing window, so the cursor under-reports confirmations near the top),
  /// else the index height. Legacy nodes with no daemon height fall back to the
  /// index height. Keeps the balance confirmed/pending split consistent with
  /// history, which counts the same way.
  int get _shieldConfirmationHeight {
    final storage = _shieldSyncEngine!.storage;
    final indexHeight = storage.lastSyncedHeight;
    final daemonHeight =
        _shieldSyncEngine!.saplingClient.capabilities?.daemonHeight;
    return (daemonHeight != null && daemonHeight > indexHeight)
        ? daemonHeight
        : indexHeight;
  }

  /// True when [error] signals the shielded pool can't fund a send (including
  /// the after-fee case). Lets an auto-selected z-to-z fall back to shielding
  /// transparent funds (t-to-z) instead of failing.
  bool _isInsufficientShieldedFunds(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('insufficient shielded balance') ||
        message.contains('insufficient balance after fee') ||
        message.contains('could not select sufficient notes') ||
        message.contains('no spendable shielded notes');
  }

  /// Reconcile shielded balance: the Rust engine is the source of truth.
  /// Locked against concurrent operations. Call after sync, broadcast,
  /// restoration, or any note mutation.
  Future<void> _reconcileShieldedBalance() async {
    if (_shieldSyncEngine == null) {
      printV('[PIVX] Cannot reconcile balance: Sync engine not initialized');
      return;
    }

    await _balanceLock.synchronized(() async {
      try {
        final refHeight = _shieldConfirmationHeight;
        shieldedBalance = _shieldSyncEngine!.balanceAt(refHeight);
        pendingShieldedBalance = _shieldSyncEngine!.pendingBalanceAt(refHeight);
        // always push into the balance map, even when the observables already
        // match. the sync's onProgress updates shieldedBalance but not the map,
        // so the old `if changed` guard skipped the map update and the ui stayed
        // on the stale value until a manual pull-to-refresh. this is the
        // reconcile that makes a received/confirmed note show on its own.
        _applyShieldedBalanceToMap();
      } catch (e) {
        printV('[PIVX] Balance reconciliation failed');
        // best-effort; don't rethrow
      }
    });

    // keep shielded history in lockstep with balance. refresh used to run only
    // in startSync's success path, so header/poll syncs updated balance but left
    // history empty. every reconcile now rebuilds history from the same notes.
    try {
      await _refreshShieldedTransactionHistory();
    } catch (e) {
      printV('[PIVX] Shielded tx history refresh failed');
    }

    // 0-conf mempool receives use a separate route, so they aren't gated by the
    // confirmed-notes guard above and show even before the first block.
    try {
      await _refreshShieldedMempoolHistory();
    } catch (e) {
      printV('[PIVX] Shielded mempool history refresh failed');
    }
  }

  /// Refresh the 0-conf shielded mempool snapshot (network op). Best-effort:
  /// null from scanMempool means unavailable, keep the prior snapshot; a
  /// non-null list (possibly empty) replaces it.
  Future<void> _refreshShieldedMempool() async {
    if (_shieldSyncEngine == null) return;
    // runs every sync as the safety net even when subscribed: on a reconnect the
    // push feed goes silently stale (server drops the sub, no replay), and the
    // poll is what keeps 0-conf alive. the push just delivers it faster between.
    try {
      await _mempoolLock.synchronized(() async {
        final result = await _shieldSyncEngine!.scanMempool();
        if (result == null) return; // unavailable this cycle, keep prior snapshot
        _applyMempoolResult(result);
      });
    } catch (e) {
      printV('[PIVX Sapling] Mempool peek failed (non-fatal)');
    }
  }

  /// Apply a mempool scan/push result to the 0-conf state. Full replacement:
  /// the push feed sends full state (not a diff), and a stale beyond-cap entry
  /// in the rare truncated case is cleaned by the node-checked disappeared-tx
  /// reconcile rather than lingering.
  void _applyMempoolResult(MempoolScanResult result) {
    _mempoolIncoming = result.incoming;
  }

  /// Subscribe to the node's mempool push feed once per session when supported,
  /// so 0-conf receives arrive at push latency (~5s) instead of on the poll.
  /// The poll (_refreshShieldedMempool) stays as the fallback when unsupported.
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
          final result =
              await _shieldSyncEngine!.decryptMempoolSnapshot(snapshot);
          _applyMempoolResult(result);
        });
        await _reconcileShieldedBalance();
      } catch (e) {
        printV('[PIVX Sapling] Mempool push apply failed (non-fatal)');
      }
    },
        // stream errored or the socket closed the feed: drop it so the poll
        // resumes and the next sync re-subscribes (no silent 0-conf starve).
        onError: (Object _) => _resetMempoolSubscription(),
        onDone: _resetMempoolSubscription,
        cancelOnError: false);
    printV('[PIVX Sapling] Subscribed to mempool push feed');
  }

  void _resetMempoolSubscription() {
    _mempoolSubscription?.cancel();
    _mempoolSubscription = null;
  }

  /// Grace before a still-pending send is treated as gone. A valid PIVX tx
  /// mines within a few 60s blocks, so past this window an unmined tx the node
  /// no longer has is evicted/replaced, not just slow.
  static const Duration _kPendingSpendEvictionGrace = Duration(minutes: 15);

  /// consecutive sync cycles a pending send must be observed missing (past the
  /// grace, on a canary-verified healthy node) before its notes are released.
  static const int _kEvictionConfirmations = 3;

  /// per-txid streak of consecutive "missing" observations for pending sends.
  final Map<String, int> _shieldedSpendMissStreak = {};

  /// rotating start for the bounded orphan z-receive node-check each cycle.
  int _orphanCheckCursor = 0;

  /// True when the node has no record of [txid] (not in mempool, not mined).
  /// getTransactionVerbose returns empty on a network failure too, so fund-side
  /// callers pair this with the canary + grace + streak; never act on a bare
  /// failure.
  Future<bool> _shieldedTxMissingFromNode(String txid) async {
    try {
      final verbose = await electrumClient.getTransactionVerbose(hash: txid);
      return verbose.isEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Reconcile shielded txs we track as pending against the node. An accepted
  /// send or a 0-conf receive can be evicted, replaced, or reorged out and then
  /// never resolve, leaving stuck-pending history, locked notes, or stale
  /// balance. Node-status checks drive all three cleanups, acting only on a
  /// definitive "missing".
  Future<void> _reconcileDisappearedShieldedTxs() async {
    if (_shieldSyncEngine == null || !electrumClient.isConnected) return;
    final storage = _shieldSyncEngine!.storage;
    final now = DateTime.now();
    var historyChanged = false;
    var balanceDirty = false;
    var releasedNotes = false;

    // 1. pending spends. releasing notes is fund-adjacent, so guard hard: a
    // canary (a mined tx we hold, definitely on the node) must be FOUND (node
    // is healthy, not returning empty for everything), the send must be past
    // the grace, and the node must report it missing on several consecutive
    // cycles. even then a wrong release only risks a failed respend (nullifier
    // conflict), never lost funds.
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
    // drop streak counters for txids that left pending state (mined/cleared).
    _shieldedSpendMissStreak
        .removeWhere((txid, _) => !spendPendingAt.containsKey(txid));
    if (spendPendingAt.isNotEmpty) {
      // canary: a mined tx we hold definitely exists on the node. check a few
      // (the first could be reorg-stale) and treat the node as healthy if ANY
      // is found, so one stale note can't block release forever.
      final canaries = <String>{};
      for (final note in storage.notes) {
        if (note.height > 0) {
          canaries.add(note.txid);
          if (canaries.length >= 3) break;
        }
      }
      var nodeHealthy = false;
      for (final canary in canaries) {
        if (!await _shieldedTxMissingFromNode(canary)) {
          nodeHealthy = true;
          break;
        }
      }
      if (nodeHealthy) {
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

    // 2. 0-conf mempool receives: drop any the node no longer has. display only,
    // self-healing (re-added next scan if it reappears).
    if (_mempoolIncoming.isNotEmpty) {
      final kept = <MempoolIncomingNote>[];
      for (final note in _mempoolIncoming) {
        if (await _shieldedTxMissingFromNode(note.txid)) continue;
        kept.add(note);
      }
      if (kept.length != _mempoolIncoming.length) {
        _mempoolIncoming = kept;
        balanceDirty = true;
      }
    }

    // 3. orphaned z-receive entries (no backing note, e.g. reorged out): prune
    // the ones the node no longer has. bounded per cycle to cap node queries.
    final noteTxids = storage.notes.map((n) => n.txid).toSet();
    final orphans = transactionHistory.transactions.entries
        .where((e) =>
            e.value.additionalInfo['isPivxShielded'] == true &&
            e.value.additionalInfo['pivxRoute'] == 'z-receive' &&
            !noteTxids.contains(e.key))
        .map((e) => e.key)
        .toList();
    if (orphans.isNotEmpty) {
      // check a rotating window each cycle to cap node queries, so stale
      // entries past the window aren't starved when earlier ones stay valid.
      const window = 15;
      final start =
          orphans.length <= window ? 0 : _orphanCheckCursor % orphans.length;
      for (var i = 0; i < orphans.length && i < window; i++) {
        final txid = orphans[(start + i) % orphans.length];
        if (!await _shieldedTxMissingFromNode(txid)) continue;
        transactionHistory.transactions.remove(txid);
        historyChanged = true;
      }
      _orphanCheckCursor = (start + window) % orphans.length;
    }

    // native restore skipped these notes while they were pending, so re-add
    // them or the builder can't select them even though balance shows spendable.
    if (releasedNotes) {
      try {
        await _shieldSyncEngine!.restoreNotesFromStorage();
      } catch (e) {
        printV('[PIVX Sapling] Re-restore after spend release failed');
      }
    }

    if (historyChanged) await transactionHistory.save();
    if (balanceDirty) await _reconcileShieldedBalance();
  }

  // mirror the current shielded balance into the balance map's second* fields,
  // preserving the transparent fields. no network, unlike updateBalance().
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

  Future<void> _refreshShieldedTransactionHistory() async {
    if (_shieldSyncEngine == null) return;

    final storage = _shieldSyncEngine!.storage;
    final currentHeight = _shieldConfirmationHeight;
    final byTxid = <String, List<StoredSaplingNote>>{};
    for (final note in storage.notes) {
      byTxid.putIfAbsent(note.txid, () => <StoredSaplingNote>[]).add(note);
    }
    printV(
        '[PIVX] Shielded history refresh: ${storage.notes.length} notes -> ${byTxid.length} txid group(s)');

    // don't reconcile (add/update/prune) history against an empty note set. a
    // transient-empty storage (mid-rescan, failed sync, interrupted load) would
    // prune every saved shielded-receive. skip until we have notes.
    if (byTxid.isEmpty) return;

    var changed = false;
    // a z-receive entry with no backing note (reorged out) is pruned by the
    // node-checked orphan pass in _reconcileDisappearedShieldedTxs, not here,
    // so a receive still valid in the mempool isn't dropped without a check.

    // txids that spent our own notes are our sends; the notes they create are
    // change returning to the pool, not receives. captured at broadcast
    // (pendingSpendingTxid) and after mining (spendingTxid).
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

    for (final spend in mySpendHeightsByTxid.entries) {
      final existing = transactionHistory.transactions[spend.key];
      if (existing != null &&
          existing.additionalInfo['isPivxShielded'] == true &&
          existing.direction == TransactionDirection.outgoing) {
        existing.height = spend.value;
        existing.confirmations = currentHeight >= spend.value
            ? currentHeight - spend.value + 1
            : 0;
        existing.isPending = false;
        changed = true;
      }
    }

    for (final entry in byTxid.entries) {
      // our own send: keep the outgoing entry recorded at broadcast (with the
      // sent amount), refresh its confirmations from the mined change note, and
      // drop any incoming we created for the change before the spend was
      // detected, so change never shows as "Received shielded".
      if (mySpendTxids.contains(entry.key)) {
        final existing = transactionHistory.transactions[entry.key];
        if (existing != null &&
            existing.additionalInfo['isPivxShielded'] == true) {
          if (existing.direction == TransactionDirection.incoming) {
            transactionHistory.transactions.remove(entry.key);
            changed = true;
          } else {
            final minHeight = entry.value
                .map((note) => note.height)
                .reduce((a, b) => a < b ? a : b);
            if (minHeight > 0) {
              existing.height = minHeight;
              existing.confirmations =
                  currentHeight >= minHeight ? currentHeight - minHeight + 1 : 0;
              existing.isPending = false;
              changed = true;
            }
          }
        }
        continue;
      }

      final notes = entry.value;
      final amount = notes.fold<int>(0, (sum, note) => sum + note.value);
      final height =
          notes.map((note) => note.height).reduce((a, b) => a < b ? a : b);
      final confirmations = height > 0 && currentHeight >= height
          ? currentHeight - height + 1
          : 0;
      // first non-empty decrypted memo for this receive (usually one output).
      final memo = notes
          .map((note) => note.memo)
          .firstWhere((m) => m != null && m.isNotEmpty, orElse: () => null);
      final existing = transactionHistory.transactions[entry.key];

      if (existing == null) {
        transactionHistory.addOne(ElectrumTransactionInfo(
          WalletType.pivx,
          id: entry.key,
          height: height,
          amount: _pivxMoney(amount),
          fee: _zeroPivxMoney,
          direction: TransactionDirection.incoming,
          isPending: confirmations <
              PivxShieldedConfirmationPolicy.receiveConfirmations,
          date: _shieldedNoteDate(notes),
          confirmations: confirmations,
          additionalInfo: {
            'isPivxShielded': true,
            'pivxPool': 'shielded',
            'pivxRoute': 'z-receive',
            'pivxRequiredConfirmations':
                PivxShieldedConfirmationPolicy.receiveConfirmations,
            if (memo != null) 'memo': memo,
          },
        ));
        changed = true;
      } else if (existing.additionalInfo['isPivxShielded'] == true) {
        if (existing.direction == TransactionDirection.outgoing) {
          if (height > 0) {
            existing.height = height;
            existing.confirmations = confirmations;
            existing.isPending = false;
            changed = true;
          }
          continue;
        }

        existing.height = height;
        existing.amount = _pivxMoney(amount);
        existing.confirmations = confirmations;
        existing.isPending =
            confirmations < PivxShieldedConfirmationPolicy.receiveConfirmations;
        // promoting from z-mempool: re-date off the mined block, not the stale
        // mempool firstSeen/now, so an import or 0-conf->confirmed flow shows the
        // real time.
        existing.date = _shieldedNoteDate(notes);
        // promote a 0-conf mempool entry to a confirmed receive so the mempool
        // prune (which keys off the z-mempool route) leaves it alone.
        existing.additionalInfo['pivxRoute'] = 'z-receive';
        if (memo != null) existing.additionalInfo['memo'] = memo;
        changed = true;
      }
    }

    if (changed) {
      await transactionHistory.save();
    }
  }

  /// Reconcile 0-conf mempool receives into history as pending incoming entries
  /// under a distinct 'z-mempool' route, so the confirmed-note prune leaves them
  /// alone. Prune any that dropped out of the snapshot or got mined (the
  /// confirmed z-receive entry takes over at the same txid once the note lands).
  Future<void> _refreshShieldedMempoolHistory() async {
    final storage = _shieldSyncEngine?.storage;
    final knownTxids = storage?.notes.map((n) => n.txid).toSet() ?? <String>{};
    final liveTxids = _mempoolIncoming.map((n) => n.txid).toSet();
    var changed = false;

    final stale = transactionHistory.transactions.entries
        .where((entry) =>
            entry.value.additionalInfo['pivxRoute'] == 'z-mempool' &&
            (!liveTxids.contains(entry.key) || knownTxids.contains(entry.key)))
        .map((entry) => entry.key)
        .toList();
    for (final txid in stale) {
      transactionHistory.transactions.remove(txid);
      changed = true;
    }

    for (final note in _mempoolIncoming) {
      if (knownTxids.contains(note.txid)) continue; // confirmed entry wins
      final existing = transactionHistory.transactions[note.txid];
      final date = note.firstSeen != null
          ? DateTime.fromMillisecondsSinceEpoch(note.firstSeen! * 1000)
          : DateTime.now();
      if (existing == null) {
        transactionHistory.addOne(ElectrumTransactionInfo(
          WalletType.pivx,
          id: note.txid,
          height: 0,
          amount: _pivxMoney(note.value),
          fee: _zeroPivxMoney,
          direction: TransactionDirection.incoming,
          isPending: true,
          date: date,
          confirmations: 0,
          additionalInfo: {
            'isPivxShielded': true,
            'pivxPool': 'shielded',
            'pivxRoute': 'z-mempool',
            'pivxRequiredConfirmations':
                PivxShieldedConfirmationPolicy.receiveConfirmations,
          },
        ));
        changed = true;
      } else if (existing.additionalInfo['pivxRoute'] == 'z-mempool') {
        existing.amount = _pivxMoney(note.value);
        changed = true;
      }
    }

    if (changed) {
      await transactionHistory.save();
    }
  }

  /// Date for a shielded receive: the mined block time (all notes here share a
  /// txid, so one block), falling back to the earliest scan time for legacy
  /// notes stored before blockTime was captured.
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
    String route = 'z-to-z',
  }) async {
    transactionHistory.addOne(ElectrumTransactionInfo(
      WalletType.pivx,
      id: txid,
      height: 0,
      amount: _pivxMoney(amount),
      fee: _pivxMoney(fee),
      direction: TransactionDirection.outgoing,
      isPending: true,
      date: DateTime.now(),
      confirmations: 0,
      to: toAddress,
      additionalInfo: {
        'isPivxShielded': true,
        'pivxPool': 'shielded',
        'pivxRoute': route,
        'pivxRequiredConfirmations':
            PivxShieldedConfirmationPolicy.receiveConfirmations,
      },
    ));
    await transactionHistory.save();
  }

  Future<void> _ensureShieldSyncEngineInitialized() async {
    await initializeSapling();

    if (_shieldSyncEngine != null) {
      if (!_shieldSyncEngineInitialized) {
        await _shieldSyncEngine!.initialize();
        _shieldSyncEngineInitialized = true;
        await _debugClearPendingShieldedSpendReservations();
      }
      _restoreCurrentShieldedAddressFromStorage();
      return;
    }

    _shieldSyncEngine = await ShieldSyncEngineFactory.create(
      keyManager: _saplingKeyManager!,
      walletId: walletInfo.id,
      isTestnet: network == PivxNetwork.testnet,
      electrumClient: electrumClient,
      encryptionFileUtils: encryptionFileUtils,
      password: password,
    );
    await _shieldSyncEngine!.initialize();
    _shieldSyncEngineInitialized = true;
    _restoreCurrentShieldedAddressFromStorage();
    await _debugClearPendingShieldedSpendReservations();
  }

  void _restoreCurrentShieldedAddressFromStorage() {
    final addresses = _shieldSyncEngine?.storage.addresses;
    if (addresses == null || addresses.isEmpty) return;

    final current = currentShieldedReceiveAddressFromStorage(addresses);
    currentShieldedAddress = current.address;
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

  Future<void> _debugClearPendingShieldedSpendReservations() async {
    if (!kDebugMode || !_debugClearPendingShieldedSpends) return;
    if (_shieldSyncEngine == null) return;

    final cleared = await _shieldSyncEngine!.storage.clearPendingSpentNotes();
    final staleHistoryTxids = transactionHistory.transactions.entries
        .where((entry) =>
            entry.value.additionalInfo['isPivxShielded'] == true &&
            {'z-to-z', 'z-to-t'}.contains(entry.value.additionalInfo['pivxRoute']) &&
            entry.value.direction == TransactionDirection.outgoing &&
            entry.value.isPending)
        .map((entry) => entry.key)
        .toList(growable: false);

    for (final txid in staleHistoryTxids) {
      transactionHistory.transactions.remove(txid);
    }

    if (staleHistoryTxids.isNotEmpty) {
      await transactionHistory.save();
    }

    printV(
      '[PIVX Sapling] Debug pending shielded spend cleanup: '
      'cleared_value=$cleared stale_history=${staleHistoryTxids.length}',
    );

    if (cleared <= 0 && staleHistoryTxids.isEmpty) return;

    printV('[PIVX Sapling] Debug cleared pending shielded spends');
    await _shieldSyncEngine!.restoreNotesFromStorage();
    await _reconcileShieldedBalance();
  }

  Future<void> _ensureSaplingRpcSupportsShieldedSync() async {
    await _ensureShieldSyncEngineInitialized();
    final capabilities =
        await _shieldSyncEngine!.saplingClient.probeCapabilities();
    if (!capabilities.supportsBlockRange) {
      throw StateError(
          'Current PIVX node does not support Sapling block scanning');
    }
    saplingRpcAvailable = true;
    lastShieldSyncError = null;
  }

  Future<void> _ensureSaplingRpcSupportsShieldedSend() async {
    await _ensureSaplingRpcSupportsShieldedSync();
    final capabilities =
        await _shieldSyncEngine!.saplingClient.probeCapabilities();
    if (!capabilities.supportsBestAnchor || !capabilities.supportsWitness) {
      saplingRpcAvailable = false;
      lastShieldSyncError =
          'Current PIVX node cannot provide Sapling anchors/witnesses for shielded sends.';
      throw StateError(lastShieldSyncError!);
    }
  }

  /// Shielded payment address for [index] (default: current). Bech32 ps1...
  Future<String> getShieldedAddress({int? index}) async {
    if (index != null) {
      await initializeSapling();
      final address = await _saplingKeyManager!.deriveAddress(index);
      return address;
    }

    await _ensureShieldSyncEngineInitialized();
    return currentShieldedAddress!;
  }

  List<StoredShieldedAddress> get shieldedAddresses {
    if (_shieldSyncEngine == null) return [];
    return _shieldSyncEngine!.storage.addresses;
  }

  /// Generate a new diversified shielded address. All diversified addresses
  /// share one viewing key and the same shielded balance.
  Future<String> generateNewShieldedAddress({String? label}) async {
    await _ensureShieldSyncEngineInitialized();

    final index = _shieldSyncEngine!.storage.getAndIncrementDiversifierIndex();
    final address = await _saplingKeyManager!.deriveAddress(index);

    final storedAddress = StoredShieldedAddress(
      diversifierIndex: index,
      address: address,
      label: label,
    );
    await _shieldSyncEngine!.storage.addAddress(storedAddress);

    currentShieldedAddress = address;

    return address;
  }

  Future<void> updateShieldedAddressLabel(String address, String? label) async {
    if (_shieldSyncEngine != null) {
      await _shieldSyncEngine!.storage.updateAddressLabel(address, label);
    }
  }

  /// Scan the chain for incoming shielded notes and update the balance.
  /// [fromHeight] defaults to the last synced height.
  Future<void> syncShielded({
    int? fromHeight,
    SyncProgressCallback? onProgress,
  }) async {
    if (isShieldSyncing) return;

    await _ensureShieldSyncEngineInitialized();

    // wait for a stable connection
    int retries = 0;
    while (!electrumClient.isConnected && retries < 10) {
      await Future.delayed(const Duration(milliseconds: 500));
      retries++;
    }
    if (!electrumClient.isConnected) {
      printV('[PIVX Sapling] Connection not available, aborting sync');
      return;
    }

    isShieldSyncing = true;

    try {
      await _ensureSaplingRpcSupportsShieldedSync();

      final initialRestoreHeight = await _initialShieldSyncHeight();

      await _shieldSyncEngine!.startSync(
        startHeight: fromHeight ?? initialRestoreHeight,
        onProgress: (status) async {
          lastShieldSyncedBlock = status.lastSyncedBlock;

          await _balanceLock.synchronized(() async {
            final refHeight = _shieldConfirmationHeight;
            shieldedBalance = _shieldSyncEngine!.balanceAt(refHeight);
            pendingShieldedBalance =
                _shieldSyncEngine!.pendingBalanceAt(refHeight);
          });

          // shielded sync must not drive overall syncStatus: it blocks
          // transparent sends while shielded catches up (hours after a restore),
          // though the transparent chain is synced. shielded progress shows via
          // pivxSyncIndicatorText / isShieldSyncing.
          onProgress?.call(status);
        },
      );

      // best-effort: a failure here must not skip the reconcile below, or a
      // stored note never reaches the balance map (the UI reads that, not the
      // shieldedBalance field) or the history, and the receive stays invisible.
      try {
        await _advanceShieldedDiversifierIndexPastObservedNotes();
      } catch (e) {
        printV('[PIVX Sapling] Diversifier advance failed (non-fatal)');
      }
      // subscribe to the push feed for faster 0-conf; the poll below stays on as
      // the reconnect safety net.
      await _ensureShieldedMempoolSubscription();
      // best-effort 0-conf mempool peek before reconcile, so incoming shows in
      // balance + history this cycle. null keeps the prior snapshot.
      await _refreshShieldedMempool();
      // reconcile also rebuilds history now, so it's the single source of truth.
      await _reconcileShieldedBalance();
      // best-effort: clean up sends/receives the node dropped (evicted, replaced,
      // reorged out) so they don't stay stuck-pending or lock their notes.
      try {
        await _reconcileDisappearedShieldedTxs();
      } catch (e) {
        printV('[PIVX Sapling] Disappeared-tx reconcile failed (non-fatal)');
      }
      saplingRpcAvailable = true;
      lastShieldSyncError = null;
    } catch (e) {
      saplingRpcAvailable = false;
      lastShieldSyncError = sanitizeShieldSyncError(e);
      rethrow;
    } finally {
      isShieldSyncing = false;
    }
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
      final height = _heightFromHeaderEvent(event);
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

  /// Periodically re-runs shielded sync so incoming notes and confirmations
  /// stay live even if the header subscription dies on a reconnect. syncShielded
  /// is re-entrant-guarded and caps cheaply at db_height when caught up, and its
  /// completion refreshes balances and confirmations (against daemon_height).
  void _ensureShieldedSyncPoll() {
    if (_shieldedSyncPollTimer != null || !saplingEnabled) {
      return;
    }
    _shieldedSyncPollTimer = Timer.periodic(
      const Duration(seconds: PivxNetwork.shieldedSyncPollInterval),
      (_) async {
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

  static int? _heightFromHeaderEvent(Object? event) {
    if (event is int) return event;
    if (event is num) return event.toInt();
    if (event is Map) {
      return _intFromHeaderField(event['height']) ??
          _intFromHeaderField(event['block_height']);
    }
    return null;
  }

  static int? _intFromHeaderField(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  @visibleForTesting
  static core_sync.SyncStatus? syncStatusForShieldProgress(SyncStatus status) {
    if (status.blocksRemaining > 0 && status.chainTip > 0) {
      final progress = status.lastSyncedBlock / status.chainTip;
      return core_sync.SyncingSyncStatus(status.blocksRemaining, progress);
    }

    if (status.blocksRemaining == 0 && status.progress >= 1.0) {
      return core_sync.SyncedSyncStatus();
    }

    return null;
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

  /// Also syncs shielded notes after the transparent sync.
  @override
  @action
  Future<void> startSync() async {
    await super.startSync();

    if (saplingEnabled && _saplingKeyManager != null) {
      _ensureShieldedHeaderSyncSubscription();
      _ensureShieldedSyncPoll();
      try {
        await syncShielded();

        // reconcile (locks internally)
        await _reconcileShieldedBalance();
        await updateBalance();
      } catch (e) {
        if (kDebugMode) {
          printV('[PIVX] Shielded sync debug: ${e.runtimeType}: $e');
        }
        printV('[PIVX] Shielded sync failed: ${sanitizeShieldSyncError(e)}');
        // Don't fail the whole sync if shielded sync fails.
      }
    }
  }

  /// Clear stored notes and rescan from [fromHeight] (Sapling activation
  /// height when null). Use when notes lack spending data or the balance is
  /// wrong.
  Future<void> rescanShielded({
    int? fromHeight,
    void Function(SyncStatus)? onProgress,
  }) async {
    await _ensureShieldSyncEngineInitialized();

    // Stop any in-flight sync and wait for it to unwind before clearing storage
    // and resetting the native engine. Otherwise the running pass faults on the
    // reset handle (surfacing as a generic error), and the resync below would
    // early-return while a sync is still marked active.
    _shieldSyncEngine!.requestStop();
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    while (isShieldSyncing && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    await _shieldSyncEngine!.storage.clear();
    _shieldSyncEngine!.resetNativeEngine();

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
        final derived = await _saplingKeyManager!.deriveAddress(index);
        return _decodeSaplingPaymentAddressHex(derived);
      },
    );
    await _shieldSyncEngine!.storage
        .advanceNextDiversifierIndexAtLeast(nextIndex);
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
      final decoded =
          const Bech32Codec().decode(encodedAddress, encodedAddress.length);
      final expectedHrp = network == PivxNetwork.testnet
          ? PivxSaplingNetwork.testnetPaymentAddressHrp
          : PivxSaplingNetwork.mainnetPaymentAddressHrp;
      if (decoded.hrp != expectedHrp) {
        return null;
      }

      final bytes = _convertBits(decoded.data, 5, 8, false);
      if (bytes.length != kSaplingPaymentAddressSize) {
        return null;
      }
      return hex.encode(bytes);
    } catch (_) {
      return null;
    }
  }

  List<int> _convertBits(List<int> data, int inBits, int outBits, bool pad) {
    var value = 0;
    var bits = 0;
    final maxV = (1 << outBits) - 1;
    final result = <int>[];

    for (final dataValue in data) {
      if (dataValue < 0 || dataValue >> inBits != 0) {
        throw ArgumentError('Invalid Bech32 data value');
      }

      value = (value << inBits) | dataValue;
      bits += inBits;

      while (bits >= outBits) {
        bits -= outBits;
        result.add((value >> bits) & maxV);
      }
    }

    if (pad) {
      if (bits > 0) {
        result.add((value << (outBits - bits)) & maxV);
      }
    } else if (bits >= inBits || ((value << (outBits - bits)) & maxV) != 0) {
      throw ArgumentError('Invalid Bech32 padding');
    }

    return result;
  }

  /// Error message used when reserved (build-time locked) notes are the
  /// reason a shielded spend cannot be funded.
  @visibleForTesting
  static const String shieldedNotesLockedMessage =
      'Insufficient shielded balance: notes are locked by a pending transaction.';

  /// Nullifiers of notes selected by built-but-not-yet-committed shielded
  /// transactions, keyed by pending transaction id.
  ///
  /// In-memory only: a restart drops the pending transaction objects too, so
  /// the reservations must not survive it either.
  final Map<String, Set<String>> _reservedShieldedNotes =
      <String, Set<String>>{};

  /// All nullifiers currently reserved by pending shielded transactions.
  @visibleForTesting
  Set<String> get reservedShieldedNullifiers =>
      _reservedShieldedNotes.values.expand((nullifiers) => nullifiers).toSet();

  /// Reserve the notes selected for pending transaction [txId].
  ///
  /// Throws the standard insufficient-shielded-funds [Exception] when any
  /// nullifier is already reserved by a different pending transaction, so a
  /// second build can never share notes with an uncommitted first build.
  @visibleForTesting
  void reserveShieldedNotes(String txId, Iterable<String> nullifiers) {
    final requested = nullifiers.toSet();
    if (requested.isEmpty) return;
    final reservedByOthers = _reservedShieldedNotes.entries
        .where((entry) => entry.key != txId)
        .expand((entry) => entry.value)
        .toSet();
    if (requested.any(reservedByOthers.contains)) {
      throw Exception(shieldedNotesLockedMessage);
    }
    _reservedShieldedNotes[txId] = requested;
  }

  /// Release the note reservation held by pending transaction [txId].
  /// Idempotent: releasing an unknown or already released id is a no-op.
  @visibleForTesting
  void releaseReservedShieldedNotes(String txId) {
    _reservedShieldedNotes.remove(txId);
  }

  /// Fail fast with [shieldedNotesLockedMessage] when reserved notes are what
  /// makes [amount] unreachable, or when a spend-all would have to consume a
  /// reserved note. When the balance is insufficient regardless of
  /// reservations this returns normally so the builder reports its usual
  /// insufficient-balance error.
  @visibleForTesting
  static void ensureShieldedNotesNotLocked({
    required Map<String, int> spendableNoteValuesByNullifier,
    required Set<String> reservedNullifiers,
    required int amount,
    required bool spendAll,
  }) {
    if (reservedNullifiers.isEmpty) return;
    var total = 0;
    var unreservedTotal = 0;
    var anyReservedSpendable = false;
    spendableNoteValuesByNullifier.forEach((nullifier, value) {
      total += value;
      if (reservedNullifiers.contains(nullifier)) {
        anyReservedSpendable = true;
      } else {
        unreservedTotal += value;
      }
    });
    if (!anyReservedSpendable) return;
    if (spendAll || (unreservedTotal < amount && total >= amount)) {
      throw Exception(shieldedNotesLockedMessage);
    }
  }

  /// Drop reservations whose notes have all left the unspent set (terminally
  /// spent or pending-spent via a committed transaction or sync). Storage
  /// already excludes those notes from selection, so the stale reservation
  /// would only lock a rebuilt spend out of its funds.
  void _pruneStaleShieldedNoteReservations() {
    if (_reservedShieldedNotes.isEmpty) return;
    final unspentNullifiers = <String>{};
    for (final note in _shieldSyncEngine!.storage.unspentNotes) {
      final nullifier = note.nullifier;
      if (nullifier != null) unspentNullifiers.add(nullifier);
    }
    _reservedShieldedNotes.removeWhere(
        (_, nullifiers) => !nullifiers.any(unspentNullifiers.contains));
  }

  /// Build a signed shielded transaction. [amount] in zatoshis; [memo] up to
  /// 512 bytes, shielded outputs only.
  Future<SaplingTransactionResult> createShieldedTransaction({
    required String toAddress,
    required int amount,
    String? memo,
    bool useShieldedInputs = true,
    bool spendAllShieldedInputs = false,
  }) async {
    await _ensureShieldSyncEngineInitialized();
    await _ensureSaplingRpcSupportsShieldedSend();

    // Lock: concurrent builds could select the same notes (double-spend) or
    // read inconsistent balance state.
    return await _balanceLock.synchronized(() async {
      _pruneStaleShieldedNoteReservations();
      ensureShieldedNotesNotLocked(
        spendableNoteValuesByNullifier: {
          for (final note in _shieldSyncEngine!.storage.spendableNotesAt(
            chainHeight: _shieldSyncEngine!.storage.lastSyncedHeight,
          ))
            if (note.nullifier != null) note.nullifier!: note.value,
        },
        reservedNullifiers: reservedShieldedNullifiers,
        amount: amount,
        spendAll: spendAllShieldedInputs,
      );

      if (_saplingTxBuilder == null) {
        _saplingTxBuilder = await SaplingTransactionBuilderFactory.create(
          keyManager: _saplingKeyManager!,
          syncEngine: _shieldSyncEngine!,
          isTestnet: network == PivxNetwork.testnet,
        );
      }

      await _ensureProvingParamsLoaded();

      final options = SaplingTransactionOptions(
        toAddress: toAddress,
        amount: amount,
        memo: memo,
        useShieldedInputs: useShieldedInputs,
        spendAllShieldedInputs: spendAllShieldedInputs,
      );

      // exclude notes reserved by an in-flight build so a concurrent send picks
      // different notes instead of overlapping and failing after the proof.
      final result = await _saplingTxBuilder!.buildTransaction(
        options: options,
        reservedNullifiers: reservedShieldedNullifiers,
      );
      reserveShieldedNotes(result.txId, result.spentNullifiers);
      return result;
    });
  }

  /// Shield transparent funds into the shielded pool. [amount] in zatoshis,
  /// null shields all available.
  Future<SaplingTransactionResult> shieldFunds({int? amount}) async {
    await initializeSapling();
    final destination = (await _saplingKeyManager!.getDefaultAddress()).encoded;
    final built = await _buildShieldTransactionResult(
      toAddress: destination,
      requestedAmount: amount,
      isSendAll: amount == null,
    );
    return built.result;
  }

  /// Build a t-to-z (shield) transaction spending transparent P2PKH UTXOs
  /// into a Sapling output, with transparent change.
  Future<_BuiltShieldTransaction> _buildShieldTransactionResult({
    required String toAddress,
    int? requestedAmount,
    required bool isSendAll,
    String? memo,
  }) async {
    await initializeSapling();
    await _ensureShieldSyncEngineInitialized();

    // Confirmed, spendable, standard P2PKH transparent UTXOs only.
    final available = unspentCoins
        .where((utx) =>
            utx.isSending &&
            !utx.isFrozen &&
            (utx.confirmations ?? 0) > 0 &&
            PivxNetwork.p2pkhScriptPubKeyHex(utx.bitcoinAddressRecord.address)
                .isNotEmpty)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
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
        plan = SaplingTransactionBuilderWrapper.planShieldSpend(
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
      final scriptPubKey = PivxNetwork.p2pkhScriptPubKeyHex(record.address);
      return <String, dynamic>{
        'txid': utx.hash,
        'vout': utx.vout,
        'value': utx.value,
        'script_pubkey': scriptPubKey,
        'private_key': privateKey,
      };
    }).toList(growable: false);

    // shield change is transparent leftover, needs a base58 addr.
    // walletAddresses.address can be the selected ps1 shielded addr, which fails
    // base58 decode in rust, so pull a real transparent change addr.
    final changeAddress = plan.change > 0
        ? (await walletAddresses.getChangeAddress()).address
        : null;

    final result = await _balanceLock.synchronized(() async {
      _saplingTxBuilder ??= await SaplingTransactionBuilderFactory.create(
        keyManager: _saplingKeyManager!,
        syncEngine: _shieldSyncEngine!,
        isTestnet: network == PivxNetwork.testnet,
      );
      await _ensureProvingParamsLoaded();
      return await _saplingTxBuilder!.buildShieldTransaction(
        utxos: utxoMaps,
        toAddress: toAddress,
        amount: amount,
        memo: memo,
        fee: plan.fee,
        changeAddress: changeAddress,
        change: plan.change,
      );
    });

    return _BuiltShieldTransaction(
      result: result,
      amount: amount,
      fee: result.fee,
    );
  }

  /// Derive the transparent signing key for [record], verifying the derived
  /// address matches record.address first. The shield builder hands raw keys to
  /// Rust, which fails closed on a mismatch ("UTXO private key does not match the
  /// script public key hash"). Try the record's branch/derivation (per-type HD
  /// map, then legacy, then opposite branch for stale metadata), verify, and
  /// throw if no key reproduces the address rather than emit one that can't sign.
  String _transparentSigningKeyHexFor(BaseBitcoinAddressRecord record) {
    final candidates = <Bip32Slip10Secp256k1>[
      record.isHidden
          ? (sideHdByType[record.type] ?? sideHd)
          : (mainHdByType[record.type] ?? mainHd),
      record.isHidden ? sideHd : mainHd,
      record.isHidden
          ? (mainHdByType[record.type] ?? mainHd)
          : (sideHdByType[record.type] ?? sideHd),
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

  /// Deshield funds into the transparent pool. [amount] in zatoshis;
  /// [toAddress] defaults to own address.
  Future<SaplingTransactionResult> deshieldFunds({
    required int amount,
    String? toAddress,
  }) async {
    final destination = toAddress ?? walletAddresses.address;
    if (_isShieldedAddress(destination)) {
      throw Exception('Deshield destination must be a transparent address.');
    }
    return await createShieldedTransaction(
      toAddress: destination,
      amount: amount,
      useShieldedInputs: true,
    );
  }

  /// Download and load Sapling proving params (~51MB, needed for Groth16
  /// proofs).
  Future<void> _ensureProvingParamsLoaded() async {
    if (_saplingTxBuilder == null) {
      throw StateError('Transaction builder not initialized');
    }

    if (_saplingTxBuilder!.hasProvingParams) {
      return;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final provingParamsPath = '${appDir.path}/pivx_sapling_params';

    // Provision params: prefer the bundled asset (instant), fall back to the
    // network download only for builds compiled without the bundle.
    if (!await _saplingTxBuilder!.hasLocalProvingParams(provingParamsPath)) {
      final fromBundle = await _saplingTxBuilder!
          .copyProvingParamsFromBundle(provingParamsPath);
      if (fromBundle) {
        printV('PIVX Sapling proving parameters provisioned from app bundle.');
      } else {
        printV('Downloading PIVX Sapling proving parameters (~51MB)...');
        await _saplingTxBuilder!.downloadProvingParams(
          path: provingParamsPath,
          onProgress: (progress) {
            printV(
                'Proving params download: ${(progress * 100).toStringAsFixed(1)}%');
          },
        );
        printV('Proving parameters downloaded successfully.');
      }
    }

    printV('Loading PIVX Sapling proving parameters...');
    await _saplingTxBuilder!.loadProvingParams(path: provingParamsPath);
    printV('Proving parameters loaded successfully.');
  }

  bool isValidShieldedAddress(String address) {
    final isTestnet = network == PivxNetwork.testnet;
    if (isTestnet) {
      return address.startsWith(PivxSaplingNetwork.testnetPaymentAddressHrp);
    }
    return address.startsWith(PivxSaplingNetwork.mainnetPaymentAddressHrp);
  }

  /// PIVX has no SegWit/MWEB; skip those checks and use custom scripthash.
  @override
  Future<ElectrumBalance> fetchBalances() async {
    final addresses = walletAddresses.allAddresses
        .where((address) => address.address.isNotEmpty)
        .toList();

    final balanceFutures = <Future<Map<String, dynamic>>>[];
    final validAddresses = <BaseBitcoinAddressRecord>[];
    final seenScriptHashes = <String>{};

    for (var i = 0; i < addresses.length; i++) {
      final addressRecord = addresses[i];
      // custom scripthash avoids SegWit exceptions
      final sh = PivxNetwork.computeScriptHash(addressRecord.address);
      if (sh.isEmpty) continue;
      // Count each on-chain address once. allAddresses is a plain list that can
      // briefly hold the same address under more than one record during
      // discovery (a later addAddresses de-dups via toSet, which is why the
      // doubling self-heals). Summing a scripthash twice doubles the transparent
      // balance in that window.
      if (!seenScriptHashes.add(sh)) continue;
      validAddresses.add(addressRecord);
      final balanceFuture = electrumClient.getBalance(sh);
      balanceFutures.add(balanceFuture);
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

    final balances = await Future.wait(balanceFutures);

    // getBalance swallows a per-scripthash error and returns {}, so one transient
    // miss looks identical to "malformed". a restored wallet queries many
    // addresses against a flaky server, so one failure must not zero the whole
    // balance. sum the good responses, keep last-known for failed ones, and treat
    // only a full wipeout (every query failed) as a lost connection.
    var failedCount = 0;
    for (var i = 0; i < balances.length; i++) {
      final balance = balances[i];
      final addressRecord =
          i < validAddresses.length ? validAddresses[i] : null;
      final hasKeys =
          balance['confirmed'] != null && balance['unconfirmed'] != null;

      if (!hasKeys) {
        failedCount++;
        // ponytail: last-known so a transient miss flickers, never zeros.
        totalConfirmed += addressRecord?.balance ?? 0;
        continue;
      }

      final confirmed = balance['confirmed'] as int? ?? 0;
      final unconfirmed = balance['unconfirmed'] as int? ?? 0;
      totalConfirmed += confirmed;
      totalUnconfirmed += unconfirmed;

      if (addressRecord != null) {
        addressRecord.balance = confirmed + unconfirmed;
        if (confirmed > 0 || unconfirmed > 0) {
          addressRecord.setAsUsed();
        }
      }
    }

    if (balances.isNotEmpty && failedCount == balances.length) {
      printV('[PIVX] All transparent balance queries failed; connection lost');
      syncStatus = core_sync.LostConnectionSyncStatus();
      final previousBalance = balance[currency];

      return ElectrumBalance(
        confirmed: previousBalance?.confirmed ?? _zeroPivxMoney,
        unconfirmed: previousBalance?.unconfirmed ?? _zeroPivxMoney,
        frozen: previousBalance?.frozen ?? _zeroPivxMoney,
        secondConfirmed: _pivxMoney(shieldedBalance),
        secondUnconfirmed: _pivxMoney(_displayPendingShielded),
      );
    }

    // Primary balance is transparent; shielded is carried as the secondary.
    return ElectrumBalance(
      confirmed: _pivxMoney(totalConfirmed),
      unconfirmed: _pivxMoney(totalUnconfirmed),
      frozen: _pivxMoney(totalFrozen),
      secondConfirmed: _pivxMoney(shieldedBalance),
      secondUnconfirmed: _pivxMoney(_displayPendingShielded),
    );
  }

  /// Custom scripthash health check; PIVX has no SegWit.
  @override
  Future<bool> checkNodeHealth() async {
    try {
      final addresses = walletAddresses.allAddresses
          .where((address) => address.address.isNotEmpty)
          .toList();

      if (addresses.isEmpty) {
        return false;
      }

      final firstAddress = addresses.first;
      final sh = PivxNetwork.computeScriptHash(firstAddress.address);
      if (sh.isEmpty) return false;

      await electrumClient.getBalance(sh, throwOnError: true);
      if (saplingEnabled) {
        await _ensureSaplingRpcSupportsShieldedSync();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // Force the per-address unspent path so fetchUnspent's height-based
  // confirmations are used. The batch path derives confirmations from
  // fetchTransactionInfoBatch -> BtcTransaction.fromRaw, which can't parse a
  // Sapling funding tx and returns null, dropping a valid transparent coin
  // received from a shielded tx as unspendable. pivx history and balance use
  // their own paths, so this only affects UTXO fetching.
  @override
  bool get shouldUseBatchFetching => false;

  /// Uses custom PIVX scripthash.
  @override
  Future<List<BitcoinUnspent>?> fetchUnspent(
      BitcoinAddressRecord address) async {
    List<BitcoinUnspent> updatedUnspentCoins = [];

    final sh = PivxNetwork.computeScriptHash(address.address);
    if (sh.isEmpty) return [];

    final unspents = await electrumClient.getListUnspent(sh);
    if (unspents == null) return null;

    final tip = await getCurrentChainTip();
    await Future.wait(unspents.map((unspent) async {
      try {
        final coin = BitcoinUnspent.fromJSON(address, unspent);
        coin.isChange = address.isHidden;
        // confirmations from the UTXO's own height in listunspent. the tx-info
        // path uses BtcTransaction.fromRaw, which can't parse a Sapling funding
        // tx and returns null, so a transparent coin received from a shielded tx
        // (z->t or shield change) got null confirmations and was dropped as
        // unspendable.
        // a UTXO with a block height is confirmed even if our cached tip is
        // stale (tip < height right after a new block). clamp to 1 there so it
        // stays spendable instead of getting dropped by the confirmed filter.
        final height = unspent['height'] as int?;
        coin.confirmations = (height != null && height > 0)
            ? (tip >= height ? tip - height + 1 : 1)
            : 0;
        updatedUnspentCoins.add(coin);
      } catch (_) {}
    }));

    return updatedUnspentCoins;
  }

  /// Custom scripthash: parent's getScriptHash(network) fails for PIVX.
  @override
  Future<void> fetchTransactionsForAddressType(
    Map<String, ElectrumTransactionInfo> historiesWithDetails,
    BitcoinAddressType type,
  ) async {
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

      if (history.isNotEmpty) {
        addressRecord.txCount = history.length;
        historiesWithDetails.addAll(history);

        final matchedAddresses =
            addressRecord.isHidden ? hiddenAddresses : receiveAddresses;
        final isUsedAddressUnderGap = matchedAddresses
                .toList()
                .indexOf(addressRecord) >=
            matchedAddresses.length -
                (addressRecord.isHidden
                    ? ElectrumWalletAddressesBase.defaultChangeAddressesCount
                    : ElectrumWalletAddressesBase.defaultReceiveAddressesCount);

        if (isUsedAddressUnderGap) {
          final prevLength = walletAddresses.allAddresses.length;

          // discover addresses until the gap limit is met
          await walletAddresses.discoverAddresses(
            matchedAddresses.toList(),
            addressRecord.isHidden,
            (address) async {
              await subscribeForUpdates();
              return _fetchPivxAddressHistory(
                      address, await getCurrentChainTip())
                  .then(
                      (history) => history.isNotEmpty ? address.address : null);
            },
            type: type,
            isLegacyDerivation: false,
          );

          final newLength = walletAddresses.allAddresses.length;

          if (newLength > prevLength) {
            await fetchTransactionsForAddressType(historiesWithDetails, type);
          }
        }
      }
    }));
  }

  /// Fetch address history with PIVX scripthash.
  Future<Map<String, ElectrumTransactionInfo>> _fetchPivxAddressHistory(
      BitcoinAddressRecord addressRecord, int? currentHeight) async {
    try {
      final Map<String, ElectrumTransactionInfo> historiesWithDetails = {};

      final sh = PivxNetwork.computeScriptHash(addressRecord.address);
      if (sh.isEmpty) return {};

      final history = await electrumClient.getHistory(sh);

      if (history.isNotEmpty) {
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
                // the tx's block itself is the first confirmation so add 1
                if ((currentHeight ?? 0) > 0) {
                  storedTx.confirmations = currentHeight! - height + 1;
                }
                storedTx.isPending = storedTx.confirmations == 0;
              }

              historiesWithDetails[txHash] = storedTx;
            } else {
              final tx = await fetchTransactionInfo(
                  hash: txHash, height: height, retryOnFailure: true);
              // z->t receives carry Sapling data that BtcTransaction.fromRaw
              // rejects, so fetchTransactionInfo returns null and the receive is
              // dropped from history while the balance still credits it. rebuild
              // it from the node's decoded verbose JSON instead.
              final entry = tx ??
                  await _buildPivxIncomingFromVerbose(
                      txHash, height, currentHeight);

              if (entry != null) {
                historiesWithDetails[txHash] = entry;
                transactionHistory.addOne(entry);
                await transactionHistory.save();
              }
            }
          } catch (e) {
            // one unparseable tx (e.g. an OP_RETURN note output) must not drop
            // the whole address's history. skip it, keep the rest, log for diag.
            printV('PIVX: skipped tx $txHash in address history: $e');
          }

          return Future.value(null);
        }));
      }

      return historiesWithDetails;
    } catch (e) {
      printV('PIVX: Error fetching transparent address history');
      return {};
    }
  }

  /// Build an incoming history entry from the node's verbose tx JSON when the
  /// raw parser can't deserialize the tx (Sapling-bearing z->t receives).
  /// Sums outputs paying our receive (non-change) addresses; returns null when
  /// none pay us, so our own change / sends never register as a false incoming.
  Future<ElectrumTransactionInfo?> _buildPivxIncomingFromVerbose(
      String txHash, int height, int? currentHeight) async {
    try {
      // our own z->t send spends our shielded notes; the shielded side records
      // that outgoing, so don't also log a transparent incoming for it.
      final shieldedStorage = _shieldSyncEngine?.storage;
      if (shieldedStorage != null &&
          shieldedStorage.notes.any((n) =>
              n.spendingTxid == txHash || n.pendingSpendingTxid == txHash)) {
        return null;
      }

      final verbose = await electrumClient.getTransactionVerbose(hash: txHash);
      if (verbose.isEmpty) return null;
      final vout = verbose['vout'];
      if (vout is! List) return null;

      final receiveAddresses = walletAddresses.allAddresses
          .where((a) => !a.isHidden)
          .map((a) => a.address)
          .toSet();

      int received = 0;
      for (final out in vout) {
        if (out is! Map) continue;
        final spk = out['scriptPubKey'];
        if (spk is! Map) continue;
        final outAddresses = <String>{};
        final list = spk['addresses'];
        if (list is List) outAddresses.addAll(list.map((e) => e.toString()));
        final single = spk['address'];
        if (single != null) outAddresses.add(single.toString());
        if (outAddresses.any(receiveAddresses.contains)) {
          received += stringDoubleToBitcoinAmount((out['value'] ?? 0).toString());
        }
      }
      if (received <= 0) return null;

      final confirmations =
          (currentHeight != null && height > 0 && currentHeight >= height)
              ? currentHeight - height + 1
              : 0;
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

  /// PIVX transparent dust threshold based on PIVX Core dustRelayFee
  /// of 30,000 zatoshis/kB and a typical 182-byte output spend cost.
  @override
  BigInt get networkDustAmount =>
      BigInt.from(PivxFeePolicy.transparentDustThreshold);

  /// Estimate tx size: ~148 B/input, ~34 B/output, ~10 B overhead.
  static int estimatedPivxTransactionSize(int inputsCount, int outputsCounts) =>
      PivxFeePolicy.transparentTxSize(inputsCount, outputsCounts);

  @override
  int feeRate(TransactionPriority priority) {
    // PIVX ElectrumX servers don't serve blockchain.estimatefee, so the base
    // rate resolves to 0 and every transparent send builds a zero-fee tx that
    // the network rejects. Use PIVX's fixed min-relay-based rate instead.
    if (priority is PivxTransactionPriority) {
      return priority.feeRate;
    }
    return PivxFeePolicy.minRelayFeePerKb;
  }

  @override
  int feeAmountForPriority(
    TransactionPriority priority,
    int inputsCount,
    int outputsCount, {
    int? size,
  }) =>
      feeRate(priority) *
      (size ?? estimatedPivxTransactionSize(inputsCount, outputsCount)) ~/
      1000;

  @override
  int feeAmountWithFeeRate(int feeRate, int inputsCount, int outputsCount,
          {int? size}) =>
      feeRate *
      (size ?? estimatedPivxTransactionSize(inputsCount, outputsCount)) ~/
      1000;

  static Future<PivxWallet> create({
    required String mnemonic,
    required String password,
    required WalletInfo walletInfo,
    required DerivationInfo derivationInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required EncryptionFileUtils encryptionFileUtils,
    bool isTestnet = false,
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
      pivxNetwork: isTestnet ? PivxNetwork.testnet : PivxNetwork.mainnet,
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
    bool? isTestnet,
  }) async {
    final pivxNetwork = (isTestnet ?? walletInfo.network == 'testnet')
        ? PivxNetwork.testnet
        : PivxNetwork.mainnet;

    final hasKeysFile = await WalletKeysFile.hasKeysFile(name, walletInfo.type);

    ElectrumWalletSnapshot? snp = null;

    try {
      snp = await ElectrumWalletSnapshot.load(
        encryptionFileUtils,
        name,
        walletInfo.type,
        password,
        pivxNetwork,
      );
    } catch (e) {
      if (!hasKeysFile) rethrow;
    }

    final WalletKeysData keysData;
    // Migrate old-scheme wallets to the .keys file scheme.
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
      pivxNetwork: pivxNetwork,
      initialRegularAddressIndex: snp?.regularAddressIndex,
      initialChangeAddressIndex: snp?.changeAddressIndex,
      addressPageType: P2pkhAddressType.p2pkh,
      passphrase: keysData.passphrase,
    );
  }

  @override
  Future<String> signMessage(String message, {String? address = null}) async {
    int? index;
    try {
      index = address != null
          ? walletAddresses.allAddresses
              .firstWhere((element) => element.address == address)
              .index
          : null;
    } catch (_) {}
    final HD = index == null ? mainHd : mainHd.childKey(Bip32KeyIndex(index));
    final priv = ECPrivate.fromWif(
      WifEncoder.encode(HD.privateKey.raw, netVer: network.wifNetVer),
      netVersion: network.wifNetVer,
    );
    return priv.signMessage(StringUtils.encode(message));
  }

  /// Shielded (Sapling) addresses start with 'ps1' (mainnet) or
  /// 'ptestsapling1' (testnet).
  bool _isShieldedAddress(String address) {
    final addr = address.toLowerCase().trim();
    return addr.startsWith('ps1') || addr.startsWith('ptestsapling1');
  }

  /// Routes to the Sapling builder when the destination is shielded (ps1...),
  /// otherwise the standard transparent path.
  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    final transactionCredentials = credentials as BitcoinTransactionCredentials;
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
          'PIVX mixed transparent and shielded outputs are not supported yet.');
    }

    if (spendFromShielded && hasTransparentOutput) {
      // z-to-t (deshield): spend shielded notes into a transparent payment
      // output with shielded change, built by the Sapling builder.
      return await _createShieldedPendingTransaction(transactionCredentials);
    }

    if (hasShieldedOutput) {
      var source = transactionCredentials.coinTypeToSpendFrom;
      final autoSelected = source == UnspentCoinType.any;
      if (autoSelected) {
        // No explicit source picked: match the shielded destination
        // privacy-first: spend shielded notes (z-to-z) when they cover the
        // send, otherwise shield transparent funds (t-to-z).
        final out = transactionCredentials.outputs.first;
        final needed = out.sendAll ? 1 : (out.cryptoAmount.amount.toInt());
        source = shieldedBalance >= needed
            ? UnspentCoinType.sapling
            : UnspentCoinType.transparent;
      }

      // shieldedBalance >= needed ignores the sapling fee, so an exact-balance
      // z-to-z can't cover it. when we auto-picked shielded, fall back to
      // shielding transparent funds (t-to-z) instead of failing the send. an
      // explicit shielded source is respected and surfaces the error.
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

    // all-transparent send: no shielded output to carry a memo. the memo field
    // shows for pivx globally, so strip any entered memo here or it leaks
    // on-chain as a public OP_RETURN on the transparent tx.
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
      return await super.createTransaction(stripped);
    }
    return await super.createTransaction(credentials);
  }

  /// Pending shielded transaction built by the Sapling builder (z-to-z, z-to-t
  /// deshield, or t-to-z shield).
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
    // only a shielded destination carries a memo; drop a stale one for a
    // transparent recipient so the build doesn't reject it.
    final memo = transparentDestination ? null : output.memo;

    final coinType = sourceOverride ?? credentials.coinTypeToSpendFrom;
    if (coinType != UnspentCoinType.sapling) {
      // t-to-z (shield): spend transparent UTXOs into the Sapling output.
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
        fee: built.fee,
        onCommit: (tx) async {
          // record the shield as an outgoing "Sent" so the transparent change
          // isn't shown as a received utxo. nothing else records this send, so
          // without it the change utxo reads as an incoming payment.
          try {
            await _recordPendingShieldedOutgoing(
              txid: built.result.txId,
              amount: built.amount,
              fee: built.fee,
              toAddress: toAddress,
              route: 't-to-z',
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

    await initializeSapling();
    await _ensureShieldSyncEngineInitialized();

    final amount = isSendAll
        ? _shieldedSendAllAmount(transparentDestination: transparentDestination)
        : output.cryptoAmount.amount.toInt();

    final hasShieldedFunds = shieldedBalance >= amount;

    if (hasShieldedFunds) {
      final result = await createShieldedTransaction(
        toAddress: toAddress,
        amount: amount,
        memo: memo,
        useShieldedInputs: true,
        spendAllShieldedInputs: isSendAll,
      );

      return PendingPivxShieldedTransaction(
        result: result,
        electrumClient: electrumClient,
        amount: amount,
        fee: result.fee,
        onBroadcastFailure: () => releaseReservedShieldedNotes(result.txId),
        onCommit: (tx) async {
          try {
            await _recordPendingShieldedOutgoing(
              txid: result.txId,
              amount: amount,
              fee: result.fee,
              toAddress: toAddress,
              route: transparentDestination ? 'z-to-t' : 'z-to-z',
            );

            if (result.spentNullifiers.isNotEmpty) {
              await _shieldSyncEngine!.storage.markPendingSpentByNullifiers(
                result.spentNullifiers,
                result.txId,
              );
              await _reconcileShieldedBalance();
            } else {
              await updateBalance();
            }
          } finally {
            // The broadcast already succeeded, so the build-time reservation has
            // done its job and must be dropped even if the bookkeeping above
            // threw, otherwise the notes stay locked for the session. The next
            // sync reconciles authoritative on-chain spend state.
            releaseReservedShieldedNotes(result.txId);
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

    throw Exception('Insufficient shielded balance.');
  }

  int _shieldedSendAllAmount({bool transparentDestination = false}) {
    final notes = _shieldSyncEngine!.storage.spendableNotesAt(
      chainHeight: _shieldSyncEngine!.storage.lastSyncedHeight,
    );
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

  /// PIVX coinstake detection (primitives/transaction.cpp): non-empty vin,
  /// first vin has a prevout, first vout empty, >=2 outputs. Coinstake outputs
  /// have different maturity rules, so this matters for balance.
  static bool isCoinstakeTransaction(Map<String, dynamic> tx) {
    final vins = tx['vin'] as List?;
    final vouts = tx['vout'] as List?;

    if (vins == null || vins.isEmpty) return false;
    if (vouts == null || vouts.length < 2) return false;

    final firstVin = vins.first as Map<String, dynamic>?;
    if (firstVin == null) return false;
    final txid = firstVin['txid'];
    if (txid == null || txid == '') return false;

    final firstVout = vouts.first as Map<String, dynamic>?;
    if (firstVout == null) return false;
    final value = firstVout['value'];
    if (value != 0 && value != 0.0) return false;

    return true;
  }

  /// Coinbase detection: single vin with a null prevout.
  static bool isCoinbaseTransaction(Map<String, dynamic> tx) {
    final vins = tx['vin'] as List?;
    if (vins == null || vins.length != 1) return false;

    final firstVin = vins.first as Map<String, dynamic>?;
    if (firstVin == null) return false;

    final coinbase = firstVin['coinbase'];
    return coinbase != null;
  }
}

/// Built t-to-z shield transaction with its planned amount and fee.
class _BuiltShieldTransaction {
  _BuiltShieldTransaction({
    required this.result,
    required this.amount,
    required this.fee,
  });

  final SaplingTransactionResult result;
  final int amount;
  final int fee;
}
