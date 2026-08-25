/// Persistent storage for Sapling notes discovered during sync (JSON file).

import 'dart:convert';
import 'dart:io';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

/// Provisional PIVX shielded confirmation policy used by wallet-side balance
/// separation until release owner/canonical Core policy is confirmed.
class PivxShieldedConfirmationPolicy {
  static const int receiveConfirmations = 6;
  static const int spendConfirmations = 6;
}

/// Count-only shielded spend-eligibility diagnostics. Intentionally omits
/// values, txids, commitments, nullifiers, and addresses so logs can explain
/// selection failures without exposing wallet metadata.
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
  /// Unique identifier (txid:index).
  final String id;

  /// The value in zatoshis.
  final int value;

  /// Block height where this note was created.
  final int height;

  /// Transaction ID that created this note.
  final String txid;

  final int outputIndex;

  final int treePosition;

  /// Note commitment (cmu) as hex.
  final String cmu;

  /// Nullifier as hex (computed when we have spending key).
  final String? nullifier;

  bool isSpent;

  /// Whether this note is reserved by a locally broadcast shielded spend that
  /// has not been observed in a mined Sapling spend yet.
  bool isPendingSpend;

  /// Whether a server-reported spend was observed for this note without a
  /// matching locally broadcast transaction. Quarantined notes are excluded
  /// from spendable balance but the marker is reversible by rescan, so a
  /// malicious server cannot permanently freeze funds with fabricated spends.
  bool isProvisionallySpent;

  /// Transaction ID that spent this note (if spent).
  String? spendingTxid;

  /// Block height where this note's nullifier was mined as spent.
  int? spendingHeight;

  /// Transaction ID that is expected to spend this note, if pending.
  String? pendingSpendingTxid;

  /// Timestamp when the outgoing spend reservation was recorded.
  DateTime? pendingSpendAt;

  final DateTime discoveredAt;

  /// Unix epoch of the block that mined this note. History dates off this, not
  /// discoveredAt (scan time), so an import shows real times. Mutable so a
  /// rescan keeps it; null for legacy notes stored before it was captured.
  int? blockTime;

  /// Decrypted memo. Mutable so a rescan (which loses the memo because native
  /// restore drops it) can keep the previously stored value.
  String? memo;

  // Cryptographic data needed to restore note to native engine
  /// Random seed (rseed) as hex, 32 bytes
  final String? rseed;

  /// Diversifier as hex, 11 bytes
  final String? diversifier;

  /// Diversified transmission key (pk_d) as hex, 32 bytes
  final String? pkD;

  /// Recipient address as hex
  final String? address;

  /// Transaction index within the block
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

  /// JSON with the exact keys expected by the native cw_pivx_restore_note.
  Map<String, dynamic> toNativeRestoreJson() {
    // The address field should be diversifier + pk_d concatenated (43 bytes as hex = 86 chars)
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

  /// Check if this note has all the cryptographic data needed for spending.
  bool get hasSpendingData =>
      rseed != null && diversifier != null && pkD != null && nullifier != null;

  /// Confirmation count at [chainHeight]. The block containing the note counts
  /// as the first confirmation.
  int confirmationsAt(int chainHeight) {
    if (height <= 0 || chainHeight < height) return 0;
    return chainHeight - height + 1;
  }

  bool isConfirmedAt(int chainHeight, int minConfirmations) =>
      confirmationsAt(chainHeight) >= minConfirmations;

  /// The value in PIVX.
  double get valuePivx => value / 100000000.0;
}

class StoredShieldedAddress {
  final int diversifierIndex;

  /// The encoded address (ps1...).
  final String address;

  String? label;

  /// Default address (index 0).
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
  final String walletId;
  final bool isTestnet;
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

  // height of the last full sidecar write. completeSyncRange only rewrites the
  // (large, encrypted) file once we've scanned this many blocks past it, instead
  // of per block/range. a restore did ~28k inline writes. notes are still saved
  // as they're found, so a crash only re-scans the blocks since the checkpoint.
  int _lastSavedHeight = 0;
  static const int _checkpointEveryBlocks = 10000;

  SaplingNoteStorage({
    required this.walletId,
    this.isTestnet = false,
    this.encryptionFileUtils,
    this.password,
    this.allowUnencryptedStorage = false,
  });

  List<StoredSaplingNote> get notes => List.unmodifiable(_notes);

  List<StoredShieldedAddress> get addresses => List.unmodifiable(_addresses);

  int get nextDiversifierIndex => _nextDiversifierIndex;

  /// Get unspent notes. Quarantined (provisionally spent) notes are excluded
  /// so an unverified server-reported spend can never inflate spendable funds.
  List<StoredSaplingNote> get unspentNotes => _notes
      .where((n) => !n.isSpent && !n.isPendingSpend && !n.isProvisionallySpent)
      .toList();

  /// Nullifiers of notes quarantined by server-reported spends that did not
  /// match a locally broadcast transaction. Lets the wallet layer surface a
  /// node-integrity warning. Reset by [clear] (rescan).
  List<String> get quarantinedNullifiers => _notes
      .where((n) => n.isProvisionallySpent && !n.isSpent)
      .map((n) => n.nullifier)
      .whereType<String>()
      .toList();

  /// Get notes that can be restored into the native spender and selected.
  List<StoredSaplingNote> get spendableNotes =>
      unspentNotes.where((n) => n.hasSpendingData).toList();

  List<StoredSaplingNote> confirmedNotesAt({
    required int chainHeight,
    int minConfirmations = PivxShieldedConfirmationPolicy.receiveConfirmations,
    bool requireSpendingData = false,
  }) {
    return unspentNotes.where((note) {
      if (requireSpendingData && !note.hasSpendingData) return false;
      return note.isConfirmedAt(chainHeight, minConfirmations);
    }).toList();
  }

  List<StoredSaplingNote> pendingReceivedNotesAt({
    required int chainHeight,
    int minConfirmations = PivxShieldedConfirmationPolicy.receiveConfirmations,
  }) {
    return unspentNotes
        .where((note) => !note.isConfirmedAt(chainHeight, minConfirmations))
        .toList();
  }

  List<StoredSaplingNote> spendableNotesAt({
    required int chainHeight,
    int minConfirmations = PivxShieldedConfirmationPolicy.spendConfirmations,
  }) {
    return confirmedNotesAt(
      chainHeight: chainHeight,
      minConfirmations: minConfirmations,
      requireSpendingData: true,
    );
  }

  /// Get notes reserved by an outgoing transaction awaiting confirmation.
  List<StoredSaplingNote> get pendingSpentNotes =>
      _notes.where((n) => !n.isSpent && n.isPendingSpend).toList();

  /// Total unreserved observed balance; use getBalanceSafe() for thread safety.
  int get balance => unspentNotes.fold<int>(0, (sum, n) => sum + n.value);

  /// Total balance with enough local data to spend.
  int get spendableBalance =>
      spendableNotes.fold<int>(0, (sum, n) => sum + n.value);

  int confirmedBalanceAt({
    required int chainHeight,
    int minConfirmations = PivxShieldedConfirmationPolicy.receiveConfirmations,
    bool requireSpendingData = true,
  }) {
    return confirmedNotesAt(
      chainHeight: chainHeight,
      minConfirmations: minConfirmations,
      requireSpendingData: requireSpendingData,
    ).fold<int>(0, (sum, note) => sum + note.value);
  }

  int pendingReceivedBalanceAt({
    required int chainHeight,
    int minConfirmations = PivxShieldedConfirmationPolicy.receiveConfirmations,
  }) {
    return pendingReceivedNotesAt(
      chainHeight: chainHeight,
      minConfirmations: minConfirmations,
    ).fold<int>(0, (sum, note) => sum + note.value);
  }

  int spendableBalanceAt({
    required int chainHeight,
    int minConfirmations = PivxShieldedConfirmationPolicy.spendConfirmations,
  }) {
    return spendableNotesAt(
      chainHeight: chainHeight,
      minConfirmations: minConfirmations,
    ).fold<int>(0, (sum, note) => sum + note.value);
  }

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

  /// Get locally reserved outgoing value.
  int get pendingOutgoingBalance =>
      pendingSpentNotes.fold<int>(0, (sum, n) => sum + n.value);

  /// Total balance (thread-safe).
  Future<int> getBalanceSafe() async {
    return await _lock.synchronized<int>(() {
      return balance;
    });
  }

  int get lastSyncedHeight => _lastSyncedHeight;

  /// Get the next canonical global Sapling commitment tree position.
  int get nextTreePosition => _nextTreePosition;

  /// Whether the global tree cursor came from current encrypted storage.
  ///
  /// Older sidecars did not persist a global cursor, so loading
  /// max(owned-note-position)+1 is only a legacy hint. It must not be trusted
  /// for resumed post-activation scanning unless the server returns explicit
  /// global output positions.
  bool get hasPersistedTreePosition => _hasPersistedTreePosition;

  /// Block hashes recorded for scanned Sapling heights.
  Map<int, String> get scannedBlockHashes =>
      Map.unmodifiable(_scannedBlockHashes);

  Future<String> get _storagePath async {
    final dir = await getApplicationDocumentsDirectory();
    final network = isTestnet ? 'testnet' : 'mainnet';
    return '${dir.path}/pivx_sapling_${walletId}_$network.json.enc';
  }

  /// Legacy plaintext path used before PIVX Sapling sidecar encryption.
  Future<String> get _legacyPlaintextStoragePath async {
    final dir = await getApplicationDocumentsDirectory();
    final network = isTestnet ? 'testnet' : 'mainnet';
    return '${dir.path}/pivx_sapling_${walletId}_$network.json';
  }

  /// Load notes from storage (thread-safe).
  Future<void> load() async {
    if (_isLoaded) return;
    await _lock.synchronized(() async {
      await _loadUnlocked();
    });
  }

  /// Internal load method (must be called within lock).
  Future<void> _loadUnlocked() async {
    if (_isLoaded) return;

    try {
      _assertEncryptedStorageAvailable();

      final encryptedPath = await _storagePath;
      final encryptedFile = File(encryptedPath);
      final legacyPath = await _legacyPlaintextStoragePath;
      final legacyFile = File(legacyPath);

      if (await encryptedFile.exists()) {
        final contents = allowUnencryptedStorage
            ? await encryptedFile.readAsString()
            : await encryptionFileUtils!
                .read(path: encryptedPath, password: password!);
        final data = jsonDecode(contents) as Map<String, dynamic>;
        _loadFromJson(data);
      } else if (await legacyFile.exists()) {
        if (allowUnencryptedStorage) {
          final contents = await legacyFile.readAsString();
          final data = jsonDecode(contents) as Map<String, dynamic>;
          _loadFromJson(data);
          _isLoaded = true;
          return;
        }

        final contents = await legacyFile.readAsString();
        final data = jsonDecode(contents) as Map<String, dynamic>;
        _loadFromJson(data);

        await _save();
        await legacyFile.delete();
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

  /// Save notes to storage (thread-safe public method).
  Future<void> save() async {
    await _lock.synchronized(() async {
      await _save();
    });
  }

  /// Internal save method (must be called within lock).
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

  /// Clear all notes and reset sync state (thread-safe).
  /// Used for rescanning the blockchain. Also resets quarantine markers since
  /// notes are dropped and rediscovered from chain data.
  Future<void> clear() async {
    await _lock.synchronized(() async {
      _notes = [];
      _lastSyncedHeight = 0;
      _nextTreePosition = 0;
      _hasPersistedTreePosition = false;
      _scannedBlockHashes = {};
      // Keep addresses, they're derived deterministically
      await _save();
    });
    printV('[PIVX Sapling Storage] Cleared all notes for rescan');
  }

  /// Add a new note (thread-safe).
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
        // a rescan re-decrypts a note the native engine restored without a memo,
        // so keep the previously stored memo instead of nulling it.
        note.memo ??= previous.memo;
        note.blockTime ??= previous.blockTime;
        _notes[existing] = note;
      } else {
        _notes.add(note);
      }
      await _save();
    });
  }

  /// Mark a note as spent (thread-safe).
  Future<void> markSpent(String noteId, String spendingTxid) async {
    await _lock.synchronized(() async {
      final note = _notes.firstWhere((n) => n.id == noteId);
      note.isSpent = true;
      note.isPendingSpend = false;
      note.isProvisionallySpent = false;
      note.spendingTxid = spendingTxid;
      note.spendingHeight = null;
      note.pendingSpendingTxid = null;
      note.pendingSpendAt = null;
      await _save();
    });
  }

  /// Mark notes spent by nullifier (thread-safe).
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

  /// Record a server-reported spend for [nullifier] (thread-safe).
  ///
  /// A spend matching a locally broadcast (pending outgoing) transaction is
  /// terminal, exactly like [markSpentByNullifier]. An unexpected spend is
  /// quarantined instead: the note is marked provisionally spent, excluded
  /// from spendable balance, and the marker is reversible by rescan
  /// ([clear]) or reorg rewind, so a malicious ElectrumX server cannot
  /// irreversibly freeze funds by fabricating spend events.
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
      if (note.isSpent) return true; // Already terminal; nothing to change.

      if (note.isPendingSpend) {
        // Matches a transaction this wallet broadcast: terminal spend.
        note.isSpent = true;
        note.isPendingSpend = false;
        note.isProvisionallySpent = false;
        note.pendingSpendingTxid = null;
        note.pendingSpendAt = null;
      } else {
        // No local outgoing state for this nullifier: quarantine.
        note.isProvisionallySpent = true;
      }
      note.spendingTxid = spendingTxid;
      note.spendingHeight = spendingHeight;
      await _save();
      return true;
    });
  }

  /// Reserve notes by nullifier after a successful local broadcast.
  ///
  /// Reserved notes are excluded from spendable balance immediately, before the
  /// spending nullifier appears in a later scanned block.
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

  /// Clear local pending-spend reservations.
  ///
  /// This is intended for debug/test recovery when a locally constructed
  /// transaction was not accepted by the node but older code already reserved
  /// its nullifiers.
  Future<int> clearPendingSpentNotes() async {
    return await _lock.synchronized(() async {
      var clearedValue = 0;

      for (final note in _notes) {
        if (!note.isPendingSpend || note.isSpent) continue;

        note.isPendingSpend = false;
        note.pendingSpendingTxid = null;
        note.pendingSpendAt = null;
        clearedValue += note.value;
      }

      if (clearedValue > 0) {
        await _save();
      }

      return clearedValue;
    });
  }

  /// Release the pending-spend reservation for [spendingTxid] (an evicted or
  /// reorged-out send) so the reserved notes are spendable again. Returns the
  /// released value in zatoshis. Only touches notes reserved by this txid;
  /// mined-spent notes (isSpent) are left alone.
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

  /// Update the last synced height (thread-safe).
  Future<void> setLastSyncedHeight(int height) async {
    await _lock.synchronized(() async {
      _lastSyncedHeight = height;
      await _save();
    });
  }

  /// Update the next canonical Sapling tree position after processing outputs.
  Future<void> setNextTreePosition(int position) async {
    await _lock.synchronized(() async {
      if (position > _nextTreePosition) {
        _nextTreePosition = position;
        _hasPersistedTreePosition = true;
        await _save();
      }
    });
  }

  /// Update sync height and global tree cursor. The write is checkpointed: set
  /// [flush] to force it (e.g. at the end of a sync pass), otherwise it only
  /// hits disk once progress passes [_checkpointEveryBlocks].
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
      _scannedBlockHashes.removeWhere((height, _) => height > lastSyncedHeight);
      if (flush ||
          _lastSyncedHeight - _lastSavedHeight >= _checkpointEveryBlocks) {
        await _save();
      }
    });
  }

  /// Force the checkpointed sync state to disk (call at the end of a sync pass
  /// so incremental polls persist their resume height).
  Future<void> flushSync() async {
    await _lock.synchronized(() async {
      if (_lastSyncedHeight != _lastSavedHeight) {
        await _save();
      }
    });
  }

  /// Rewind shielded state to [height] after a detected reorg.
  ///
  /// Notes created after the rewind point are removed. Spend markers observed
  /// after that point are cleared so the rescan can re-apply the canonical
  /// branch. The global tree cursor is intentionally marked untrusted because
  /// the next sync must rely on explicit server positions after a rollback.
  Future<void> rewindToHeight(int height) async {
    await _lock.synchronized(() async {
      _notes.removeWhere((note) => note.height > height);
      for (final note in _notes) {
        if (note.spendingHeight != null && note.spendingHeight! > height) {
          // A real local send that reorged out reverts to PENDING, keeping the
          // txid so the disappeared-tx reconcile can re-check it before the note
          // is spendable again. A quarantined phantom server spend has no real
          // send behind it, so a reorg past the claimed height frees it fully.
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

  List<StoredSaplingNote> getNotesInRange(int startHeight, int endHeight) {
    return _notes
        .where((n) => n.height >= startHeight && n.height <= endHeight)
        .toList();
  }

  /// Add a new shielded address (thread-safe).
  Future<void> addAddress(StoredShieldedAddress address) async {
    await _lock.synchronized(() async {
      final existing =
          _addresses.indexWhere((a) => a.address == address.address);
      if (existing >= 0) {
        _addresses[existing] = address;
      } else {
        _addresses.add(address);
      }
      if (address.diversifierIndex >= _nextDiversifierIndex) {
        _nextDiversifierIndex = address.diversifierIndex + 1;
      }
      await _save();
    });
  }

  /// Get the next diversifier index and increment it.
  ///
  /// Synchronous (no awaits), so it cannot interleave with locked sections on
  /// the single-threaded event loop; the next persisting write saves it.
  int getAndIncrementDiversifierIndex() {
    final index = _nextDiversifierIndex;
    _nextDiversifierIndex++;
    return index;
  }

  /// Advance the next shielded receive index without moving it backwards
  /// (thread-safe).
  Future<void> advanceNextDiversifierIndexAtLeast(int nextIndex) async {
    await _lock.synchronized(() async {
      if (nextIndex <= _nextDiversifierIndex) {
        return;
      }

      _nextDiversifierIndex = nextIndex;
      await _save();
    });
  }

  /// Update an address label (thread-safe).
  Future<void> updateAddressLabel(String address, String? label) async {
    await _lock.synchronized(() async {
      final stored = _addresses.cast<StoredShieldedAddress?>().firstWhere(
            (a) => a?.address == address,
            orElse: () => null,
          );
      if (stored != null) {
        stored.label = label;
        await _save();
      }
    });
  }

  StoredShieldedAddress? getAddressByEncoded(String address) {
    return _addresses.cast<StoredShieldedAddress?>().firstWhere(
          (a) => a?.address == address,
          orElse: () => null,
        );
  }

  /// Clear addresses (keeps notes and sync state, thread-safe).
  Future<void> clearAddresses() async {
    await _lock.synchronized(() async {
      _addresses.clear();
      _nextDiversifierIndex = 1;
      await _save();
    });
  }
}
