/// Encrypted JSON sidecar for Sapling notes, sync cursor and addresses.

import 'dart:convert';
import 'dart:io';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

/// Provisional until the canonical Core policy is confirmed.
class PivxShieldedConfirmationPolicy {
  static const int receiveConfirmations = 6;
  static const int spendConfirmations = 6;
}

/// Counts only: logs explain selection failures without leaking values, txids
/// or nullifiers.
class PivxShieldedSpendEligibilitySummary {
  final int chainHeight;
  final int minConfirmations;
  final int totalUnspent;
  final int spendable;
  final int pendingConfirmation;
  final int pendingSpend;
  final int missingSpendingData;

  const PivxShieldedSpendEligibilitySummary({
    required this.chainHeight,
    required this.minConfirmations,
    required this.totalUnspent,
    required this.spendable,
    required this.pendingConfirmation,
    required this.pendingSpend,
    required this.missingSpendingData,
  });

  String get sanitizedLogLine =>
      'chain_height=$chainHeight min_confirmations=$minConfirmations '
      'total_unspent=$totalUnspent spendable=$spendable '
      'pending_confirmations=$pendingConfirmation '
      'pending_spend=$pendingSpend missing_spending_data=$missingSpendingData';
}

class StoredSaplingNote {
  /// txid:outputIndex.
  final String id;
  final int value;
  final int height;
  final String txid;
  final int outputIndex;
  final int treePosition;
  final String cmu;
  final String? nullifier;

  bool isSpent;

  /// Reserved by a local broadcast not yet seen mined.
  bool isPendingSpend;

  /// Server-reported spend with no matching local broadcast. Excluded from
  /// balance but reversible by rescan, so a malicious server cannot freeze
  /// funds with fabricated spends.
  bool isProvisionallySpent;

  String? spendingTxid;
  int? spendingHeight;
  String? pendingSpendingTxid;
  DateTime? pendingSpendAt;

  final DateTime discoveredAt;

  /// Block epoch; history dates off this so an import shows real times.
  /// Mutable so a rescan keeps it.
  int? blockTime;

  /// Mutable: native restore drops the memo, so a rescan keeps the stored one.
  String? memo;

  // Needed to restore the note into the native engine.
  final String? rseed;
  final String? diversifier;
  final String? pkD;

  /// diversifier + pk_d as hex.
  final String? address;
  final int? txIndex;

  StoredSaplingNote({
    required this.id,
    required this.value,
    required this.height,
    required this.txid,
    required this.outputIndex,
    required this.treePosition,
    required this.cmu,
    this.nullifier,
    this.isSpent = false,
    this.isPendingSpend = false,
    this.isProvisionallySpent = false,
    this.spendingTxid,
    this.spendingHeight,
    this.pendingSpendingTxid,
    this.pendingSpendAt,
    DateTime? discoveredAt,
    this.blockTime,
    this.memo,
    this.rseed,
    this.diversifier,
    this.pkD,
    this.address,
    this.txIndex,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  factory StoredSaplingNote.fromJson(Map<String, dynamic> json) {
    return StoredSaplingNote(
      id: json['id'] as String,
      value: json['value'] as int,
      height: json['height'] as int,
      txid: json['txid'] as String,
      outputIndex: json['outputIndex'] as int,
      treePosition: json['treePosition'] as int,
      cmu: json['cmu'] as String,
      nullifier: json['nullifier'] as String?,
      isSpent: json['isSpent'] as bool? ?? false,
      isPendingSpend: json['isPendingSpend'] as bool? ?? false,
      isProvisionallySpent: json['isProvisionallySpent'] as bool? ?? false,
      spendingTxid: json['spendingTxid'] as String?,
      spendingHeight: json['spendingHeight'] as int?,
      pendingSpendingTxid: json['pendingSpendingTxid'] as String?,
      pendingSpendAt: json['pendingSpendAt'] != null
          ? DateTime.parse(json['pendingSpendAt'] as String)
          : null,
      discoveredAt: json['discoveredAt'] != null
          ? DateTime.parse(json['discoveredAt'] as String)
          : null,
      blockTime: json['blockTime'] as int? ?? json['block_time'] as int?,
      memo: json['memo'] as String?,
      rseed: json['rseed'] as String?,
      diversifier: json['diversifier'] as String?,
      pkD: json['pk_d'] as String? ?? json['pkD'] as String?,
      address: json['address'] as String?,
      txIndex: json['tx_index'] as int? ?? json['txIndex'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
      'height': height,
      'txid': txid,
      'outputIndex': outputIndex,
      'treePosition': treePosition,
      'cmu': cmu,
      'nullifier': nullifier,
      'isSpent': isSpent,
      'isPendingSpend': isPendingSpend,
      'isProvisionallySpent': isProvisionallySpent,
      'spendingTxid': spendingTxid,
      'spendingHeight': spendingHeight,
      'pendingSpendingTxid': pendingSpendingTxid,
      'pendingSpendAt': pendingSpendAt?.toIso8601String(),
      'discoveredAt': discoveredAt.toIso8601String(),
      'blockTime': blockTime,
      'memo': memo,
      'rseed': rseed,
      'diversifier': diversifier,
      'pk_d': pkD,
      'address': address,
      'tx_index': txIndex,
    };
  }

  /// Exact keys expected by cw_pivx_restore_note.
  Map<String, dynamic> toNativeRestoreJson() {
    final addressHex = address ?? ((diversifier ?? '') + (pkD ?? ''));

    return {
      'value': value,
      'position': treePosition,
      'height': height,
      'tx_index': txIndex ?? 0,
      'output_index': outputIndex,
      'nullifier': nullifier ?? '',
      'rseed': rseed ?? '',
      'address': addressHex,
      'diversifier': diversifier ?? '',
      'pk_d': pkD ?? '',
      'cmu': cmu,
    };
  }

  bool get hasSpendingData =>
      rseed != null && diversifier != null && pkD != null && nullifier != null;

  /// The note's own block is the first confirmation.
  int confirmationsAt(int chainHeight) {
    if (height <= 0 || chainHeight < height) return 0;
    return chainHeight - height + 1;
  }

  bool isConfirmedAt(int chainHeight, int minConfirmations) =>
      confirmationsAt(chainHeight) >= minConfirmations;
}

class StoredShieldedAddress {
  final int diversifierIndex;
  final String address;
  String? label;
  final bool isDefault;

  final DateTime createdAt;

  StoredShieldedAddress({
    required this.diversifierIndex,
    required this.address,
    this.label,
    this.isDefault = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory StoredShieldedAddress.fromJson(Map<String, dynamic> json) {
    return StoredShieldedAddress(
      diversifierIndex: json['diversifierIndex'] as int,
      address: json['address'] as String,
      label: json['label'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'diversifierIndex': diversifierIndex,
      'address': address,
      'label': label,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class SaplingNoteStorage {
  String walletId;
  final EncryptionFileUtils? encryptionFileUtils;
  final String? password;
  final bool allowUnencryptedStorage;

  List<StoredSaplingNote> _notes = [];
  List<StoredShieldedAddress> _addresses = [];
  int _lastSyncedHeight = 0;
  int _nextTreePosition = 0;
  bool _hasPersistedTreePosition = false;
  Map<int, String> _scannedBlockHashes = {};
  int _nextDiversifierIndex = 1; // 0 is the default address
  bool _isLoaded = false;
  final Lock _lock = Lock();

  // A restore did ~28k inline writes of the encrypted file. Notes still save as
  // found, so a crash only rescans blocks since the checkpoint.
  int _lastSavedHeight = 0;
  static const int _checkpointEveryBlocks = 10000;
  static const int _keptBlockHashes = 200;

  SaplingNoteStorage({
    required this.walletId,
    this.encryptionFileUtils,
    this.password,
    this.allowUnencryptedStorage = false,
  }) {
    _live[walletId] = this;
  }

  // Rename runs on a second wallet instance while the open one keeps saving;
  // the live store must switch paths or it recreates the old file.
  static final Map<String, SaplingNoteStorage> _live = {};

  /// Moves the note file to [newId] under the live store's lock, if any.
  static Future<void> rename(String oldId, String newId) async {
    Future<void> move() async {
      final file = File(await pathFor(oldId));
      if (await file.exists()) await file.rename(await pathFor(newId));
    }

    final live = _live[oldId];
    if (live == null) return move();
    await live._lock.synchronized(() async {
      await move();
      live.walletId = newId;
    });
    _live.remove(oldId);
    _live[newId] = live;
  }

  void release() {
    if (identical(_live[walletId], this)) _live.remove(walletId);
  }

  List<StoredSaplingNote> get notes => List.unmodifiable(_notes);

  List<StoredShieldedAddress> get addresses => List.unmodifiable(_addresses);

  int get nextDiversifierIndex => _nextDiversifierIndex;

  /// Excludes pending and quarantined notes.
  List<StoredSaplingNote> get unspentNotes => _notes
      .where((n) => !n.isSpent && !n.isPendingSpend && !n.isProvisionallySpent)
      .toList();

  List<String> get quarantinedNullifiers => _notes
      .where((n) => n.isProvisionallySpent && !n.isSpent)
      .map((n) => n.nullifier)
      .whereType<String>()
      .toList();

  static int _sum(Iterable<StoredSaplingNote> notes) =>
      notes.fold<int>(0, (sum, n) => sum + n.value);

  List<StoredSaplingNote> spendableNotesAt({
    required int chainHeight,
    int minConfirmations = PivxShieldedConfirmationPolicy.spendConfirmations,
  }) =>
      unspentNotes
          .where((n) =>
              n.hasSpendingData &&
              n.isConfirmedAt(chainHeight, minConfirmations))
          .toList();

  int spendableBalanceAt({
    required int chainHeight,
    int minConfirmations = PivxShieldedConfirmationPolicy.spendConfirmations,
  }) =>
      _sum(spendableNotesAt(
          chainHeight: chainHeight, minConfirmations: minConfirmations));

  int pendingReceivedBalanceAt({
    required int chainHeight,
    int minConfirmations = PivxShieldedConfirmationPolicy.receiveConfirmations,
  }) =>
      _sum(unspentNotes
          .where((n) => !n.isConfirmedAt(chainHeight, minConfirmations)));

  List<StoredSaplingNote> get pendingSpentNotes =>
      _notes.where((n) => !n.isSpent && n.isPendingSpend).toList();

  int get balance => _sum(unspentNotes);

  int get spendableBalance =>
      _sum(unspentNotes.where((n) => n.hasSpendingData));

  int get pendingOutgoingBalance => _sum(pendingSpentNotes);

  PivxShieldedSpendEligibilitySummary spendEligibilitySummaryAt({
    required int chainHeight,
    int minConfirmations = PivxShieldedConfirmationPolicy.spendConfirmations,
  }) {
    var pendingConfirmation = 0;
    var pendingSpend = 0;
    var missingSpendingData = 0;
    var spendable = 0;

    final unspent = _notes.where((note) => !note.isSpent).toList();
    for (final note in unspent) {
      if (note.isPendingSpend || note.isProvisionallySpent) {
        pendingSpend++;
        continue;
      }
      if (!note.hasSpendingData) {
        missingSpendingData++;
        continue;
      }
      if (!note.isConfirmedAt(chainHeight, minConfirmations)) {
        pendingConfirmation++;
        continue;
      }
      spendable++;
    }

    return PivxShieldedSpendEligibilitySummary(
      chainHeight: chainHeight,
      minConfirmations: minConfirmations,
      totalUnspent: unspent.length,
      spendable: spendable,
      pendingConfirmation: pendingConfirmation,
      pendingSpend: pendingSpend,
      missingSpendingData: missingSpendingData,
    );
  }

  int get lastSyncedHeight => _lastSyncedHeight;

  int get nextTreePosition => _nextTreePosition;

  /// false when the cursor is only the max(note position)+1 hint, which must
  /// not be trusted without server global output positions.
  bool get hasPersistedTreePosition => _hasPersistedTreePosition;

  Map<int, String> get scannedBlockHashes =>
      Map.unmodifiable(_scannedBlockHashes);

  Future<String> get _storagePath => pathFor(walletId);

  /// Outside the wallet dir, so delete and rename must move it by hand.
  static Future<String> pathFor(String walletId) async {
    final dir = await getApplicationDocumentsDirectory();
    // `_mainnet` suffix kept so existing wallets find their note file.
    return '${dir.path}/pivx_sapling_${walletId}_mainnet.json.enc';
  }

  Future<void> load() async {
    if (_isLoaded) return;
    await _lock.synchronized(() async {
      await _loadUnlocked();
    });
  }

  Future<void> _loadUnlocked() async {
    if (_isLoaded) return;

    try {
      _assertEncryptedStorageAvailable();

      final path = await _storagePath;
      final file = File(path);
      if (await file.exists()) {
        final contents = allowUnencryptedStorage
            ? await file.readAsString()
            : await encryptionFileUtils!.read(path: path, password: password!);
        _loadFromJson(jsonDecode(contents) as Map<String, dynamic>);
      }

      _isLoaded = true;
    } catch (e) {
      printV('[PIVX Sapling Storage] Failed to load encrypted sidecar');
      _notes = [];
      _addresses = [];
      _lastSyncedHeight = 0;
      _nextTreePosition = 0;
      _hasPersistedTreePosition = false;
      _scannedBlockHashes = {};
      _nextDiversifierIndex = 1;
      _isLoaded = false;
      rethrow;
    }
  }

  void _assertEncryptedStorageAvailable() {
    if (allowUnencryptedStorage) return;
    if (encryptionFileUtils == null || password == null) {
      throw StateError(
          'PIVX Sapling sidecar storage requires wallet encryption');
    }
  }

  void _loadFromJson(Map<String, dynamic> data) {
    _lastSyncedHeight = data['lastSyncedHeight'] as int? ?? 0;
    _nextDiversifierIndex = data['nextDiversifierIndex'] as int? ?? 1;
    _notes = (data['notes'] as List<dynamic>?)
            ?.map((e) => StoredSaplingNote.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    _addresses = (data['addresses'] as List<dynamic>?)
            ?.map((e) =>
                StoredShieldedAddress.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final fallbackTreePosition = _notes.isNotEmpty
        ? _notes.map((n) => n.treePosition).reduce((a, b) => a > b ? a : b) + 1
        : 0;
    final persistedTreePosition = data['nextTreePosition'] as int?;
    _nextTreePosition = persistedTreePosition ?? fallbackTreePosition;
    _hasPersistedTreePosition = persistedTreePosition != null;
    _scannedBlockHashes = _decodeScannedBlockHashes(data['scannedBlockHashes']);
  }

  Map<int, String> _decodeScannedBlockHashes(Object? raw) {
    final hashes = <int, String>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final height = entry.key is int
            ? entry.key as int
            : int.tryParse(entry.key.toString());
        final hash = entry.value?.toString();
        if (height != null && hash != null && hash.isNotEmpty) {
          hashes[height] = hash;
        }
      }
    }
    return hashes;
  }

  /// Caller holds [_lock].
  Future<void> _save() async {
    try {
      _assertEncryptedStorageAvailable();

      final path = await _storagePath;
      final file = File(path);

      final data = <String, dynamic>{
        'lastSyncedHeight': _lastSyncedHeight,
        'nextDiversifierIndex': _nextDiversifierIndex,
        'notes': _notes.map((n) => n.toJson()).toList(),
        'addresses': _addresses.map((a) => a.toJson()).toList(),
        'scannedBlockHashes': _scannedBlockHashes
            .map((height, hash) => MapEntry('$height', hash)),
      };
      if (_hasPersistedTreePosition) {
        data['nextTreePosition'] = _nextTreePosition;
      }

      final encoded = jsonEncode(data);
      if (allowUnencryptedStorage) {
        await file.writeAsString(encoded);
      } else {
        await encryptionFileUtils!
            .write(path: path, password: password!, data: encoded);
      }
      _lastSavedHeight = _lastSyncedHeight;
    } catch (e) {
      printV('[PIVX Sapling Storage] Failed to save encrypted sidecar');
      rethrow;
    }
  }

  /// Rescan: drops notes (and so quarantine markers); addresses are kept since
  /// they derive deterministically.
  Future<void> clear() async {
    await _lock.synchronized(() async {
      _notes = [];
      _lastSyncedHeight = 0;
      _nextTreePosition = 0;
      _hasPersistedTreePosition = false;
      _scannedBlockHashes = {};
      await _save();
    });
    printV('[PIVX Sapling Storage] Cleared all notes for rescan');
  }

  Future<void> addNote(StoredSaplingNote note) async {
    await _lock.synchronized(() async {
      final existing = _notes.indexWhere((n) => n.id == note.id);
      if (existing >= 0) {
        final previous = _notes[existing];
        note.isSpent = note.isSpent || previous.isSpent;
        note.isPendingSpend = note.isPendingSpend || previous.isPendingSpend;
        note.isProvisionallySpent =
            note.isProvisionallySpent || previous.isProvisionallySpent;
        note.spendingTxid ??= previous.spendingTxid;
        note.pendingSpendingTxid ??= previous.pendingSpendingTxid;
        note.pendingSpendAt ??= previous.pendingSpendAt;
        note.memo ??= previous.memo;
        note.blockTime ??= previous.blockTime;
        _notes[existing] = note;
      } else {
        _notes.add(note);
      }
      await _save();
    });
  }

  Future<bool> markSpentByNullifier(
    String nullifier,
    String spendingTxid, {
    int? spendingHeight,
  }) async {
    return await _lock.synchronized(() async {
      final note = _notes.cast<StoredSaplingNote?>().firstWhere(
            (n) => n?.nullifier == nullifier,
            orElse: () => null,
          );

      if (note != null) {
        note.isSpent = true;
        note.isPendingSpend = false;
        note.isProvisionallySpent = false;
        note.spendingTxid = spendingTxid;
        note.spendingHeight = spendingHeight;
        note.pendingSpendingTxid = null;
        note.pendingSpendAt = null;
        await _save();
        return true;
      }
      return false;
    });
  }

  /// Terminal when it matches a local broadcast; otherwise quarantined,
  /// reversible by rescan or reorg rewind.
  Future<bool> recordObservedSpendByNullifier(
    String nullifier,
    String spendingTxid, {
    int? spendingHeight,
  }) async {
    return await _lock.synchronized(() async {
      final note = _notes.cast<StoredSaplingNote?>().firstWhere(
            (n) => n?.nullifier == nullifier,
            orElse: () => null,
          );

      if (note == null) return false;
      if (note.isSpent) return true;

      if (note.isPendingSpend) {
        note.isSpent = true;
        note.isPendingSpend = false;
        note.isProvisionallySpent = false;
        note.pendingSpendingTxid = null;
        note.pendingSpendAt = null;
      } else {
        note.isProvisionallySpent = true;
      }
      note.spendingTxid = spendingTxid;
      note.spendingHeight = spendingHeight;
      await _save();
      return true;
    });
  }

  /// After a local broadcast, so balance drops before the spend is mined.
  Future<int> markPendingSpentByNullifiers(
    List<String> nullifiers,
    String pendingTxid,
  ) async {
    if (nullifiers.isEmpty) return 0;

    return await _lock.synchronized(() async {
      final pendingSet = nullifiers.toSet();
      var reservedValue = 0;

      for (final note in _notes) {
        if (note.nullifier == null || !pendingSet.contains(note.nullifier)) {
          continue;
        }
        if (note.isSpent) continue;

        note.isPendingSpend = true;
        note.pendingSpendingTxid = pendingTxid;
        note.pendingSpendAt = DateTime.now();
        reservedValue += note.value;
      }

      if (reservedValue > 0) {
        await _save();
      }

      return reservedValue;
    });
  }

  /// Evicted or reorged-out send: its notes become spendable again. Returns the
  /// released value.
  Future<int> releasePendingSpend(String spendingTxid) async {
    return await _lock.synchronized(() async {
      var releasedValue = 0;
      for (final note in _notes) {
        if (note.isSpent) continue;
        if (note.pendingSpendingTxid != spendingTxid) continue;
        note.isPendingSpend = false;
        note.pendingSpendingTxid = null;
        note.pendingSpendAt = null;
        releasedValue += note.value;
      }
      if (releasedValue > 0) {
        await _save();
      }
      return releasedValue;
    });
  }

  Future<void> setNextTreePosition(int position) async {
    await _lock.synchronized(() async {
      if (position > _nextTreePosition) {
        _nextTreePosition = position;
        _hasPersistedTreePosition = true;
        await _save();
      }
    });
  }

  /// Hits disk only past [_checkpointEveryBlocks] unless [flush].
  Future<void> completeSyncRange({
    required int lastSyncedHeight,
    required int nextTreePosition,
    required bool treePositionIsTrusted,
    Map<int, String> blockHashes = const {},
    bool flush = false,
  }) async {
    await _lock.synchronized(() async {
      _lastSyncedHeight = lastSyncedHeight;
      if (nextTreePosition > _nextTreePosition) {
        _nextTreePosition = nextTreePosition;
      }
      if (treePositionIsTrusted) {
        _hasPersistedTreePosition = true;
      }
      _scannedBlockHashes.addAll(blockHashes);
      // Reorg detection compares the last 100 heights; keeping every scanned
      // hash made each save re-encrypt ~600k entries after a restore (UI ANR).
      _scannedBlockHashes.removeWhere((height, _) =>
          height > lastSyncedHeight ||
          height <= lastSyncedHeight - _keptBlockHashes);
      if (flush ||
          _lastSyncedHeight - _lastSavedHeight >= _checkpointEveryBlocks) {
        await _save();
      }
    });
  }

  /// End of a pass, so incremental polls persist their resume height.
  Future<void> flushSync() async {
    await _lock.synchronized(() async {
      if (_lastSyncedHeight != _lastSavedHeight) {
        await _save();
      }
    });
  }

  /// Drops later notes and spend markers. The cursor goes untrusted: the next
  /// sync must use explicit server positions.
  Future<void> rewindToHeight(int height) async {
    await _lock.synchronized(() async {
      _notes.removeWhere((note) => note.height > height);
      for (final note in _notes) {
        if (note.spendingHeight != null && note.spendingHeight! > height) {
          // A reorged-out local send reverts to pending so the disappeared-tx
          // reconcile re-checks it; a quarantined phantom spend frees fully.
          final revertedTxid = note.spendingTxid;
          final wasQuarantined = note.isProvisionallySpent;
          note.isSpent = false;
          note.isProvisionallySpent = false;
          note.spendingTxid = null;
          note.spendingHeight = null;
          if (revertedTxid != null && !wasQuarantined) {
            note.isPendingSpend = true;
            note.pendingSpendingTxid = revertedTxid;
            note.pendingSpendAt = DateTime.now();
          }
        }
      }
      _lastSyncedHeight = height;
      _nextTreePosition = 0;
      _hasPersistedTreePosition = false;
      _scannedBlockHashes.removeWhere((blockHeight, _) => blockHeight > height);
      await _save();
    });
  }

  Future<void> addShieldedAddress(StoredShieldedAddress address) async {
    await _lock.synchronized(() async {
      _addresses.add(address);
      if (address.diversifierIndex >= _nextDiversifierIndex) {
        _nextDiversifierIndex = address.diversifierIndex + 1;
      }
      await _save();
    });
  }

  Future<void> advanceNextDiversifierIndexAtLeast(int nextIndex) async {
    await _lock.synchronized(() async {
      if (nextIndex <= _nextDiversifierIndex) {
        return;
      }

      _nextDiversifierIndex = nextIndex;
      await _save();
    });
  }
}
