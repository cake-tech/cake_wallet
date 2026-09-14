// Silent Payments scan-worker isolate - the counterpart to
// silent_payments_scanner.dart's SilentPaymentsScanner, which spawns these
// workers (via Isolate.spawn(_handleScanSilentPayments, ...)) and orchestrates
// them from the main isolate. Split into its own file for the same
// reviewability reason as that one, but along a different boundary: this is
// every top-level declaration that runs *inside* a spawned worker isolate -
// its own memory, no access to the wallet object at all, communicating with
// the main isolate only via SendPort/ReceivePort message passing. It never
// calls back into ElectrumWalletBase or SilentPaymentsScanner directly.
//
// This is a `part of` electrum_wallet.dart (not a normal import) so it keeps
// access to ElectrumWalletBase's private members without any renaming -
// Dart privacy is per-library, and a part file is the same library as the
// file it's `part of`.
part of "electrum_wallet.dart";

class ScanNode {
  ScanNode(this.uri, {required this.useSSL});
  final Uri uri;
  final bool? useSSL;
}

/// Main-isolate-side handle for one scan worker isolate, covering
/// `[rangeStart, rangeEnd]` under [historical] mode (both frozen for this
/// worker's whole life — a new range/mode means a new round, not a mutation
/// of this handle). [commandPort] is null until the worker's
/// [ScanWorkerReady] handshake arrives; a stop request before that point has
/// no cooperative channel to use and falls back to a hard kill immediately
/// (see [ElectrumWalletBase._stopWorker]).
class _ScanWorkerHandle {
  _ScanWorkerHandle(
    this.workerIndex,
    this.isolateFuture, {
    required this.rangeStart,
    required this.rangeEnd,
    required this.historical,
  }) : checkpointBaseline = rangeStart;

  final int workerIndex;
  final Future<Isolate> isolateFuture;
  // This worker's fixed starting point for its whole life — kept separately
  // from checkpointBaseline (below), which is *not* fixed: it advances
  // forward on every coalesced checkpoint flush. _aggregateScanProgress
  // used to compute "how much total work this worker has" as
  // rangeEnd - checkpointBaseline, which shrinks every time a flush moves
  // checkpointBaseline forward — chasing its own numerator and pinning the
  // reported percentage near 0 forever, even while the absolute blocksLeft
  // count (and the ETA derived from its rate of change) genuinely
  // progressed correctly. rangeStart never moves, so it's the only safe
  // denominator anchor.
  final int rangeStart;
  final int rangeEnd;
  final bool historical;
  SendPort? commandPort;
  final Completer<void> stoppedCompleter = Completer<void>();

  // This worker's own coalesced-checkpoint state (ADR-0011) — kept
  // per-handle rather than as a wallet-level scalar because N>1 workers
  // scanning disjoint ranges each need their own baseline/pending height;
  // sharing one would let one worker's flush silently clobber another's.
  int checkpointBaseline;
  int? pendingCheckpointHeight;
}

class ScanData {
  ScanData({
    required this.workerIndex,
    required this.sendPort,
    required this.silentAddress,
    required this.masterHD,
    required this.height,
    required this.node,
    required this.network,
    required this.chainTip,
    required this.rangeEnd,
    required this.electrumClient,
    required this.transactionHistoryIds,
    required this.labels,
    required this.labelIndexes,
    required this.isSingleScan,
    required this.debugLogPath,
    required this.rescanHeights,
    required this.historical,
    required this.protocolVersion,
  });

  factory ScanData.fromHeight(ScanData scanData, int newHeight) => ScanData(
        workerIndex: scanData.workerIndex,
        sendPort: scanData.sendPort,
        silentAddress: scanData.silentAddress,
        masterHD: scanData.masterHD,
        height: newHeight,
        node: scanData.node,
        network: scanData.network,
        chainTip: scanData.chainTip,
        rangeEnd: scanData.rangeEnd,
        transactionHistoryIds: scanData.transactionHistoryIds,
        electrumClient: scanData.electrumClient,
        labels: scanData.labels,
        labelIndexes: scanData.labelIndexes,
        isSingleScan: scanData.isSingleScan,
        debugLogPath: scanData.debugLogPath,
        rescanHeights: scanData.rescanHeights,
        historical: scanData.historical,
        protocolVersion: scanData.protocolVersion,
      );

  /// Index into the round's `_scanWorkers` list (ADR-0001/item 2) — tags
  /// every message this worker sends on the shared [sendPort] so the main
  /// isolate can route it to the right `_ScanWorkerHandle` instead of
  /// assuming there's only ever one worker.
  final int workerIndex;
  final SendPort sendPort;
  final SilentPaymentOwner silentAddress;
  final Bip32Slip10Secp256k1 masterHD;
  final int height;
  final ScanNode? node;
  final BasedUtxoNetwork network;

  /// The wallet's true chain tip — used for confirmation counts and status
  /// display, never as this worker's own scan boundary (see [rangeEnd]).
  final int chainTip;
  final electrum.ElectrumClient electrumClient;
  final List<String> transactionHistoryIds;
  final Map<String, String> labels;
  final List<int> labelIndexes;
  final bool isSingleScan;
  final String debugLogPath;
  final List<int>? rescanHeights;

  /// The upper bound of *this worker's own* sub-range (ADR-0009, item 2) —
  /// distinct from [chainTip], the wallet-wide true tip. At N=1 (legacy
  /// node, forced rescan, or single-height scan) this equals [chainTip], so
  /// behavior is unchanged from before partitioning existed; at N>1 each
  /// worker gets its own, generally-lower `rangeEnd` from its partitioned
  /// chunk. Used for range-bound decisions (how many blocks are left to
  /// request, when to stop resubscribing, when this worker's own job is
  /// done) — never for confirmations/display, which always want the true
  /// [chainTip].
  final int rangeEnd;

  /// Whether this scan should include already-spent outputs
  /// (`historicalMode` on the wire request) — decided by the main isolate
  /// in `_setListeners`/`_resolveHistoricalMode` (ADR-0004/ADR-0013), not
  /// derived from `rescanHeights` inside the worker the way it used to be:
  /// a forced rescan is always historical, but so is a normal (non-rescan)
  /// call while a backfill job is in progress, which `rescanHeights` alone
  /// can't distinguish.
  final bool historical;

  /// The `blockchain.tweaks.subscribe` wire-protocol version to request -
  /// always `ElectrumWalletBase._defaultScanProtocolVersion` now that
  /// scanning targets a dedicated, known-v2-capable server instead of
  /// negotiating against whatever node the user selected (ADR-0020 still
  /// describes the wire formats themselves): `1` means the JSON path
  /// (`response.blockTweaks`), `>= 2` means the compact binary path
  /// (`response.tweaksV2Bytes` / `ScanSession.scanBlock`).
  final int protocolVersion;
}

class SyncResponse {
  SyncResponse(this.workerIndex, this.height, this.syncStatus);
  final int workerIndex;
  final int height;
  final SyncStatus syncStatus;
}

/// Sent by a scan worker on the shared data [SendPort] as the very first
/// message, before it connects to anything — handshakes the worker's own
/// command port back to the main isolate so [StopScanWorker] can reach it.
class ScanWorkerReady {
  ScanWorkerReady(this.workerIndex, this.commandPort);
  final int workerIndex;
  final SendPort commandPort;
}

/// Sent by the main isolate on a worker's command port to request a
/// cooperative shutdown (ADR-0010): the worker finishes tearing down its
/// own connection/session and sends [WorkerStopped] back, rather than being
/// hard-killed. Sent on that worker's own dedicated command port, so unlike
/// [ScanWorkerReady]/[WorkerStopped]/[SyncResponse] (all on the one shared
/// data port) it never needs a [workerIndex] to be routed correctly.
class StopScanWorker {
  const StopScanWorker();
}

/// Sent by a scan worker on the shared data [SendPort] once it has torn
/// down its connection/session in response to [StopScanWorker].
class WorkerStopped {
  const WorkerStopped(this.workerIndex);
  final int workerIndex;
}

Future<void> _handleScanSilentPayments(ScanData scanData) async {
  final shouldUpdateSyncStatus = scanData.rescanHeights == null || scanData.rescanHeights!.isEmpty;
  CakeTor.instance = await CakeTorInstance.getInstance();

  final node = scanData.node?.uri ?? Uri.parse("tcp://electrs.rafaelxmr.com:50005");

  void log(String message, LogLevel level) {
    printV(
      "[Scanning worker ${scanData.workerIndex}] $message",
      file: scanData.debugLogPath,
      level: level,
    );
  }

  // This worker's own monotonic "furthest confirmed height reported so far"
  // floor. Every resubscribe (noData branch, the "too large" retry, the
  // subscribe-error reconnect path, etc.) creates a new stream/listener
  // without explicitly closing whichever one preceded it — if the server or
  // client ever lets an older, already-superseded listener callback still
  // fire after a newer one already advanced further (confirmed via
  // _aggregateScanProgress's REGRESSION detector: a worker reported a
  // height *behind* its own already-flushed checkpointBaseline, which
  // should be structurally impossible), that stale callback used to be able
  // to report its own earlier height here, making the aggregated
  // wallet-wide "blocks left" figure jump backward even though real scan
  // progress never actually regressed. Clamping every outgoing height to
  // this worker's own high-water mark makes that impossible regardless of
  // which code path produced the stale report, without needing to hunt down
  // and fix every individual resubscribe call site's cleanup.
  var highestReportedHeight = scanData.height - 1;

  // Every message on the shared data `sendPort` gets tagged with this
  // worker's index (ADR-0001/item 2) so the main isolate can route it to
  // the right `_ScanWorkerHandle` instead of assuming there's only one.
  void sendSync(int height, SyncStatus status) {
    final clamped = height > highestReportedHeight ? height : highestReportedHeight;
    highestReportedHeight = clamped;
    scanData.sendPort.send(SyncResponse(scanData.workerIndex, clamped, status));
  }

  // Cooperative shutdown (ADR-0010): handshake our command port back to the
  // main isolate immediately, before connecting to anything, so a stop
  // request can never race an unhandshaked worker into a hard kill.
  final commandPort = ReceivePort();
  var stopRequested = false;
  ElectrumProvider? scanningClient;
  List<ScanSession> sessions = [];
  var cleanedUp = false;

  Future<void> cleanupAndAck() async {
    if (cleanedUp) {
      return;
    }
    cleanedUp = true;

    for (final session in sessions) {
      session.dispose();
    }
    // Closes the shared connection every in-flight/scheduled `scan()`
    // subscribe call for this worker was using, per ADR-0010.
    scanningClient?.rpc.disconnect();
    commandPort.close();
    scanData.sendPort.send(WorkerStopped(scanData.workerIndex));
  }

  scanData.sendPort.send(ScanWorkerReady(scanData.workerIndex, commandPort.sendPort));
  commandPort.listen((message) {
    if (message is StopScanWorker) {
      stopRequested = true;
      unawaited(cleanupAndAck());
    }
  });

  try {
    // if (scanData.shouldSwitchNodes) {
    // Non-final — a genuine subscribe error (below) rebuilds the
    // connection via reconnectClient() and reassigns this, which every
    // closure that captured `client` picks up automatically since Dart
    // closures share the enclosing variable's box rather than a snapshot.
    var client = await ElectrumProvider.connect(
      ElectrumTCPService.connect(node),
    );
    scanningClient = client;
    // }

    // The test node this worker talks to has shown its underlying TCP
    // connection dying every ~10-30s under load (observed via server-side
    // peer connect/disconnect churn correlated with client-side "SOCKET
    // CLOSED" events on the main wallet connection) — a real network-path
    // instability, not a one-off. `ElectrumTCPService.reconnect()` exists
    // upstream in bitcoin_base but is unused/broken (it discards the new
    // socket it creates), so without this, the very first such hiccup on
    // this worker's single persistent connection permanently kills
    // scanning: onSubscribeError below used to just report
    // LostConnectionSyncStatus and give up forever, since nothing else in
    // this isolate ever rebuilds the socket.
    Future<void> reconnectClient() async {
      try {
        scanningClient?.rpc.disconnect();
      } catch (_) {}
      client = await ElectrumProvider.connect(ElectrumTCPService.connect(node));
      scanningClient = client;
    }

    log("connected to ${node.toString()}", LogLevel.info);

    // Only the receiver matching this wallet's actual network is ever
    // reachable - a mainnet output can never tweak-match a testnet-derived
    // (m/352'/1'/...) key or vice versa (BIP-352's coin_type field is part
    // of the derivation). Building and scanning both unconditionally used
    // to cost a full second `session.scanBlock` call per block for every
    // single mainnet wallet (the overwhelming majority of users) for a
    // receiver that could never match - device-confirmed via
    // `receiver[0]`/`receiver[1]` both firing per block regardless of
    // network, and per-block scan time roughly halving once only the
    // applicable receiver is built.
    final receivers = [
      scanData.network == BitcoinNetwork.testnet
          ? Receiver(
              scanData.masterHD.derivePath(SILENT_PAYMENTS_SCAN_PATH_TESTNET).privateKey.toHex(),
              scanData.masterHD.derivePath(SILENT_PAYMENTS_SPEND_PATH_TESTNET).publicKey.toHex(),
              true,
              scanData.labelIndexes,
              scanData.labelIndexes.length,
            )
          : Receiver(
              scanData.silentAddress.b_scan.toHex(),
              scanData.silentAddress.B_spend.toHex(),
              false,
              scanData.labelIndexes,
              scanData.labelIndexes.length,
            ),
    ];

    log(
      "using receiver: b_scan: ${receivers[0].bScan}, b_spend: ${receivers[0].BSpend}, network: ${scanData.network.value}, labelIndexes: ${scanData.labelIndexes}",
      LogLevel.info,
    );

    // Persistent sp_scanner sessions (ADR-0001): one per receiver, built
    // once here and reused for every block this worker scans, instead of
    // the old stateless `scanOutputs` rebuilding its Secp256k1/Receiver
    // context on every single call.
    sessions = receivers.map(ScanSession.create).toList();

    /// Two-pass amount fetch (ADR-0015): `blockchain.tweaks.get` for one
    /// v2 match, since v2's compact stream deliberately omits amount/spend
    /// (`doc/tweaks_v2_protocol.md` §2). Retries with capped exponential
    /// backoff on a transient (connection-level) failure, indefinitely —
    /// by design this blocks the caller (and so blocks that height's range
    /// advancement) for as long as it takes, rather than leaving a
    /// scattered gap in the coverage set. A structural server error
    /// (`RPCError` — no tweak row, an ineligible vout) is NOT retried: it
    /// means this specific match can never resolve, so it's logged and
    /// dropped instead of wedging the worker on an unresolvable call
    /// forever.
    Future<ElectrumTweaksGetResponse?> fetchTweaksGetWithBackoff({
      required String txid,
      required int vout,
      required int height,
    }) async {
      var backoff = const Duration(seconds: 1);
      const maxBackoff = Duration(seconds: 30);

      while (true) {
        if (stopRequested) {
          return null;
        }
        try {
          return await client.request(ElectrumTweaksGet(txid: txid, vout: vout, height: height));
        } on RPCError catch (e) {
          log(
            "tweaks.get permanent failure, dropping match: txid: $txid, vout: $vout, height: $height: $e",
            LogLevel.error,
          );
          return null;
        } catch (e) {
          log(
            "tweaks.get transient failure, retrying in ${backoff.inSeconds}s: txid: $txid, vout: $vout, height: $height: $e",
            LogLevel.error,
          );
          await Future.delayed(backoff);
          if (backoff < maxBackoff) {
            backoff *= 2;
          }
        }
      }
    }

    Future<void> scan(int syncHeight, {required bool isSingleScan}) async {
      final int initialSyncHeight = syncHeight;

      // Some servers (e.g. electrs-tweaks in historical mode) reject a
      // tweaks.subscribe request outright once the range's outpoint count
      // exceeds a server-side spend-resolution cap, instead of just
      // streaming a smaller amount — this worker has no way to know that
      // cap in advance (it isn't advertised, and outpoint density varies
      // block to block), so it can only find out by being rejected and
      // shrinking. Once shrunk, stays shrunk for the rest of this worker's
      // range rather than repeatedly re-triggering the same rejection.
      int? _countCap;

      // Conservative starting guess for a still-undiscovered cap: asking for
      // the whole remaining range on the very first request (which could be
      // tens of thousands of blocks) means that request needs a full round
      // trip just to be told it's too large, then another for each halving
      // — and under a connection that dies every ~10-30s (observed on this
      // test node), a large in-flight request is exactly the kind that
      // rarely survives long enough to even get rejected, so the worker
      // just keeps reconnecting and resending the same oversized request
      // forever instead of ever discovering the real cap. 2000 blocks is
      // comfortably under the 25000-outpoint cap for typical density, so
      // the common case converges in one request instead of a dozen.
      const _initialCountGuess = 2000;

      int getCountToScanPerRequest(int syncHeight) {
        if (isSingleScan) {
          return 1;
        }

        // This worker's own range boundary (item 2), not the wallet-wide
        // true tip — at N=1 they're the same value.
        final amountLeft = scanData.rangeEnd - syncHeight + 1;
        final cap = _countCap ?? _initialCountGuess;
        return cap < amountLeft ? cap : amountLeft;
      }

      // subscribeAndListen, listenFn and onSubscribeError below are
      // mutually referential (a subscribe error retries via
      // subscribeAndListen, which listens with listenFn and
      // onSubscribeError again) — declared as late variables up front so
      // each closure can reference the others regardless of definition
      // order below, then assigned in the only order Dart's no-forward-
      // reference rule for local functions actually allows.
      late void Function(int height) subscribeAndListen;
      late void Function(Object error, StackTrace stackTrace) Function(int height) onSubscribeError;

      // Initial status UI update, send how many blocks in total to scan
      if (shouldUpdateSyncStatus) {
        sendSync(syncHeight, StartingScanSyncStatus(syncHeight));
      }

      final req = ElectrumTweaksSubscribe(
        height: syncHeight,
        count: getCountToScanPerRequest(syncHeight),
        historicalMode: scanData.historical,
        protocolVersion: scanData.protocolVersion >= 2 ? scanData.protocolVersion : null,
      );

      var _scanningStream = client.subscribe(req);

      log(
        "initial request: height: $syncHeight, count: ${getCountToScanPerRequest(syncHeight)}",
        LogLevel.info,
      );

      void endScanningSuccesfully() {
        if (isSingleScan) {
          sendSync(syncHeight, SyncedSyncStatus());
        } else {
          // This worker's own range boundary, not the wallet-wide true tip
          // (see `SyncingSyncStatus.fromHeightValues` below for why this is
          // a deliberate, documented rough edge at N>1 rather than a bug).
          sendSync(syncHeight, SyncedTipSyncStatus(scanData.rangeEnd));
        }

        _scanningStream?.close();
        _scanningStream = null;

        log(
          "ended: syncHeight: $syncHeight, rangeEnd: ${scanData.rangeEnd}, isSingleScan: ${isSingleScan}",
          LogLevel.info,
        );
      }

      /// v2 (compact binary) block handling — the counterpart to the v1
      /// `blockTweaks` loop below, for when `response.tweaksV2Bytes != null`.
      /// One `scanBlock` call per receiver session (mirroring v1's
      /// per-receiver `session.scan` loop), matches grouped by txid so one
      /// `ElectrumTransactionInfo` is sent per tx just like v1, and one
      /// `blockchain.tweaks.get` fetch per match to fill in the
      /// amount/spent fields v2 omits (ADR-0015).
      /// Returns `false` if cooperative shutdown (ADR-0010) interrupted
      /// processing before every match in this block was resolved — the
      /// caller must NOT advance `syncHeight`/mark this height covered in
      /// that case (ADR-0015: a height is never marked covered with an
      /// unresolved match; shutdown mid-fetch is exactly that, not a
      /// "give up and move on" case like a permanent per-match error is).
      Future<bool> processTweaksV2Block(List<int> blockBytes, int blockHeight) async {
        final bytes = Uint8List.fromList(blockBytes);
        final matchesByTxid = <String, List<Map<String, dynamic>>>{};

        for (var i = 0; i < sessions.length; i++) {
          final rawMatches = sessions[i].scanBlock(bytes);
          for (final raw in rawMatches) {
            final match = raw as Map<String, dynamic>;
            matchesByTxid
                .putIfAbsent(match["txid"] as String, () => [])
                .add({...match, "_receiverIndex": i});
          }
        }

        for (final entry in matchesByTxid.entries) {
          final txid = entry.key;
          final matches = entry.value;
          final matchHeight = matches.first["height"] as int;

          try {
            final txInfo = ElectrumTransactionInfo(
              WalletType.bitcoin,
              id: txid,
              height: matchHeight,
              amount: Money.zero(CryptoCurrency.btc),
              fee: Money.zero(CryptoCurrency.btc),
              direction: TransactionDirection.incoming,
              isReplaced: false,
              date: scanData.network == BitcoinNetwork.mainnet
                  ? getDateByBitcoinHeight(matchHeight)
                  : DateTime.now(),
              confirmations: scanData.chainTip - matchHeight + 1,
              isReceivedSilentPayment: true,
              isPending: false,
              unspents: [],
            );

            for (final match in matches) {
              final vout = match["vout"] as int;
              // Already reversed to conventional display-hex order by
              // sp_scanner's v2 decoder (verified by
              // scan_block_v2_test.dart's "must already be reversed"
              // assertion) — matches blockchain.tweaks.get's own txid
              // convention (doc/tweaks_v2_protocol.md §5), unlike the v2
              // *blob's* internal-order txid field (§2). Do not reverse
              // this again.
              final outputPubkey = match["output_pubkey"] as String;
              final label = match["label"] as String;
              final tweak = match["tweak"] as String;

              final fetched = await fetchTweaksGetWithBackoff(
                txid: txid,
                vout: vout,
                height: matchHeight,
              );

              if (stopRequested) {
                // Shutdown interrupted this fetch (or a prior one in this
                // same block) — abandon the whole block unresolved rather
                // than reporting a partial txInfo.
                return false;
              }
              if (fetched == null) {
                // Permanent per-match failure (RPCError — already logged
                // in fetchTweaksGetWithBackoff): NOT a transient fetch
                // failure, but a server self-inconsistency (this output
                // was just streamed as a match by tweaks.subscribe, yet
                // tweaks.get says no row exists for it). ADR-0015 requires
                // a height never be marked covered with an unresolved
                // match, so this blocks the same way shutdown does — the
                // wallet retries this height on its next restart rather
                // than silently losing the payment from view. This is a
                // deliberate hard stop, not a bug: a stuck scan sitting at
                // one fixed height in the debug log means exactly this.
                return false;
              }
              // Counted toward txInfo.amount regardless of current spent
              // status - that's the historical fact of what this tx
              // received, and is what lets a since-spent SP receive still
              // show up as an archival "Received" entry in tx history on a
              // fresh/historical rescan (confirmed missing before this fix:
              // this whole match used to be dropped outright via an early
              // `continue` below, so a wallet restored from seed and
              // re-scanning historically never saw a payment it had
              // already spent in an earlier session at all - not just
              // absent from balance, but invisible to history entirely).
              // Only a currently-unspent match gets a
              // BitcoinSilentPaymentsUnspent added to txInfo.unspents below
              // - that list is also what fetchBalances()/updateAllUnspents()
              // treat as "currently spendable", so a spent match must never
              // land there or it would inflate the balance/coin list with
              // funds that don't exist anymore.
              txInfo.amount += Money.fromInt(fetched.amount, txInfo.amount.currency);

              // Mirrors v1's `if (spent == null) unspents.add(...)`.
              if (fetched.spent) {
                continue;
              }

              final labelValue = label == "None" ? null : label;
              final receivingOutputAddress = ECPublic.fromHex(outputPubkey)
                  .toTaprootAddress(tweak: false)
                  .toAddress(scanData.network);

              final receivedAddressRecord = BitcoinSilentPaymentAddressRecord(
                receivingOutputAddress,
                index: 0,
                isHidden: false,
                isUsed: true,
                network: scanData.network,
                silentPaymentTweak: tweak,
                type: SegwitAddresType.p2tr,
                txCount: 1,
                balance: fetched.amount,
                // See the v1 branch's equivalent for why this is keyed off
                // the wallet's actual network rather than receiver index.
                spendDerivationPath: scanData.network == BitcoinNetwork.testnet
                    ? SILENT_PAYMENTS_SPEND_PATH_TESTNET
                    : SILENT_PAYMENTS_SPEND_PATH,
              );

              final unspent = BitcoinSilentPaymentsUnspent(
                receivedAddressRecord,
                txid,
                fetched.amount,
                vout,
                silentPaymentTweak: tweak,
                silentPaymentLabel: labelValue,
              );

              txInfo.unspents!.add(unspent);
            }

            log(
              "FOUND (v2): txid: $txid, matches: ${matches.length}, height: $matchHeight",
              LogLevel.info,
            );
            scanData.sendPort.send({txInfo.id: txInfo});
          } catch (e, stacktrace) {
            if (shouldUpdateSyncStatus) {
              sendSync(syncHeight, LostConnectionSyncStatus());
            }

            log(stacktrace.toString(), LogLevel.error);
            log(e.toString(), LogLevel.error);
          }
        }

        return true;
      }

      // Forward-declared so resubscribeToNextHeight (below) can close over
      // it before listenFn itself is assigned further down - by the time
      // that closure actually runs (the stream emits again), listenFn is
      // guaranteed to already be set.
      late final void Function(Map<String, dynamic> event, ElectrumTweaksSubscribe req) listenFn;

      // `Stream.listen`'s callback is `void Function(T)`, not `Future
      // Function(T)` - the stream never awaits what `_processEvent` (below)
      // returns, so nothing stops it from starting the next block's
      // processing before the current one's finishes. Most blocks have no
      // match and return almost immediately, but a real match needs an
      // extra network round trip (`tweaks.get`, in processTweaksV2Block) to
      // resolve amount/spent status - so a slow, match-bearing block can
      // still be mid-resolution while many faster, empty blocks after it
      // race ahead, advance `syncHeight`, and trigger the next resubscribe.
      // Device-confirmed: `resubscribing: nextHeight: 894500` was logged
      // BEFORE `FOUND ... height: 894343` even appeared - the match was
      // real and already in flight, just not finished, when the scan
      // reported that height as covered and moved on. It also explains the
      // syncHeight regressions the monotonic guard now defends against - a
      // fast block finishing after a slower earlier one already advanced
      // things further. Routing every event through this chain restores
      // one-at-a-time processing regardless of how many subscription
      // generations are involved.
      var _processingChain = Future<void>.value();

      // Shared by both the null-response and explicit-noData paths below:
      // move this worker on to the next unscanned height rather than
      // abandoning the rest of its assigned range.
      void resubscribeToNextHeight(ElectrumTweaksSubscribe req) {
        if (isSingleScan) {
          log("ending: isSingleScan", LogLevel.info);
          endScanningSuccesfully();
          return;
        }

        final nextHeight = syncHeight + 1;

        if (nextHeight <= scanData.rangeEnd && !stopRequested) {
          log(
            "resubscribing: nextHeight: $nextHeight, count: ${getCountToScanPerRequest(nextHeight)}",
            LogLevel.info,
          );

          // Close the previous subscription BEFORE creating the next one and
          // reassign `_scanningStream` to it. Without this, every "done"/null
          // ack left the old subscription open (never cancelled) while a
          // brand new one was created on top of it - both still wired to
          // `listenFn` and both still live on the same connection, each
          // independently pushing its own progress into the shared,
          // isolate-local `syncHeight`. Device evidence: `syncHeight` for a
          // single worker oscillating (e.g. 893005 -> 893499 -> 893255 ->
          // 893499) instead of climbing monotonically, and zero `FOUND`
          // lines despite hundreds of blocks nominally scanned - i.e. an
          // ever-growing swarm of duplicate overlapping subscriptions
          // re-requesting the same already-scanned window instead of one
          // subscription making real forward progress. Also pass the fresh
          // request object to `listenFn`, not the stale outer `req` - a
          // resubscribed worker must report its own current height/count.
          _scanningStream?.close();
          _scanningStream = null;

          final nextReq = ElectrumTweaksSubscribe(
            height: nextHeight,
            count: getCountToScanPerRequest(nextHeight),
            historicalMode: scanData.historical,
            protocolVersion: scanData.protocolVersion >= 2 ? scanData.protocolVersion : null,
          );
          final nextStream = client.subscribe(nextReq);

          if (nextStream != null) {
            _scanningStream = nextStream;
            nextStream.listen(
              (event) => listenFn(event, nextReq),
              onError: onSubscribeError(nextHeight),
            );
          } else {
            if (shouldUpdateSyncStatus) {
              sendSync(scanData.height, LostConnectionSyncStatus());
            }
          }
        }

        log(
          "ending: resubscribing: nextHeight: $nextHeight, count: ${getCountToScanPerRequest(nextHeight)}",
          LogLevel.info,
        );
      }

      Future<void> _processEvent(Map<String, dynamic> event, ElectrumTweaksSubscribe req) async {
        if (stopRequested) {
          // Cooperative shutdown in progress (ADR-0010) — don't process or
          // resubscribe further; `cleanupAndAck` already ran (or is
          // running) from the command-port listener.
          unawaited(_scanningStream?.close());
          _scanningStream = null;
          return;
        }

        final response = req.onResponse(event);

        if (response == null) {
          // ElectrumTweaksSubscribeResponse.fromJson returns null for a
          // terminal/ack-only message on this stream (its own doc comment:
          // "the *terminal* id-matched RPC result" branch) - this is not a
          // real failure, but the old code here treated it as one: log and
          // give up on this worker's ENTIRE remaining range, no
          // resubscribe. That silently stopped a worker partway through a
          // continuous range scan - device-confirmed via a match a range
          // scan never found, that a single targeted re-scan of that exact
          // height then found immediately (the height had never actually
          // been reached because an earlier terminal-ack message on this
          // same worker had already killed its listen loop). Resubscribing
          // here exactly like the explicit noData branch below fixes that.
          if (_scanningStream != null) {
            resubscribeToNextHeight(req);
          }
          return;
        }

        if (_scanningStream == null) {
          log(
            "ending: response = $response, stream = $_scanningStream",
            LogLevel.error,
          );
          return;
        }

        // is success or error msg
        final noData = response.message != null;

        if (noData) {
          resubscribeToNextHeight(req);
          return;
        }

        if (response.tweaksV2Bytes != null) {
          final v2Bytes = response.tweaksV2Bytes!;
          // Minimum valid blob is 5 bytes: u32 height + a 1-byte
          // CompactSize tx_count=0 (the empty-tail bookmark itself, §2's
          // smallest legal shape). Guard against a truncated/malformed
          // blob here instead of letting `ByteData.sublistView` throw
          // `RangeError` uncaught, which would kill listenFn's isolate
          // event loop rather than reporting `LostConnectionSyncStatus`
          // like every other failure path in this function does.
          if (v2Bytes.length < 5) {
            if (shouldUpdateSyncStatus) {
              sendSync(syncHeight, LostConnectionSyncStatus());
            }
            log("v2 blob too short to contain a height: ${v2Bytes.length} bytes", LogLevel.error);
            return;
          }

          // v2 responses don't populate `response.block` (it's hardcoded
          // to 0 — see ElectrumTweaksSubscribeResponse.fromJson's
          // tweaks_v2 branch); the height lives in the blob itself, as its
          // first 4 bytes (doc/tweaks_v2_protocol.md §2: `u32 height
          // little-endian`). This applies uniformly to a real block AND
          // the zero-tx empty-tail bookmark — neither is special-cased
          // (§2's "Empty-tail bookmark" note), so the height read here is
          // always valid once the length guard above passes.
          final tweakHeight =
              ByteData.sublistView(Uint8List.fromList(v2Bytes), 0, 4).getUint32(0, Endian.little);

          // Stale re-delivery guard: `_handleResponse`'s id-less-message
          // routing (bitcoin_base's electrum_tcp_service.dart/
          // electrum_ssl_service.dart) matches an incoming
          // `blockchain.tweaks.subscribe` push to whichever task is the
          // last-inserted entry for that method in `_tasks` - and
          // subscription tasks are never removed from `_tasks` once
          // superseded. A still-in-flight record (or the "done" ack) from a
          // window this worker has already moved past can therefore still
          // land on the CURRENT subscription's subject after resubscribing.
          // Device-confirmed: the same match got FOUND three times, and a
          // later window took ~4x longer than an equally-sized earlier one,
          // because the serialized queue (see the chaining around
          // `listenFn`/`_processEvent`) was dutifully re-processing these
          // stale re-deliveries in order instead of dropping them. This is
          // the same idempotence principle as the syncHeight-regression
          // guard below, applied earlier so a stale record doesn't even pay
          // for a session.scanBlock/tweaks.get pass.
          if (tweakHeight < syncHeight) {
            return;
          }

          // `rangeEnd`, not `chainTip`: at N>1 this is progress through
          // this worker's own slice, not the wallet as a whole. Each
          // worker's `SyncingSyncStatus` still overwrites the wallet's one
          // shared, last-writer-wins progress value — a known, accepted
          // rough edge (see `_setListeners`'s `SyncResponse` handling for
          // the "don't flash Synced early" half of this). Worth flagging
          // precisely for a future polish pass: `SyncingSyncStatus.
          // updateEtaHistory`'s `blockHistory` is a *static*, process-wide
          // map (sync_status.dart), so N workers each feeding their own
          // slice's `blocksLeft` into it mixes unrelated series into one
          // ETA — the fix there is a single feeder, not just averaging.
          final syncingStatus = isSingleScan
              ? SyncingSyncStatus(1, 0)
              : SyncingSyncStatus.fromHeightValues(
                  scanData.rangeEnd,
                  initialSyncHeight,
                  tweakHeight,
                );
          if (shouldUpdateSyncStatus) {
            sendSync(syncHeight, syncingStatus);
          }

          final completed = await processTweaksV2Block(v2Bytes, tweakHeight);
          if (!completed) {
            // Cooperative shutdown aborted mid-block (ADR-0010/ADR-0015):
            // do not advance syncHeight or mark this height reached — an
            // unresolved match must not be treated as covered. The
            // respawned worker re-scans from the last flushed checkpoint,
            // which still includes this height.
            return;
          }

          // Never let syncHeight regress. Device evidence: with two
          // subscriptions briefly alive on the same worker (the previous
          // one's "done" and the next one's real block data can still race
          // on the wire despite closing the old stream on resubscribe - see
          // resubscribeToNextHeight), a stale/out-of-order block for an
          // already-passed height can still reach here and would otherwise
          // rewind syncHeight, sending the worker into a bounded rescan loop
          // that never escapes a several-hundred-block window (confirmed:
          // the same match at 893804 was FOUND twice, and the worker never
          // advanced past ~894250 despite running for 36000+ log lines).
          if (tweakHeight > syncHeight) {
            syncHeight = tweakHeight;
          }
          if ((tweakHeight >= scanData.rangeEnd) || isSingleScan) {
            endScanningSuccesfully();
          }
          return;
        }

        final tweakHeight = response.block;

        // Stale re-delivery guard - see the v2 branch above for why.
        if (tweakHeight < syncHeight) {
          return;
        }

        // Continuous status UI update, send how many blocks left to scan.
        // See the v2 branch above for why `rangeEnd` (not `chainTip`) and
        // the static `blockHistory` ETA-mixing caveat.
        final syncingStatus = isSingleScan
            ? SyncingSyncStatus(1, 0)
            : SyncingSyncStatus.fromHeightValues(scanData.rangeEnd, initialSyncHeight, tweakHeight);

        if (shouldUpdateSyncStatus) {
          sendSync(syncHeight, syncingStatus);
        }

        try {
          final blockTweaks = response.blockTweaks;

          for (final txid in blockTweaks.keys) {
            final tweakData = blockTweaks[txid];
            final outputPubkeys = tweakData!.outputPubkeys;
            final tweak = tweakData.tweak;

            try {
              final addToWallet = <String, dynamic>{};

              for (var i = 0; i < receivers.length; i++) {
                final receiver = receivers[i];
                final session = sessions[i];
                final preparedList = outputPubkeys.keys.toList().map((e) => [e]).toList();
                final scanResult = session.scan(preparedList, tweak);

                if (scanResult.isEmpty) {
                  continue;
                }

                if (addToWallet[receiver.BSpend] == null) {
                  addToWallet[receiver.BSpend] = scanResult;
                } else {
                  addToWallet[receiver.BSpend].addAll(scanResult);
                }
              }

              if (addToWallet.isEmpty) {
                // no results tx, continue to next tx
                continue;
              }

              log(
                "FOUND: addToWallet: ${addToWallet.length}, txid: $txid, tweak: $tweak, height: $tweakHeight",
                LogLevel.info,
              );

              // initial placeholder ElectrumTransactionInfo object to update values based on new scanned unspent(s) on the following loop
              final txInfo = ElectrumTransactionInfo(
                WalletType.bitcoin,
                id: txid,
                height: tweakHeight,
                amount: Money.zero(CryptoCurrency.btc),
                fee: Money.zero(CryptoCurrency.btc),
                direction: TransactionDirection.incoming,
                isReplaced: false,
                date: scanData.network == BitcoinNetwork.mainnet
                    ? getDateByBitcoinHeight(tweakHeight)
                    : DateTime.now(),
                confirmations: scanData.chainTip - tweakHeight + 1,
                isReceivedSilentPayment: true,
                isPending: false,
                unspents: [],
              );

              final List<BitcoinUnspent> unspents = [];

              addToWallet.forEach((bSpend, scanResultPerLabel) {
                scanResultPerLabel.forEach((label, scanOutput) {
                  final labelValue = label == "None" ? null : label.toString();

                  (scanOutput as Map<String, dynamic>).forEach((outputPubkey, tweak) {
                    final tK = tweak as String;

                    final receivingOutputAddress = ECPublic.fromHex(outputPubkey)
                        .toTaprootAddress(tweak: false)
                        .toAddress(scanData.network);

                    final matchingOutput = outputPubkeys[outputPubkey]!;
                    final amount = matchingOutput.amount;
                    final pos = matchingOutput.vout;
                    final spent = matchingOutput.spendingInput;

                    // final labelIndex = labelValue != null ? scanData.labels[label] : 0;
                    // final balance = ElectrumBalance();
                    // balance.confirmed = amount;

                    final receivedAddressRecord = BitcoinSilentPaymentAddressRecord(
                      receivingOutputAddress,
                      index: 0,
                      isHidden: false,
                      isUsed: true,
                      network: scanData.network,
                      silentPaymentTweak: tK,
                      type: SegwitAddresType.p2tr,
                      txCount: 1,
                      balance: amount,
                      // Only one receiver is ever built now (see its
                      // construction above) - which BIP-352 path applies is
                      // determined by the wallet's actual network, not by
                      // which array slot happened to match.
                      spendDerivationPath: scanData.network == BitcoinNetwork.testnet
                          ? SILENT_PAYMENTS_SPEND_PATH_TESTNET
                          : SILENT_PAYMENTS_SPEND_PATH,
                    );

                    final unspent = BitcoinSilentPaymentsUnspent(
                      receivedAddressRecord,
                      txid,
                      amount,
                      pos,
                      silentPaymentTweak: tK,
                      silentPaymentLabel: labelValue,
                    );

                    if (spent == null) {
                      unspents.add(unspent);
                      txInfo.unspents!.add(unspent);
                    }

                    txInfo.amount += Money.fromInt(unspent.value, txInfo.amount.currency);
                  });
                });
              });

              scanData.sendPort.send({txInfo.id: txInfo});
            } catch (e, stacktrace) {
              if (shouldUpdateSyncStatus) {
                sendSync(syncHeight, LostConnectionSyncStatus());
              }

              log(stacktrace.toString(), LogLevel.error);
              log(e.toString(), LogLevel.error);
              return;
            }
          }
        } catch (e, stacktrace) {
          if (shouldUpdateSyncStatus) {
            sendSync(syncHeight, LostConnectionSyncStatus());
          }

          log(stacktrace.toString(), LogLevel.error);
          log(e.toString(), LogLevel.error);
          return;
        }

        // See the v2 branch above for why this must never regress.
        if (tweakHeight > syncHeight) {
          syncHeight = tweakHeight;
        }

        if ((tweakHeight >= scanData.rangeEnd) || isSingleScan) {
          endScanningSuccesfully();
        }
      }

      listenFn = (event, req) {
        // Chain, don't await directly here - this closure's own signature is
        // `void Function(...)` (required by Stream.listen), so there's
        // nothing for the stream to await anyway. Chaining onto
        // `_processingChain` (rather than firing `_processEvent` directly)
        // is what actually serializes processing across every event, from
        // every subscription generation, in delivery order. `catchError`
        // keeps a single event's failure from poisoning the chain forever -
        // without it, every event after the first uncaught throw would
        // silently never run, the same silent-death failure mode the
        // response==null case used to have before it got its own handling.
        _processingChain =
            _processingChain.then((_) => _processEvent(event, req)).catchError((e, stacktrace) {
          log("_processEvent failed: $e", LogLevel.error);
          log(stacktrace.toString(), LogLevel.error);
        });
      };

      // Re-issues the subscribe for [height] at whatever count
      // getCountToScanPerRequest currently allows (i.e. after _countCap may
      // have been shrunk) and starts listening again, with the same
      // too-large-request recovery wired in.
      subscribeAndListen = (height) {
        final retryReq = ElectrumTweaksSubscribe(
          height: height,
          count: getCountToScanPerRequest(height),
          historicalMode: scanData.historical,
          protocolVersion: scanData.protocolVersion >= 2 ? scanData.protocolVersion : null,
        );
        final stream = client.subscribe(retryReq);
        if (stream == null) {
          if (shouldUpdateSyncStatus) {
            sendSync(height, LostConnectionSyncStatus());
          }
          return;
        }
        // Close whatever this worker's previous subscription was before
        // replacing it - same leak as resubscribeToNextHeight had (this path
        // is used for both the too-large-request retry ramp and the
        // reconnect-after-error retry, both of which can otherwise leave a
        // prior subscription alive and still delivering data alongside the
        // new one). Also listen with `retryReq`, not the stale outer `req`.
        _scanningStream?.close();
        _scanningStream = stream;
        stream.listen((event) => listenFn(event, retryReq), onError: onSubscribeError(height));
      };

      // A rejected-as-too-large error (server-side outpoint/spend-resolution
      // cap) is recovered by halving _countCap and retrying the same
      // height; any other subscribe error is treated as a real connection
      // failure, matching listenFn's own error handling elsewhere.
      onSubscribeError = (height) => (error, stackTrace) async {
            final message = error.toString();
            final tooLarge = message.contains("exceeds") && message.contains("cap");
            final current = getCountToScanPerRequest(height);

            if (tooLarge && current > 1) {
              _countCap = current ~/ 2 < 1 ? 1 : current ~/ 2;
              log(
                "subscribe rejected as too large (count=$current), retrying height $height with count $_countCap: $error",
                LogLevel.warn,
              );
              subscribeAndListen(height);
              return;
            }

            log("subscribe error at height $height: $error", LogLevel.error);
            log(stackTrace.toString(), LogLevel.error);
            if (shouldUpdateSyncStatus) {
              sendSync(height, LostConnectionSyncStatus());
            }

            // Any other subscribe error is treated as a dead connection.
            // Rebuild it and resume from the same height, capped exponential
            // backoff, indefinitely (bounded only by cooperative shutdown) —
            // matches fetchTweaksGetWithBackoff's retry style for the same
            // class of transient connection failure.
            var backoff = const Duration(seconds: 1);
            const maxBackoff = Duration(seconds: 30);
            while (!stopRequested) {
              try {
                await reconnectClient();
                log("reconnected after subscribe error, resuming at height $height", LogLevel.info);
                subscribeAndListen(height);
                return;
              } catch (e) {
                log(
                  "reconnect after subscribe error failed, retrying in ${backoff.inSeconds}s: $e",
                  LogLevel.error,
                );
                await Future.delayed(backoff);
                if (backoff < maxBackoff) {
                  backoff *= 2;
                }
              }
            }
          };

      _scanningStream?.listen(
        (event) => listenFn(event, req),
        onError: onSubscribeError(syncHeight),
      );
    }

    if (scanData.rescanHeights != null) {
      for (final height in scanData.rescanHeights!) {
        log("rescanning from height: $height", LogLevel.info);
        unawaited(scan(height, isSingleScan: true));
      }
    } else {
      unawaited(scan(scanData.height, isSingleScan: scanData.isSingleScan));
    }
  } catch (e) {
    log("Error in _handleScanSilentPayments: $e", LogLevel.error);
    if (shouldUpdateSyncStatus) {
      sendSync(scanData.height, LostConnectionSyncStatus());
    }
    await cleanupAndAck();
  }
}
