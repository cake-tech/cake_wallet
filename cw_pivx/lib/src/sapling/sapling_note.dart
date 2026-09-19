/// Sapling note data model: a unit of value in the shielded pool, decryptable
/// and spendable only by the holder of the spending key.
library;

import 'dart:typed_data';

import 'package:hive/hive.dart';

part 'sapling_note.g.dart';

/// A Sapling note (shielded value). The note commitment is:
/// NoteCommitment = PedersenHash("Zcash_PH", [g_d^ivk | pk_d | v | rcm]).
@HiveType(typeId: 150)
class SaplingNote {
  SaplingNote({
    required this.diversifier,
    required this.pkD,
    required this.value,
    required this.rcm,
    required this.rseed,
    this.memo,
  });

  /// Diversifier (11 bytes); derives the transmission key g_d.
  @HiveField(0)
  final Uint8List diversifier;

  /// Diversified transmission key pk_d (32 bytes).
  @HiveField(1)
  final Uint8List pkD;

  /// The value of the note in zatoshis.
  @HiveField(2)
  final int value;

  /// Commitment randomness rcm (32 bytes); blinds the note commitment.
  @HiveField(3)
  final Uint8List rcm;

  /// Note randomness seed (32 bytes); derives v2-note randomness.
  @HiveField(4)
  final Uint8List rseed;

  /// Optional memo field (512 bytes, UTF-8 encoded).
  @HiveField(5)
  final String? memo;

  Uint8List toBytes() {
    final writer = BytesBuilder();
    writer.add(diversifier);
    writer.add(pkD);
    writer.add(_intToBytes(value, 8));
    writer.add(rcm);
    writer.add(rseed);
    return writer.toBytes();
  }

  static SaplingNote fromBytes(Uint8List bytes) {
    if (bytes.length < 115) {
      throw ArgumentError('Invalid note bytes length');
    }
    var offset = 0;
    final diversifier = bytes.sublist(offset, offset + 11);
    offset += 11;
    final pkD = bytes.sublist(offset, offset + 32);
    offset += 32;
    final value = _bytesToInt(bytes.sublist(offset, offset + 8));
    offset += 8;
    final rcm = bytes.sublist(offset, offset + 32);
    offset += 32;
    final rseed = bytes.sublist(offset, offset + 32);
    return SaplingNote(
      diversifier: diversifier,
      pkD: pkD,
      value: value,
      rcm: rcm,
      rseed: rseed,
    );
  }

  static Uint8List _intToBytes(int value, int length) {
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = (value >> (i * 8)) & 0xFF;
    }
    return bytes;
  }

  static int _bytesToInt(Uint8List bytes) {
    var value = 0;
    for (var i = 0; i < bytes.length; i++) {
      value |= bytes[i] << (i * 8);
    }
    return value;
  }
}

/// A spendable Sapling note plus its witness (Merkle path to the tree root) and
/// nullifier. The witness is a serialized incremental witness that tracks the
/// note's tree position as blocks are added.
@HiveType(typeId: 151)
class SpendableNote {
  SpendableNote({
    required this.note,
    required this.witness,
    required this.nullifier,
    required this.txid,
    required this.outputIndex,
    required this.blockHeight,
    required this.isSpent,
    this.spendingTxid,
  });

  @HiveField(0)
  final SaplingNote note;

  /// Incremental witness (Merkle path), serialized as hex.
  @HiveField(1)
  String witness;

  /// Nullifier (32-byte hex); derived from note + spending key + witness position.
  @HiveField(2)
  final String nullifier;

  /// The transaction ID that created this note.
  @HiveField(3)
  final String txid;

  /// The output index within the transaction.
  @HiveField(4)
  final int outputIndex;

  /// The block height where this note was created.
  @HiveField(5)
  final int blockHeight;

  /// Whether this note has been spent.
  @HiveField(6)
  bool isSpent;

  /// The transaction ID that spent this note (if spent).
  @HiveField(7)
  String? spendingTxid;

  /// The value of the note in zatoshis.
  int get value => note.value;

  /// The value of the note in PIVX.
  double get valuePivx => value / 100000000.0;
}

class SaplingSyncStatus {
  SaplingSyncStatus({
    required this.lastSyncedBlock,
    required this.currentBlock,
    required this.progress,
    required this.isSyncing,
    this.error,
  });

  /// The last block that was fully synced.
  final int lastSyncedBlock;

  /// The current chain tip.
  final int currentBlock;

  /// Sync progress as a percentage (0.0 to 1.0).
  final double progress;

  final bool isSyncing;

  final String? error;

  factory SaplingSyncStatus.notStarted() => SaplingSyncStatus(
        lastSyncedBlock: 0,
        currentBlock: 0,
        progress: 0.0,
        isSyncing: false,
      );

  factory SaplingSyncStatus.complete(int block) => SaplingSyncStatus(
        lastSyncedBlock: block,
        currentBlock: block,
        progress: 1.0,
        isSyncing: false,
      );
}
