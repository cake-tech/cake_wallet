/// Wallet-facing Sapling key manager, shield sync engine and tx builder over the
/// Rust FFI.

import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_pivx/src/pivx_exchange_address.dart';
import 'package:cw_pivx/src/pivx_network.dart';
import 'package:cw_pivx/src/sapling/pivx_sapling_electrumx.dart';
import 'package:cw_pivx/src/sapling/sapling_constants.dart';
import 'package:cw_pivx/src/sapling/sapling_note_storage.dart';
import 'package:cw_pivx/src/sapling/sapling_ffi.dart' as ffi;

/// Blocks to stay behind db_height on a node without `consistent_db_height`:
/// it can advance db_height before the block's Sapling data is queryable, and
/// scanning that committed-but-empty block skips a note for good.
const int _kSaplingIndexSafetyMargin = 3;

class SaplingKeyManager {
  final ffi.SaplingKeys keys;

  SaplingKeyManager.fromSeed(Uint8List seed)
      : keys = ffi.SaplingKeys.fromSeed(seed);

  String get defaultAddress => keys.getDefaultAddress();

  String deriveAddress(int index) => keys.deriveAddress(index);

  bool validateAddress(String address) => ffi.validateAddress(address);

  void dispose() => keys.dispose();
}

/// 0-conf incoming payment. Display-only: no tree position or witness.
class MempoolIncomingNote {
  final String txid;
  final int value;
  final int? firstSeen;

  MempoolIncomingNote(
      {required this.txid, required this.value, this.firstSeen});
}

class ShieldSyncEngine {
  final ffi.SaplingSyncEngine _engine;
  final dynamic electrumClient;
  final PIVXSaplingElectrumX saplingClient;
  final SaplingKeyManager keyManager;
  final SaplingNoteStorage storage;
  bool _isSyncing = false;
  bool _stopRequested = false;
  bool _treePositionIsTrusted = false;
  // Captured per sync/peek from the probed capabilities.
  bool _usesDisplayByteOrder = false;
  // Separate decryptor so 0-conf peeks never touch the real notes or tree.
  ffi.SaplingSyncEngine? _mempoolPeekEngine;
  bool _mempoolUnsupportedLogged = false;
  // Next global tree position. A plain int: blocks are processed sequentially
  // on one isolate.
  int _treePosition = 0;

  ShieldSyncEngine._(
    this._engine,
    this.electrumClient,
    this.saplingClient, {
    required this.keyManager,
    required this.storage,
  });

  /// Loads storage and restores unspent notes into a fresh native engine.
  static Future<ShieldSyncEngine> create({
    required SaplingKeyManager keyManager,
    required String walletId,
    required dynamic electrumClient,
    required EncryptionFileUtils encryptionFileUtils,
    required String password,
  }) async {
    final storage = SaplingNoteStorage(
      walletId: walletId,
      encryptionFileUtils: encryptionFileUtils,
      password: password,
    );
    await storage.load();
    final engine = ShieldSyncEngine._(
      ffi.SaplingSyncEngine(),
      electrumClient,
      PIVXSaplingElectrumX(electrumClient: electrumClient),
      keyManager: keyManager,
      storage: storage,
    );
    engine._treePosition = storage.nextTreePosition;
    engine._treePositionIsTrusted = storage.hasPersistedTreePosition;
    engine.restoreNotesFromStorage();
    return engine;
  }

  /// The native engine starts empty on every launch and after a reset.
  void restoreNotesFromStorage() {
    _unrestoredNoteIds.clear();
    for (final note in storage.notes) {
      if (note.isSpent ||
          note.isPendingSpend ||
          note.isProvisionallySpent ||
          !note.hasSpendingData) {
        continue;
      }
      if (!ffi.restoreNote(
        keyHandle: keyManager.keys.handle,
        syncHandle: _engine.handle,
        noteData: note.toNativeRestoreJson(),
      )) {
        _unrestoredNoteIds.add(note.id);
        printV('[PIVX Sapling] Failed to restore one stored note; excluded '
            'from the spendable balance until a rescan');
      }
    }
  }

  void resetNativeEngine() {
    _engine.reset();
    _unrestoredNoteIds.clear();
    _treePosition = 0;
    _treePositionIsTrusted = false;
  }

  int balanceAt(int chainHeight) =>
      spendableNotesAt(chainHeight).fold(0, (sum, n) => sum + n.value);

  /// Stored spendable notes minus any the native engine refused on restore,
  /// so the balance never shows funds the builder cannot select.
  List<StoredSaplingNote> spendableNotesAt(int chainHeight) => storage
      .spendableNotesAt(chainHeight: chainHeight)
      .where((note) => !_unrestoredNoteIds.contains(note.id))
      .toList();

  final Set<String> _unrestoredNoteIds = {};

  /// daemon_height when it leads the cursor, shared by display and spend or
  /// the UI shows funds the builder refuses. Stored notes are indexed, so
  /// witnessable at any depth.
  int get confirmationHeight {
    final indexHeight = storage.lastSyncedHeight;
    final daemonHeight = saplingClient.daemonHeight;
    return (daemonHeight != null && daemonHeight > indexHeight)
        ? daemonHeight
        : indexHeight;
  }

  int pendingBalanceAt(int chainHeight) =>
      storage.pendingReceivedBalanceAt(chainHeight: chainHeight);

  /// Cooperative cancel, checked between block rounds. Wait for the sync to
  /// finish before mutating storage or the native engine.
  void requestStop() => _stopRequested = true;

  Uint8List _toSerializationOrder(Uint8List bytes) => _usesDisplayByteOrder
      ? Uint8List.fromList(bytes.reversed.toList())
      : bytes;

  /// Scan from [startHeight] (default: last synced + 1 or activation) up to the
  /// db_height ceiling. True only when the pass reached that ceiling.
  Future<bool> startSync({
    int? startHeight,
    required void Function(SyncStatus) onProgress,
  }) async {
    if (_isSyncing) {
      return false;
    }

    _isSyncing = true;
    _stopRequested = false;

    try {
      final lastSyncedBlock = storage.lastSyncedHeight;
      final activationHeight = saplingClient.activationHeight;

      int effectiveStartHeight;
      if (startHeight != null) {
        effectiveStartHeight =
            startHeight < activationHeight ? activationHeight : startHeight;
      } else {
        effectiveStartHeight = lastSyncedBlock > activationHeight
            ? lastSyncedBlock + 1
            : activationHeight;
      }

      final capabilities = await saplingClient.probeCapabilities();
      _usesDisplayByteOrder = capabilities.usesDisplayByteOrder;
      if (startHeight == null &&
          capabilities.supportsBlockHashes &&
          lastSyncedBlock >= activationHeight) {
        final rewindHeight = await _detectReorgRewindHeight(lastSyncedBlock);
        if (rewindHeight != null) {
          await storage.rewindToHeight(rewindHeight);
          resetNativeEngine();
          restoreNotesFromStorage();
          effectiveStartHeight = rewindHeight >= activationHeight
              ? rewindHeight + 1
              : activationHeight;
        }
      }
      if (!storage.hasPersistedTreePosition &&
          effectiveStartHeight > activationHeight &&
          !capabilities.supportsGlobalOutputPositions) {
        throw SaplingRpcException(
          'PIVX Sapling sync cannot start after activation without a persisted tree cursor or server global output positions',
        );
      }
      _treePositionIsTrusted = storage.hasPersistedTreePosition ||
          effectiveStartHeight <= activationHeight;

      onProgress(SyncStatus(
        lastSyncedBlock: effectiveStartHeight,
        chainTip: effectiveStartHeight,
        blocksRemaining: 0,
        progress: 0.0,
      ));

      // Target db_height, never the tip: above it the node answers
      // index_incomplete. Fresh each pass; the probe-time value never moves.
      // No db_height at all: nothing to scan this pass.
      int effectiveTargetHeight = effectiveStartHeight;
      final indexCeiling = await saplingClient.fetchLiveIndexHeight() ??
          capabilities.indexHeight;
      // Not caught up: scanning the start block and returning true read as
      // Synced. The poll retries once the node reports its index.
      if (indexCeiling == null) return false;
      final margin = capabilities.supportsConsistentDbHeight
          ? 0
          : _kSaplingIndexSafetyMargin;
      effectiveTargetHeight = indexCeiling - margin;

      // A restore or rescan height above the index starts at the index: the
      // early return below saves no cursor, so the wallet read Synced with
      // nothing scanned and payments landing before that height were skipped.
      if (startHeight != null &&
          effectiveTargetHeight >= activationHeight &&
          effectiveTargetHeight < effectiveStartHeight) {
        effectiveStartHeight = effectiveTargetHeight;
      }

      if (effectiveTargetHeight < effectiveStartHeight) {
        onProgress(SyncStatus(
          lastSyncedBlock: effectiveStartHeight,
          chainTip: effectiveStartHeight,
          blocksRemaining: 0,
          progress: 1.0,
        ));
        return true;
      }

      printV(
          '[PIVX Sapling] Sync starting at $effectiveStartHeight; target $effectiveTargetHeight');

      final reachedTarget = await saplingClient.syncBlocks(
        fromHeight: effectiveStartHeight,
        toHeight: effectiveTargetHeight,
        batchSize: 100,
        // Round-trip bound in sparse stretches, so a recovery (~28.5k windows)
        // scales with this. Each window can carry a 2MB response, so 12 put up
        // to 24MB ahead of the 5s keepalive ping and looped at 5410300 on a
        // slow link. Cost: dense stretches need ~0.4MB/s to beat the 30s fetch.
        parallelBatches: 6,
        shouldCancel: () => _stopRequested,
        onBatch: (blocks) async {
          for (final block in blocks) {
            await _processBlock(block);
          }
        },
        onRangeComplete: (rangeStart, rangeEnd, blockHashes) async {
          final totalRange = effectiveTargetHeight - effectiveStartHeight + 1;
          final safeTotalRange = totalRange < 1 ? 1 : totalRange;
          final progress =
              (rangeEnd - effectiveStartHeight + 1) / safeTotalRange;
          final remaining = effectiveTargetHeight - rangeEnd;
          final clampedProgress = progress.clamp(0.0, 1.0);
          if (rangeStart <= effectiveStartHeight ||
              rangeEnd >= effectiveTargetHeight ||
              rangeEnd % 10000 == 0) {
            final percentage = (clampedProgress * 100).toStringAsFixed(2);
            printV(
                '[PIVX Sapling] Range complete $rangeStart-$rangeEnd; $remaining blocks remaining; $percentage%');
          }
          onProgress(SyncStatus(
            lastSyncedBlock: rangeEnd,
            chainTip: effectiveTargetHeight,
            blocksRemaining: remaining > 0 ? remaining : 0,
            progress: clampedProgress,
          ));
          // Empty ranges too; cursor and height share one sidecar write.
          await storage.completeSyncRange(
            lastSyncedHeight: rangeEnd,
            nextTreePosition: _treePosition,
            treePositionIsTrusted: _treePositionIsTrusted,
            blockHashes: blockHashes,
          );
        },
      );

      await storage.flushSync();
      // A short pass must not emit the zero-remaining event: the wallet reads
      // it as caught up. The next header or poll resumes from the cursor.
      if (!reachedTarget) {
        printV(
            '[PIVX Sapling] Pass stopped at ${storage.lastSyncedHeight} of $effectiveTargetHeight');
        return false;
      }
      printV(
          '[PIVX Sapling] Synced from $effectiveStartHeight to $effectiveTargetHeight');

      onProgress(SyncStatus(
        lastSyncedBlock: effectiveTargetHeight,
        chainTip: effectiveTargetHeight,
        blocksRemaining: 0,
        progress: 1.0,
      ));
      return true;
    } finally {
      _isSyncing = false;
    }
  }

  /// Blocks must be processed strictly in order: tree positions are sequential.
  Future<void> _processBlock(SaplingBlock block) async {
    final outputs = block.txs.expand((tx) => tx.outputs).toList();
    final outputCount = outputs.length;
    final explicitPositionCount =
        outputs.where((output) => output.globalPosition != null).length;
    if (explicitPositionCount > 0 && explicitPositionCount != outputCount) {
      throw SaplingRpcException(
          'PIVX Sapling block ${block.height} has partial output position data');
    }

    final hasExplicitPositions = explicitPositionCount == outputCount;
    var currentPosition = _treePosition;
    int? previousExplicitPosition;
    var checkedExplicitCursor = false;
    // A spend marker is saved immediately, so its height+hash checkpoint must
    // be too, or crash + reorg leaves the note stuck spent.
    var markedSpend = false;

    // Spends first. Unexpected server-reported spends are quarantined
    // (reversible by rescan) so a malicious server cannot freeze funds.
    for (final tx in block.txs) {
      for (final spend in tx.spends) {
        final nullifierBytes = _toSerializationOrder(spend.nullifierBytes);
        final nullifierHex = hex.encode(nullifierBytes);
        _engine.checkNullifier(nullifierBytes);
        final spentOurNote = await storage.recordObservedSpendByNullifier(
          nullifierHex,
          tx.txid,
          spendingHeight: block.height,
        );
        if (spentOurNote) markedSpend = true;
      }
    }

    var addedNote = false;
    for (var txIdx = 0; txIdx < block.txs.length; txIdx++) {
      final tx = block.txs[txIdx];
      for (var outIdx = 0; outIdx < tx.outputs.length; outIdx++) {
        final output = tx.outputs[outIdx];
        final treePosition = output.globalPosition ?? currentPosition;
        if (hasExplicitPositions) {
          if (!checkedExplicitCursor &&
              _treePositionIsTrusted &&
              currentPosition > 0 &&
              treePosition != currentPosition) {
            throw SaplingRpcException(
                'PIVX Sapling block ${block.height} output positions do not match the persisted tree cursor');
          }
          checkedExplicitCursor = true;
          _treePositionIsTrusted = true;
          if (previousExplicitPosition != null &&
              treePosition != previousExplicitPosition + 1) {
            throw SaplingRpcException(
                'PIVX Sapling block ${block.height} output positions are not contiguous');
          }
          previousExplicitPosition = treePosition;
        }

        // Ciphertext is raw wire bytes and is never reversed.
        final cmuBytes = _toSerializationOrder(output.cmuBytes);
        final epkBytes = _toSerializationOrder(output.epkBytes);

        final value = _engine.tryDecryptOutput(
          keys: keyManager.keys,
          cmu: cmuBytes,
          epk: epkBytes,
          encCiphertext: output.ciphertextBytes,
          height: block.height,
          txIndex: txIdx,
          outputIndex: outIdx,
          position: treePosition,
        );

        if (value > 0) {
          // One note by position, not all notes per match (O(K^2) on restore).
          final fullNoteData =
              ffi.getNoteAtPosition(_engine.handle, treePosition);
          if (fullNoteData == null) {
            // Stored without spend data, so it stays out of the spendable
            // balance instead of showing funds no send can use.
            printV('[PIVX Sapling] Native note restore data unavailable; '
                'note not spendable until a rescan');
          }

          final note = StoredSaplingNote(
            id: '${tx.txid}:$outIdx',
            value: value,
            height: block.height,
            blockTime: block.time,
            txid: tx.txid,
            outputIndex: outIdx,
            treePosition: treePosition,
            cmu: hex.encode(cmuBytes),
            nullifier: fullNoteData?['nullifier'] as String?,
            rseed: fullNoteData?['rseed'] as String?,
            diversifier: fullNoteData?['diversifier'] as String?,
            pkD: fullNoteData?['pk_d'] as String?,
            address: fullNoteData?['address'] as String?,
            memo: fullNoteData?['memo'] as String?,
            txIndex: txIdx,
          );
          await storage.addNote(note);
          addedNote = true;
        }

        currentPosition = treePosition + 1;
      }
    }

    if (currentPosition > _treePosition) _treePosition = currentPosition;
    // A block that yielded a note checkpoints now, not on the 10k batch: a note
    // saved ahead of its block hash is orphaned by crash + reorg.
    await storage.completeSyncRange(
      lastSyncedHeight: block.height,
      nextTreePosition: currentPosition,
      treePositionIsTrusted: _treePositionIsTrusted,
      blockHashes: block.hash.isEmpty
          ? const {}
          : <int, String>{block.height: block.hash},
      flush: addedNote || markedSpend,
    );
  }

  Future<int?> _detectReorgRewindHeight(int lastSyncedBlock) async {
    final activationHeight = saplingClient.activationHeight;
    if (lastSyncedBlock < activationHeight) return null;

    final compareStart = lastSyncedBlock - 99 > activationHeight
        ? lastSyncedBlock - 99
        : activationHeight;
    final range = await saplingClient.getBlockRangeResult(
      compareStart,
      endHeight: lastSyncedBlock,
    );
    if (range.blockHashes.isEmpty) return null;

    var firstMismatch = 0;
    for (var height = compareStart; height <= lastSyncedBlock; height++) {
      final localHash = storage.scannedBlockHashes[height];
      final serverHash = range.blockHashes[height];
      if (localHash == null || serverHash == null) {
        continue;
      }
      if (localHash.toLowerCase() != serverHash.toLowerCase()) {
        firstMismatch = height;
        break;
      }
    }

    if (firstMismatch == 0) {
      await storage.completeSyncRange(
        lastSyncedHeight: lastSyncedBlock,
        nextTreePosition: storage.nextTreePosition,
        treePositionIsTrusted: storage.hasPersistedTreePosition,
        blockHashes: range.blockHashes,
      );
      return null;
    }

    var rewindHeight = firstMismatch - 1;
    for (var height = firstMismatch - 1; height >= activationHeight; height--) {
      final localHash = storage.scannedBlockHashes[height];
      final serverHash = range.blockHashes[height];
      if (localHash != null &&
          serverHash != null &&
          localHash.toLowerCase() == serverHash.toLowerCase()) {
        rewindHeight = height;
        break;
      }
    }
    if (rewindHeight < activationHeight) {
      rewindHeight = activationHeight - 1;
    }

    printV('[PIVX Sapling] Reorg detected; rewinding shielded sync state');
    return rewindHeight;
  }

  /// 0-conf incoming notes; null when unavailable (caller keeps prior state).
  Future<List<MempoolIncomingNote>?> scanMempool() async {
    final capabilities = await saplingClient.probeCapabilities();
    if (!capabilities.supportsMempool) {
      if (!_mempoolUnsupportedLogged) {
        _mempoolUnsupportedLogged = true;
        printV('[PIVX Sapling] Mempool 0-conf not advertised by node');
      }
      return null;
    }

    final snapshot = await saplingClient.fetchMempool();
    if (snapshot == null) return null;
    return decryptMempoolSnapshot(snapshot);
  }

  /// Skips known txids and the wallet's own sends (a spend reveals one of its
  /// nullifiers, so its outputs are change).
  Future<List<MempoolIncomingNote>> decryptMempoolSnapshot(
      SaplingMempoolResult snapshot) async {
    final capabilities = await saplingClient.probeCapabilities();
    _usesDisplayByteOrder = capabilities.usesDisplayByteOrder;
    if (snapshot.txs.isEmpty) {
      _mempoolPeekEngine?.reset();
      return const [];
    }

    final knownTxids = storage.notes.map((n) => n.txid).toSet();
    final myNullifiers =
        storage.notes.map((n) => n.nullifier).whereType<String>().toSet();

    final peek = _mempoolPeekEngine ??= ffi.SaplingSyncEngine();
    // Bounds the throwaway note set to one cycle.
    peek.reset();

    final incoming = <MempoolIncomingNote>[];
    var position = 0;
    for (final tx in snapshot.txs) {
      if (knownTxids.contains(tx.txid)) continue;
      if (tx.spends.any((spend) => myNullifiers
          .contains(hex.encode(_toSerializationOrder(spend.nullifierBytes))))) {
        continue;
      }

      var txValue = 0;
      for (final output in tx.outputs) {
        // Value is position-independent, so a sentinel position is fine.
        final value = peek.tryDecryptOutput(
          keys: keyManager.keys,
          cmu: _toSerializationOrder(output.cmuBytes),
          epk: _toSerializationOrder(output.epkBytes),
          encCiphertext: output.ciphertextBytes,
          height: 0,
          txIndex: 0,
          outputIndex: 0,
          position: position++,
        );
        if (value > 0) txValue += value;
      }
      if (txValue > 0) {
        incoming.add(MempoolIncomingNote(
          txid: tx.txid,
          value: txValue,
          firstSeen: tx.firstSeen,
        ));
      }
    }
    if (snapshot.txs.isNotEmpty) {
      printV(
          '[PIVX Sapling] Mempool peek: ${snapshot.txs.length} tx in snapshot, ${incoming.length} ours');
    }
    return incoming;
  }

  void dispose() {
    _engine.dispose();
    _mempoolPeekEngine?.dispose();
    _mempoolPeekEngine = null;
  }
}

class SyncStatus {
  final int lastSyncedBlock;
  final int chainTip;
  final int blocksRemaining;
  final double progress;

  SyncStatus({
    required this.lastSyncedBlock,
    required this.chainTip,
    required this.blocksRemaining,
    required this.progress,
  });
}

class SaplingTransactionBuilder {
  final SaplingKeyManager keyManager;
  final ShieldSyncEngine syncEngine;
  bool _proverInitialized = false;

  SaplingTransactionBuilder({
    required this.keyManager,
    required this.syncEngine,
  });

  bool get hasProvingParams => _proverInitialized;

  /// Provision (verified local file, else download) and load
  /// the ~51MB Groth16 params. Each path hashes the files exactly once.
  Future<void> ensureProvingParams(String path) async {
    if (_proverInitialized) return;
    if (!await hasLocalProvingParams(path)) {
      printV('Downloading PIVX Sapling proving parameters (~51MB)...');
      await downloadProvingParamsToPath(path: path, onProgress: (_) {});
    }
    if (!ffi.initProver(path)) {
      throw Exception('Failed to initialize prover: ${ffi.getLastError()}');
    }
    _proverInitialized = true;
  }

  Future<bool> hasLocalProvingParams(String path) async {
    final spendPath = '$path/sapling-spend.params';
    final outputPath = '$path/sapling-output.params';

    return await _verifyParamFile(
          file: File(spendPath),
          expectedSize: SaplingParams.spendParamsSize,
          expectedHash: SaplingParams.spendParamsHash,
        ) &&
        await _verifyParamFile(
          file: File(outputPath),
          expectedSize: SaplingParams.outputParamsSize,
          expectedHash: SaplingParams.outputParamsHash,
        );
  }

  static Future<void> downloadProvingParamsToPath({
    required String path,
    required void Function(double) onProgress,
    List<String> mirrors = SaplingParams.mirrors,
    int spendParamsSize = SaplingParams.spendParamsSize,
    String spendParamsHash = SaplingParams.spendParamsHash,
    int outputParamsSize = SaplingParams.outputParamsSize,
    String outputParamsHash = SaplingParams.outputParamsHash,
  }) async {
    final expectedTotalSize = spendParamsSize + outputParamsSize;

    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    var downloadedBytes = 0;

    await _downloadParamIfNeeded(
      urls: [for (final m in mirrors) '$m/${SaplingParams.spendParamsFileName}'],
      destination: '$path/${SaplingParams.spendParamsFileName}',
      expectedSize: spendParamsSize,
      expectedHash: spendParamsHash,
      onDownloaded: (bytes) {
        downloadedBytes = bytes;
        onProgress(downloadedBytes / expectedTotalSize);
      },
    );
    downloadedBytes = spendParamsSize;
    onProgress(downloadedBytes / expectedTotalSize);

    await _downloadParamIfNeeded(
      urls: [for (final m in mirrors) '$m/${SaplingParams.outputParamsFileName}'],
      destination: '$path/${SaplingParams.outputParamsFileName}',
      expectedSize: outputParamsSize,
      expectedHash: outputParamsHash,
      onDownloaded: (bytes) {
        onProgress((downloadedBytes + bytes) / expectedTotalSize);
      },
    );

    onProgress(1.0);
  }

  static Future<void> _downloadParamIfNeeded({
    required List<String> urls,
    required String destination,
    required int expectedSize,
    required String expectedHash,
    required void Function(int bytesDownloaded) onDownloaded,
  }) async {
    final destinationFile = File(destination);
    if (await _verifyParamFile(
      file: destinationFile,
      expectedSize: expectedSize,
      expectedHash: expectedHash,
    )) {
      onDownloaded(expectedSize);
      return;
    }

    if (await destinationFile.exists()) {
      await destinationFile.delete();
    }

    Object? lastError;
    for (final url in urls) {
      try {
        await _downloadFileAtomically(
          url: url,
          destination: destination,
          expectedSize: expectedSize,
          expectedHash: expectedHash,
          onProgress: onDownloaded,
        );
        return;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('No Sapling params mirrors configured');
  }

  static Future<bool> _verifyParamFile({
    required File file,
    required int expectedSize,
    required String expectedHash,
  }) async {
    try {
      if (!await file.exists()) return false;

      final size = await file.length();
      if (size != expectedSize) return false;

      final hash = await _sha256File(file);
      return hash == expectedHash;
    } catch (_) {
      return false;
    }
  }

  static Future<String> _sha256File(File file) async {
    final digestSink = AccumulatorSink<Digest>();
    final input = sha256.startChunkedConversion(digestSink);
    await for (final chunk in file.openRead()) {
      input.add(chunk);
    }
    input.close();
    return digestSink.events.single.toString();
  }

  /// Download a file through Cake's proxy/Tor wrapper, verify it, then rename.
  static Future<void> _downloadFileAtomically({
    required String url,
    required String destination,
    required int expectedSize,
    required String expectedHash,
    required void Function(int bytesDownloaded) onProgress,
  }) async {
    final destinationFile = File(destination);
    final tempFile = File('$destination.download');
    final uri = Uri.parse(url);

    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    final client = CakeTor.instance == null
        ? HttpClient()
        // ignore: deprecated_member_use
        : ProxyWrapper().getHttpClient(internal: true);
    IOSink? output;
    final digestSink = AccumulatorSink<Digest>();
    final hashInput = sha256.startChunkedConversion(digestSink);
    var downloadedBytes = 0;

    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw Exception(
            'PIVX Sapling proving parameter download failed with HTTP ${response.statusCode}');
      }

      output = tempFile.openWrite();
      await for (final chunk in response) {
        downloadedBytes += chunk.length;
        hashInput.add(chunk);
        output.add(chunk);
        onProgress(downloadedBytes);
      }
      await output.flush();
      await output.close();
      output = null;
    } catch (_) {
      try {
        await output?.close();
      } catch (_) {}
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    } finally {
      hashInput.close();
      client.close(force: true);
    }

    if (downloadedBytes != expectedSize) {
      await tempFile.delete();
      throw Exception(
          'PIVX Sapling proving parameter size mismatch after download');
    }

    final hash = digestSink.events.single.toString();
    if (hash != expectedHash) {
      await tempFile.delete();
      throw Exception(
          'PIVX Sapling proving parameter hash mismatch after download');
    }

    if (!await _verifyParamFile(
      file: tempFile,
      expectedSize: expectedSize,
      expectedHash: expectedHash,
    )) {
      await tempFile.delete();
      throw Exception(
          'PIVX Sapling proving parameter verification failed after write');
    }

    if (await destinationFile.exists()) {
      await destinationFile.delete();
    }
    await tempFile.rename(destination);
  }

  /// z-to-z for a Sapling destination, z-to-t (deshield) with shielded change
  /// for a transparent one.
  Future<SaplingTransactionResult> buildTransaction({
    required SaplingTransactionOptions options,
  }) async {
    final isShieldedDestination = keyManager.validateAddress(options.toAddress);
    if (!isShieldedDestination) {
      final address = options.toAddress;
      // Consensus: bad-txns-exchange-addr-has-sapling. Only t-to-t can pay it.
      if (PivxExchangeAddress.looksLike(address)) {
        throw Exception(
            'Exchange addresses can only be paid from transparent funds');
      }
      // Loose shape check; the native builder does strict base58check.
      final looksValidTransparent =
          PivxNetwork.isValidAddress(address) && !address.startsWith('ps');
      if (!looksValidTransparent) {
        throw Exception('Invalid destination address');
      }
      if (options.memo != null && options.memo!.isNotEmpty) {
        throw Exception(
            'PIVX memos are not supported for transparent destinations');
      }
    }

    final dustFloor = isShieldedDestination
        ? PivxFeePolicy.shieldedDustThreshold
        : PivxFeePolicy.transparentDustThreshold;
    if (options.amount < dustFloor) {
      throw Exception(isShieldedDestination
          ? 'Amount below PIVX shielded dust threshold'
          : 'Amount below PIVX transparent dust threshold');
    }

    if (syncEngine.balanceAt(syncEngine.confirmationHeight) < options.amount) {
      throw Exception('Insufficient shielded balance');
    }

    if (!hasProvingParams) {
      throw Exception(
          'Proving parameters not loaded. Call loadProvingParams first.');
    }

    final syncHandle = syncEngine._engine.handle;
    final spendChainHeight = syncEngine.confirmationHeight;
    final spendEligibility = syncEngine.storage.spendEligibilitySummaryAt(
      chainHeight: spendChainHeight,
    );
    printV(
        '[PIVX Sapling] Shielded spend eligibility: ${spendEligibility.sanitizedLogLine}');

    final spendableNullifiers = syncEngine
        .spendableNotesAt(spendChainHeight)
        .map((note) => note.nullifier)
        .whereType<String>()
        .toSet();
    final allNotes = ffi
        .getSpendableNotes(syncHandle)
        .where((note) => spendableNullifiers.contains(note['nullifier']))
        .toList();

    if (allNotes.isEmpty) {
      throw Exception(
          'No spendable shielded notes available at required confirmations (${PivxShieldedConfirmationPolicy.spendConfirmations})');
    }

    // A shielded spend needs a canonical Merkle witness; fail closed before
    // selecting anything.
    final capabilities = await syncEngine.saplingClient.probeCapabilities();
    if (!capabilities.canonicalWitnesses) {
      throw Exception(
          'PIVX shielded send unavailable: this node cannot provide canonical witnesses');
    }
    final usesDisplay = capabilities.usesDisplayByteOrder;

    // Verify selected notes are unspent on-chain before the 30-60s proof: the
    // same seed may have spent them elsewhere (e.g. PIVX Core). Spent ones are
    // marked and reselected, bounded so a bad node cannot loop forever.
    List<Map<String, dynamic>> selectedNotes = const [];
    var selectionVerified = false;
    for (var attempt = 0; attempt < 6; attempt++) {
      selectedNotes = selectNotesForAmount(
        allNotes,
        options.amount,
        spendAll: options.spendAllShieldedInputs,
        transparentDestination: !isShieldedDestination,
      );
      if (selectedNotes.isEmpty) {
        throw Exception('Could not select sufficient notes');
      }

      final selectedNullifiers = <String>{
        for (final n in selectedNotes)
          if (n['nullifier'] is String) n['nullifier'] as String,
      };
      if (selectedNullifiers.isEmpty) {
        selectionVerified = true;
        break;
      }

      final queryToStored = <String, String>{
        for (final nf in selectedNullifiers)
          (usesDisplay ? reverseSaplingHexBytes(nf) : nf): nf,
      };
      final spentStatus = await syncEngine.saplingClient
          .checkNullifiers(queryToStored.keys.toList());
      final alreadySpent = <String>{
        for (final entry in spentStatus.entries)
          if (entry.value && queryToStored.containsKey(entry.key))
            queryToStored[entry.key]!,
      };
      if (alreadySpent.isEmpty) {
        selectionVerified = true;
        break; // every selected note is spendable on-chain
      }

      for (final nf in alreadySpent) {
        await syncEngine.storage.markSpentByNullifier(nf, 'external-spend');
      }
      allNotes.removeWhere((n) => alreadySpent.contains(n['nullifier']));
    }
    if (!selectionVerified || selectedNotes.isEmpty) {
      throw Exception(
          'Could not assemble a spendable set of shielded notes (some were '
          'already spent on-chain). The balance has been updated. Resync and '
          'try again.');
    }

    final totalInput =
        selectedNotes.fold<int>(0, (sum, n) => sum + (n['value'] as int));
    final spendPlan = planShieldedSpend(
      totalInput: totalInput,
      amount: options.amount,
      saplingInputs: selectedNotes.length,
      transparentDestination: !isShieldedDestination,
    );
    final fee = spendPlan.fee;

    if (!spendPlan.canBuild || totalInput < options.amount + fee) {
      throw Exception('Insufficient balance after fee');
    }

    // Every witness must bind to this one anchor.
    final anchorResult = await syncEngine.saplingClient.getBestAnchor();
    final notesWithWitnesses =
        await _fetchWitnesses(selectedNotes, anchorResult, usesDisplay);
    final spendAnchor = _spendAnchorForWitnesses(
          notesWithWitnesses,
        ) ??
        anchorResult.anchor;
    if (spendAnchor.toLowerCase() != anchorResult.anchor.toLowerCase()) {
      printV('[PIVX Sapling] Using witness-returned spend anchor');
    }
    // Prover wants serialization order (Anchor::from_bytes). Per-note cmu in
    // the notes JSON is already serialization order.
    final proverAnchor =
        usesDisplay ? reverseSaplingHexBytes(spendAnchor) : spendAnchor;

    printV('[PIVX Sapling] Building shielded transaction (30-60s proving)');
    final result = ffi.buildShieldedTransaction(
      keyHandle: keyManager.keys.handle,
      notesJson: jsonEncode(notesWithWitnesses),
      toAddress: options.toAddress,
      amount: options.amount,
      memo: options.memo,
      fee: fee,
      anchorHex: proverAnchor,
    );
    if (result['status'] == 'error') {
      final nativeError = result['error']?.toString();
      final suffix =
          nativeError == null || nativeError.isEmpty ? '' : ': $nativeError';
      printV('[PIVX Sapling] Native transaction build failed$suffix');
      throw Exception('PIVX shielded transaction build failed$suffix');
    }

    return SaplingTransactionResult(
      txHex: result['tx_hex'] as String,
      txId: result['txid'] as String,
      fee: fee,
      spentNullifiers: selectedNotes
          .map((note) => note['nullifier'] as String?)
          .whereType<String>()
          .toList(growable: false),
    );
  }

  /// t-to-z. The native builder re-verifies each UTXO key against its script
  /// hash and fails closed.
  Future<SaplingTransactionResult> buildShieldTransaction({
    required List<Map<String, dynamic>> utxos,
    required String toAddress,
    required int amount,
    String? memo,
    required int fee,
    String? changeAddress,
    int change = 0,
  }) async {
    if (!keyManager.validateAddress(toAddress)) {
      throw Exception('Shield destination must be a Sapling address');
    }
    if (amount < PivxFeePolicy.shieldedDustThreshold) {
      throw Exception('Amount below PIVX shielded dust threshold');
    }
    if (utxos.isEmpty) {
      throw Exception('No transparent UTXOs selected');
    }
    if (!hasProvingParams) {
      throw Exception(
          'Proving parameters not loaded. Call loadProvingParams first.');
    }

    printV('[PIVX Sapling] Building shield (t-to-z) transaction');
    final result = ffi.buildShieldTransaction(
      keyHandle: keyManager.keys.handle,
      utxosJson: jsonEncode(utxos),
      toAddress: toAddress,
      amount: amount,
      memo: memo,
      fee: fee,
      changeAddress: changeAddress,
      change: change,
    );

    if (result['status'] == 'error') {
      final nativeError = result['error']?.toString();
      final suffix =
          nativeError == null || nativeError.isEmpty ? '' : ': $nativeError';
      printV('[PIVX Sapling] Native shield transaction build failed$suffix');
      throw Exception('PIVX shield transaction build failed$suffix');
    }

    return SaplingTransactionResult(
      txHex: result['tx_hex'] as String,
      txId: result['txid'] as String,
      fee: (result['fee'] as num?)?.toInt() ?? fee,
    );
  }

  /// t-to-z: one Sapling output, change back to a transparent address.
  static ShieldedSpendPlan planShieldSpend({
    required int totalInput,
    required int amount,
    required int transparentInputs,
  }) =>
      _plan(
        totalInput: totalInput,
        amount: amount,
        dustThreshold: PivxFeePolicy.transparentDustThreshold,
        feeFor: (withChange) => PivxFeePolicy.saplingFee(
          saplingOutputs: 1,
          transparentInputs: transparentInputs,
          transparentOutputs: withChange ? 1 : 0,
        ),
      );

  /// Select notes to cover the required amount plus its fee.
  static List<Map<String, dynamic>> selectNotesForAmount(
    List<Map<String, dynamic>> allNotes,
    int amount, {
    bool spendAll = false,
    bool transparentDestination = false,
  }) {
    // Sort by value descending to minimize number of inputs
    final sorted = List<Map<String, dynamic>>.from(allNotes)
      ..sort((a, b) => (b['value'] as int).compareTo(a['value'] as int));

    if (spendAll) {
      return sorted;
    }

    final selected = <Map<String, dynamic>>[];
    var total = 0;

    for (final note in sorted) {
      selected.add(note);
      total += note['value'] as int;
      if (planShieldedSpend(
        totalInput: total,
        amount: amount,
        saplingInputs: selected.length,
        transparentDestination: transparentDestination,
      ).canBuild) {
        break;
      }
    }

    return selected;
  }

  /// z-to-z or z-to-t. Change always stays shielded, so shielded dust applies.
  static ShieldedSpendPlan planShieldedSpend({
    required int totalInput,
    required int amount,
    required int saplingInputs,
    bool transparentDestination = false,
  }) =>
      _plan(
        totalInput: totalInput,
        amount: amount,
        dustThreshold: PivxFeePolicy.shieldedDustThreshold,
        feeFor: (withChange) => PivxFeePolicy.saplingFee(
          saplingInputs: saplingInputs,
          saplingOutputs:
              (transparentDestination ? 0 : 1) + (withChange ? 1 : 0),
          transparentOutputs: transparentDestination ? 1 : 0,
        ),
      );

  /// Change at or below [dustThreshold] is absorbed into the fee.
  static ShieldedSpendPlan _plan({
    required int totalInput,
    required int amount,
    required int dustThreshold,
    required int Function(bool withChange) feeFor,
  }) {
    final noChangeFee = feeFor(false);
    if (totalInput < amount + noChangeFee) {
      return ShieldedSpendPlan(fee: noChangeFee, change: 0, canBuild: false);
    }
    final remainder = totalInput - amount - noChangeFee;
    if (remainder <= dustThreshold) {
      return ShieldedSpendPlan(
          fee: noChangeFee + remainder, change: 0, canBuild: true);
    }

    final withChangeFee = feeFor(true);
    if (totalInput < amount + withChangeFee) {
      return ShieldedSpendPlan(fee: withChangeFee, change: 0, canBuild: false);
    }
    final change = totalInput - amount - withChangeFee;
    if (change <= dustThreshold) {
      return ShieldedSpendPlan(
          fee: withChangeFee + change, change: 0, canBuild: true);
    }
    return ShieldedSpendPlan(
        fee: withChangeFee, change: change, canBuild: true);
  }

  Future<List<Map<String, dynamic>>> _fetchWitnesses(
    List<Map<String, dynamic>> notes,
    BestAnchorResult anchorResult,
    bool usesDisplay,
  ) async {
    final result = <Map<String, dynamic>>[];
    for (final note in notes) {
      final cmu = note['cmu'] as String?;
      if (cmu == null || cmu.isEmpty) {
        throw Exception('PIVX shielded note is missing its commitment');
      }
      // Request in the node's order; the note's own 'cmu' stays serialization
      // order for the prover.
      final witness = await syncEngine.saplingClient.getAnchorBoundWitness(
        commitment: usesDisplay ? reverseSaplingHexBytes(cmu) : cmu,
        anchor: anchorResult,
        notePosition: note['position'] as int?,
      );
      result.add({
        ...note,
        'witness': witness.path.join(),
        'witness_position': witness.position,
        'anchor': witness.anchor,
        'anchor_height': witness.anchorHeight,
        'witness_source': witness.source,
      });
    }
    return result;
  }

  String? _spendAnchorForWitnesses(List<Map<String, dynamic>> notes) {
    String? anchor;
    for (final note in notes) {
      final noteAnchor = note['anchor'] as String?;
      if (noteAnchor == null || noteAnchor.isEmpty) {
        continue;
      }
      if (anchor == null) {
        anchor = noteAnchor;
        continue;
      }
      if (anchor.toLowerCase() != noteAnchor.toLowerCase()) {
        throw SaplingRpcException(
            'PIVX Sapling witnesses returned inconsistent anchors');
      }
    }
    return anchor;
  }

  void dispose() {
    if (_proverInitialized) {
      ffi.disposeProver();
      _proverInitialized = false;
    }
  }
}

class SaplingTransactionOptions {
  final String toAddress;
  final int amount;
  final String? memo;
  final bool spendAllShieldedInputs;

  SaplingTransactionOptions({
    required this.toAddress,
    required this.amount,
    this.memo,
    this.spendAllShieldedInputs = false,
  });
}

class ShieldedSpendPlan {
  ShieldedSpendPlan({
    required this.fee,
    required this.change,
    required this.canBuild,
  });

  final int fee;
  final int change;
  final bool canBuild;
}

class SaplingTransactionResult {
  final String txHex;
  final String txId;
  final int fee;
  final List<String> spentNullifiers;

  SaplingTransactionResult({
    required this.txHex,
    required this.txId,
    required this.fee,
    this.spentNullifiers = const [],
  });
}
