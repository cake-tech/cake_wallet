/// Sapling shield synchronization engine: scans for incoming notes (trial
/// decryption), tracks spent notes (nullifiers), and maintains the commitment
/// tree and per-note witnesses for transaction building.
///
/// Uses ElectrumX Sapling RPCs:
/// - `blockchain.sapling.get_outputs_by_height`: shielded outputs per block
/// - `blockchain.sapling.get_nullifier_status`: nullifier spent status
/// - `blockchain.sapling.get_best_anchor`: current best anchor
/// - `blockchain.sapling.get_commitment_info`: commitment tree state
/// - `blockchain.sapling.get_anchor_height`: block height for an anchor
library;

import 'dart:async';
import 'dart:typed_data';

import 'sapling_note.dart';
import 'sapling_key_manager.dart';

typedef SyncProgressCallback = void Function(SaplingSyncStatus status);

class SaplingBlockData {
  SaplingBlockData({
    required this.height,
    required this.outputs,
    required this.nullifiers,
    this.timestamp,
  });

  final int height;

  /// Encrypted note ciphertexts.
  final List<SaplingOutput> outputs;

  /// Spent-note markers revealed in this block.
  final List<String> nullifiers;

  final int? timestamp;
}

class SaplingOutput {
  SaplingOutput({
    required this.cmu,
    required this.ephemeralKey,
    required this.ciphertext,
    required this.txid,
    required this.outputIndex,
  });

  /// Note commitment (32-byte hex); appended to the commitment tree.
  final String cmu;

  /// Ephemeral public key for note decryption (32 bytes as hex).
  final String ephemeralKey;

  /// Encrypted note ciphertext (580 bytes as hex).
  final String ciphertext;

  final String txid;

  final int outputIndex;
}

/// Sapling commitment tree: a depth-32 Merkle tree of all note commitments.
/// Tracks tree state (for anchors) and incremental witnesses (for spending).
abstract class SaplingCommitmentTree {
  factory SaplingCommitmentTree() {
    throw UnimplementedError(
        'SaplingCommitmentTree requires native implementation');
  }

  /// Append a note commitment [cmu] (32 bytes).
  void append(Uint8List cmu);

  /// Current tree root/anchor (32-byte hash).
  Uint8List get root;

  /// Number of commitments in the tree.
  int get size;

  Uint8List serialize();

  static SaplingCommitmentTree deserialize(Uint8List bytes) {
    throw UnimplementedError(
        'SaplingCommitmentTree.deserialize requires native implementation');
  }
}

/// Incremental witness: the Merkle path from a note to the tree root, updated
/// as new notes are added.
abstract class SaplingIncrementalWitness {
  factory SaplingIncrementalWitness.fromTree(SaplingCommitmentTree tree) {
    throw UnimplementedError(
        'SaplingIncrementalWitness requires native implementation');
  }

  void append(Uint8List cmu);

  /// Merkle path for this witness; null if not yet valid.
  List<Uint8List>? get path;

  int get position;

  /// Root at the time this witness was created.
  Uint8List get root;

  Uint8List serialize();

  static SaplingIncrementalWitness deserialize(Uint8List bytes) {
    throw UnimplementedError(
        'SaplingIncrementalWitness.deserialize requires native implementation');
  }
}

/// Shield sync engine for scanning and tracking Sapling notes.
abstract class ShieldSyncEngine {
  ShieldSyncEngine({
    required this.keyManager,
    required this.isTestnet,
  });

  final SaplingKeyManager keyManager;

  final bool isTestnet;

  int get lastSyncedBlock;

  int get currentBlockHeight;

  bool get isSyncing;

  SaplingSyncStatus get syncStatus;

  /// The total shielded balance in zatoshis.
  int get balance;

  double get balancePivx => balance / 100000000.0;

  /// The pending (unconfirmed) balance in zatoshis.
  int get pendingBalance;

  List<SpendableNote> get spendableNotes;

  List<SpendableNote> get spentNotes;

  SaplingCommitmentTree get commitmentTree;

  /// Load saved sync state and prepare for syncing.
  Future<void> initialize();

  /// Start syncing; [startHeight] defaults to Sapling activation.
  Future<void> startSync({
    int? startHeight,
    SyncProgressCallback? onProgress,
  });

  Future<void> stopSync();

  /// Clear notes after [height] and rescan.
  Future<void> rescan(int height);

  /// Spendable notes totaling >= [amount] (zatoshis), smallest-first for
  /// consolidation.
  List<SpendableNote> selectNotesForAmount(int amount, {int maxNotes = 10});

  /// Whether [nullifier] is known (double-spend detection).
  bool isNullifierKnown(String nullifier);

  /// Mark notes spent by nullifier, after broadcasting a transaction.
  void markNotesSpent(List<String> nullifiers, String txid);

  Uint8List get currentAnchor;

  Future<Uint8List?> getAnchorAtHeight(int height);

  Future<void> save();

  Future<void> load();

  void dispose();
}

/// Sapling-specific ElectrumX RPC methods the server must support.
abstract class ElectrumSaplingRpc {
  /// RPC blockchain.sapling.get_outputs_by_height: outputs (cmu, epk,
  /// ciphertext) for a block range.
  Future<List<SaplingBlockData>> getOutputsByHeight(
      int startHeight, int endHeight);

  /// RPC blockchain.sapling.get_nullifier_status: map of nullifier -> spent.
  Future<Map<String, bool>> getNullifierStatus(List<String> nullifiers);

  /// RPC blockchain.sapling.get_commitment_info: tree state and anchor at a height.
  Future<CommitmentInfo> getCommitmentInfo(int height);

  /// RPC blockchain.sapling.get_anchor_height: height where [anchor] was the root.
  Future<int?> getAnchorHeight(String anchor);

  /// RPC blockchain.sapling.get_best_anchor: best anchor and its height.
  Future<AnchorInfo> getBestAnchor();
}

class CommitmentInfo {
  CommitmentInfo({
    required this.height,
    required this.root,
    required this.size,
  });

  final int height;

  /// Tree root (anchor) at this height.
  final String root;

  /// Number of commitments in the tree.
  final int size;
}

class AnchorInfo {
  AnchorInfo({
    required this.anchor,
    required this.height,
  });

  /// The anchor (tree root).
  final String anchor;

  final int height;
}
