/// Factories that wrap the native Sapling FFI implementations.

import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_pivx/src/pivx_network.dart';
import 'package:cw_pivx/src/sapling/native_sapling_key_manager.dart';
import 'package:cw_pivx/src/sapling/native_shield_sync_engine.dart';
import 'package:cw_pivx/src/sapling/pivx_sapling_electrumx.dart';
import 'package:cw_pivx/src/sapling/sapling_constants.dart';
import 'package:cw_pivx/src/sapling/sapling_note_storage.dart';
import 'package:cw_pivx/src/sapling/sapling_ffi.dart' as ffi;
import 'package:cw_pivx/src/sapling/utils/atomic_tree_position.dart';

/// blocks to stay behind `db_height` on a node without `consistent_db_height`.
/// it can advance `db_height` a beat before a block's Sapling data is queryable,
/// so scanning at the ceiling hits a committed-but-empty block and skips a note.
/// stopgap; a consistent node drops it to 0.
const int _kSaplingIndexSafetyMargin = 3;

class SaplingKeyManagerFactory {
  static Future<SaplingKeyManagerWrapper> create({
    required Uint8List seed,
    bool isTestnet = false,
    int accountIndex = 0,
  }) async {
    final nativeManager = await NativeSaplingKeyManager.fromSeed(
      seed,
      isTestnet: isTestnet,
    );
    return SaplingKeyManagerWrapper(nativeManager);
  }
}

/// Simpler wallet-facing wrapper around the native key manager.
class SaplingKeyManagerWrapper {
  final NativeSaplingKeyManager _manager;
  String? _defaultAddressCached;
  int _nextIndex = 0;

  SaplingKeyManagerWrapper(this._manager);

  Future<void> initialize() async {
    _defaultAddressCached = await _manager.getDefaultAddress();
  }

  Future<SaplingAddressResult> getDefaultAddress() async {
    final encoded = _defaultAddressCached ?? await _manager.getDefaultAddress();
    return SaplingAddressResult(encoded: encoded);
  }

  Future<SaplingAddressResult?> getAddressAtIndex(Uint8List indexBytes) async {
    int index = 0;
    for (int i = 0; i < 8 && i < indexBytes.length; i++) {
      index |= indexBytes[i] << (i * 8);
    }
    final encoded = await _manager.deriveAddress(index);
    return SaplingAddressResult(encoded: encoded);
  }

  Future<SaplingAddressResult> getNextAddress() async {
    final encoded = await _manager.deriveAddress(_nextIndex);
    _nextIndex++;
    return SaplingAddressResult(encoded: encoded);
  }

  Future<String> deriveAddress(int index) async {
    return await _manager.deriveAddress(index);
  }

  Future<String> getFullViewingKey() async {
    return await _manager.getFullViewingKey();
  }

  bool validateAddress(String address) {
    return _manager.validateAddress(address);
  }

  void dispose() {
    _manager.dispose();
  }
}

class SaplingAddressResult {
  final String encoded;

  SaplingAddressResult({required this.encoded});
}

class ShieldSyncEngineFactory {
  static Future<ShieldSyncEngineWrapper> create({
    required SaplingKeyManagerWrapper keyManager,
    required String walletId,
    bool isTestnet = false,
    required dynamic electrumClient,
    required EncryptionFileUtils encryptionFileUtils,
    required String password,
  }) async {
    final nativeEngine = NativeShieldSyncEngine(isTestnet: isTestnet);
    final saplingClient = PIVXSaplingElectrumX(
      electrumClient: electrumClient,
      isTestnet: isTestnet,
    );
    final storage = SaplingNoteStorage(
      walletId: walletId,
      isTestnet: isTestnet,
      encryptionFileUtils: encryptionFileUtils,
      password: password,
    );
    await storage.load();

    return ShieldSyncEngineWrapper(
      nativeEngine,
      electrumClient,
      saplingClient,
      keyManager: keyManager,
      storage: storage,
      isTestnet: isTestnet,
    );
  }
}

/// An incoming shielded payment seen in the mempool (0-conf). Display-only:
/// not a spendable note (no tree position/witness), can be dropped/replaced.
class MempoolIncomingNote {
  final String txid;
  final int value;
  final int? firstSeen;

  MempoolIncomingNote({required this.txid, required this.value, this.firstSeen});
}

/// Result of a mempool peek. [truncated] true when the server hit its output
/// cap, so absence from [incoming] is not authoritative eviction and the caller
/// must merge rather than replace.
class MempoolScanResult {
  final List<MempoolIncomingNote> incoming;
  final bool truncated;

  MempoolScanResult(this.incoming, {this.truncated = false});
}

class ShieldSyncEngineWrapper {
  final NativeShieldSyncEngine _engine;
  final dynamic electrumClient;
  final PIVXSaplingElectrumX saplingClient;
  final SaplingKeyManagerWrapper keyManager;
  final SaplingNoteStorage storage;
  final bool isTestnet;
  bool _isSyncing = false;
  bool _stopRequested = false;
  bool _treePositionIsTrusted = false;
  // Node speaks display-order 32-byte hex (v1 hex_byte_order=display), so
  // server nullifiers must be reversed to serialization order for on-device
  // spend matching. Captured once per sync from the probed capabilities.
  bool _usesDisplayByteOrder = false;
  // throwaway decryptor for mempool peeking; isolated from _engine so 0-conf
  // decrypts never touch the real note set, tree, or balance.
  ffi.SaplingSyncEngine? _mempoolPeekEngine;
  bool _mempoolUnsupportedLogged = false;
  final AtomicTreePosition _treePosition = AtomicTreePosition();

  ShieldSyncEngineWrapper(
    this._engine,
    this.electrumClient,
    this.saplingClient, {
    required this.keyManager,
    required this.storage,
    this.isTestnet = false,
  });

  int get nativeSyncHandle => _engine.handle;

  Future<void> initialize() async {
    await storage.load();
    _treePosition.initialize(storage.nextTreePosition);
    _treePositionIsTrusted = storage.hasPersistedTreePosition;

    await restoreNotesFromStorage();
  }

  /// Restore notes from Dart storage into the native sync engine, which is
  /// recreated empty on each app restart.
  Future<void> restoreNotesFromStorage() async {
    final keyHandle = keyManager._manager.nativeKeys.handle;
    final syncHandle = _engine.handle;

    printV('[PIVX Sapling] Restoring spendable notes from encrypted storage');

    for (final note in storage.notes) {
      if (note.isSpent) {
        continue;
      }
      if (note.isPendingSpend) {
        continue;
      }
      if (note.isProvisionallySpent) {
        continue; // Quarantined by an unverified server-reported spend
      }
      if (!note.hasSpendingData) {
        continue;
      }

      final success = ffi.restoreNote(
        keyHandle: keyHandle,
        syncHandle: syncHandle,
        noteData: note.toNativeRestoreJson(),
      );

      if (!success) {
        printV('[PIVX Sapling] Failed to restore one stored note');
      }
    }

    printV('[PIVX Sapling] Stored note restore pass complete');
  }

  /// Reset the native sync engine (rescan; clears in-memory state).
  void resetNativeEngine() {
    _engine.nativeEngine.reset();
    _treePosition.initialize(0);
    _treePositionIsTrusted = false;
    printV('[PIVX Sapling] Reset native sync engine');
  }

  int get balance => storage.spendableBalanceAt(
        chainHeight: storage.lastSyncedHeight,
      );

  int balanceAt(int chainHeight) => storage.spendableBalanceAt(
        chainHeight: chainHeight,
      );

  /// Nullifiers quarantined by unverified server-reported spends; a non-empty
  /// list is a node-integrity warning signal for the wallet layer.
  List<String> get quarantinedNullifiers => storage.quarantinedNullifiers;

  int get pendingBalance => storage.pendingReceivedBalanceAt(
        chainHeight: storage.lastSyncedHeight,
      );

  int pendingBalanceAt(int chainHeight) => storage.pendingReceivedBalanceAt(
        chainHeight: chainHeight,
      );

  bool get isSyncing => _isSyncing;

  /// Cooperatively cancel an in-flight [startSync]: the block loop checks this
  /// between rounds and returns early. Callers that need the engine idle (e.g.
  /// a rescan about to reset it) should request the stop, then wait for
  /// [isSyncing] to clear before mutating storage or the native engine.
  void requestStop() => _stopRequested = true;

  /// Fetch Sapling blocks from the last synced height to the tip, trial-decrypt
  /// outputs, update the tree/witnesses, and track spends. [startHeight]
  /// defaults to last-synced or activation; [targetHeight] defaults to the tip.
  Future<void> startSync({
    int? startHeight,
    int? targetHeight,
    Uint8List? viewingKey,
    required void Function(SyncStatus) onProgress,
  }) async {
    if (_isSyncing) {
      return;
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
          await restoreNotesFromStorage();
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

      // cap the target at db_height minus a safety margin, always, including a
      // header-triggered targetHeight (only the poll path capped before, so
      // header syncs scanned at the tip). two reasons:
      //  1. the index lags the tip; targeting the tip makes the top batches
      //     return index_incomplete and repoll/fail near the top.
      //  2. db_height can advance a block or two before that block's sapling data
      //     is queryable via get_block_range. scanning at db_height then returns
      //     a complete-but-empty block that holds a note; each block is scanned
      //     once and the cursor advances past it, so the note is lost forever.
      // staying [_kSaplingIndexSafetyMargin] behind guarantees every block is
      // scanned once, after its data is committed. legacy nodes without an index
      // status fall back to the header tip.
      int effectiveTargetHeight = targetHeight ?? effectiveStartHeight;
      // fresh db_height each pass; capabilities.indexHeight is cached at probe
      // time and never moves, so it stalls the sync at the first ceiling (new
      // receives never scanned). cached is fallback only.
      final indexCeiling =
          await saplingClient.fetchLiveIndexHeight() ?? capabilities.indexHeight;
      if (indexCeiling != null) {
        // stopgap for a node that advances db_height before a block's Sapling
        // data is queryable: staying behind avoids scanning a committed-but-empty
        // block and skipping a note. drops to 0 once it advertises
        // consistent_db_height.
        final margin = capabilities.supportsConsistentDbHeight
            ? 0
            : _kSaplingIndexSafetyMargin;
        effectiveTargetHeight = indexCeiling - margin;
      } else if (targetHeight == null) {
        try {
          final tip = await electrumClient.getCurrentBlockChainTip();
          if (tip != null && tip > effectiveStartHeight) {
            effectiveTargetHeight = tip as int;
          }
        } catch (e) {
          // Fall back to start height, no sync will happen
        }
      }

      if (effectiveTargetHeight < effectiveStartHeight) {
        onProgress(SyncStatus(
          lastSyncedBlock: effectiveStartHeight,
          chainTip: effectiveStartHeight,
          blocksRemaining: 0,
          progress: 1.0,
        ));
        return;
      }

      printV(
          '[PIVX Sapling] Sync starting at $effectiveStartHeight; target $effectiveTargetHeight');

      var outputsChecked = 0;
      var blocksWithSapling = 0;

      await saplingClient.syncBlocks(
        fromHeight: effectiveStartHeight,
        toHeight: effectiveTargetHeight,
        batchSize: 100, // Max 100 blocks per request per server limit
        // round-trip-bound over a recovery (2.85M blocks = ~28.5k requests), so
        // concurrency is the lever. 5 -> 12; tune down if the v1 node drops the
        // session under load.
        parallelBatches: 12, // Parallel requests (network I/O remains parallel)
        shouldCancel: () => _stopRequested,
        onBatch: (blocks) async {
          for (final block in blocks) {
            await _processSingleBlock(
              block,
              keyManager,
              storage,
              (count) => outputsChecked += count,
              () => blocksWithSapling++,
            );
          }
        },
        onRangeComplete: (rangeStart, rangeEnd, blockHashes) async {
          final totalRange = effectiveTargetHeight - effectiveStartHeight + 1;
          final safeTotalRange = totalRange < 1 ? 1 : totalRange;
          final progress =
              (rangeEnd - effectiveStartHeight + 1) / safeTotalRange;
          final remaining = effectiveTargetHeight - rangeEnd;
          final clampedProgress = progress.clamp(0.0, 1.0);
          if (shouldLogPivxShieldSyncCheckpoint(
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            startHeight: effectiveStartHeight,
            targetHeight: effectiveTargetHeight,
          )) {
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
          // Update storage sync height for empty ranges too, keeping the
          // persisted tree cursor and height in the same sidecar write.
          await storage.completeSyncRange(
            lastSyncedHeight: rangeEnd,
            nextTreePosition: _treePosition.current,
            treePositionIsTrusted: _treePositionIsTrusted,
            blockHashes: blockHashes,
          );
          _engine.nativeEngine.setSyncHeight(rangeEnd);
        },
      );

      await storage.flushSync();

      printV(
          '[PIVX Sapling] Sync complete: checked $outputsChecked outputs in $blocksWithSapling blocks with Sapling txs');
      printV(
          '[PIVX Sapling] Synced from $effectiveStartHeight to $effectiveTargetHeight');
      printV('[PIVX Sapling] Encrypted storage updated');

      onProgress(SyncStatus(
        lastSyncedBlock: effectiveTargetHeight,
        chainTip: effectiveTargetHeight,
        blocksRemaining: 0,
        progress: 1.0,
      ));
    } finally {
      _isSyncing = false;
    }
  }

  /// Process one block at a time in sequence, avoiding races in tree-position
  /// assignment.
  Future<void> _processSingleBlock(
    SaplingBlock block,
    SaplingKeyManagerWrapper keyManager,
    SaplingNoteStorage storage,
    void Function(int count) onOutputsChecked,
    void Function() onBlockWithSapling,
  ) async {
    final nativeKeys = keyManager._manager.nativeKeys;
    final nativeEngine = _engine.nativeEngine;

    final outputs = block.txs.expand((tx) => tx.outputs).toList();
    final outputCount = outputs.length;
    if (outputCount > 0) {
      onBlockWithSapling();
    }

    final explicitPositionCount =
        outputs.where((output) => output.globalPosition != null).length;
    if (explicitPositionCount > 0 && explicitPositionCount != outputCount) {
      throw SaplingRpcException(
          'PIVX Sapling block ${block.height} has partial output position data');
    }

    final hasExplicitPositions = explicitPositionCount == outputCount;
    var currentPosition = _treePosition.current;
    int? previousExplicitPosition;
    var checkedExplicitCursor = false;
    // a block that spends one of our notes persists that spend marker right away
    // (recordObservedSpendByNullifier -> _save). force its height/hash checkpoint
    // too, same reason as addedNote, so a crash + reorg can't leave a note stuck
    // marked spent while the saved height still lags behind the spend.
    var markedSpend = false;

    // Process spends (nullifiers) first: mark our notes as spent.
    // Spends matching a locally broadcast transaction are terminal; unexpected
    // server-reported spends are quarantined (provisionally spent, reversible
    // by rescan) so a malicious server cannot irreversibly freeze funds.
    for (final tx in block.txs) {
      for (final spend in tx.spends) {
        // Native notes and stored notes hold nullifiers in serialization order
        // (Rust canonical). A display-order node reports spend nullifiers in
        // display order, so reverse them before matching or our own spends are
        // never detected. Non-display nodes are untouched (current behavior).
        final nullifierBytes = _usesDisplayByteOrder
            ? Uint8List.fromList(spend.nullifierBytes.reversed.toList())
            : spend.nullifierBytes;
        final nullifierHex = _usesDisplayByteOrder
            ? reverseSaplingHexBytes(spend.nullifier)
            : spend.nullifier;
        nativeEngine.checkNullifier(nullifierBytes);
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
        onOutputsChecked(1);
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

        // A display-order node emits the 32-byte cmu and epk big-endian
        // (uint256 GetHex), but native trial decryption and note storage work
        // in little-endian serialization order, so reverse both before the
        // crypto boundary. The ciphertext is a raw byte blob and must not be
        // touched. Same rule as the spend nullifiers above; non-display nodes
        // are untouched.
        final cmuBytes = _usesDisplayByteOrder
            ? Uint8List.fromList(output.cmuBytes.reversed.toList())
            : output.cmuBytes;
        final epkBytes = _usesDisplayByteOrder
            ? Uint8List.fromList(output.epkBytes.reversed.toList())
            : output.epkBytes;

        final value = nativeEngine.tryDecryptOutput(
          keys: nativeKeys,
          cmu: cmuBytes,
          epk: epkBytes,
          encCiphertext: output.ciphertextBytes,
          height: block.height,
          txIndex: txIdx,
          outputIndex: outIdx,
          position: treePosition,
        );

        if (value > 0) {
          // the note we just decrypted is stored at treePosition. grab that one
          // note directly instead of serializing every note and scanning (was
          // O(K^2) over a restore).
          final fullNoteData =
              ffi.getNoteAtPosition(nativeEngine.handle, treePosition);
          if (fullNoteData == null) {
            printV('[PIVX Sapling] Native note restore data unavailable');
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

    await _treePosition.setAtLeast(currentPosition);
    // a block that yielded a note must checkpoint its height+hash now, not on the
    // 10k batch. addNote already wrote the note, so batching would leave the note
    // ahead of its block on disk; a crash there plus a reorg of that block would
    // orphan the note (reorg detection only looks back to the saved height).
    await storage.completeSyncRange(
      lastSyncedHeight: block.height,
      nextTreePosition: currentPosition,
      treePositionIsTrusted: _treePositionIsTrusted,
      blockHashes: block.hash.isEmpty
          ? const {}
          : <int, String>{block.height: block.hash},
      flush: addedNote || markedSpend,
    );
    nativeEngine.setSyncHeight(block.height);
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

  /// Spent status for multiple nullifiers (nullifier hex -> spent).
  Future<Map<String, bool>> checkNullifiers(List<String> nullifiers) async {
    return await saplingClient.checkNullifiers(nullifiers);
  }

  Future<BestAnchorResult> getBestAnchor() async {
    return await saplingClient.getBestAnchor();
  }

  /// Clear stored notes and reset sync state for a rescan.
  Future<void> rescan({int? fromHeight}) async {
    await storage.clear();
    _treePosition.reset();
    _treePositionIsTrusted = false;
  }

  void stopSync() {
    _isSyncing = false;
  }

  /// Trial-decrypt the unconfirmed Sapling mempool for 0-conf incoming notes.
  /// null when the snapshot is unavailable (caller keeps prior state); a
  /// non-null list (possibly empty) replaces it. Display-only: decrypts against
  /// a throwaway engine so nothing touches the real note set, tree, or balance.
  /// Skips txids already in storage (mined/known) and our own sends (a spend
  /// nullifier matching one of our notes means the outputs are change).
  Future<MempoolScanResult?> scanMempool() async {
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

  /// Trial-decrypt a mempool snapshot (from a poll or a subscribe push) into our
  /// 0-conf incoming notes. Isolated peek engine; same byte-order reversal,
  /// txid dedup, and own-send suppression as the block scan.
  Future<MempoolScanResult> decryptMempoolSnapshot(
      SaplingMempoolResult snapshot) async {
    final capabilities = await saplingClient.probeCapabilities();
    _usesDisplayByteOrder = capabilities.usesDisplayByteOrder;
    if (snapshot.txs.isEmpty) {
      // clear the throwaway state so the peek engine doesn't hold prior notes.
      _mempoolPeekEngine?.reset();
      return MempoolScanResult(const []);
    }

    final nativeKeys = keyManager._manager.nativeKeys;
    final knownTxids = storage.notes.map((n) => n.txid).toSet();
    final myNullifiers =
        storage.notes.map((n) => n.nullifier).whereType<String>().toSet();

    final peek =
        _mempoolPeekEngine ??= ffi.SaplingSyncEngine(isTestnet: isTestnet);
    // clear the prior cycle's throwaway notes so the sink stays bounded.
    peek.reset();

    final incoming = <MempoolIncomingNote>[];
    var position = 0;
    for (final tx in snapshot.txs) {
      if (knownTxids.contains(tx.txid)) continue; // already mined or seen

      // our own send: a spend reveals one of our nullifiers, so its outputs are
      // change coming back to us, not an incoming payment.
      final isOwnSend = tx.spends.any((spend) {
        final nfBytes = _usesDisplayByteOrder
            ? Uint8List.fromList(spend.nullifierBytes.reversed.toList())
            : spend.nullifierBytes;
        return myNullifiers.contains(hex.encode(nfBytes));
      });
      if (isOwnSend) continue;

      var txValue = 0;
      for (final output in tx.outputs) {
        // same crypto-boundary reversal as the block scan; value is
        // position-independent so the sentinel position below is fine.
        final cmuBytes = _usesDisplayByteOrder
            ? Uint8List.fromList(output.cmuBytes.reversed.toList())
            : output.cmuBytes;
        final epkBytes = _usesDisplayByteOrder
            ? Uint8List.fromList(output.epkBytes.reversed.toList())
            : output.epkBytes;
        final value = peek.tryDecryptOutput(
          keys: nativeKeys,
          cmu: cmuBytes,
          epk: epkBytes,
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
    return MempoolScanResult(incoming, truncated: snapshot.truncated);
  }

  void dispose() {
    _engine.dispose();
    _mempoolPeekEngine?.dispose();
    _mempoolPeekEngine = null;
  }
}

bool shouldLogPivxShieldSyncCheckpoint({
  required int rangeStart,
  required int rangeEnd,
  required int startHeight,
  required int targetHeight,
  int checkpointInterval = 10000,
}) {
  if (rangeStart <= startHeight) {
    return true;
  }
  if (rangeEnd >= targetHeight) {
    return true;
  }
  if (checkpointInterval <= 0) {
    return false;
  }
  return rangeEnd % checkpointInterval == 0;
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

typedef SyncProgressCallback = void Function(SyncStatus status);

class SaplingTransactionBuilderFactory {
  static Future<SaplingTransactionBuilderWrapper> create({
    required SaplingKeyManagerWrapper keyManager,
    required ShieldSyncEngineWrapper syncEngine,
    bool isTestnet = false,
  }) async {
    return SaplingTransactionBuilderWrapper(
      keyManager: keyManager,
      syncEngine: syncEngine,
      isTestnet: isTestnet,
    );
  }
}

class SaplingTransactionBuilderWrapper {
  final SaplingKeyManagerWrapper keyManager;
  final ShieldSyncEngineWrapper syncEngine;
  final bool isTestnet;
  String? _provingParamsPath;
  bool _proverInitialized = false;

  SaplingTransactionBuilderWrapper({
    required this.keyManager,
    required this.syncEngine,
    required this.isTestnet,
  });

  bool get hasProvingParams => _provingParamsPath != null && _proverInitialized;

  String get provingParamsPath => _provingParamsPath ?? '';

  /// Load the proving params (~50 MB, Groth16); downloaded/stored once.
  Future<void> loadProvingParams({required String path}) async {
    if (!await hasLocalProvingParams(path)) {
      throw Exception('Proving parameters not found at $path. '
          'Call downloadProvingParams first.');
    }

    if (!ffi.initProver(path)) {
      final error = ffi.getLastError();
      throw Exception('Failed to initialize prover: $error');
    }

    _provingParamsPath = path;
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

  /// Provision proving params from the bundled Flutter asset.
  ///
  /// Returns true when both params were copied out of the app bundle and pass
  /// SHA256 verification against [SaplingParams]. Returns false when the bundle
  /// carries no params (a build compiled WITHOUT the ~51MB asset), so the
  /// caller falls back to the network download. Only an absent/empty bundle
  /// returns false; a present-but-corrupt bundle throws (funds-critical).
  Future<bool> copyProvingParamsFromBundle(String path) async {
    final spend = await loadBundledParamOrNull(
        'packages/cw_pivx/assets/params/${SaplingParams.spendParamsFileName}');
    final output = await loadBundledParamOrNull(
        'packages/cw_pivx/assets/params/${SaplingParams.outputParamsFileName}');

    // No bundled params in this build, let the caller download them.
    if (spend == null || output == null) return false;

    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    await writeAndVerifyProvingParam(
      bytes: spend,
      destination: '$path/${SaplingParams.spendParamsFileName}',
      expectedSize: SaplingParams.spendParamsSize,
      expectedHash: SaplingParams.spendParamsHash,
    );
    await writeAndVerifyProvingParam(
      bytes: output,
      destination: '$path/${SaplingParams.outputParamsFileName}',
      expectedSize: SaplingParams.outputParamsSize,
      expectedHash: SaplingParams.outputParamsHash,
    );
    _provingParamsPath = path;
    return true;
  }

  /// Load a bundled param asset, returning null when it is absent or empty
  /// (a build without bundled params). Never throws on absence.
  static Future<Uint8List?> loadBundledParamOrNull(String assetKey) async {
    try {
      final data = await rootBundle.load(assetKey);
      if (data.lengthInBytes == 0) return null;
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } catch (_) {
      return null;
    }
  }

  /// Write [bytes] to [destination] and verify the written file's size and
  /// SHA256 against the expected values. Throws (and removes the file) on
  /// mismatch so a bad param file is never left behind.
  static Future<void> writeAndVerifyProvingParam({
    required Uint8List bytes,
    required String destination,
    required int expectedSize,
    required String expectedHash,
  }) async {
    final file = File(destination);
    await file.writeAsBytes(bytes, flush: true);
    if (!await _verifyParamFile(
      file: file,
      expectedSize: expectedSize,
      expectedHash: expectedHash,
    )) {
      if (await file.exists()) {
        await file.delete();
      }
      throw Exception(
          'PIVX Sapling bundled proving parameter verification failed for $destination');
    }
  }

  /// Download proving parameters from PIVX servers to [path].
  Future<void> downloadProvingParams({
    required String path,
    required void Function(double) onProgress,
  }) async {
    await downloadProvingParamsToPath(path: path, onProgress: onProgress);
    _provingParamsPath = path;
  }

  static Future<void> downloadProvingParamsToPath({
    required String path,
    required void Function(double) onProgress,
    String spendParamsUrl = SaplingParams.spendParamsUrl,
    int spendParamsSize = SaplingParams.spendParamsSize,
    String spendParamsHash = SaplingParams.spendParamsHash,
    String outputParamsUrl = SaplingParams.outputParamsUrl,
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
      url: spendParamsUrl,
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
      url: outputParamsUrl,
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
    required String url,
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

    await _downloadFileAtomically(
      url: url,
      destination: destination,
      expectedSize: expectedSize,
      expectedHash: expectedHash,
      onProgress: onDownloaded,
    );
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

  /// Build a transaction spending shielded notes.
  ///
  /// A Sapling destination produces a z-to-z transaction; a PIVX transparent
  /// destination produces a z-to-t (deshield) transaction with a transparent
  /// payment output and shielded change.
  Future<SaplingTransactionResult> buildTransaction({
    required SaplingTransactionOptions options,
    Set<String> reservedNullifiers = const {},
  }) async {
    final isShieldedDestination = keyManager.validateAddress(options.toAddress);
    if (!isShieldedDestination) {
      // Loose client-side shape check; the native builder performs the
      // strict base58check + network-prefix validation and fails closed.
      // PivxNetwork.isValidAddress only knows mainnet prefixes, so testnet
      // destinations are length-checked here and fully validated natively.
      final address = options.toAddress;
      final looksValidTransparent = isTestnet
          ? address.length >= 26 && address.length <= 36
          : PivxNetwork.isValidAddress(address) && !address.startsWith('ps');
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

    if (syncEngine.balance < options.amount) {
      throw Exception('Insufficient shielded balance');
    }

    if (!hasProvingParams) {
      throw Exception(
          'Proving parameters not loaded. Call loadProvingParams first.');
    }

    final syncHandle = syncEngine.nativeSyncHandle;
    final spendChainHeight = syncEngine.storage.lastSyncedHeight;
    final spendEligibility = syncEngine.storage.spendEligibilitySummaryAt(
      chainHeight: spendChainHeight,
    );
    printV(
        '[PIVX Sapling] Shielded spend eligibility: ${spendEligibility.sanitizedLogLine}');

    final spendableNullifiers = syncEngine.storage
        .spendableNotesAt(
          chainHeight: spendChainHeight,
        )
        .map((note) => note.nullifier)
        .whereType<String>()
        .toSet();
    final allNotes = ffi
        .getSpendableNotes(syncHandle)
        .where((note) => spendableNullifiers.contains(note['nullifier']))
        .where((note) => !reservedNullifiers.contains(note['nullifier']))
        .toList();

    if (allNotes.isEmpty) {
      throw Exception(
          'No spendable shielded notes available at required confirmations (${PivxShieldedConfirmationPolicy.spendConfirmations})');
    }

    // Select notes, then verify none is already spent on-chain before the
    // expensive proof. The local view can lag the node, and the same seed may
    // have spent these notes in another wallet (e.g. PIVX Core), so a locally-
    // "unspent" note may already be spent. Drop any spent note, mark it spent
    // (fixes the stale balance), and reselect so we pick spendable notes that
    // cover the amount, instead of building a tx the node rejects as
    // bad-txns-shielded-requirements-not-met after a 30-60s proof. Bounded so a
    // misbehaving node can't loop us forever.
    final nodeUsesDisplay = (await syncEngine.saplingClient.probeCapabilities())
        .usesDisplayByteOrder;
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

      // Notes hold nullifiers in serialization order; the node indexes them in
      // display order, so reverse for the query and map the result back.
      final queryToStored = <String, String>{
        for (final nf in selectedNullifiers)
          (nodeUsesDisplay ? reverseSaplingHexBytes(nf) : nf): nf,
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

    // Verify we have enough after fee
    if (!spendPlan.canBuild || totalInput < options.amount + fee) {
      throw Exception('Insufficient balance after fee');
    }

    printV('[PIVX Sapling] Shielded note selection complete');

    // A shielded spend needs a canonical Merkle witness. Fail closed against
    // nodes that cannot provide one rather than building an unspendable tx.
    final capabilities = await syncEngine.saplingClient.probeCapabilities();
    if (!capabilities.canonicalWitnesses) {
      throw Exception(
          'PIVX shielded send unavailable: this node cannot provide canonical witnesses');
    }
    final usesDisplay = capabilities.usesDisplayByteOrder;

    // Get current anchor once and require every witness to be bound to it.
    printV('[PIVX Sapling] Getting anchor...');
    final anchorResult = await syncEngine.getBestAnchor();
    printV('[PIVX Sapling] Got spend anchor');

    printV('[PIVX Sapling] Fetching witnesses...');
    final notesWithWitnesses =
        await _fetchWitnesses(selectedNotes, anchorResult, usesDisplay);
    printV('[PIVX Sapling] Witnesses fetched');
    final witnessSources = notesWithWitnesses
        .map((note) => note['witness_source'] as String?)
        .whereType<String>()
        .toList(growable: false);
    final witnessSourceSummary =
        witnessSources.isEmpty ? 'none' : witnessSources.toSet().join(',');
    printV('[PIVX Sapling] Witness source summary: $witnessSourceSummary');
    if (witnessSources
        .contains(SaplingWitnessResult.sourceCommitmentOnlyFallback)) {
      printV(
          '[PIVX Sapling] Witness fallback used; anchor-bound ElectrumX release gate remains open');
    }
    final spendAnchor = _spendAnchorForWitnesses(
          notesWithWitnesses,
        ) ??
        anchorResult.anchor;
    if (spendAnchor.toLowerCase() != anchorResult.anchor.toLowerCase()) {
      printV('[PIVX Sapling] Using witness-returned spend anchor');
    }
    // The prover decodes anchorHex with Anchor::from_bytes and compares the
    // recomputed witness root (from the serialization-order path + internal
    // note cmu) to it, so the anchor must be serialization order. spendAnchor
    // is display order on a display node; reverse it. The per-note cmu in the
    // notes JSON is already Rust serialization order and is left untouched.
    final proverAnchor =
        usesDisplay ? reverseSaplingHexBytes(spendAnchor) : spendAnchor;

    final keyHandle = keyManager._manager.nativeKeys.handle;

    final notesJson = jsonEncode(notesWithWitnesses);
    printV('[PIVX Sapling] Building shielded transaction');

    printV(
        '[PIVX Sapling] Calling FFI buildShieldedTransaction (this may take 30-60 seconds for proving)...');
    final result = ffi.buildShieldedTransaction(
      keyHandle: keyHandle,
      notesJson: notesJson,
      toAddress: options.toAddress,
      amount: options.amount,
      memo: options.memo,
      fee: fee,
      anchorHex: proverAnchor,
    );
    printV('[PIVX Sapling] FFI transaction build returned');

    if (result['status'] == 'error') {
      final nativeError = result['error']?.toString();
      final suffix =
          nativeError == null || nativeError.isEmpty ? '' : ': $nativeError';
      printV('[PIVX Sapling] Native transaction build failed$suffix');
      throw Exception('PIVX shielded transaction build failed$suffix');
    }

    final txHex = result['tx_hex'] as String;
    final txid = result['txid'] as String;

    return SaplingTransactionResult(
      rawTx: Uint8List.fromList(hex.decode(txHex)),
      txHex: txHex,
      txId: txid,
      fee: fee,
      spentNullifiers: selectedNotes
          .map((note) => note['nullifier'] as String?)
          .whereType<String>()
          .toList(growable: false),
      witnessSources: witnessSources,
    );
  }

  /// Build a transparent-to-shielded (t-to-z, shield) transaction.
  ///
  /// [utxos] entries carry txid, vout, value, script_pubkey and private_key
  /// exactly as required by the native builder, which re-verifies the key
  /// against the script hash and fails closed.
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

    final keyHandle = keyManager._manager.nativeKeys.handle;
    final utxosJson = jsonEncode(utxos);
    printV('[PIVX Sapling] Building shield (t-to-z) transaction');
    final result = ffi.buildShieldTransaction(
      keyHandle: keyHandle,
      utxosJson: utxosJson,
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

    final txHex = result['tx_hex'] as String;
    final txid = result['txid'] as String;
    return SaplingTransactionResult(
      rawTx: Uint8List.fromList(hex.decode(txHex)),
      txHex: txHex,
      txId: txid,
      fee: (result['fee'] as num?)?.toInt() ?? fee,
    );
  }

  /// Plan the fee and transparent change for a t-to-z shield spend.
  ///
  /// The destination is one Sapling output; change (if any) returns to a
  /// transparent change address. Dust change is absorbed into the fee using
  /// the transparent dust threshold.
  static ShieldedSpendPlan planShieldSpend({
    required int totalInput,
    required int amount,
    required int transparentInputs,
  }) {
    final noChangeFee = PivxFeePolicy.saplingFee(
      saplingInputs: 0,
      saplingOutputs: 1,
      transparentInputs: transparentInputs,
    );

    if (totalInput < amount + noChangeFee) {
      return ShieldedSpendPlan(fee: noChangeFee, change: 0, canBuild: false);
    }

    final noChangeRemainder = totalInput - amount - noChangeFee;
    if (noChangeRemainder <= PivxFeePolicy.transparentDustThreshold) {
      return ShieldedSpendPlan(
        fee: noChangeFee + noChangeRemainder,
        change: 0,
        canBuild: true,
      );
    }

    final withChangeFee = PivxFeePolicy.saplingFee(
      saplingInputs: 0,
      saplingOutputs: 1,
      transparentInputs: transparentInputs,
      transparentOutputs: 1,
    );
    if (totalInput < amount + withChangeFee) {
      return ShieldedSpendPlan(fee: withChangeFee, change: 0, canBuild: false);
    }

    final change = totalInput - amount - withChangeFee;
    if (change <= PivxFeePolicy.transparentDustThreshold) {
      return ShieldedSpendPlan(
        fee: withChangeFee + change,
        change: 0,
        canBuild: true,
      );
    }

    return ShieldedSpendPlan(
        fee: withChangeFee, change: change, canBuild: true);
  }

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

  /// Plan the fee and change for a shielded spend.
  ///
  /// A shielded destination (z-to-z) pays one Sapling output plus optional
  /// Sapling change; a transparent destination (z-to-t) pays one transparent
  /// output plus optional Sapling change. Change always stays shielded, so
  /// dust-change absorption always uses the shielded dust threshold.
  static ShieldedSpendPlan planShieldedSpend({
    required int totalInput,
    required int amount,
    required int saplingInputs,
    bool transparentDestination = false,
  }) {
    final destinationSaplingOutputs = transparentDestination ? 0 : 1;
    final destinationTransparentOutputs = transparentDestination ? 1 : 0;

    final noChangeFee = PivxFeePolicy.saplingFee(
      saplingInputs: saplingInputs,
      saplingOutputs: destinationSaplingOutputs,
      transparentOutputs: destinationTransparentOutputs,
    );

    if (totalInput < amount + noChangeFee) {
      return ShieldedSpendPlan(fee: noChangeFee, change: 0, canBuild: false);
    }

    final noChangeRemainder = totalInput - amount - noChangeFee;
    if (noChangeRemainder <= PivxFeePolicy.shieldedDustThreshold) {
      return ShieldedSpendPlan(
        fee: noChangeFee + noChangeRemainder,
        change: 0,
        canBuild: true,
      );
    }

    final withChangeFee = PivxFeePolicy.saplingFee(
      saplingInputs: saplingInputs,
      saplingOutputs: destinationSaplingOutputs + 1,
      transparentOutputs: destinationTransparentOutputs,
    );
    if (totalInput < amount + withChangeFee) {
      return ShieldedSpendPlan(
        fee: withChangeFee,
        change: 0,
        canBuild: false,
      );
    }

    final change = totalInput - amount - withChangeFee;
    if (change <= PivxFeePolicy.shieldedDustThreshold) {
      return ShieldedSpendPlan(
        fee: withChangeFee + change,
        change: 0,
        canBuild: true,
      );
    }

    return ShieldedSpendPlan(
      fee: withChangeFee,
      change: change,
      canBuild: true,
    );
  }

  /// Fetch merkle witnesses for notes from ElectrumX.
  ///
  /// Uses blockchain.sapling.get_witness RPC:
  /// - commitment_hex: 32-byte commitment (cmu) as hex
  /// - anchor_height: Block height of anchor
  ///
  /// Returns: {position, path, anchor, commitment, commitment_height}
  Future<List<Map<String, dynamic>>> _fetchWitnesses(
    List<Map<String, dynamic>> notes,
    BestAnchorResult anchorResult,
    bool usesDisplay,
  ) async {
    final result = <Map<String, dynamic>>[];

    for (final note in notes) {
      final noteWithWitness = Map<String, dynamic>.from(note);

      try {
        String? cmu = note['cmu'] as String?;

        if (cmu == null || cmu.isEmpty) {
          printV('[PIVX] Note missing cmu, cannot fetch witness');
          noteWithWitness['witness'] = '';
          noteWithWitness['witness_position'] = 0;
          result.add(noteWithWitness);
          continue;
        }

        // Fetch witness from ElectrumX and require it to match the selected
        // anchor that will be passed into FFI signing. The stored cmu is Rust
        // serialization order; a display-order node indexes and echoes
        // commitments in display order, so request in display order. The
        // note's own 'cmu' entry (serialization) is left untouched for the
        // prover's per-note cmu check.
        final requestCommitment =
            usesDisplay ? reverseSaplingHexBytes(cmu) : cmu;
        printV('[PIVX] Fetching shielded witness');
        final witness = await syncEngine.saplingClient.getAnchorBoundWitness(
          commitment: requestCommitment,
          anchor: anchorResult,
          notePosition: note['position'] as int?,
        );

        printV('[PIVX] Got shielded witness response');
        // Serialize path as hex-encoded concatenated hashes for the current
        // FFI transaction builder contract.
        final witnessHex = witness.path.join('');
        final firstPathLength =
            witness.path.isEmpty ? 0 : witness.path.first.length;
        final isHexPath = RegExp(r'^[0-9a-fA-F]+$').hasMatch(witnessHex);
        printV(
            '[PIVX Sapling] Witness path shape: count=${witness.path.length}, first_chars=$firstPathLength, total_chars=${witnessHex.length}, hex=$isHexPath');
        noteWithWitness['witness'] = witnessHex;
        noteWithWitness['witness_position'] = witness.position;
        noteWithWitness['anchor'] = witness.anchor;
        noteWithWitness['anchor_height'] = witness.anchorHeight;
        noteWithWitness['witness_source'] = witness.source;
      } catch (e) {
        printV('[PIVX] Failed to fetch witness');
        rethrow; // Don't continue with missing witness data
      }

      result.add(noteWithWitness);
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
  final bool useShieldedInputs;
  final bool spendAllShieldedInputs;

  SaplingTransactionOptions({
    required this.toAddress,
    required this.amount,
    this.memo,
    this.useShieldedInputs = true,
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
  final Uint8List rawTx;
  final String txHex;
  final String txId;
  final int fee;
  final List<String> spentNullifiers;
  final List<String> witnessSources;

  SaplingTransactionResult({
    required this.rawTx,
    required this.txHex,
    required this.txId,
    required this.fee,
    this.spentNullifiers = const [],
    this.witnessSources = const [],
  });
}
