part of "electrum_wallet.dart";

class SilentPaymentsScanner {
  SilentPaymentsScanner(this._wallet);

  final ElectrumWalletBase _wallet;

  List<_ScanWorkerHandle> _scanWorkers = [];

  static const int _scanWorkerCountV2 = 4;
  static const int _scanWorkerCountLegacy = 1;
  static const int _scanWorkerCountMax = 32;
  int _scanWorkerCount(int protocolVersion, {int? override}) {
    if (protocolVersion < 2) {
      return _scanWorkerCountLegacy;
    }
    if (override == null) {
      return _scanWorkerCountV2;
    }
    return override.clamp(1, _scanWorkerCountMax);
  }

  static const int _silentPaymentsActivationHeight = 823807;

  static const String defaultScanServerHost = "172.104.252.163";
  static const int defaultScanServerPort = 50003;
  static final ScanNode defaultScanNode = ScanNode(
    Uri.parse("tcp://$defaultScanServerHost:$defaultScanServerPort"),
    useSSL: true,
  );

  // User-chosen scan server (SP settings), or null to use [defaultScanNode].
  // Static because the worker isolates are spawned per wallet but the
  // setting is app-wide; the app layer pushes it in at startup and whenever
  // the user edits it. Takes effect from the next scan round.
  static ScanNode? customScanNode;

  static ScanNode get activeScanNode => customScanNode ?? defaultScanNode;

  /// Applies [raw] as the scan server. Blank or unparsable input reverts to
  /// the default. Returns whether a custom server is now active.
  static bool setCustomScanServer(String? raw) {
    customScanNode = parseScanServer(raw);

    return customScanNode != null;
  }

  /// Parses `host`, `host:port`, `ssl://host[:port]` or `tcp://host[:port]`.
  /// A bare address means TLS (the safe choice); use `tcp://` for plaintext.
  /// Missing ports default to 50002 (ssl) / 50001 (tcp). Returns null when
  /// [raw] is blank or not a usable address.
  static ScanNode? parseScanServer(String? raw) {
    var value = raw?.trim() ?? "";
    if (value.isEmpty) {
      return null;
    }

    var useSSL = true;
    final schemeMatch = RegExp(r'^([a-zA-Z][a-zA-Z0-9+.-]*)://').firstMatch(value);

    if (schemeMatch != null) {
      final scheme = schemeMatch.group(1)!.toLowerCase();

      if (scheme == "tcp") {
        useSSL = false;
      } else if (scheme != "ssl" && scheme != "tls") {
        return null;
      }

      value = value.substring(schemeMatch.end);
    }

    value = value.replaceAll(RegExp(r'/+$'), "");

    final uri = Uri.tryParse("tcp://$value");

    if (uri == null || uri.host.isEmpty || uri.path.isNotEmpty) {
      return null;
    }

    final port = uri.hasPort ? uri.port : (useSSL ? 50002 : 50001);

    if (port < 1 || port > 65535) {
      return null;
    }

    return ScanNode(Uri.parse("tcp://${uri.host}:$port"), useSSL: useSSL);
  }

  // The dedicated scan server is always this version - no per-node
  // negotiation needed (see defaultScanNode's doc comment above).
  static const int _defaultScanProtocolVersion = 2;

  int _scanWorkerGeneration = 0;

  int _pendingSetListenersCalls = 0;

  final Set<int> _doneWorkerIndices = {};

  // More uncovered gaps than workers this round: partitionForWorkers hands
  // out only the first workerCount of them, so another round has to pick up
  // the rest once these workers finish.
  bool _hasDeferredGaps = false;

  Timer? _checkpointFlushTimer;
  Future<void> _checkpointFlushQueue = Future.value();
  static const _checkpointFlushInterval = Duration(milliseconds: 1500);

  StreamSubscription<dynamic>? _receiveStream;

  // Periodic re-verify cadence (see maybeReverify below), owned here rather
  // than on the wallet since it's pure scan-reverify bookkeeping.
  DateTime? _lastSilentPaymentsScan;
  static const Duration _silentPaymentsScanDelay = Duration(minutes: 1);

  /// Whether a scan round still has workers running.
  bool get isScanning => _scanWorkers.any((w) => !_doneWorkerIndices.contains(w.workerIndex));

  /// Stops this wallet's scan for good (wallet closing). The workers use their
  /// own scan-server connection, so a wallet-node reconnect must not call this.
  Future<void> dispose() async {
    _scanWorkerGeneration++;
    await stopScanWorkers();
    await _receiveStream?.cancel();
    _receiveStream = null;
  }

  Future<void> rescan({
    required int height,
    bool? doSingleScan,
    int? workerCountOverride,
    bool? historicalModeOverride,
    bool ignoreExistingCoverage = true,
  }) async {
    _pendingSetListenersCalls++;
    unawaited(
      setListeners(
        height,
        doSingleScan: doSingleScan,
        workerCountOverride: workerCountOverride,
        ignoreExistingCoverage: ignoreExistingCoverage,
        historicalModeOverride: historicalModeOverride,
      ).whenComplete(() => _pendingSetListenersCalls--),
    );
  }

  /// The automatic periodic re-verify `startSync` runs on every sync pass:
  /// re-checks that already-found Silent Payments matches haven't been
  /// reorged out, at most once per `_silentPaymentsScanDelay`, and defers to
  /// any already-in-flight `setListeners` call rather than racing it.
  Future<void> maybeReverify() async {
    final now = DateTime.now();
    final shouldForceRescan = _lastSilentPaymentsScan == null ||
        now.difference(_lastSilentPaymentsScan!) >= _silentPaymentsScanDelay;

    // Timer prevents server failure and this infinite looping and requesting
    if (!shouldForceRescan) {
      return;
    }
    _lastSilentPaymentsScan = now;

    final rescanHeights = <int>[];

    for (final tx in _wallet.transactionHistory.transactions.values) {
      if (tx.unspents != null && tx.unspents!.isNotEmpty) {
        for (final unspent in tx.unspents!) {
          if (unspent.silentPaymentTweak != null && tx.height != null && tx.height! > 0) {
            rescanHeights.add(tx.height!);
            break;
          }
        }
      }
    }

    if (rescanHeights.isEmpty) {
      return;
    }

    if (_pendingSetListenersCalls > 0 || isScanning) {
      return;
    }

    _pendingSetListenersCalls++;
    unawaited(
      setListeners(
        _wallet.walletInfo.restoreHeight,
        rescanHeights: rescanHeights,
      ).whenComplete(() => _pendingSetListenersCalls--),
    );
  }

  Future<void> setListeners(
    int height, {
    int? chainTipParam,
    bool? doSingleScan,
    List<int>? rescanHeights,
    int? workerCountOverride,
    bool ignoreExistingCoverage = false,
    bool? historicalModeOverride,
  }) async {
    final chainTip = chainTipParam ?? await _wallet.getUpdatedChainTip();
    final shouldUpdateSyncStatus = rescanHeights == null || rescanHeights.isEmpty;
    final isForcedRescan = !shouldUpdateSyncStatus;
    final isSingleScan = doSingleScan ?? false;

    if (chainTip == height && chainTip > 0) {
      _wallet.syncStatus = SyncedSyncStatus();
      return;
    }

    if (chainTip <= 0) {
      if (shouldUpdateSyncStatus) {
        _wallet.syncStatus = LostConnectionSyncStatus();
      }
      return;
    }

    if (shouldUpdateSyncStatus) {
      _wallet.syncStatus = AttemptingScanSyncStatus();
    }

    final generation = ++_scanWorkerGeneration;
    await stopScanWorkers();
    if (generation != _scanWorkerGeneration) {
      return;
    }

    // Historical is opt-in (the rescan page's toggle, passed as
    // historicalModeOverride). The one internal exception is re-verifying
    // known matches: a non-historical reply drops spent outputs, so an
    // already-spent match would look reorged out.
    final historical = historicalModeOverride ?? isForcedRescan;
    final scanFloor = (isForcedRescan || ignoreExistingCoverage)
        ? height
        : (height > _wallet.walletInfo.restoreHeight ? height : _wallet.walletInfo.restoreHeight);
    final scanCeiling = chainTip;

    printV(
      "[SP CHECKPOINT DEBUG] setListeners: height(param)=$height "
      "restoreHeight(post-stop)=${_wallet.walletInfo.restoreHeight} scanFloor=$scanFloor "
      "scanCeiling=$scanCeiling isForcedRescan=$isForcedRescan "
      "ignoreExistingCoverage=$ignoreExistingCoverage historical=$historical",
    );

    if (ignoreExistingCoverage && !isForcedRescan) {
      printV("[SP CHECKPOINT DEBUG] wiping coverage, new floor=$scanFloor");
      await WalletInfoScanCoverage.deleteByWalletInfoId(_wallet.walletInfo.internalId);
      _wallet.walletInfo.restoreHeight = scanFloor;
      _wallet.walletInfo.backfillTargetHeight = null;
      await _wallet.walletInfo.save();
    }

    final appDir = await getAppDir();
    final String debugLogPath = "${appDir.path}/logs/debug.log";
    if (generation != _scanWorkerGeneration) {
      return;
    }

    List<CoverageRange> chunks;
    var hasDeferredGaps = false;
    if (isForcedRescan || isSingleScan) {
      chunks = [CoverageRange(scanFloor, scanCeiling)];
    } else {
      final workerCount = _scanWorkerCount(
        _defaultScanProtocolVersion,
        override: workerCountOverride,
      );
      final coverage = ignoreExistingCoverage
          ? <WalletInfoScanCoverage>[]
          : await WalletInfoScanCoverage.selectList(
              _wallet.walletInfo.internalId,
              historical: historical,
            );
      final gapInputRanges =
          coverage.map((c) => CoverageRange(c.startHeight, c.endHeight)).toList();
      if (scanFloor < _silentPaymentsActivationHeight) {
        final deadZoneEnd = _silentPaymentsActivationHeight - 1 < scanCeiling
            ? _silentPaymentsActivationHeight - 1
            : scanCeiling;
        gapInputRanges.add(CoverageRange(scanFloor, deadZoneEnd));
      }
      final gaps = uncoveredRanges(gapInputRanges, scanFloor, scanCeiling);
      chunks = partitionForWorkers(gaps, workerCount);
      hasDeferredGaps = gaps.length > workerCount;

      if (chunks.isEmpty) {
        _wallet.syncStatus = SyncedSyncStatus();
        return;
      }
    }

    await _receiveStream?.cancel();
    if (generation != _scanWorkerGeneration) {
      return;
    }

    final receivePort = ReceivePort();
    final workers = <_ScanWorkerHandle>[];
    for (var i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      final isolateFuture = Isolate.spawn(
        _handleScanSilentPayments,
        ScanData(
          workerIndex: i,
          sendPort: receivePort.sendPort,
          silentAddress: _wallet.walletAddresses.silentAddress!,
          masterHD: _wallet._masterHD!,
          network: _wallet.network,
          height: chunk.startHeight,
          chainTip: chainTip,
          rangeEnd: chunk.endHeight,
          electrumClient: electrum.ElectrumClient(),
          transactionHistoryIds: _wallet.transactionHistory.transactions.keys.toList(),
          node: SilentPaymentsScanner.activeScanNode,
          labels: _wallet.walletAddresses.labels,
          labelIndexes: _wallet.walletAddresses.silentAddresses
              .where((addr) => addr.type == SilentPaymentsAddresType.p2sp && addr.index >= 1)
              .map((addr) => addr.index)
              .toList(),
          isSingleScan: isSingleScan,
          debugLogPath: debugLogPath,
          rescanHeights: rescanHeights,
          historical: historical,
          protocolVersion: _defaultScanProtocolVersion,
        ),
      );
      workers.add(
        _ScanWorkerHandle(
          i,
          isolateFuture,
          rangeStart: chunk.startHeight,
          rangeEnd: chunk.endHeight,
          historical: historical,
        ),
      );
    }
    _scanWorkers = workers;
    _doneWorkerIndices.clear();
    _hasDeferredGaps = hasDeferredGaps;

    _receiveStream = receivePort.listen((var message) async {
      if (message is ScanWorkerReady) {
        final worker = _scanWorkers.firstWhereOrNull((w) => w.workerIndex == message.workerIndex);
        worker?.commandPort = message.commandPort;
        return;
      }

      if (message is WorkerStopped) {
        final worker = _scanWorkers.firstWhereOrNull((w) => w.workerIndex == message.workerIndex);
        if (worker != null && !worker.stoppedCompleter.isCompleted) {
          worker.stoppedCompleter.complete();
        }
        return;
      }

      if (message is Map<String, ElectrumTransactionInfo>) {
        for (final map in message.entries) {
          final txid = map.key;
          final tx = map.value;

          if (tx.unspents != null) {
            final existingTxInfo = _wallet.transactionHistory.transactions[txid];
            final txAlreadyExisted = existingTxInfo != null;

            // Updating tx after re-scanned
            if (txAlreadyExisted) {
              final previousUnspents = existingTxInfo.unspents;

              existingTxInfo.amount = tx.amount;
              existingTxInfo.confirmations = tx.confirmations;
              existingTxInfo.height = tx.height;
              existingTxInfo.date = tx.date;
              existingTxInfo.isReceivedSilentPayment = tx.isReceivedSilentPayment;
              existingTxInfo.direction = tx.direction;
              existingTxInfo.isPending = tx.isPending;
              existingTxInfo.unspents = tx.unspents;

              final newUnspents = tx.unspents!
                  .where(
                    (unspent) => !(previousUnspents?.any(
                          (element) =>
                              element.hash.contains(unspent.hash) &&
                              element.vout == unspent.vout &&
                              element.value == unspent.value,
                        ) ??
                        false),
                  )
                  .toList();

              if (newUnspents.isNotEmpty) {
                newUnspents.forEach(_wallet._updateSilentAddressRecord);

                final newAmount = newUnspents.length > 1
                    ? newUnspents.map((e) => e.value).reduce((value, unspent) => value + unspent)
                    : newUnspents[0].value;

                if (existingTxInfo.direction == TransactionDirection.incoming) {
                  existingTxInfo.amount += Money.fromInt(newAmount, _wallet.currency);
                }

                // Update balance record
                _wallet._bumpConfirmedBalance(Money.fromInt(newAmount, _wallet.currency));
              }

              _wallet.transactionHistory.transactions.remove(txid);
              _wallet.transactionHistory.addOne(existingTxInfo);
              await _wallet.save();
            } else {
              // else: First time seeing this TX after scanning
              tx.unspents!.forEach(_wallet._updateSilentAddressRecord);

              // Add new TX record
              _wallet.transactionHistory.addMany(message);

              final spendableAmount = tx.unspents!.isEmpty
                  ? Money.zero(_wallet.currency)
                  : Money.fromInt(
                      tx.unspents!.map((e) => e.value).reduce((a, b) => a + b),
                      _wallet.currency,
                    );
              _wallet._bumpConfirmedBalance(spendableAmount);

              await _wallet.save();
            }

            await _wallet.updateAllUnspents();
          }
        }
      }

      if (message is SyncResponse) {
        if (message.syncStatus is UnsupportedSyncStatus) {
          _wallet.nodeSupportsSilentPayments = false;
        }

        final isWorkerDone =
            message.syncStatus is SyncedSyncStatus || message.syncStatus is SyncedTipSyncStatus;
        if (isWorkerDone) {
          _doneWorkerIndices.add(message.workerIndex);
        }

        // Update this worker's known progress *before* aggregating below,
        // so the aggregate reflects this message rather than the previous
        // one.
        final worker = _scanWorkers.firstWhereOrNull((w) => w.workerIndex == message.workerIndex);
        if (worker != null) {
          worker.pendingCheckpointHeight = message.height;
          _checkpointFlushTimer ??= Timer.periodic(
            _checkpointFlushInterval,
            (_) => _flushCheckpoint(),
          );
        }

        final allWorkersDone = isWorkerDone && _doneWorkerIndices.length == _scanWorkers.length;

        if (shouldUpdateSyncStatus) {
          if (message.syncStatus is SyncingSyncStatus) {
            _wallet.syncStatus = _aggregateScanProgress();
          } else if (isWorkerDone && !allWorkersDone) {
            _wallet.syncStatus = _aggregateScanProgress();
          } else if (!allWorkersDone) {
            // A worker that lost the scan server reconnects on its own. Its
            // LostConnection must not reach the wallet as-is: that status
            // drives the wallet node's reconnect and resubscribe logic, and
            // the wallet node is a different connection.
            _wallet.syncStatus = message.syncStatus is NotConnectedSyncStatus
                ? AttemptingScanSyncStatus()
                : message.syncStatus;
          }
        }

        if (allWorkersDone) {
          await _flushCheckpoint();

          if (shouldUpdateSyncStatus && _hasDeferredGaps) {
            _hasDeferredGaps = false;

            if (_wallet.walletInfo.restoreHeight < scanCeiling) {
              await rescan(
                height: _wallet.walletInfo.restoreHeight,
                historicalModeOverride: historical,
                ignoreExistingCoverage: false,
              );
              return;
            }
          }

          if (shouldUpdateSyncStatus) {
            final restoreHeight = _wallet.walletInfo.restoreHeight;
            _wallet.syncStatus = restoreHeight >= scanCeiling
                ? SyncedTipSyncStatus(restoreHeight)
                : await _trueRemainingBlocks(restoreHeight, scanCeiling);
          }
        }
      }
    });
  }

  SyncingSyncStatus _aggregateScanProgress() {
    var totalToScan = 0;
    var totalLeft = 0;

    for (final w in _scanWorkers) {
      final workerTotal = w.rangeEnd - w.rangeStart + 1;
      final done = _doneWorkerIndices.contains(w.workerIndex);
      final current = done ? w.rangeEnd : (w.pendingCheckpointHeight ?? w.checkpointBaseline);
      final left = w.rangeEnd - current;
      if (workerTotal <= 0) {
        continue;
      }
      totalToScan += workerTotal;
      totalLeft += left < 0 ? 0 : left;
    }

    if (totalToScan <= 0) {
      return SyncingSyncStatus(0, 1);
    }

    final rawPtc = 1.0 - (totalLeft / totalToScan);
    final ptc = rawPtc < 0.0 ? 0.0 : (rawPtc > 1.0 ? 1.0 : rawPtc);
    return SyncingSyncStatus(totalLeft, ptc);
  }

  Future<SyncingSyncStatus> _trueRemainingBlocks(int floorHeight, int ceilingHeight) async {
    if (floorHeight >= ceilingHeight) {
      return SyncingSyncStatus(0, 1);
    }

    final coverage = await WalletInfoScanCoverage.selectList(_wallet.walletInfo.internalId);
    final ranges = coverage.map((c) => CoverageRange(c.startHeight, c.endHeight)).toList();
    if (floorHeight < _silentPaymentsActivationHeight) {
      ranges.add(CoverageRange(floorHeight, _silentPaymentsActivationHeight - 1));
    }

    final gaps = uncoveredRanges(ranges, floorHeight, ceilingHeight);
    final blocksLeft = gaps.fold<int>(0, (sum, gap) => sum + (gap.endHeight - gap.startHeight + 1));
    final totalSpan = ceilingHeight - floorHeight + 1;
    final rawPtc = 1.0 - (blocksLeft / totalSpan);
    final ptc = rawPtc < 0.0 ? 0.0 : (rawPtc > 1.0 ? 1.0 : rawPtc);
    return SyncingSyncStatus(blocksLeft, ptc);
  }

  /// Cooperatively stops every current scan worker (ADR-0010) and clears
  /// [_scanWorkers]. Safe to call when there are none running.
  Future<void> stopScanWorkers() async {
    _checkpointFlushTimer?.cancel();
    _checkpointFlushTimer = null;
    // Flush immediately on a deliberate stop instead of leaving up to
    // `_checkpointFlushInterval` of already-reported progress unpersisted.
    await _flushCheckpoint();

    if (_scanWorkers.isEmpty) {
      return;
    }

    final workers = _scanWorkers;
    _scanWorkers = [];
    await Future.wait(workers.map(_stopWorker));
  }

  Future<void> _stopWorker(_ScanWorkerHandle worker) async {
    final isolate = await worker.isolateFuture;
    isolate.kill(priority: Isolate.immediate);
  }

  Future<void> _flushCheckpoint() {
    final scheduled = _checkpointFlushQueue.then((_) => _flushCheckpointOnce());
    // The queue's own tail must never end up rejected (that would wedge
    // every future flush behind a permanently-failed `Future`) - errors
    // still propagate to whoever awaited `scheduled` (this call's own
    // return value), just not into the chain itself.
    _checkpointFlushQueue = scheduled.then((_) {}, onError: (_) {});
    return scheduled;
  }

  Future<void> _flushCheckpointOnce() async {
    if (_scanWorkers.isEmpty) {
      return;
    }
    final pending = _scanWorkers.where((w) => w.pendingCheckpointHeight != null).toList();
    if (pending.isEmpty) {
      return;
    }

    printV(
      "[SP CHECKPOINT DEBUG] flush start: restoreHeight(pre)=${_wallet.walletInfo.restoreHeight} "
      "pending=${pending.map((w) => '#${w.workerIndex}[${w.checkpointBaseline}->${w.pendingCheckpointHeight}]hist=${w.historical}').join(', ')}",
    );

    for (final worker in pending) {
      final target = worker.pendingCheckpointHeight!;
      worker.pendingCheckpointHeight = null;

      final workerDone = _doneWorkerIndices.contains(worker.workerIndex);
      final hasNewCoverage =
          workerDone ? target >= worker.checkpointBaseline : target > worker.checkpointBaseline;
      if (hasNewCoverage) {
        await WalletInfoScanCoverage.markCovered(
          walletInfoId: _wallet.walletInfo.internalId,
          historical: worker.historical,
          startHeight: worker.checkpointBaseline,
          endHeight: target,
        );
      }
      worker.checkpointBaseline = target;
    }

    final coverage = await WalletInfoScanCoverage.selectList(_wallet.walletInfo.internalId);
    final ranges = coverage.map((c) => CoverageRange(c.startHeight, c.endHeight)).toList();

    final restoreHeightBefore = _wallet.walletInfo.restoreHeight;
    if (restoreHeightBefore < _silentPaymentsActivationHeight) {
      ranges.add(CoverageRange(restoreHeightBefore, _silentPaymentsActivationHeight - 1));
    }
    final recomputed = highestContiguouslyCoveredFrom(ranges, restoreHeightBefore);

    printV(
      "[SP CHECKPOINT DEBUG] flush coverage: rows=${coverage.map((c) => '[${c.startHeight},${c.endHeight}]hist=${c.historical}').join(', ')} "
      "restoreHeight(pre)=${_wallet.walletInfo.restoreHeight} recomputed=$recomputed",
    );

    var needsSave = false;

    if (recomputed > _wallet.walletInfo.restoreHeight) {
      _wallet.walletInfo.restoreHeight = recomputed;
      needsSave = true;
    }

    if (needsSave) {
      await _wallet.walletInfo.save();
    }
    printV(
      "[SP CHECKPOINT DEBUG] flush end: needsSave=$needsSave "
      "restoreHeight(post)=${_wallet.walletInfo.restoreHeight}",
    );
  }

  Future<bool> _getNodeIsElectrs() async {
    if (_wallet.node == null) {
      return false;
    }

    final version = await _wallet.electrumClient.version();

    if (version.isNotEmpty) {
      final server = version[0];

      if (server.toLowerCase().contains("electrs")) {
        _wallet.node!.isElectrs = true;
        unawaited(_wallet.node!.save());
        return _wallet.node!.isElectrs!;
      }

      // A real, definitive reply that just isn't electrs.
      _wallet.node!.isElectrs = false;
      unawaited(_wallet.node!.save());
      return _wallet.node!.isElectrs!;
    }

    return _wallet.node!.isElectrs ?? false;
  }

  Future<bool> getNodeSupportsSilentPayments() async {
    // As of today (august 2024), only ElectrumRS supports silent payments
    if (!(await _getNodeIsElectrs())) {
      return false;
    }

    if (_wallet.node == null) {
      return false;
    }

    try {
      final tweaksResponse = await _wallet.electrumClient.getTweaks(height: 0, timeout: 20000);

      if (tweaksResponse != null) {
        _wallet.node!.supportsSilentPayments = true;
        _wallet.node!.spMaxProtocolVersion = _extractMaxProtocolVersion(tweaksResponse);
        unawaited(_wallet.node!.save());
        return _wallet.node!.supportsSilentPayments!;
      }
    } on electrum.RequestFailedTimeoutException {
      return _wallet.node!.supportsSilentPayments ?? false;
    } catch (_) {}

    _wallet.node!.supportsSilentPayments = false;
    _wallet.node!.spMaxProtocolVersion = null;
    unawaited(_wallet.node!.save());
    return _wallet.node!.supportsSilentPayments!;
  }

  int? _extractMaxProtocolVersion(dynamic tweaksResponse) {
    try {
      final params = (tweaksResponse as Map)["params"] as List?;
      final resultParams = params?.first as Map?;
      final version = resultParams?["max_protocol_version"];
      return version is int ? version : null;
    } catch (_) {
      return null;
    }
  }
}
