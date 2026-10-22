import "dart:async";

import "package:bitcoin_base/bitcoin_base.dart";

import "package:cw_bitcoin/electrum_transaction_info.dart";
import "package:cw_bitcoin/electrum_transaction_isolate.dart";
import "package:cw_bitcoin/electrum_wallet.dart";
import "package:cw_bitcoin/input_ownership.dart";
import "package:cw_core/get_height_by_date.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:flutter/foundation.dart";
import "package:mobx/mobx.dart";

/// Resolves fee/ownership/direction details for transactions that the
/// initial sync (see [ElectrumWalletBase.getTransactionExpanded]) left
/// unresolved, via a single background resolution pass (newest-first) that
/// every sync cycle restarts (see [resolvePending]).
///
/// One instance per wallet, created once in [ElectrumWalletBase]'s
/// constructor.
class ElectrumTransactionResolver {
  ElectrumTransactionResolver(this._wallet);

  final ElectrumWalletBase _wallet;

  /// In-memory-only cache of raw tx hex keyed by txid, used solely
  /// to avoid re-fetching a parent (prevout) transaction more than once.
  /// Temporary: once a transaction's fee/ownership is resolved, nothing
  /// ever needs its inputs' raw hex again, so keeping it around on disk
  /// would only grow the wallet file forever for no benefit.
  final Map<String, String> _rawTxHexCache = {};

  String? cachedRawTxHex(String txid) => _rawTxHexCache[txid];

  void cacheRawTxHex(String txid, String hex) {
    if (hex.isNotEmpty) {
      _rawTxHexCache[txid] = hex;
    }
  }

  void cacheVerboseHexes(Map<String, Map<String, dynamic>> verboseByHash) {
    for (final entry in verboseByHash.entries) {
      final hex = entry.value["hex"] as String?;
      if (hex != null) {
        cacheRawTxHex(entry.key, hex);
      }
    }
  }

  // transactionHistory.save() re-serializes and encrypts the *entire*
  // history synchronously, regardless of how much changed.
  // _lastHistorySaveAt throttles actual disk writes to once per interval; `force` bypasses this.
  DateTime? _lastHistorySaveAt;
  static const _historySaveInterval = Duration(seconds: 3);

  Future<void> _maybePersistHistory({bool force = false}) async {
    final now = DateTime.now();
    final timeSinceLastSave =
        _lastHistorySaveAt == null ? null : now.difference(_lastHistorySaveAt!);
    final readyToSave = timeSinceLastSave == null || timeSinceLastSave >= _historySaveInterval;

    if (force || readyToSave) {
      _lastHistorySaveAt = now;
      await _wallet.transactionHistory.save();
    }
  }

  bool _isResolvingTransactions = false;
  // Set when resolvePending is called mid-run: that run's queue was built
  // before the new txs landed in history, so another run must pick them up.
  bool _isRerunRequested = false;
  // Txs the user has open, served ahead of the background queue.
  final Set<String> _prioritizedTxIds = {};

  /// Progress of each prioritized tx.
  final ObservableMap<String, TransactionResolutionProgress> resolutionProgress = ObservableMap();

  /// Parents already parsed for a background tx that paused mid-resolution
  final Map<String, Map<String, BtcTransaction>> _parsedParentsOfPausedTransaction = {};

  /// Attempts spent so far per prioritized txid, and the earliest time its
  /// next attempt may start. A tx stays prioritized until it's actually
  /// resolved or [_maxPriorityAttempts].
  final Map<String, int> _priorityAttempts = {};
  final Map<String, DateTime> _priorityRetryNotBefore = {};
  static const int _maxPriorityAttempts = 5;
  static const Duration _priorityRetryBaseDelay = Duration(seconds: 1);
  static const Duration _priorityRetryMaxDelay = Duration(seconds: 4);

  // Completed by [prioritize] to cut short the loop's idle wait between
  // retries when a newly prioritized tx arrives.
  Completer<void>? _wake;

  // Set by stop() (see ElectrumWalletBase.close) so a run in progress stops
  // immediately.
  bool _stopped = false;

  void stop() {
    _stopped = true;
  }

  /// Input-resolution chunk size for [_resolveTransactionDetails].
  /// a transaction can have hundreds of inputs, allows for
  /// [resolutionProgress] to move in steps.
  static const int _resolutionInputChunkSize = 25;

  /// Base timeout for the network calls in [_resolveTransactionDetails]
  /// does not allow for a slow/unfetchable chunk of inputs to fail or
  /// stall visible progress.
  static const int _resolutionBatchTimeoutMs = 6 * 1000;

  /// Max timeout for a whole transaction's resolution.
  static const int _maxResolutionBatchTimeoutMs = 48 * 1000;

  /// Consecutive resolution failures per txid.
  final Map<String, int> _consecutiveFailures = {};

  /// Doubles the base timeout per consecutive failure for [txId], capped at
  /// [_maxResolutionBatchTimeoutMs].
  int _timeoutMsFor(String txId) {
    final failures = (_consecutiveFailures[txId] ?? 0).clamp(0, 3);
    final scaled = _resolutionBatchTimeoutMs * (1 << failures);
    return scaled > _maxResolutionBatchTimeoutMs ? _maxResolutionBatchTimeoutMs : scaled;
  }

  /// Serves [txId] ahead of the background queue - for the transaction the
  /// user has open - and reports its progress in [resolutionProgress]. Does
  /// nothing if it's already resolved.
  ///
  /// Failed attempts are retried with backoff; once [_maxPriorityAttempts]
  /// have failed its progress is marked failed, and calling this again
  /// starts over.
  void prioritize(String txId) {
    final existingTxInfo = _wallet.transactionHistory.transactions[txId];
    if (existingTxInfo != null && !existingTxInfo.needsResolution) {
      return;
    }

    if (_prioritizedTxIds.add(txId)) {
      final previous = resolutionProgress[txId];
      resolutionProgress[txId] = TransactionResolutionProgress(
        resolvedInputs: previous?.resolvedInputs ?? 0,
        totalInputs: previous?.totalInputs ?? 0,
      );
    }

    final wake = _wake;
    if (wake != null && !wake.isCompleted) {
      wake.complete();
    }

    // Ensures the background loop is actually running (e.g. it may have
    // drained its last pending queue and gone idle since the last sync).
    _ensureResolutionLoopRunning();
  }

  void _reportProgress(String txId, int resolvedInputs, int totalInputs) {
    if (_prioritizedTxIds.contains(txId)) {
      resolutionProgress[txId] = TransactionResolutionProgress(
        resolvedInputs: resolvedInputs,
        totalInputs: totalInputs,
      );
    }
  }

  void _ensureResolutionLoopRunning() {
    if (_stopped || _isResolvingTransactions) {
      return;
    }

    _isResolvingTransactions = true;

    unawaited(
      _runResolutionLoop().whenComplete(() {
        _isResolvingTransactions = false;

        final isRerunRequested = _isRerunRequested;
        _isRerunRequested = false;

        if (_stopped) {
          _clearPrioritized();
        } else if (_prioritizedTxIds.isNotEmpty || isRerunRequested) {
          // A tx was prioritized, or new txs landed, while the loop was
          // winding down.
          _ensureResolutionLoopRunning();
        }
      }),
    );
  }

  /// Processes the pending queue one transaction at a time.
  Future<void> _runResolutionLoop() async {
    // Built once per run and reused, not rebuilt on every pick. Sorted
    // so the top-priority candidate is last.
    List<String>? pendingQueue;

    while (true) {
      if (_stopped) {
        break;
      }

      // Forces a real event-loop tick every iteration so a streak of iterations
      // that never make a network call can't block the UI from staying responsive.
      await Future<void>.delayed(Duration.zero);

      final txId =
          _nextPrioritizedTxId() ?? _nextBackgroundTxId(pendingQueue ??= _buildPendingQueue());
      if (txId == null) {
        if (_prioritizedTxIds.isEmpty) {
          break;
        }

        // Only prioritized txs in retry backoff remain.
        await _waitForRetryOrWake();
        continue;
      }

      try {
        await _resolveTransactionDetails(txId);
      } catch (e, stacktrace) {
        printV("resolution loop: failed for $txId, will retry: $e");
        printV(stacktrace);
      }

      _finishAttempt(txId);
    }

    try {
      await _maybePersistHistory(force: true);
    } catch (e, stacktrace) {
      printV("resolution loop: final history save failed: $e");
      printV(stacktrace);
    }
  }

  /// Whether background resolution of [txId] should pause so a prioritized
  /// tx (one the user has open) doesn't wait behind a large tx's every chunk.
  bool _shouldPauseForOpenedTransaction(String txId) =>
      !_prioritizedTxIds.contains(txId) && _nextPrioritizedTxId() != null;

  /// A prioritized tx whose retry backoff has elapsed, if any.
  String? _nextPrioritizedTxId() {
    final now = DateTime.now();

    for (final txId in _prioritizedTxIds) {
      final notBefore = _priorityRetryNotBefore[txId];

      if (notBefore == null || !notBefore.isAfter(now)) {
        return txId;
      }
    }

    return null;
  }

  String? _nextBackgroundTxId(List<String> pendingQueue) {
    while (pendingQueue.isNotEmpty) {
      final candidate = pendingQueue.removeLast();

      // Prioritized txs are driven by _nextPrioritizedTxId (including their backoff).
      if (_prioritizedTxIds.contains(candidate)) {
        continue;
      }

      final txInfo = _wallet.transactionHistory.transactions[candidate];

      if (txInfo != null && !txInfo.needsResolution) {
        continue;
      }

      return candidate;
    }

    return null;
  }

  /// Sleeps until the earliest prioritized retry is due, or a new tx is
  /// prioritized.
  Future<void> _waitForRetryOrWake() async {
    final now = DateTime.now();
    var delay = _priorityRetryMaxDelay;

    for (final txId in _prioritizedTxIds) {
      final remaining = (_priorityRetryNotBefore[txId] ?? now).difference(now);

      if (remaining < delay) {
        delay = remaining;
      }
    }

    final wake = _wake = Completer<void>();
    await Future.any([Future<void>.delayed(delay.isNegative ? Duration.zero : delay), wake.future]);

    _wake = null;
  }

  /// After an attempt on a prioritized [txId]: stops prioritizing it once
  /// it's resolved or attempts are exhausted, otherwise schedules a retry.
  void _finishAttempt(String txId) {
    if (!_prioritizedTxIds.contains(txId)) {
      return;
    }

    final stored = _wallet.transactionHistory.transactions[txId];
    if (stored != null && !stored.needsResolution) {
      _stopPrioritizing(txId, hasFailed: false);
      return;
    }

    final attempts = (_priorityAttempts[txId] ?? 0) + 1;
    if (attempts >= _maxPriorityAttempts) {
      printV("resolution loop: giving up on $txId after $attempts attempts");
      _stopPrioritizing(txId, hasFailed: true);
      return;
    }

    _priorityAttempts[txId] = attempts;
    final backoff = _priorityRetryBaseDelay * (1 << (attempts - 1));
    _priorityRetryNotBefore[txId] =
        DateTime.now().add(backoff > _priorityRetryMaxDelay ? _priorityRetryMaxDelay : backoff);
  }

  void _stopPrioritizing(String txId, {required bool hasFailed}) {
    _prioritizedTxIds.remove(txId);
    _priorityAttempts.remove(txId);
    _priorityRetryNotBefore.remove(txId);

    final progress = resolutionProgress[txId];
    if (!hasFailed || progress == null) {
      resolutionProgress.remove(txId);
      return;
    }

    resolutionProgress[txId] = TransactionResolutionProgress(
      resolvedInputs: progress.resolvedInputs,
      totalInputs: progress.totalInputs,
      hasFailed: true,
    );
  }

  void _clearPrioritized() {
    _prioritizedTxIds.clear();
    _priorityAttempts.clear();
    _priorityRetryNotBefore.clear();
    resolutionProgress.clear();
  }

  /// Ownership-incomplete transactions in *ascending* priority.
  List<String> _buildPendingQueue() =>
      buildPendingQueue(_wallet.transactionHistory.transactions.values);

  /// Orders txs needing resolution: fully-resolved-inputs first, then oldest
  /// first. Ties on both are broken by id so the order is deterministic.
  @visibleForTesting
  static List<String> buildPendingQueue(Iterable<ElectrumTransactionInfo> transactions) {
    final candidates = transactions.where((tx) => tx.needsResolution).toList()
      ..sort((a, b) {
        if (a.inputsOwnershipFullyResolved != b.inputsOwnershipFullyResolved) {
          return a.inputsOwnershipFullyResolved ? -1 : 1;
        }

        final byDate = a.date.compareTo(b.date);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });

    return candidates.map((tx) => tx.id).toList();
  }

  /// Resolves every input of one transaction, in small batches - each batch
  /// is one round trip, its progress persisted and reported so an
  /// interruption (e.g. [stop]) loses no completed work.
  Future<ElectrumTransactionInfo?> _resolveTransactionDetails(String txId) async {
    final existingTxInfo = _wallet.transactionHistory.transactions[txId];
    if (existingTxInfo != null && !existingTxInfo.needsResolution) {
      return existingTxInfo;
    }

    // A single whole-transaction fetch
    final timeoutMs = _timeoutMsFor(txId);
    final targetVerbose = await _wallet.fetchTransactionVerboseBatch([txId], timeoutMs: timeoutMs);
    cacheVerboseHexes(targetVerbose);
    final targetOriginal = (await parseTransactions(targetVerbose))[txId];
    if (targetOriginal == null) {
      _consecutiveFailures[txId] = (_consecutiveFailures[txId] ?? 0) + 1;
      return existingTxInfo;
    }

    // Height/time/confirmations are properties of the target tx itself, not
    // of how many inputs are resolved yet: compute once and reuse for every
    // partial and final build below.
    final height = existingTxInfo?.height;
    final verbose = targetVerbose[txId] ?? const <String, dynamic>{};
    int? time = verbose["time"] as int?;
    int? confirmations = verbose["confirmations"] as int?;
    if (height != null) {
      if (time == null && height > 0) {
        time = (getDateByBitcoinHeight(height).millisecondsSinceEpoch / 1000).round();
      }
      if (confirmations == null) {
        final tip = await _wallet.getUpdatedChainTip();
        if (tip > 0 && height > 0) {
          confirmations = tip - height + 1;
        }
      }
    }

    final totalInputs = targetOriginal.inputs.length;
    final allInputTxids = targetOriginal.inputs.map((v) => v.txId).toSet();

    final alreadyParsed = _parsedParentsOfPausedTransaction.remove(txId) ?? {};
    final cachedVerbose = <String, Map<String, dynamic>>{};
    final uncachedInputTxids = <String>[];
    for (final t in allInputTxids) {
      if (alreadyParsed.containsKey(t)) {
        continue;
      }

      final cachedHex = cachedRawTxHex(t);
      if (cachedHex != null) {
        cachedVerbose[t] = {"hex": cachedHex};
      } else {
        uncachedInputTxids.add(t);
      }
    }
    final parsedInputTxById = {...alreadyParsed, ...await parseTransactions(cachedVerbose)};

    final walletType = _wallet.walletInfo.type;
    final walletNetwork = _wallet.network;
    final ownAddresses = _wallet.addressesSet;
    final ownAddressesByAccount = _wallet.addressesSetByAccount;

    // Depends only on the tx and the address set, not on which parents are
    // fetched, so it's derived once and reused by every rebuild below. Only
    // a large tx is worth an isolate spawn (hundreds of pubkey address
    // derivations); for an ordinary one the spawn costs more than the work.
    final derived = totalInputs > maxInputsToProcessInline
        ? await deriveTransactionAddressesInIsolate(targetOriginal, ownAddresses, walletNetwork)
        : DerivedTransactionAddresses.derive(targetOriginal, ownAddresses, walletNetwork);

    ElectrumTransactionInfo buildTransactionAndAddToHistory() {
      final ins = targetOriginal.inputs.map((v) => parsedInputTxById[v.txId]).toList();
      final bundle = ElectrumTransactionBundle(
        targetOriginal,
        ins: ins,
        time: time,
        confirmations: confirmations ?? 0,
      );

      final infosByHash = buildElectrumTransactionInfos(
        (
          {txId: bundle},
          walletType,
          walletNetwork,
          ownAddresses,
          ownAddressesByAccount,
          {txId: height}
        ),
        {txId: derived},
      );
      final info = infosByHash[txId];
      if (info == null) {
        throw Exception("fromElectrumBundle failed to build info for txid=$txId");
      }
      info.id = txId;

      if (existingTxInfo != null) {
        info.date = existingTxInfo.date;
        info.isPending = existingTxInfo.isPending;
        info.isReplaced = existingTxInfo.isReplaced ?? false;
        info.to = existingTxInfo.to;
        info.from = existingTxInfo.from;
        info.unspents = existingTxInfo.unspents;
        info.isReceivedSilentPayment = existingTxInfo.isReceivedSilentPayment;
        // Parents may not be resolved yet, so the build can fail to find the
        // owning account; don't drop one found earlier.
        info.accountIndex ??= existingTxInfo.accountIndex;
      }

      _wallet.transactionHistory.addOne(info);
      return info;
    }

    void reportProgress() {
      final resolved =
          targetOriginal.inputs.where((v) => parsedInputTxById.containsKey(v.txId)).length;
      _reportProgress(txId, resolved, totalInputs);
    }

    reportProgress();

    if (uncachedInputTxids.isEmpty) {
      final result = buildTransactionAndAddToHistory();
      _consecutiveFailures.remove(txId);
      await _maybePersistHistory();
      return result;
    }

    ElectrumTransactionInfo? latestResolvedInfo;
    final chunks = _chunked(uncachedInputTxids, _resolutionInputChunkSize);
    // Rebuilding the tx info (ownership/amount/direction from whatever
    // inputs are resolved so far) and writing it into history isn't free
    // (the rebuild, plus a disk save), so only push an updated snapshot into
    // history periodically (and always on the last chunk) - reportProgress
    // stays cheap and runs every chunk regardless.
    const updateHistoryEveryNChunks = 4;
    var anyChunkIncomplete = false;

    for (final (chunkIndex, chunk) in chunks.indexed) {
      // Escalates like the target fetch: a timeout here is swallowed
      // silently, so a too-short budget would otherwise never grow.
      final chunkVerbose = await _wallet.fetchTransactionVerboseBatch(chunk, timeoutMs: timeoutMs);
      cacheVerboseHexes(chunkVerbose);
      final parsedThisChunk = await parseTransactions(chunkVerbose);
      parsedInputTxById.addAll(parsedThisChunk);

      if (chunk.any((t) => !parsedThisChunk.containsKey(t))) {
        anyChunkIncomplete = true;
      }

      reportProgress();

      final isLastChunk = chunkIndex == chunks.length - 1;
      final isHistoryUpdateDue = ((chunkIndex + 1) % updateHistoryEveryNChunks) == 0;

      final shouldPauseForOpenedTransaction =
          !isLastChunk && _shouldPauseForOpenedTransaction(txId);

      if (isHistoryUpdateDue || isLastChunk || shouldPauseForOpenedTransaction) {
        latestResolvedInfo = buildTransactionAndAddToHistory();
        // Always durable on the last chunk - a large single transaction's
        // final resolved state shouldn't be left waiting for the throttle.
        await _maybePersistHistory(force: isLastChunk);
      }

      if (shouldPauseForOpenedTransaction) {
        // Hand the loop to the tx the user has open; this one stays pending
        // and resumes from here (cached parents, kept parses) on a rerun.
        _parsedParentsOfPausedTransaction[txId] = parsedInputTxById;
        _isRerunRequested = true;
        return latestResolvedInfo;
      }
    }

    if (anyChunkIncomplete) {
      // Retried later with the already-cached parents skipped and a larger timeout.
      _consecutiveFailures[txId] = (_consecutiveFailures[txId] ?? 0) + 1;
    } else {
      _consecutiveFailures.remove(txId);
    }

    return latestResolvedInfo;
  }

  /// (Re)starts the shared resolution loop (see [_runResolutionLoop]) after
  /// each completed sync cycle, or after deferred txs land in history,
  /// without blocking it. If a run is already in progress, another one is
  /// queued so txs added after its queue was built still get resolved.
  void resolvePending() {
    if (_isResolvingTransactions) {
      _isRerunRequested = true;
      return;
    }

    _ensureResolutionLoopRunning();
  }

  final Set<String> _refreshingTxIds = {};

  /// Brings [txId] up to date right away, for the transaction the user has
  /// open, instead of waiting for its turn in the sync-wide recheck or
  /// resolution queue.
  ///
  /// A tx still needing resolution is just [prioritize]d. This covers a resolved tx classified
  /// against fewer addresses than the wallet knows now: it is re-derived on its
  /// own, from its own parents, with a single forced refetch.
  Future<ElectrumTransactionInfo?> refreshIfStale(String txId) async {
    final tx = _wallet.transactionHistory.transactions[txId];
    if (tx == null) {
      return null;
    }

    if (tx.needsResolution) {
      prioritize(txId);
      return tx;
    }

    final recordedSize = tx.additionalInfo["addressSetSizeKey"] as int?;
    // Classified against its owning account's addresses when it has one, so
    // compare with that account's current set rather than the whole wallet's.
    final accountIndex = tx.accountIndex;
    final currentSize = accountIndex != null
        ? (_wallet.addressesSetByAccount[accountIndex]?.length ?? 0)
        : _wallet.addressesSet.length;
    if (recordedSize != null && recordedSize >= currentSize) {
      return tx;
    }

    // Already being refreshed (e.g. the page was opened twice in a row).
    if (!_refreshingTxIds.add(txId)) {
      return tx;
    }

    try {
      await _recheckChunked([tx], forceResolveInputs: true);
    } finally {
      _refreshingTxIds.remove(txId);
    }

    return _wallet.transactionHistory.transactions[txId];
  }

  /// Txs the sync saw in the history of an address they don't account for yet
  /// (see [flagIfStale]), waiting for [recheckStaleTransactions].
  final Set<String> _staleTxIds = {};

  /// Recheck chunk size. Small on purpose: the newest txs (the ones a user is
  /// most likely looking at) land after one short round trip instead of after a
  /// 150-tx batch of parent fetches.
  static const int _recheckChunkSize = 10;

  /// (tx, address) pairs already flagged this session, so a tx that can never
  /// settle for an address isn't rechecked on every sync. Cleared for a tx whose
  /// recheck couldn't fetch it, so the next sync flags it again.
  final Map<String, Set<String>> _flaggedPairs = {};

  /// Txs a forced recheck couldn't fully resolve this session. They stay stale
  /// (so [refreshIfStale] retries them) but the sync doesn't recheck them again.
  final Set<String> _unsettledTxIds = {};

  /// Called by the sync for every stored [tx] it finds in [address]'s history.
  /// An address can only take part in txs that appear in its own history, so
  /// this finds exactly the txs a newly discovered address could change.
  void flagIfStale(ElectrumTransactionInfo tx, String address) {
    if (_flaggedPairs[tx.id]?.contains(address) ?? false) {
      return;
    }

    if (isStaleForAddress(tx, address)) {
      (_flaggedPairs[tx.id] ??= <String>{}).add(address);
      _staleTxIds.add(tx.id);
    }
  }

  /// Whether [tx], which appears in [address]'s history, was classified without
  /// knowing [address] belongs to the wallet.
  @visibleForTesting
  static bool isStaleForAddress(ElectrumTransactionInfo tx, String address) {
    Set<dynamic> addressesOf(String key) =>
        ((tx.additionalInfo[key] as List?)?.cast<Map<dynamic, dynamic>>() ?? const [])
            .map((entry) => entry["address"])
            .toSet();

    if (tx.outputAddresses?.contains(address) ?? false) {
      return !addressesOf("ownedOutputs").contains(address);
    }

    // In the address's history but not an output, so it was spent as an input.
    // Unresolved txs have no recorded inputs yet; the resolution loop classifies
    // them against the current address set anyway.
    return tx.inputsOwnershipFullyResolved && !addressesOf("ownedInputs").contains(address);
  }

  /// Re-derives direction/amount/ownership for the txs flagged by [flagIfStale]
  /// since the last call, newest first, in small chunks, purely from cached
  /// local data where possible.
  ///
  /// A flagged tx that fails here is flagged again by the next sync, which sees
  /// it in the same address history again, so nothing is lost on failure.
  /// Txs persisted before the address set size was recorded are also covered
  /// by [needsAddressRecheck].
  Future<void> recheckStaleTransactions() async {
    final flagged = Set<String>.of(_staleTxIds);
    _staleTxIds.clear();

    final addresses = _wallet.addressesSet;
    final transactions = _wallet.transactionHistory.transactions;
    final candidates = transactions.values.where(
      (tx) =>
          !_unsettledTxIds.contains(tx.id) &&
          (flagged.contains(tx.id) ||
              (tx.additionalInfo["addressSetSizeKey"] == null &&
                  needsAddressRecheck(tx, addresses))),
    );
    final newestFirstCandidates = candidates.toList()..sort((a, b) => b.date.compareTo(a.date));

    if (newestFirstCandidates.isEmpty) {
      return;
    }

    // A non-force refetch doesn't check input ownership, so a known send
    // (ownedInputs saved) needs the expensive forceResolveInputs path
    // instead - otherwise the non-force refetch would incorrectly clear
    // that ownership.
    final needsInputResolution = <ElectrumTransactionInfo>[];
    final cheapCandidates = <ElectrumTransactionInfo>[];
    for (final tx in newestFirstCandidates) {
      final ownedInputs = tx.additionalInfo["ownedInputs"] as List?;
      if (ownedInputs?.isNotEmpty ?? false) {
        needsInputResolution.add(tx);
      } else {
        cheapCandidates.add(tx);
      }
    }

    await _recheckChunked(needsInputResolution, forceResolveInputs: true);

    // The rest try the non-force refetch first (no parent fetch
    // needed); only inputs genuinely ambiguous by witness/scriptSig alone
    // escalate to a forced parent fetch.
    final stillAmbiguous = await _recheckChunked(cheapCandidates, forceResolveInputs: false);
    if (stillAmbiguous.isNotEmpty) {
      await _recheckChunked(stillAmbiguous, forceResolveInputs: true);
    }
  }

  /// Whether [tx] was classified against a smaller address set than
  /// [addresses], so any input or output of it may now belong to the wallet.
  ///
  /// Txs persisted before the address set size was recorded fall back to
  /// a heuristic over their saved ownership data.
  @visibleForTesting
  static bool needsAddressRecheck(ElectrumTransactionInfo tx, Set<String> addresses) {
    final recordedSize = tx.additionalInfo["addressSetSizeKey"] as int?;

    if (recordedSize != null) {
      return recordedSize < addresses.length;
    }

    final outputs = tx.outputAddresses ?? const <String>[];
    final recognizedOutputAddresses =
        ((tx.additionalInfo["ownedOutputs"] as List?)?.cast<Map<dynamic, dynamic>>() ?? const [])
            .map((o) => o["address"])
            .toSet();

    final hasNewlyRecognizedOutput =
        outputs.any((a) => addresses.contains(a) && !recognizedOutputAddresses.contains(a));

    if (hasNewlyRecognizedOutput) {
      return true;
    }

    // Also re-check txs whose inputs are fully resolved but judged "not ours"
    // - that can flip once a revealed pubkey's address joins the wallet.
    final ownedInputs = tx.additionalInfo["ownedInputs"] as List?;
    return tx.inputsOwnershipFullyResolved && (ownedInputs?.isEmpty ?? true);
  }

  /// Records that [tx] is up to date for the address set [refetched] was built
  /// against, without otherwise changing it, so it stops being a recheck
  /// candidate.
  bool _markUpToDate(ElectrumTransactionInfo tx, ElectrumTransactionInfo refetched) {
    final count = refetched.additionalInfo["addressSetSizeKey"];
    if (count == null) {
      return false;
    }

    tx.additionalInfo["addressSetSizeKey"] = count;
    return true;
  }

  /// Returns the candidates that remain genuinely ambiguous after this pass
  /// (only possible when [forceResolveInputs] is false) - not yet
  /// conclusively re-classified one way or the other, so the caller can
  /// decide whether to escalate them to a forced parent fetch.
  Future<List<ElectrumTransactionInfo>> _recheckChunked(
    List<ElectrumTransactionInfo> candidates, {
    required bool forceResolveInputs,
  }) async {
    final transactionsStillAmbiguous = <ElectrumTransactionInfo>[];

    for (var i = 0; i < candidates.length; i += _recheckChunkSize) {
      final end =
          (i + _recheckChunkSize < candidates.length) ? i + _recheckChunkSize : candidates.length;
      final chunk = candidates.sublist(i, end);

      final hashes = chunk.map((tx) => tx.id).toList();
      final heightsByHash = {for (final tx in chunk) tx.id: tx.height};

      final refetchedByHash = await _wallet.fetchTransactionInfoBatch(
        hashes: hashes,
        heightsByHash: heightsByHash,
        forceResolveInputs: forceResolveInputs,
      );

      var updated = false;
      for (final tx in chunk) {
        final refetched = refetchedByHash[tx.id];
        if (refetched == null) {
          // Couldn't refetch: let the next sync flag it again.
          _flaggedPairs.remove(tx.id);
          continue;
        }

        // Never let this pass regress a transaction from resolved back to
        // unresolved.
        final wasResolved = tx.inputsOwnershipFullyResolved;
        final isNowResolved = refetched.inputsOwnershipFullyResolved;
        if (wasResolved && !isNowResolved) {
          if (!forceResolveInputs) {
            transactionsStillAmbiguous.add(tx);
          } else {
            // Must not mark the stale tx as up to date: refreshIfStale has to
            // retry it. Skip it for the rest of the session so the sync
            // doesn't loop on it.
            _unsettledTxIds.add(tx.id);
          }

          continue;
        }

        // Settled now (e.g. a refreshIfStale retry succeeded), so the sync may
        // recheck it again when a newly discovered address makes it stale.
        _unsettledTxIds.remove(tx.id);

        // A non-forced refetch has no parent inputs, so it can't compute a
        // fee; keep the one already known.
        if (refetched.fee == null && tx.fee != null) {
          refetched.fee = tx.fee;
        }

        final changed = refetched.direction != tx.direction ||
            refetched.amount != tx.amount ||
            refetched.fee != tx.fee ||
            !tx.additionalInfo.containsKey("ownedInputs") ||
            !tx.additionalInfo.containsKey("ownedOutputs");

        if (!changed) {
          if (_markUpToDate(tx, refetched)) {
            updated = true;
          }

          continue;
        }

        refetched.id = tx.id;
        refetched.date = tx.date;
        refetched.isPending = tx.isPending;
        refetched.isReplaced = tx.isReplaced ?? false;
        refetched.to = tx.to;
        refetched.from = tx.from;
        refetched.unspents = tx.unspents;
        refetched.isReceivedSilentPayment = tx.isReceivedSilentPayment;
        refetched.accountIndex ??= tx.accountIndex;

        _wallet.transactionHistory.addOne(refetched);
        updated = true;
      }

      if (updated) {
        await _wallet.transactionHistory.save();
      }
    }

    return transactionsStillAmbiguous;
  }
}

List<List<T>> _chunked<T>(List<T> items, int size) => [
      for (var i = 0; i < items.length; i += size)
        items.sublist(i, i + size > items.length ? items.length : i + size),
    ];

/// How far [ElectrumTransactionResolver.prioritize] has got with one tx.
class TransactionResolutionProgress {
  const TransactionResolutionProgress({
    required this.resolvedInputs,
    required this.totalInputs,
    this.hasFailed = false,
  });

  /// Inputs whose parent tx is fetched so far.
  final int resolvedInputs;

  /// 0 until the tx itself has been fetched.
  final int totalInputs;

  /// The resolver gave up after repeated failed attempts.
  final bool hasFailed;
}
