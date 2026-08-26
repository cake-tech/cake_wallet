import 'dart:async';

import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_bitcoin/electrum_transaction_isolate.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_core/get_height_by_date.dart';
import 'package:cw_core/utils/print_verbose.dart';

/// Resolves fee/ownership/direction details for transactions that the
/// first pass sync (see [ElectrumWalletBase.getTransactionExpanded]) left
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
      final hex = entry.value['hex'] as String?;
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
  // Callers waiting on a specific txid register in _resolutionWaiters and are notified once
  // the loop gets to it.
  final Map<String, Completer<ElectrumTransactionInfo?>> _resolutionWaiters = {};
  final Map<String, List<void Function(int resolved, int total)>> _feeFetchProgressListeners = {};

  // Set by stop() (see ElectrumWalletBase.close) so a run in progress stops
  // immediately.
  bool _stopped = false;

  void stop() {
    _stopped = true;
  }

  /// Input-resolution chunk size for [_resolveTransactionDetails].
  /// Deliberately much smaller than [ElectrumWalletBase.transactionChunkSize]
  /// (150, used elsewhere for whole-batch history fetches): a transaction
  /// can have hundreds of inputs, and resolving it in small batches gives
  /// [watchTransactionResolution]'s progress callback frequent, meaningful
  /// updates instead of one long unbroken fetch+parse+persist step.
  static const int _resolutionInputChunkSize = 25;

  /// Timeout for the network calls in [_resolveTransactionDetails] -
  /// deliberately shorter than [ElectrumWalletBase.transactionBatchTimeoutMs]
  /// (15s). This resolves one transaction's inputs at a time, often while a
  /// UI progress indicator is watching it, so a slow/unfetchable chunk
  /// should fail fast and move on rather than stalling visible progress.
  static const int _resolutionBatchTimeoutMs = 6 * 1000;

  /// Register interest in [txId]'s resolution for the transaction details
  /// page, resolved whenever the shared background loop naturally reaches
  /// it. Returns the stored info as-is if it's already resolved.
  ///
  /// [onProgress] fires after every input batch. Concurrent calls for the
  /// same [txId] share one result instead of duplicating work.
  Future<ElectrumTransactionInfo?> watchTransactionResolution(
    String txId, {
    void Function(int resolved, int total)? onProgress,
  }) {
    final existingTxInfo = _wallet.transactionHistory.transactions[txId];
    if (existingTxInfo != null && !existingTxInfo.needsResolution) {
      return Future.value(existingTxInfo);
    }

    if (onProgress != null) {
      (_feeFetchProgressListeners[txId] ??= <void Function(int, int)>[]).add(onProgress);
    }

    final waiter = _resolutionWaiters.putIfAbsent(txId, Completer<ElectrumTransactionInfo?>.new);
    // Ensures the background loop is actually running (e.g. it may have
    // drained its last pending queue and gone idle since the last sync).
    _ensureResolutionLoopRunning();
    return waiter.future;
  }

  void _reportFeeFetchProgress(String txId, int resolved, int total) {
    for (final listener in _feeFetchProgressListeners[txId] ?? const []) {
      listener(resolved, total);
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
      }),
    );
  }

  /// Processes the pending queue one transaction at a time (ownership-
  /// incomplete before fee-only, newest-first within each). Backs both the
  /// background pass and watchTransactionResolution, which just attaches a
  /// waiter for a txid. A tx that fails to resolve simply stays pending and
  /// is retried whenever this loop next runs.
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

      pendingQueue ??= _buildPendingQueue();
      String? txId;
      while (pendingQueue.isNotEmpty) {
        final candidate = pendingQueue.removeLast();
        final txInfo = _wallet.transactionHistory.transactions[candidate];
        if (txInfo != null && !txInfo.needsResolution) {
          continue;
        }
        txId = candidate;
        break;
      }
      if (txId == null) {
        break;
      }

      ElectrumTransactionInfo? result;
      try {
        result = await _resolveTransactionDetails(txId);
      } catch (e, stacktrace) {
        printV('resolution loop: failed for $txId, will retry next run: $e');
        printV(stacktrace);
      }

      _resolutionWaiters.remove(txId)?.complete(result);
      _feeFetchProgressListeners.remove(txId);
    }

    // The last resolution(s) may still be throttled in memory, force a final save.
    await _maybePersistHistory(force: true);
  }

  /// Ownership-incomplete transactions before fee-only ones, newest-first
  /// within each. Sorted in *ascending* priority (lowest-priority first) so
  /// the intended pick order comes out via removeLast() - see [_runResolutionLoop].
  List<String> _buildPendingQueue() {
    final candidates =
        _wallet.transactionHistory.transactions.values.where((tx) => tx.needsResolution).toList()
          ..sort((a, b) {
            if (a.inputsOwnershipFullyResolved != b.inputsOwnershipFullyResolved) {
              return a.inputsOwnershipFullyResolved ? -1 : 1;
            }
            return a.date.compareTo(b.date);
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

    final targetVerbose =
        await _wallet.fetchTransactionVerboseBatch([txId], timeoutMs: _resolutionBatchTimeoutMs);
    cacheVerboseHexes(targetVerbose);
    final targetOriginal = (await parseTransactions(targetVerbose))[txId];
    if (targetOriginal == null) {
      return existingTxInfo;
    }

    // Height/time/confirmations are properties of the target tx itself, not
    // of how many inputs are resolved yet - compute once and reuse for every
    // partial and final build below.
    final height = existingTxInfo?.height;
    final verbose = targetVerbose[txId] ?? const <String, dynamic>{};
    int? time = verbose['time'] as int?;
    int? confirmations = verbose['confirmations'] as int?;
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

    final cachedVerbose = <String, Map<String, dynamic>>{};
    final uncachedInputTxids = <String>[];
    for (final t in allInputTxids) {
      final cachedHex = cachedRawTxHex(t);
      if (cachedHex != null) {
        cachedVerbose[t] = {'hex': cachedHex};
      } else {
        uncachedInputTxids.add(t);
      }
    }
    final parsedInputTxById = await parseTransactions(cachedVerbose);

    // Captured as locals so buildAndPersist's closure doesn't reference
    // _wallet directly - it isn't Isolate-transferable.
    final walletType = _wallet.walletInfo.type;
    final walletNetwork = _wallet.network;
    final ownAddresses = _wallet.addressesSet;

    Future<ElectrumTransactionInfo> buildTransactionAndAddToHistory() async {
      final ins = targetOriginal.inputs.map((v) => parsedInputTxById[v.txId]).toList();
      final bundle = ElectrumTransactionBundle(
        targetOriginal,
        ins: ins,
        time: time,
        confirmations: confirmations ?? 0,
      );
      // fromElectrumBundle re-derives ownership/addresses for every input
      // and output of the whole transaction, not just the newly-resolved
      // ones - run in a background Isolate so hundreds of address
      // derivations for a large tx, redone on every batch, can never pin
      // the UI isolate.
      final infosByHash = await buildElectrumTransactionInfosInIsolate(
        ({txId: bundle}, walletType, walletNetwork, ownAddresses, {txId: height}),
      );
      final info = infosByHash[txId];
      if (info == null) {
        throw Exception('fromElectrumBundle failed to build info for txid=$txId');
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
      }

      _wallet.transactionHistory.addOne(info);
      return info;
    }

    void reportProgress() {
      final resolved =
          targetOriginal.inputs.where((v) => parsedInputTxById.containsKey(v.txId)).length;
      _reportFeeFetchProgress(txId, resolved, totalInputs);
    }

    reportProgress();

    if (uncachedInputTxids.isEmpty) {
      final result = await buildTransactionAndAddToHistory();
      await _maybePersistHistory();
      return result;
    }

    ElectrumTransactionInfo? latestResolvedInfo;
    final chunks = _chunked(uncachedInputTxids, _resolutionInputChunkSize);
    // Re-deriving the tx info (ownership/amount/direction from whatever
    // inputs are resolved so far) and writing it into history isn't a
    // UI-isolate concern, but its isolate spawn + disk save still aren't
    // free, so only push an updated snapshot into history periodically
    // (and always on the last chunk) - reportProgress stays cheap and runs
    // every chunk regardless.
    const updateHistoryEveryNChunks = 4;
    for (final (chunkIndex, chunk) in chunks.indexed) {
      final chunkVerbose =
          await _wallet.fetchTransactionVerboseBatch(chunk, timeoutMs: _resolutionBatchTimeoutMs);
      cacheVerboseHexes(chunkVerbose);
      final parsedThisChunk = await parseTransactions(chunkVerbose);
      parsedInputTxById.addAll(parsedThisChunk);

      reportProgress();

      final isLastChunk = chunkIndex == chunks.length - 1;
      final isHistoryUpdateDue = ((chunkIndex + 1) % updateHistoryEveryNChunks) == 0;

      if (isHistoryUpdateDue || isLastChunk) {
        latestResolvedInfo = await buildTransactionAndAddToHistory();
        // Always durable on the last chunk - a large single transaction's
        // final resolved state shouldn't be left waiting for the throttle.
        await _maybePersistHistory(force: isLastChunk);
      }
    }

    return latestResolvedInfo;
  }

  /// (Re)starts the shared resolution loop (see [_runResolutionLoop]) after
  /// each completed sync cycle, without blocking it.
  void resolvePending() {
    _ensureResolutionLoopRunning();
  }

  int _lastRecheckAddressCount = -1;

  /// Re-derives direction/amount/output-ownership for persisted transactions
  /// whose output may now match a wallet address that didn't exist yet at
  /// classification time, purely from cached local data, only when the address
  /// set has grown since [_lastRecheckAddressCount].
  Future<void> recheckStaleTransactions() async {
    final currentAddressCount = _wallet.walletAddresses.allAddresses.length;
    if (currentAddressCount == _lastRecheckAddressCount) {
      return;
    }
    _lastRecheckAddressCount = currentAddressCount;

    final addresses = _wallet.addressesSet;
    final candidates = _wallet.transactionHistory.transactions.values.where((tx) {
      final outputs = tx.outputAddresses ?? const <String>[];
      final recognizedOutputAddresses =
          ((tx.additionalInfo['ownedOutputs'] as List?)?.cast<Map<dynamic, dynamic>>() ?? const [])
              .map((o) => o['address'])
              .toSet();
      final hasNewlyRecognizedOutput =
          outputs.any((a) => addresses.contains(a) && !recognizedOutputAddresses.contains(a));
      if (hasNewlyRecognizedOutput) {
        return true;
      }

      // Also re-check pass2-resolved txs judged "not ours" from inputs alone
      // - that can flip once a revealed pubkey's address joins the wallet.
      final ownedInputs = tx.additionalInfo['ownedInputs'] as List?;
      return tx.inputsOwnershipFullyResolved && (ownedInputs?.isEmpty ?? true);
    });
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
      final ownedInputs = tx.additionalInfo['ownedInputs'] as List?;
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

  /// Returns the candidates that remain genuinely ambiguous after this pass
  /// (only possible when [forceResolveInputs] is false) - not yet
  /// conclusively re-classified one way or the other, so the caller can
  /// decide whether to escalate them to a forced parent fetch.
  Future<List<ElectrumTransactionInfo>> _recheckChunked(
    List<ElectrumTransactionInfo> candidates, {
    required bool forceResolveInputs,
  }) async {
    final transactionsStillAmbiguous = <ElectrumTransactionInfo>[];

    for (var i = 0; i < candidates.length; i += ElectrumWalletBase.transactionChunkSize) {
      final end = (i + ElectrumWalletBase.transactionChunkSize < candidates.length)
          ? i + ElectrumWalletBase.transactionChunkSize
          : candidates.length;
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
          continue;
        }

        // Never let this pass regress a transaction from resolved back to
        // unresolved.
        final wasResolved = tx.inputsOwnershipFullyResolved;
        final isNowResolved = refetched.inputsOwnershipFullyResolved;
        if (wasResolved && !isNowResolved) {
          if (!forceResolveInputs) {
            transactionsStillAmbiguous.add(tx);
          }
          continue;
        }

        final changed = refetched.direction != tx.direction ||
            refetched.amount != tx.amount ||
            refetched.fee != tx.fee ||
            !tx.additionalInfo.containsKey('ownedInputs') ||
            !tx.additionalInfo.containsKey('ownedOutputs');

        if (!changed) {
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
