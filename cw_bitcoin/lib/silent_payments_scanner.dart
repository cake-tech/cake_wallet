// Silent Payments scan-worker orchestration for one wallet - the
// counterpart to silent_payments_scan_worker.dart, which is everything that
// runs *inside* the worker isolates this class spawns and talks to. This
// file is the main-isolate side: it lives on the wallet object itself and
// reaches directly into its state, which is exactly what the worker file
// can't do (separate isolate, no shared memory - message passing only).
//
// This is a `part of` electrum_wallet.dart (not a normal import) so it keeps
// direct access to ElectrumWalletBase's private members without any
// renaming — Dart privacy is per-library, and a part file is the same
// library as the file it's `part of`. It was split out purely to keep
// electrum_wallet.dart's diff reviewable: `ElectrumWalletBase` holds one
// `_spScanner` instance of this class and delegates every scan-related call
// to it (`_wallet` here is that same wallet, reached back into for
// everything outside scan orchestration itself - transaction history,
// balance, addresses, node/electrumClient, walletInfo, syncStatus).
//
// MobX-annotated members (`@action`/`@observable`/`@computed`) can't live
// here - mobx's codegen (electrum_wallet.g.dart) wraps them via
// `super.member()` and needs them declared directly on `ElectrumWalletBase`.
// Those (`_setListeners`, `rescan()`, `startSync()`, `setSilentPaymentsScanning()`)
// stay on the wallet as thin delegating stubs; only their un-annotated
// implementation bodies live here.
part of "electrum_wallet.dart";

class SilentPaymentsScanner {
  SilentPaymentsScanner(this._wallet);

  final ElectrumWalletBase _wallet;

  // One handle per scan worker isolate (ADR-0001). Milestone 2 item 2:
  // `setListeners` spawns anywhere from 1 to `_scanWorkerCount`, each
  // covering its own disjoint sub-range of what's left to scan, repartitioned
  // fresh from `WalletInfoScanCoverage` every round (never cached across
  // rounds — that's what makes it safe for a round to leave some gaps
  // unassigned when there are more of them than workers).
  List<_ScanWorkerHandle> _scanWorkers = [];

  // Worker-count tiering (ADR-0005/ADR-0007): a v2-capable node gets the
  // bench-validated parallel fast path; anything legacy/unrecognized stays
  // at today's serial N=1 behavior. `override` (from the Rescan page's
  // worker-count slider) only ever applies within the v2 tier - a legacy
  // server still can't be forced into parallel scanning, since the tier
  // gating is about what the server has demonstrated it can handle, not
  // just a speed preference. Clamped defensively; the UI's own max is
  // Platform.numberOfProcessors, but this is a public-ish entry point.
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

  // BIP-352 Silent Payments mainnet activation height - confirmed directly
  // against the real electrs-tweaks server (a raw blockchain.tweaks.subscribe
  // request for height 0 comes back with data for height 823807, never
  // anything earlier - there is no tweak data before this height because SP
  // outputs simply can't exist before it). Used to exclude the
  // unconditionally-empty [scanFloor, activation) span from chunk
  // partitioning/progress math when scanFloor is below it (see
  // setListeners' gaps computation) - without this, a "scan from height 0"
  // request divided its full nominal range evenly across N workers the same
  // way regardless of how much of it was real, scannable chain - several
  // whole chunks landing entirely before this height would "complete"
  // instantly (the server has nothing there to hold them up), jumping the
  // reported percentage to ~85% in a few hundred milliseconds with zero
  // real scanning done. Mainnet-only; this wallet only ever scans SP on
  // BitcoinNetwork.mainnet (see ScanData.network in every receiver built
  // below).
  static const int _silentPaymentsActivationHeight = 823807;

  // Silent Payments scanning always talks to this dedicated tweaks server
  // (protocol v2), regardless of which node the user has selected for
  // everything else - regular wallet operations (balance, history, unspents,
  // broadcast, fee estimation, etc.) still go through `node`/`electrumClient`
  // exactly as before, unaffected by this. A server built for fast bulk
  // tweak scanning isn't a good fit for also serving general wallet queries
  // (see the scan worker connection setup below) - the two kinds of traffic
  // have very different shapes (scanning is chatty/bulk/historical;
  // everything else is latency-sensitive, one-off calls like a transaction
  // broadcast), and forcing them through the same connection means scan
  // traffic can starve out something as important as a broadcast reply of a
  // timely response. Splitting them into two independent connections means
  // neither competes with the other.
  //
  // NOTE: this host:port is the current dev/test server - replace with the
  // real production v2 tweaks-scanning endpoint before shipping.
  static const String _defaultScanServerHost = "192.168.100.89";
  static const int _defaultScanServerPort = 50005;
  static final ScanNode _defaultScanNode = ScanNode(
    Uri.parse("tcp://$_defaultScanServerHost:$_defaultScanServerPort"),
    useSSL: false,
  );
  // The dedicated scan server is always this version - no per-node
  // negotiation needed (see _defaultScanNode's doc comment above).
  static const int _defaultScanProtocolVersion = 2;

  // Guards against two overlapping `setListeners` calls (it's invoked
  // without awaiting its own Future, and per ADR-0010's own text can be
  // triggered by every chain-tip update) racing on `_scanWorkers`: the
  // cooperative `stopScanWorkers()` await below can take up to 5s, during
  // which a second, newer call could already have spawned and registered
  // its own worker. Without this check, the older call's late assignment
  // would overwrite `_scanWorkers` and orphan the newer worker — leaking
  // its connection, command port, and native scan sessions permanently.
  int _scanWorkerGeneration = 0;

  // Tracks whether a `setListeners` call is currently in flight (from the
  // moment it's kicked off to the moment it settles), incremented/decremented
  // around the call site rather than inside `setListeners` itself so this
  // doesn't require touching its many existing return paths. Used only to
  // let the *automatic* periodic re-verify in `maybeReverify` (a low-priority
  // housekeeping check) defer to any already-in-flight call instead of
  // racing it — a real user-initiated rescan silently got cancelled this
  // way (its `setListeners` call was still awaiting `stopScanWorkers()`
  // when the periodic re-verify's own call finished that same await first,
  // bumped `_scanWorkerGeneration` past the rescan's, and the generation
  // check above evicted the rescan instead of the low-priority check).
  int _pendingSetListenersCalls = 0;

  // Which worker indices (this round) have finished their own sub-range —
  // tracked so the wallet only reports `SyncedSyncStatus`/`SyncedTipSyncStatus`
  // once every worker is done, not just the one whose message happened to
  // arrive last. Cleared at the top of each `setListeners` round, right
  // after the generation check (a superseded round must never clear the
  // live round's set).
  final Set<int> _doneWorkerIndices = {};

  // Coalesced checkpoint writer (ADR-0011): a scan worker reports progress
  // on every block, but `restoreHeight`'s `save()` rewrites the whole
  // `WalletInfo` row, and each flush also does a `WalletInfoScanCoverage`
  // read-merge-write — neither should happen per block. Each
  // `_ScanWorkerHandle` carries its own `pendingCheckpointHeight`/
  // `checkpointBaseline`/`historical` (N workers scanning disjoint ranges,
  // possibly under different job semantics for the same round in principle,
  // must not share one scalar — that was fine at N=1 but silently wrong at
  // N>1, since two workers' reported heights would otherwise overwrite one
  // shared baseline instead of each tracking its own). One shared timer
  // still does the actual flush, iterating every worker's pending height in
  // a single tick.
  Timer? _checkpointFlushTimer;
  // `Timer.periodic` doesn't await its callback, and `_flushCheckpoint`
  // does 2+ DB round trips per worker — a tick can fire again before the
  // previous flush's `checkpointBaseline = target` writes have all run,
  // reading a stale baseline and writing an overlapping/wrong coverage
  // range. `_flushCheckpoint` serializes every call through this tail
  // future instead of dropping one when another is already running -
  // confirmed a dropped-tick guard here is NOT harmless despite the old
  // assumption that "the next tick picks up the pending height anyway":
  // `stopScanWorkers()` (called at the start of every `setListeners`
  // round, and right when a round's last worker naturally finishes)
  // awaits exactly one `_flushCheckpoint()` call and then immediately
  // wipes `_scanWorkers` - if that one call happened to overlap an
  // already-in-flight flush and silently no-op'd, the just-finished
  // round's final progress was discarded for good, with no later tick
  // left to pick it up. Device-confirmed causing "always scan"/tip-follow
  // to restart from a much older height than the scan had actually just
  // reached. Serializing instead of dropping means every call's own logic
  // genuinely runs (reading `_scanWorkers` fresh at its actual turn, not
  // at enqueue time), so a caller that awaits it is guaranteed the latest
  // pending progress was persisted before it proceeds.
  Future<void> _checkpointFlushQueue = Future.value();
  static const _checkpointFlushInterval = Duration(milliseconds: 1500);

  StreamSubscription<dynamic>? _receiveStream;

  // Periodic re-verify cadence (see maybeReverify below), owned here rather
  // than on the wallet since it's pure scan-reverify bookkeeping.
  DateTime? _lastSilentPaymentsScan;
  static const Duration _silentPaymentsScanDelay = Duration(minutes: 1);

  /// Cancels the receive-port subscription. Called whenever the wallet tears
  /// down or replaces its connection (close(), connectToNode(),
  /// _performFullReconnection()) - the scan workers' own isolates aren't
  /// killed here (that's stopScanWorkers()'s job); this only stops listening
  /// to whatever messages they're still sending.
  Future<void> dispose() async {
    await _receiveStream?.cancel();
  }

  /// The user-initiated "scan from height H" entry point - serves both the
  /// Rescan page ("from height H" should mean literally that regardless of
  /// what's already covered - the default `ignoreExistingCoverage: true`)
  /// and "Resume scanning" (which wants the opposite: skip whatever's
  /// already covered and only fill the real gaps, same as passive
  /// tip-follow - pass `ignoreExistingCoverage: false`). See
  /// setListeners' `ignoreExistingCoverage` doc comment for the full
  /// rationale. Deliberately fire-and-forget, same as `setListeners` itself
  /// is everywhere else - a caller awaiting `rescan()` (the base
  /// `WalletBase.rescan()` contract is used generically across wallet
  /// types, and at least one caller does await it) must get back almost
  /// immediately, not block for the whole scan's duration.
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

    // `_pendingSetListenersCalls` alone only covers setListeners' brief
    // async *setup* (compute chainTip/historical mode/coverage, spawn
    // workers) - it decrements the moment that returns, which is almost
    // immediately, long before the workers it just spawned are actually
    // done scanning. Confirmed causing exactly the race this guard exists
    // to prevent: a user-initiated rescan's 8 workers were still several
    // minutes into real, in-progress scanning (their own baseline had
    // already advanced well past their starting height) when this periodic
    // re-verify's own `setListeners` call - seeing `_pendingSetListenersCalls
    // == 0` because the rescan's setup phase had long since returned - went
    // ahead anyway, killed all 8 workers via the ordinary supersede-and-
    // respawn path, and replaced them with its own single-worker re-check.
    // `hasActiveWorkers` closes that gap by checking for scan workers that
    // are genuinely still not done (`_scanWorkers` itself is a bad proxy for
    // this alone - it's never cleared on a round's own natural completion,
    // only when a *new* round supersedes it, so an all-done round would
    // wrongly block every future re-verify forever without also checking
    // `_doneWorkerIndices`).
    final hasActiveWorkers = _scanWorkers.any((w) => !_doneWorkerIndices.contains(w.workerIndex));
    if (_pendingSetListenersCalls > 0 || hasActiveWorkers) {
      // A real scan (user-initiated, or otherwise) is already in flight —
      // this periodic re-verify is only housekeeping (confirming
      // already-found payments haven't been reorged out), not urgent, and
      // racing it against a real scan can cancel that scan outright (see
      // _pendingSetListenersCalls' doc comment). Skip this cycle; it retries
      // again in _silentPaymentsScanDelay.
      return;
    }

    _pendingSetListenersCalls++;
    unawaited(
      setListeners(_wallet.walletInfo.restoreHeight, rescanHeights: rescanHeights)
          .whenComplete(() => _pendingSetListenersCalls--),
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

    // `chainTip > 0` guards against a real, observed false-positive: right
    // after switching nodes (or on first connect), the regular connection
    // hasn't completed its own first chain-tip lookup yet, so
    // `getUpdatedChainTip()` falls back to its `currentChainTip ?? 0`
    // placeholder - a genuinely unknown tip, not "already at height 0". A
    // rescan-from-genesis request (`height == 0`, e.g. the Rescan page's
    // "scan from block 0") would otherwise satisfy `chainTip == height`
    // against that placeholder and get silently treated as "nothing to
    // scan, already Synced" without ever actually querying/scanning
    // anything - confirmed happening exactly this way (rescan() called,
    // chainTip=0, ABORTED, SYNC_STATUS_CHANGE: Synced, zero workers
    // spawned). A real, legitimate "nothing new to scan" case always has
    // both sides at some genuine positive block height, never 0.
    if (chainTip == height && chainTip > 0) {
      _wallet.syncStatus = SyncedSyncStatus();
      return;
    }

    // A genuinely unknown chain tip (regular node not connected yet, or its
    // connection just failed outright - confirmed via a real device log
    // showing `SocketException: Connection timed out` right after this same
    // wallet was opened) must never be silently treated as "nothing to
    // scan". Left unguarded, the branch below sets
    // `scanCeiling = chainTip` (0), which then always computes an empty
    // gap/chunk list against any `scanFloor > 0` and reports a misleading
    // "already fully covered" abort - a user-initiated rescan (e.g. from the
    // Rescan page) silently does nothing and there's no automatic retry for
    // it afterwards (unlike the periodic tip-follow path, which gets
    // another chance on the next chain-tip event), so the request is simply
    // lost with no visible sign anything went wrong. Surface it as a real
    // connection problem instead.
    if (chainTip <= 0) {
      if (shouldUpdateSyncStatus) {
        _wallet.syncStatus = LostConnectionSyncStatus();
      }
      return;
    }

    if (shouldUpdateSyncStatus) {
      _wallet.syncStatus = AttemptingScanSyncStatus();
    }

    // Cooperative shutdown (ADR-0010): let any existing workers tear down
    // their own connection/session before we replace them, instead of hard
    // `Isolate.kill`ing them. Must happen before `_receiveStream` is
    // cancelled below — an outgoing worker's `WorkerStopped` ack still
    // arrives on the *current* receive port.
    //
    // This await can take up to 5s, and `setListeners` is called without
    // being awaited by at least one caller and (per ADR-0010) on every
    // chain-tip update — so a second, newer call can race in and finish
    // spawning its own workers before this one resumes. The generation
    // check below detects that and bails out instead of overwriting
    // `_scanWorkers` with now-superseded workers, which would orphan the
    // newer ones (leaked connections, command ports, and native sessions).
    final generation = ++_scanWorkerGeneration;
    await stopScanWorkers();
    if (generation != _scanWorkerGeneration) {
      return;
    }

    final historical = historicalModeOverride ??
        await _resolveHistoricalMode(height, chainTip, isForcedRescan);
    if (generation != _scanWorkerGeneration) {
      return;
    }
    // `height` is a snapshot the caller took before this call - and, for
    // the resumable (non-forced) path, possibly before `stopScanWorkers`
    // just above had a chance to flush and advance `walletInfo.restoreHeight`
    // further. Confirmed causing exactly this: a caller (e.g.
    // `setSilentPaymentsScanning`'s "always scan" path, or the chain-tip
    // subscription) read `walletInfo.restoreHeight` right as a previous
    // round's tail progress was still unflushed, then this round
    // partitioned from that stale, much older height instead of the one
    // that flush was about to persist. An explicit forced rescan
    // (`ignoreExistingCoverage`) must still mean literally "from height H"
    // - only the resumable path re-clamps to whatever's now actually
    // persisted.
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
      // An explicit "scan from height H" request (rescan()'s own default;
      // "Resume scanning" opts out of it with ignoreExistingCoverage:
      // false) means H is the new, authoritative starting point - not
      // "keep whatever fragmented coverage already exists below/around H
      // and treat it as still-outstanding work to eventually backfill".
      // Confirmed causing exactly that: old coverage left over from an
      // earlier rescan that picked a different starting height (or from
      // this same wallet's original historical-activation-height scan)
      // sat around as disconnected islands, and every later resumable
      // round (Resume scanning, always-scan) felt obligated to go back
      // and fill the gaps between them before it would consider
      // `restoreHeight` caught up - even though the user had already
      // explicitly declared H as the point that matters, with everything
      // below it out of scope. Wiping the record here and setting
      // `restoreHeight` to H directly (not `max(old, H)` - an explicit
      // rescan is an override, not a floor) means this round's own
      // progress is the *entire* coverage record going forward: once it
      // reaches the tip, there are no other fragments left to be "stuck
      // behind".
      printV("[SP CHECKPOINT DEBUG] wiping coverage, new floor=$scanFloor");
      await WalletInfoScanCoverage.deleteByWalletInfoId(_wallet.walletInfo.internalId);
      _wallet.walletInfo.restoreHeight = scanFloor;
      _wallet.walletInfo.backfillTargetHeight = null;
      await _wallet.walletInfo.save();
    }

    final appDir = await getAppDir();
    final String debugLogPath = "${appDir.path}/logs/debug.log";
    // Scanning always targets the dedicated scan server (_defaultScanNode,
    // below), which is v2-capable by construction - unlike before this
    // connection split, there's no need to probe `node` (the user's
    // regular-ops node) for SP/protocol-version support just to configure
    // the scan workers. `getNodeSupportsSilentPayments()` still exists and
    // is still called independently by the UI's own "does your node support
    // SP" prompt (see lib/bitcoin/cw_bitcoin.dart) - that's unrelated to
    // scanning ability now, just informational about `node` itself.
    if (generation != _scanWorkerGeneration) {
      return;
    }

    // Range partitioning (ADR-0009, Milestone 2 item 2): only the plain
    // tip-follow/backfill path gets split across N workers. A
    // forced rescan (specific, individually-requested heights) or an
    // explicit single-height scan is a fixed, small job over an exact
    // range — always exactly one worker, unpartitioned, unaffected by
    // worker-count tiering.
    List<CoverageRange> chunks;
    if (isForcedRescan || isSingleScan) {
      chunks = [CoverageRange(scanFloor, scanCeiling)];
    } else {
      final workerCount =
          _scanWorkerCount(_defaultScanProtocolVersion, override: workerCountOverride);
      // ignoreExistingCoverage (rescan()'s own default, true - see its doc
      // comment; the Rescan page keeps that default, "Resume scanning"
      // opts out of it with false): when true, an explicit user-initiated
      // "scan from height H" request is authoritative and must actually
      // re-scan everything from H forward, not silently skip whatever an
      // earlier round already covered - that
      // used to make the reported "blocks left" reflect only the leftover
      // gaps from previous runs (confirmed: a fresh "scan from 0" request
      // reported a small fraction of the true 0..chainTip span as "left",
      // because most of it was already marked covered by earlier scans this
      // same session). Treating coverage as empty for this one round's gap
      // computation - rather than forcing a single unpartitioned chunk the
      // way isForcedRescan/isSingleScan do - means the full range still
      // gets properly split across workerCount workers via
      // partitionForWorkers below, instead of serializing it onto one.
      final coverage = ignoreExistingCoverage
          ? <WalletInfoScanCoverage>[]
          : await WalletInfoScanCoverage.selectList(
              _wallet.walletInfo.internalId,
              historical: historical,
            );
      final gapInputRanges =
          coverage.map((c) => CoverageRange(c.startHeight, c.endHeight)).toList();
      // The pre-activation span is unconditionally empty (see
      // _silentPaymentsActivationHeight's doc comment) regardless of
      // ignoreExistingCoverage - it's not "already scanned" progress that a
      // forced rescan should redo, it's a permanent fact that there's
      // nothing there to ever find. Folding it in here (rather than
      // persisting it to WalletInfoScanCoverage) keeps it correctly
      // excluded from every round's gap computation - so chunks/percentage
      // math are only ever computed over the genuinely scannable range -
      // without conflating "the wallet actually scanned this" with "there
      // was never anything to scan" in the real coverage record.
      if (scanFloor < _silentPaymentsActivationHeight) {
        final deadZoneEnd = _silentPaymentsActivationHeight - 1 < scanCeiling
            ? _silentPaymentsActivationHeight - 1
            : scanCeiling;
        gapInputRanges.add(CoverageRange(scanFloor, deadZoneEnd));
      }
      final gaps = uncoveredRanges(gapInputRanges, scanFloor, scanCeiling);
      chunks = partitionForWorkers(gaps, workerCount);

      if (chunks.isEmpty) {
        _wallet.syncStatus = SyncedSyncStatus();
        return;
      }
    }

    await _receiveStream?.cancel();
    // `WalletInfoScanCoverage.selectList` above and `_receiveStream?.cancel()`
    // just above are both real awaits a newer, unawaited `setListeners`
    // call (ADR-0010) can race ahead of and finish spawning its own workers
    // during — re-check before spawning so a superseded round never
    // installs its (now-orphaned) workers over a newer round's.
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
          // Deliberately NOT the wallet's configured `node` - every scan
          // worker always connects to the dedicated scan server instead (see
          // _defaultScanNode's doc comment above), regardless of what the
          // user selected for regular wallet operations. That split is the
          // whole point: this connection only ever carries scan traffic, so
          // it can never compete with (and starve out replies to) something
          // latency-sensitive like a transaction broadcast on `node`'s own
          // connection.
          node: _defaultScanNode,
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
              // The newUnspents diff below must run against the *previous*
              // unspents list, before it gets overwritten with tx.unspents -
              // computing it after used to always yield an empty diff
              // (comparing the new list against itself), so a re-scanned tx
              // that picked up additional outputs never bumped the balance
              // or updated the SP address record on this path at all.
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

                // existingTxInfo.unspents was already reassigned to the
                // fresh tx.unspents wholesale above, and newUnspents is
                // itself just a filtered subset of that same tx.unspents -
                // appending it again here used to duplicate every "new"
                // unspent in the list (confirmed: rescanning a height twice
                // left one real output present twice in existingTxInfo.unspents,
                // which then made it into unspentCoins twice too via
                // updateAllUnspents()'s tx-history loop below, producing a
                // coin the wallet could never spend - building a
                // transaction that references the same outpoint twice as
                // separate inputs is invalid). tx.unspents is already the
                // complete, authoritative unspent set for this tx as of
                // this scan pass, so no further append is needed or correct.

                final newAmount = newUnspents.length > 1
                    ? newUnspents.map((e) => e.value).reduce((value, unspent) => value + unspent)
                    : newUnspents[0].value;

                if (existingTxInfo.direction == TransactionDirection.incoming) {
                  existingTxInfo.amount += Money.fromInt(newAmount, _wallet.currency);
                }

                // Update balance record
                _wallet._bumpConfirmedBalance(Money.fromInt(newAmount, _wallet.currency));
              }

              // Persist-and-notify unconditionally, not only when this scan
              // pass turned up brand-new unspents. A re-scanned match whose
              // outputs are already fully known (e.g. a match already spent
              // before this wallet ever saw it, so tx.unspents/newUnspents
              // are both empty) still had its confirmations/height/date/etc
              // mutated above and the UI must still see that - confirmed via
              // device log a match with unspents=0 silently never reached
              // the transaction history list because this whole block used
              // to be skipped when newUnspents was empty. existingTxInfo is
              // the SAME object instance already stored in
              // transactionHistory.transactions (fetched above, then
              // mutated in place) - MobX's ObservableMap only reports a
              // change when the key is new or `value != oldValue`, and
              // since this is the identical reference with no operator==
              // override, that check is always false, so addOne() alone
              // would silently be a no-op (confirmed against mobx's own
              // ObservableMap source) and no Observer watching
              // transactions/.values would ever rebuild - the UI only ever
              // picked this up after an app restart, which re-reads fresh
              // object instances from disk. Removing the key first forces
              // the map back into its "add" branch, which unconditionally
              // reports the change.
              _wallet.transactionHistory.transactions.remove(txid);
              _wallet.transactionHistory.addOne(existingTxInfo);
              await _wallet.save();
            } else {
              // else: First time seeing this TX after scanning
              tx.unspents!.forEach(_wallet._updateSilentAddressRecord);

              // Add new TX record
              _wallet.transactionHistory.addMany(message);

              // Bumped by the sum of tx.unspents (currently-spendable
              // outputs only), NOT tx.amount - tx.amount is now the full
              // historical received total regardless of spent status (see
              // processTweaksV2Block's own doc comment), so a tx rediscovered
              // on a fresh/restored wallet that already spent some or all of
              // its outputs must still get an archival history entry
              // without the now-nonexistent spent portion inflating the
              // live balance.
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
          _checkpointFlushTimer ??=
              Timer.periodic(_checkpointFlushInterval, (_) => _flushCheckpoint());
        }

        final allWorkersDone = isWorkerDone && _doneWorkerIndices.length == _scanWorkers.length;

        if (shouldUpdateSyncStatus) {
          if (message.syncStatus is SyncingSyncStatus) {
            // Each worker only knows its own slice's progress (ADR-0009's
            // range partitioning) — forwarding that local number directly
            // used to make the shared status (and the ETA history it
            // feeds) bounce between N unrelated series as workers
            // interleave their messages, which is why the bar never
            // "filled" and the ETA never converged. Recompute one true
            // wallet-wide number across every active worker instead.
            _wallet.syncStatus = _aggregateScanProgress();
          } else if (isWorkerDone && !allWorkersDone) {
            // Only some of this round's workers have finished their own
            // sub-range so far — the wallet as a whole isn't synced yet
            // (ADR-0009: N workers' progress doesn't compose into "done"
            // until every one of them reports done). Reflect the
            // remaining workers' combined progress rather than freezing
            // the display on this one worker's last update.
            _wallet.syncStatus = _aggregateScanProgress();
          } else if (!allWorkersDone) {
            // Any other status this round doesn't have a more specific
            // handler for (e.g. LostConnectionSyncStatus,
            // UnsupportedSyncStatus) - forward as-is. The "every worker in
            // this round just finished" case is handled below instead,
            // once the flush has run.
            _wallet.syncStatus = message.syncStatus;
          }
        }

        if (allWorkersDone) {
          // Every worker in this round has now genuinely finished (not
          // superseded/stopped - naturally reached the tip and settled into
          // tip-follow). Flush right away instead of leaving this round's
          // final progress to the next `_checkpointFlushInterval` tick:
          // confirmed a caller reading `walletInfo.restoreHeight` again very
          // soon after (e.g. toggling "always scan" moments after a manual
          // scan reports done) can otherwise still see the pre-completion
          // value and restart from a much older height than the scan had
          // actually just reached.
          await _flushCheckpoint();

          if (shouldUpdateSyncStatus) {
            // Deliberately NOT `message.syncStatus` here (that's just
            // whichever single worker's own SyncedTip/Synced happened to
            // be the last message to arrive - reporting that as the
            // wallet-wide status was confirmed misleading: with N>1
            // workers scanning disjoint chunks, one worker finishing its
            // own slice doesn't mean the whole assigned range is
            // contiguously covered, e.g. when this round had more real
            // gaps than workers and only closed some of them (see
            // partitionForWorkers' own doc comment) - that showed up as a
            // "Synced Tip" claiming full completion while large gaps
            // below it were still genuinely unscanned). Base it on the
            // wallet's real, just-flushed, DB-verified progress instead.
            //
            // Also NOT `_aggregateScanProgress()` here - that only sums
            // *this round's own* `_scanWorkers`, so once every one of
            // them is done it always reports "0 blocks left" regardless of
            // whether the wallet is actually caught up - confirmed
            // showing a false "0" while `restoreHeight` sat far below
            // `scanCeiling` because this round only covered some of the
            // real gaps (more gaps than workers). Recompute the true
            // remaining span from the whole wallet's coverage instead.
            final restoreHeight = _wallet.walletInfo.restoreHeight;
            _wallet.syncStatus = restoreHeight >= scanCeiling
                ? SyncedTipSyncStatus(restoreHeight)
                : await _trueRemainingBlocks(restoreHeight, scanCeiling);
          }
        }
      }
    });
  }

  /// True wallet-wide scan progress across every currently active worker.
  /// Each worker only tracks its own slice (ADR-0009's range partitioning),
  /// so this sums every worker's own [rangeEnd] - remaining-blocks into one
  /// number, instead of the previous "last writer wins" approach where the
  /// shared status (and the ETA history its constructor feeds) got
  /// overwritten by whichever worker's message happened to arrive last.
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

  /// The wallet's true remaining work in `[floorHeight, ceilingHeight]`,
  /// read fresh from `WalletInfoScanCoverage` (unioned across modes, same
  /// as `_flushCheckpointOnce`'s recompute, with the same pre-activation
  /// dead-zone fold) - unlike `_aggregateScanProgress`, this isn't limited
  /// to whatever workers happen to be in `_scanWorkers` right now, so it
  /// stays honest even when the current round only ever covered some of
  /// the real gaps (more gaps than workers - see partitionForWorkers' own
  /// doc comment) and the rest are still waiting on a later round.
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
    final blocksLeft =
        gaps.fold<int>(0, (sum, gap) => sum + (gap.endHeight - gap.startHeight + 1));
    final totalSpan = ceilingHeight - floorHeight + 1;
    final rawPtc = 1.0 - (blocksLeft / totalSpan);
    final ptc = rawPtc < 0.0 ? 0.0 : (rawPtc > 1.0 ? 1.0 : rawPtc);
    return SyncingSyncStatus(blocksLeft, ptc);
  }

  /// Cooperatively stops every current scan worker (ADR-0010) and clears
  /// [_scanWorkers]. Safe to call when there are none running.
  Future<void> stopScanWorkers() async {
    // Cancelling the timer is independent of whether there's a worker to
    // stop below: the fire-and-forget caller (`unawaited(stopScanWorkers())`
    // on the `alwaysScan = false` path) clears `_scanWorkers` and then
    // awaits up to 5s inside `_stopWorker`. If `setListeners` runs during
    // that window, its own `stopScanWorkers()` call would see an
    // already-empty `_scanWorkers` and, if this cancel were below the early
    // return, never cancel the still-running timer. `_flushCheckpoint`
    // itself now also bails when `_scanWorkers` is empty, but that's safe
    // here specifically because the flush below runs *before* `_scanWorkers`
    // is cleared a few lines down — it's the cancel above, not the flush,
    // that has to be unconditional.
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

  /// Kills one worker immediately - no cooperative StopScanWorker/
  /// WorkerStopped handshake, no waiting around for it to ack. This used to
  /// send StopScanWorker and wait up to 5s for an ack before falling back to
  /// a hard kill (ADR-0010's original cooperative-shutdown design), but a
  /// superseded worker can legitimately take that entire 5s to actually stop
  /// (confirmed live: a worker still mid-resubscribe when the new request
  /// arrived kept running for over a second before even seeing the stop
  /// signal, and the *next* scan round's workers didn't spawn until the
  /// full ~5s grace period elapsed) - from the user's perspective that reads
  /// as "I asked for a new scan and the old one just kept going instead."
  /// Safe to kill outright: `_flushCheckpoint()` (called right before this
  /// in `stopScanWorkers`) persists every checkpoint this worker has
  /// already *reported* via message-passing, independent of whether the
  /// isolate itself is still alive - a hard kill only discards whatever
  /// in-flight progress hadn't been reported yet, which just means a little
  /// redundant re-scanning of that small tail next round (coverage-marking
  /// is idempotent), never a silently-missed match.
  Future<void> _stopWorker(_ScanWorkerHandle worker) async {
    final isolate = await worker.isolateFuture;
    isolate.kill(priority: Isolate.immediate);
  }

  /// Coalesced checkpoint flush (ADR-0011): extends each worker's own
  /// `WalletInfoScanCoverage` range and recomputes `restoreHeight` from the
  /// coverage set, at most every `_checkpointFlushInterval`, no matter how
  /// many `SyncResponse`s arrived in between. No-op if nothing is pending.
  ///
  /// Every call is chained onto `_checkpointFlushQueue` rather than run
  /// directly, so an overlapping call waits its turn and still genuinely
  /// executes (reading `_scanWorkers`/pending heights fresh at its own turn)
  /// instead of silently no-op'ing - see `_checkpointFlushQueue`'s own doc
  /// comment for why a dropped flush here is a real data-loss bug, not a
  /// harmless skip.
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

    // Every worker spawned together in one `setListeners` round shares
    // the same historical decision (ADR-0004/ADR-0013) — a backfill job
    // or a plain tip-follow is decided once per round, not per-worker.
    final roundHistorical = _scanWorkers.first.historical;

    printV(
      "[SP CHECKPOINT DEBUG] flush start: restoreHeight(pre)=${_wallet.walletInfo.restoreHeight} "
      "pending=${pending.map((w) => '#${w.workerIndex}[${w.checkpointBaseline}->${w.pendingCheckpointHeight}]hist=${w.historical}').join(', ')}",
    );

    for (final worker in pending) {
      final target = worker.pendingCheckpointHeight!;
      worker.pendingCheckpointHeight = null;

      // Strict `>` alone missed a real edge case: a worker whose entire
      // assigned range is exactly one block (rangeStart == rangeEnd, e.g.
      // exactly one new block arrived while the wallet was fully caught
      // up) reports its completion at `target == checkpointBaseline`
      // (both equal rangeStart) - `target > checkpointBaseline` is false,
      // so that single block never got marked covered at all, and
      // `restoreHeight` stayed stuck reporting "1 block left" forever.
      // Only relax to `>=` once this worker is confirmed done
      // (_doneWorkerIndices) - its `target` is then a genuine completion
      // height, safe to treat as covered even when equal to the start.
      // For a still-in-progress worker, `target` could just be its
      // opening "starting scan" report at its own rangeStart - nothing
      // has actually been verified there yet, so the strict `>` still
      // applies to avoid marking a not-yet-scanned height as covered.
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

    // Recompute the resumable prefix from the coverage set instead of
    // trusting any single worker's own reported height (ADR-0009): with
    // N>1 workers completing their sub-ranges out of order, no single
    // report alone guarantees "everything below this is scanned" the way
    // it did at N=1 — `restoreHeight` has to mean the same thing
    // regardless of worker count.
    //
    // Deliberately NOT filtered to `roundHistorical`: `restoreHeight` is a
    // single, mode-agnostic "how far forward has scanning gotten at all"
    // cursor - a range scanned non-historically still means new incoming
    // payments were checked there, it just lacks spent-output data (that
    // distinction is exactly what `WalletInfoScanCoverage.historical`
    // exists to track separately, per-range, for whoever needs to know
    // whether a given height still needs a historical pass). Filtering
    // this recompute to one mode used to leave `restoreHeight` stuck
    // below progress genuinely made under the other mode - confirmed:
    // toggling "always scan" (forced historical) right after a manual
    // "Resume scanning"/Rescan (non-historical) restarted from a stale,
    // much older height instead of picking up from the tip that manual
    // scan had already reached. Combining both modes here fixes that
    // while leaving the per-round gap computation in `setListeners`
    // (which legitimately must stay mode-specific - a range only ever
    // covered non-historically genuinely still needs a historical pass)
    // untouched.
    final coverage = await WalletInfoScanCoverage.selectList(_wallet.walletInfo.internalId);
    final ranges = coverage.map((c) => CoverageRange(c.startHeight, c.endHeight)).toList();

    // Same pre-activation dead-zone fold `setListeners`' own gap computation
    // does (see `_silentPaymentsActivationHeight`'s doc comment) - and for
    // the same reason: that zone is deliberately never written to
    // `WalletInfoScanCoverage` (it's not real scanned progress, just a
    // permanent "nothing was ever there" fact), so without folding it in
    // here too, `highestContiguouslyCoveredFrom` below required real
    // coverage starting at or before `restoreHeight` itself. For a wallet
    // whose `restoreHeight` sits below the activation height (e.g. restored
    // from height 0), that requirement could never be satisfied no matter
    // how much real coverage existed above the activation height -
    // confirmed by device logs showing `restoreHeight` permanently stuck at
    // 0 (recomputed=-1) across many completed scan rounds, which is what
    // actually caused every round to restart scanning the whole
    // [activationHeight, chainTip] span from scratch - not a stale-height
    // bug as earlier fixes here assumed, but this recompute never being
    // able to leave 0 in the first place.
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
      if (roundHistorical &&
          _wallet.walletInfo.backfillTargetHeight != null &&
          recomputed >= _wallet.walletInfo.backfillTargetHeight!) {
        // Backfill job complete (ADR-0004/ADR-0013): the historical range
        // up to its frozen target is now contiguously covered. Clear the
        // target so the next `setListeners` call falls back to plain
        // non-historical tip-follow instead of perpetually treating a
        // finished job as still in progress.
        _wallet.walletInfo.backfillTargetHeight = null;
      }
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

  /// Decides whether the upcoming scan should run with `historicalMode:
  /// true` (ADR-0004), and — only for a genuinely fresh wallet — starts a
  /// new backfill job by freezing `walletInfo.backfillTargetHeight` to the
  /// current chain tip. Only consulted when `setListeners`'s caller didn't
  /// pass an explicit `historicalModeOverride` (the Rescan page's toggle) —
  /// an override always wins and this is skipped entirely, including its
  /// backfill-job side effect.
  ///
  /// [isForcedRescan] (`rescanHeights` given) is always historical,
  /// unchanged from before this item, and never starts a backfill job of
  /// its own.
  ///
  /// "Fresh wallet" requires no `WalletInfoScanCoverage` row yet and no
  /// transaction history yet. A wallet that already has coverage or
  /// history — from an earlier session, or one that predates this feature
  /// entirely — is left alone.
  ///
  /// Note: because `setListeners` already returns early when `chainTip ==
  /// height`, this is never evaluated at the literal moment of wallet
  /// creation for a wallet created at the current tip — only on the first
  /// call where the tip has since moved past `height`. In practice this
  /// still lands on the wallet's first real scan, just not at t=0.
  Future<bool> _resolveHistoricalMode(int height, int chainTip, bool isForcedRescan) async {
    if (isForcedRescan) {
      return true;
    }

    if (_wallet.walletInfo.backfillTargetHeight == null &&
        chainTip > height &&
        _wallet.transactionHistory.transactions.isEmpty) {
      final existingCoverage =
          await WalletInfoScanCoverage.selectList(_wallet.walletInfo.internalId);
      if (existingCoverage.isEmpty) {
        _wallet.walletInfo.backfillTargetHeight = chainTip;
        await _wallet.walletInfo.save();
      }
    }

    // Forced to always scan historically (requests spent-output data on
    // every round, not just forced rescans/backfill) - the
    // caught-up-to-tip/tip-follow bookkeeping above (backfillTargetHeight)
    // is left in place for its coverage side effects, it just no longer
    // gates the return value below.
    return true;
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

    // An empty response here is indistinguishable from "the socket wasn't
    // connected right now" — electrum.dart's call() returns null instantly
    // rather than erroring when !isConnected, so this isn't a real answer
    // from the server. Overwriting a previously-confirmed electrs node
    // with false here fed straight into getNodeSupportsSilentPayments
    // always short-circuiting to false, popping the "switch node" dialog
    // for a node that IS electrs, just momentarily unreachable (this test
    // node's connection has been dying every ~10-30s). Keep whatever we
    // already knew instead of clobbering a good result with an
    // inconclusive one.
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
      // A short default timeout here made this probe an easy false
      // negative under this test node's connection instability (the same
      // reason ping() got a longer timeout — see its comment): a real
      // reply queued behind other in-flight traffic long enough to still
      // arrive, just not within 5s.
      final tweaksResponse = await _wallet.electrumClient.getTweaks(height: 0, timeout: 20000);

      if (tweaksResponse != null) {
        _wallet.node!.supportsSilentPayments = true;
        // Piggybacked capability/version discovery: every tweaks_subscribe
        // RPC result carries max_protocol_version regardless of what
        // protocol_version was requested (see electrs-tweaks's
        // doc/tweaks_v2_protocol.md §1/§4). Absent (older server) means
        // JSON-only — leave null, callers treat null as version 1.
        _wallet.node!.spMaxProtocolVersion = _extractMaxProtocolVersion(tweaksResponse);
        unawaited(_wallet.node!.save());
        return _wallet.node!.supportsSilentPayments!;
      }
    } on electrum.RequestFailedTimeoutException {
      // A timeout is inconclusive, not a negative result — this used to
      // overwrite (and persist) a previously *confirmed* v2-capable node
      // with supportsSilentPayments=false/spMaxProtocolVersion=null just
      // because this one probe attempt didn't get a reply in time under
      // this test node's connection instability. That's exactly what was
      // popping the "switch to a v2 node" dialog for a node that DOES
      // support v2 — every rescan attempt re-probes fresh (see
      // getNodeIsElectrsSPEnabled), and a single unlucky timeout was
      // enough to poison it for every subsequent attempt too, since the
      // false result got saved to disk. Leave whatever we already knew
      // about this node alone instead of clobbering a good result with an
      // inconclusive one.
      return _wallet.node!.supportsSilentPayments ?? false;
    } catch (_) {}

    _wallet.node!.supportsSilentPayments = false;
    _wallet.node!.spMaxProtocolVersion = null;
    unawaited(_wallet.node!.save());
    return _wallet.node!.supportsSilentPayments!;
  }

  /// Extracts `max_protocol_version` from a `blockchain.tweaks.subscribe`
  /// RPC result (not a push notification — see electrs-tweaks's
  /// doc/tweaks_v2_protocol.md §4 for why the two are shaped differently).
  /// Returns null for a legacy server that doesn't advertise it, or any
  /// unexpected shape — never throws.
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
