/// PIVX Sapling ElectrumX API client: type-safe access to Sapling-specific RPCs.
///
/// - `blockchain.sapling.capabilities`: probe v1 RPC contract metadata
/// - `blockchain.sapling.get_block_range`: v1 block-range envelopes
/// - `blockchain.sapling.get_nullifier_status`: nullifier spent status
/// - `blockchain.sapling.get_commitment_info`: commitment details
/// - `blockchain.sapling.get_best_anchor`: current anchor metadata
/// - `blockchain.sapling.get_witness`: anchor-bound Merkle witness
/// - legacy aliases remain as fallbacks until default nodes expose v1 metadata
///
/// Activation heights: mainnet 2,700,500, testnet 201.

import 'dart:async';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_pivx/src/sapling/sapling_ffi.dart' as sapling_ffi;

/// Locally recomputes the Sapling Merkle root for a witness and compares it
/// to the expected anchor. Returns true on match, false on a clean mismatch,
/// and throws when verification itself cannot be performed.
typedef WitnessRootVerifier = bool Function({
  required String witnessHex,
  required String cmuHex,
  required String anchorHex,
  required int position,
});

int? _optionalInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

/// Reverse the byte order of a 32-byte (64 hex char) value.
///
/// PIVX v1 ElectrumX servers advertise `hex_byte_order: "display"`, emitting
/// every 32-byte value (cmu, epk, anchor, nullifier, cv, rk) big-endian via
/// uint256 GetHex. The native Sapling crypto (`Anchor::from_bytes`,
/// `ExtractedNoteCommitment::from_bytes`, jubjub `AffinePoint::from_bytes`,
/// nullifier matching) works in little-endian serialization order, so every
/// 32-byte value must be reversed at the crypto boundary when the node uses
/// display order, including cmu and epk on the trial-decryption/receive path.
/// The only contract exception is witness path nodes. Variable-length blobs
/// (ciphertexts, proofs) are raw wire bytes and are never reversed.
String reverseSaplingHexBytes(String hexValue) {
  final buffer = StringBuffer();
  for (var offset = hexValue.length; offset >= 2; offset -= 2) {
    buffer.write(hexValue.substring(offset - 2, offset));
  }
  return buffer.toString();
}

/// v1 get_block_range error types that mean "not ready yet, retry" rather than
/// a hard failure. Never advance the synced height past these.
const Set<String> _retryableRangeErrorTypes = {
  'index_incomplete',
  'index_not_ready',
  'backend_timeout',
};

String? _rangeErrorType(Object? error) {
  if (error == null) return null;
  if (error is Map) {
    return _optionalString(error['type']) ?? _optionalString(error['code']);
  }
  if (error is String) {
    return error.isEmpty ? null : error;
  }
  return null;
}

const String _v1LiveProbeHex32 =
    '0000000000000000000000000000000000000000000000000000000000000000';

class _BatchResult {
  final List<SaplingBlock> blocks;
  final int startHeight;
  final int endHeight;
  final Map<int, String> blockHashes;
  _BatchResult(this.blocks, this.startHeight, this.endHeight, this.blockHashes);
}

class SaplingRpcException implements Exception {
  final String message;
  final Object? cause;

  SaplingRpcException(this.message, [this.cause]);

  @override
  String toString() => cause == null ? message : '$message: $cause';
}

/// A retryable get_block_range failure (indexer lag / backend timeout). The
/// sync loop already retries on any [SaplingRpcException]; this distinct
/// subtype marks the "not ready yet" case so callers never treat it as a hard
/// malformed-data error and never advance the synced height past it.
class SaplingRetryableRangeException extends SaplingRpcException {
  SaplingRetryableRangeException(super.message, [super.cause]);
}

/// capability probe that failed on an incomplete/garbled caps payload (worth
/// retrying), not a definitive rejection (wrong network, half-upgraded v1,
/// unsupported node). carries the cause so the real message surfaces once
/// retries are exhausted.
class _RetryableCapabilityProbe implements Exception {
  _RetryableCapabilityProbe(this.cause);
  final Object cause;
  @override
  String toString() => 'RetryableCapabilityProbe: $cause';
}

// cap on a single get_block_range. only trips when the node keeps the socket
// alive (keep-alive ping still answers, no disconnect) but stalls on the range
// query. call() has no timeout, so this stops that stall wedging the sync.
const Duration kSaplingBlockRangeFetchTimeout = Duration(seconds: 30);

class SaplingRpcCapabilities {
  static const String v1ContractId = 'pivx.sapling.electrumx.v1';
  static const String legacyBlockRangeContractId = 'legacy.block_range';

  final bool supportsBlockRange;
  final bool supportsGlobalOutputPositions;
  final bool supportsBestAnchor;
  final bool supportsWitness;
  final bool supportsBlockHashes;
  final bool supportsStructuredErrors;
  final String? network;
  final int? activationHeight;
  final int? maxBlockRange;
  final String? contract;
  final String? serverVersion;
  final String? pivxCoreVersion;
  final Set<String> methods;

  /// Raw `hex_byte_order` advertised by the node ("display" or "serialization").
  final String? hexByteOrder;

  /// Node can serve canonical Merkle witnesses for shielded spends. True only
  /// when `features.canonical_witnesses` is set AND a witness backend is wired
  /// up (`witness_backend` present). Shielded sends are gated on this.
  final bool canonicalWitnesses;

  /// Node uses consensus (block-anchored) anchors.
  final bool consensusAnchors;

  /// Raw `index_status` block (ready/state/db_height/daemon_height/lag/...).
  final Map<String, dynamic>? indexStatus;

  /// Structured get_block_range error types the node may return.
  final List<String> rangeErrorTypes;

  /// node serves the sparse active-height index
  /// (`blockchain.sapling.get_active_heights`); lets a restore skip empty block
  /// windows instead of scanning every 100-block range.
  final bool supportsActiveHeights;

  /// Max heights the node returns per get_active_heights call
  /// (`active_heights_max_limit`); null when not advertised.
  final int? activeHeightsMaxLimit;

  /// node guarantees `db_height` advances past a block only once its Sapling
  /// data is committed and queryable (no committed-but-empty window). when true,
  /// scan right at db_height; when false, stay a small margin behind.
  final bool supportsConsistentDbHeight;

  /// node exposes get_mempool: unconfirmed Sapling outputs for trial-decryption,
  /// so incoming shielded shows at 0-conf instead of waiting a block.
  final bool supportsMempool;

  /// node exposes mempool.subscribe: push the mempool envelope on change, so the
  /// wallet swaps its poll for one subscription per session.
  final bool supportsMempoolSubscribe;

  static const Set<String> requiredV1Methods = {
    'blockchain.sapling.get_block_range',
    'blockchain.sapling.get_best_anchor',
    'blockchain.sapling.get_witness',
    'blockchain.sapling.get_nullifier_status',
    'blockchain.sapling.get_commitment_info',
  };

  const SaplingRpcCapabilities({
    required this.supportsBlockRange,
    required this.supportsGlobalOutputPositions,
    required this.supportsBestAnchor,
    required this.supportsWitness,
    this.supportsBlockHashes = false,
    this.supportsStructuredErrors = false,
    this.network,
    this.activationHeight,
    this.maxBlockRange,
    this.contract,
    this.serverVersion,
    this.pivxCoreVersion,
    this.methods = const {},
    this.hexByteOrder,
    this.canonicalWitnesses = false,
    this.consensusAnchors = false,
    this.indexStatus,
    this.rangeErrorTypes = const [],
    this.supportsActiveHeights = false,
    this.activeHeightsMaxLimit,
    this.supportsConsistentDbHeight = false,
    this.supportsMempool = false,
    this.supportsMempoolSubscribe = false,
  });

  /// The node emits 32-byte hex (cmu / anchor / nullifier) in big-endian
  /// display order, so those values must be reversed at the crypto boundary.
  bool get usesDisplayByteOrder => hexByteOrder?.toLowerCase() == 'display';

  /// Flushed Sapling index height (`index_status.db_height`). This is the
  /// ceiling for get_block_range: `to <= db_height` is always served, `to >
  /// db_height` returns index_incomplete/index_not_ready. Null on legacy nodes
  /// that don't report an index status.
  int? get indexHeight => _optionalInt(indexStatus?['db_height']);

  /// The daemon's chain tip as seen by the node (`index_status.daemon_height`),
  /// i.e. the true header tip. Use this for confirmation counts; it can lead
  /// the Sapling index by a small processing window. Null when not reported.
  int? get daemonHeight => _optionalInt(indexStatus?['daemon_height']);

  factory SaplingRpcCapabilities.fromJson(Map<String, dynamic> json) {
    final methodList = <String>{};
    final rawMethods = json['methods'] as List<dynamic>? ??
        json['supported_methods'] as List<dynamic>?;
    if (rawMethods != null) {
      methodList.addAll(rawMethods.map((e) => e.toString()));
    }
    final aliases = json['aliases'];
    if (aliases is Map) {
      methodList.addAll(aliases.keys.map((e) => e.toString()));
      for (final value in aliases.values) {
        if (value is List) {
          methodList.addAll(value.map((e) => e.toString()));
        } else if (value != null) {
          methodList.add(value.toString());
        }
      }
    } else if (aliases is List) {
      methodList.addAll(aliases.map((e) => e.toString()));
    }
    final rawFeatures = json['features'];
    final features = rawFeatures is Map ? rawFeatures : null;
    final rawRangeFormat = json['range_response_format'];
    final rangeFormat = rawRangeFormat is Map ? rawRangeFormat : null;
    final network = _optionalString(json['network']);
    final activationHeight = _optionalInt(json['sapling_activation_height']) ??
        _optionalInt(json['activation_height']);
    final witnessBackend = _optionalString(json['witness_backend']);
    final indexStatusRaw = json['index_status'];
    final rangeErrorTypesRaw = json['range_error_types'];

    bool hasMethod(String name) => methodList.contains(name);

    return SaplingRpcCapabilities(
      supportsBlockRange: hasMethod('blockchain.sapling.get_block_range') ||
          json['supports_block_range'] == true,
      supportsGlobalOutputPositions: json['global_output_positions'] == true ||
          json['supports_global_output_positions'] == true ||
          features?['global_output_positions'] == true ||
          rangeFormat?['global_output_positions'] == true,
      supportsBestAnchor: hasMethod('blockchain.sapling.get_best_anchor') ||
          hasMethod('blockchain.sapling.get_tree_state') ||
          json['supports_best_anchor'] == true,
      supportsWitness: hasMethod('blockchain.sapling.get_witness') ||
          json['supports_witness'] == true,
      supportsBlockHashes: json['block_hashes'] == true ||
          json['supports_block_hashes'] == true ||
          features?['block_hashes'] == true ||
          rangeFormat?['block_hashes'] == true,
      supportsStructuredErrors: json['structured_errors'] == true ||
          json['supports_structured_errors'] == true ||
          features?['structured_errors'] == true,
      network: network,
      activationHeight: activationHeight,
      maxBlockRange: _optionalInt(json['max_block_range']) ??
          _optionalInt(json['max_range_size']),
      contract: _optionalString(json['contract']) ??
          _optionalString(json['contract_id']),
      serverVersion: _optionalString(json['server_version']) ??
          _optionalString(json['electrumx_version']),
      pivxCoreVersion: _optionalString(json['pivx_core_version']) ??
          _optionalString(json['core_version']),
      methods: methodList,
      hexByteOrder: _optionalString(json['hex_byte_order']),
      canonicalWitnesses:
          features?['canonical_witnesses'] == true && witnessBackend != null,
      consensusAnchors: json['consensus_anchors'] == true,
      indexStatus: indexStatusRaw is Map
          ? Map<String, dynamic>.from(indexStatusRaw)
          : null,
      rangeErrorTypes: rangeErrorTypesRaw is List
          ? rangeErrorTypesRaw.map((e) => e.toString()).toList(growable: false)
          : const [],
      supportsActiveHeights:
          hasMethod('blockchain.sapling.get_active_heights') ||
              hasMethod('sapling.get_active_heights') ||
              json['supports_active_height_index'] == true ||
              features?['active_height_index'] == true ||
              features?['supports_active_height_index'] == true,
      activeHeightsMaxLimit: _optionalInt(json['active_heights_max_limit']) ??
          _optionalInt(features?['active_heights_max_limit']),
      supportsConsistentDbHeight: json['consistent_db_height'] == true ||
          features?['consistent_db_height'] == true,
      supportsMempool: hasMethod('blockchain.sapling.get_mempool') ||
          hasMethod('sapling.get_mempool') ||
          json['supports_mempool'] == true ||
          features?['supports_mempool'] == true,
      supportsMempoolSubscribe:
          hasMethod('blockchain.sapling.mempool.subscribe') ||
              hasMethod('sapling.mempool.subscribe') ||
              json['supports_mempool_subscribe'] == true ||
              features?['supports_mempool_subscribe'] == true,
    );
  }

  bool get advertisesV1Contract => contract?.toLowerCase() == v1ContractId;

  bool get supportsV1ReleaseContract =>
      advertisesV1Contract &&
      supportsBlockRange &&
      supportsGlobalOutputPositions &&
      supportsBestAnchor &&
      supportsWitness &&
      supportsBlockHashes &&
      supportsStructuredErrors &&
      methods.containsAll(requiredV1Methods);

  bool get isLegacyBlockRangeOnly => contract == legacyBlockRangeContractId;

  static SaplingRpcCapabilities legacyBlockRangeOnly() =>
      const SaplingRpcCapabilities(
        supportsBlockRange: true,
        supportsGlobalOutputPositions: false,
        supportsBestAnchor: false,
        supportsWitness: false,
        contract: legacyBlockRangeContractId,
      );
}

class SaplingActivation {
  static const int mainnet = 2700500;
  static const int testnet = 201;
}

/// Result from get_nullifier_status RPC.
class NullifierStatus {
  final bool spent;

  final String? txid;

  final int? height;

  NullifierStatus({
    required this.spent,
    this.txid,
    this.height,
  });

  factory NullifierStatus.fromJson(Map<String, dynamic> json) {
    return NullifierStatus(
      spent: json['spent'] as bool? ?? false,
      txid: json['txid'] as String?,
      height: json['height'] as int?,
    );
  }
}

/// Result from get_commitment_info RPC.
class CommitmentInfo {
  final bool exists;

  final String? txid;

  final int? height;

  final int? index;

  CommitmentInfo({
    required this.exists,
    this.txid,
    this.height,
    this.index,
  });

  factory CommitmentInfo.fromJson(Map<String, dynamic> json) {
    return CommitmentInfo(
      exists: json['exists'] as bool? ?? false,
      txid: json['txid'] as String?,
      height: json['height'] as int?,
      index: json['index'] as int?,
    );
  }
}

class SaplingShieldedOutput {
  /// Note commitment (cmu), 32 bytes hex.
  final String cmu;

  /// Ephemeral public key, 32 bytes hex.
  final String epk;

  /// Encrypted note ciphertext, 580 bytes hex (1160 hex chars).
  final String ciphertext;

  /// Value commitment (cv), 32 bytes hex.
  final String cv;

  /// Outgoing ciphertext, 80 bytes hex (160 hex chars).
  final String outCiphertext;

  /// Canonical global Sapling commitment tree position, if returned by server.
  final int? globalPosition;

  SaplingShieldedOutput({
    required this.cmu,
    required this.epk,
    required this.ciphertext,
    required this.cv,
    required this.outCiphertext,
    this.globalPosition,
  });

  factory SaplingShieldedOutput.fromJson(Map<String, dynamic> json) {
    return SaplingShieldedOutput(
      cmu: json['cmu'] as String,
      epk: json['epk'] as String,
      ciphertext: json['ciphertext'] as String,
      cv: json['cv'] as String,
      outCiphertext: json['out_ciphertext'] as String,
      globalPosition: _optionalInt(json['global_position']) ??
          _optionalInt(json['tree_position']) ??
          _optionalInt(json['position']) ??
          _optionalInt(json['index']),
    );
  }

  Uint8List get cmuBytes => Uint8List.fromList(hex.decode(cmu));

  Uint8List get epkBytes => Uint8List.fromList(hex.decode(epk));

  Uint8List get ciphertextBytes => Uint8List.fromList(hex.decode(ciphertext));

  Uint8List get cvBytes => Uint8List.fromList(hex.decode(cv));

  Uint8List get outCiphertextBytes =>
      Uint8List.fromList(hex.decode(outCiphertext));
}

/// Result from get_outputs_by_height RPC.
class SaplingOutputsResult {
  final int startHeight;

  final int endHeight;

  final int totalOutputs;

  final List<SaplingShieldedOutput> outputs;

  /// True when results were truncated by the limit.
  final bool truncated;

  SaplingOutputsResult({
    required this.startHeight,
    required this.endHeight,
    required this.totalOutputs,
    required this.outputs,
    required this.truncated,
  });

  factory SaplingOutputsResult.fromJson(Map<String, dynamic> json) {
    final outputsList = (json['outputs'] as List<dynamic>?)
            ?.map((e) =>
                SaplingShieldedOutput.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return SaplingOutputsResult(
      startHeight: json['start_height'] as int,
      endHeight: json['end_height'] as int,
      totalOutputs: json['total_outputs'] as int? ?? outputsList.length,
      outputs: outputsList,
      truncated: json['truncated'] as bool? ?? false,
    );
  }
}

class SaplingBlockRangeResult {
  final int startHeight;
  final int endHeight;
  final List<SaplingBlock> blocks;
  final Map<int, String> blockHashes;

  SaplingBlockRangeResult({
    required this.startHeight,
    required this.endHeight,
    required this.blocks,
    this.blockHashes = const {},
  });
}

class SaplingSpend {
  /// Nullifier being revealed (marks a note as spent).
  final String nullifier;

  final String cv;

  /// Anchor used for the spend proof (Merkle tree root).
  final String anchor;

  final String rk;

  SaplingSpend({
    required this.nullifier,
    required this.cv,
    required this.anchor,
    required this.rk,
  });

  factory SaplingSpend.fromJson(Map<String, dynamic> json) {
    return SaplingSpend(
      nullifier: json['nullifier'] as String,
      cv: json['cv'] as String,
      anchor: json['anchor'] as String,
      rk: json['rk'] as String,
    );
  }

  Uint8List get nullifierBytes => Uint8List.fromList(hex.decode(nullifier));

  Uint8List get cvBytes => Uint8List.fromList(hex.decode(cv));

  Uint8List get anchorBytes => Uint8List.fromList(hex.decode(anchor));

  Uint8List get rkBytes => Uint8List.fromList(hex.decode(rk));
}

/// A Sapling transaction from get_block_range.
class SaplingTransaction {
  final String txid;

  /// Shielded outputs (new notes being created).
  final List<SaplingShieldedOutput> outputs;

  /// Shielded spends (notes being spent, nullifiers revealed).
  final List<SaplingSpend> spends;

  /// Unix epoch the tx entered the mempool (get_mempool only, null for blocks).
  final int? firstSeen;

  SaplingTransaction({
    required this.txid,
    required this.outputs,
    required this.spends,
    this.firstSeen,
  });

  factory SaplingTransaction.fromJson(Map<String, dynamic> json) {
    return SaplingTransaction(
      txid: json['txid'] as String,
      firstSeen: _optionalInt(json['first_seen']),
      outputs: (json['outputs'] as List<dynamic>?)
              ?.map((e) =>
                  SaplingShieldedOutput.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      spends: (json['spends'] as List<dynamic>?)
              ?.map((e) => SaplingSpend.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SaplingBlock {
  final int height;

  final String hash;

  /// Unix epoch.
  final int time;

  final List<SaplingTransaction> txs;

  SaplingBlock({
    required this.height,
    required this.hash,
    required this.time,
    required this.txs,
  });

  factory SaplingBlock.fromJson(Map<String, dynamic> json) {
    return SaplingBlock(
      height: json['height'] as int,
      hash: json['hash'] as String,
      time: json['time'] as int,
      txs: (json['txs'] as List<dynamic>?)
              ?.map(
                  (e) => SaplingTransaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  int get outputCount {
    int count = 0;
    for (final tx in txs) {
      count += tx.outputs.length;
    }
    return count;
  }

  int get spendCount {
    int count = 0;
    for (final tx in txs) {
      count += tx.spends.length;
    }
    return count;
  }

  List<Uint8List> get allNullifiers {
    final nullifiers = <Uint8List>[];
    for (final tx in txs) {
      for (final spend in tx.spends) {
        nullifiers.add(spend.nullifierBytes);
      }
    }
    return nullifiers;
  }

  List<SaplingShieldedOutput> get allOutputs {
    final outputs = <SaplingShieldedOutput>[];
    for (final tx in txs) {
      outputs.addAll(tx.outputs);
    }
    return outputs;
  }
}

/// Snapshot from get_mempool: unconfirmed Sapling txs (same tx shape as a block,
/// no height/position). [truncated] true when the server hit its output cap.
class SaplingMempoolResult {
  final List<SaplingTransaction> txs;
  final bool truncated;

  SaplingMempoolResult({required this.txs, this.truncated = false});

  factory SaplingMempoolResult.fromJson(Map<String, dynamic> json) {
    return SaplingMempoolResult(
      txs: (json['txs'] as List<dynamic>?)
              ?.map(
                  (e) => SaplingTransaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      truncated: json['truncated'] == true,
    );
  }
}

/// Result from get_best_anchor RPC.
class BestAnchorResult {
  /// The current best anchor (Merkle root).
  final String anchor;

  final int height;

  BestAnchorResult({
    required this.anchor,
    required this.height,
  });

  factory BestAnchorResult.fromJson(Map<String, dynamic> json) {
    final anchor = json['anchor'] as String? ?? json['root'] as String?;
    final height = _optionalInt(json['anchor_height']) ??
        _optionalInt(json['anchorHeight']) ??
        _optionalInt(json['height']);
    if (anchor == null || anchor.isEmpty) {
      throw SaplingRpcException(
          'PIVX Sapling best-anchor response has no anchor');
    }
    if (height == null) {
      throw SaplingRpcException(
          'PIVX Sapling best-anchor response has no anchor height');
    }

    return BestAnchorResult(
      anchor: anchor,
      height: height,
    );
  }

  Uint8List get anchorBytes => Uint8List.fromList(hex.decode(anchor));
}

/// Parsed v1 `blockchain.sapling.get_tree_state` response.
///
/// The v1 contract dropped `nullifier_count`; anchors/roots are display-order
/// hex and must be reversed (see [reverseSaplingHexBytes]) if ever fed to the
/// native crypto boundary.
class SaplingTreeState {
  final String? anchor;
  final String? root;
  final String? latestAnchor;
  final int? treeSize;
  final int? commitmentCount;
  final int? height;
  final int? indexedHeight;
  final int? anchorFirstHeight;
  final int? saplingActivationHeight;
  final String? blockHash;

  SaplingTreeState({
    this.anchor,
    this.root,
    this.latestAnchor,
    this.treeSize,
    this.commitmentCount,
    this.height,
    this.indexedHeight,
    this.anchorFirstHeight,
    this.saplingActivationHeight,
    this.blockHash,
  });

  factory SaplingTreeState.fromJson(Map<String, dynamic> json) {
    return SaplingTreeState(
      anchor: _optionalString(json['anchor']) ?? _optionalString(json['root']),
      root: _optionalString(json['root']) ?? _optionalString(json['anchor']),
      latestAnchor: _optionalString(json['latest_anchor']),
      treeSize: _optionalInt(json['tree_size']),
      commitmentCount: _optionalInt(json['commitment_count']),
      height: _optionalInt(json['height']),
      indexedHeight: _optionalInt(json['indexed_height']),
      anchorFirstHeight: _optionalInt(json['anchor_first_height']),
      saplingActivationHeight: _optionalInt(json['sapling_activation_height']),
      blockHash: _optionalString(json['block_hash']),
    );
  }
}

/// Anchor-bound Merkle witness for spend proof construction.
class SaplingWitnessResult {
  static const String sourceUnknown = 'unknown';
  static const String sourceAnchorBound = 'anchor_bound';
  static const String sourceCommitmentOnlyFallback = 'commitment_only_fallback';
  static const int saplingTreeDepth = 32;
  static const int saplingNodeHexLength = 64;
  static final BigInt _jubjubBaseFieldModulus = BigInt.parse(
      '73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001',
      radix: 16);
  static const List<String> _emptyRoots = [
    '0100000000000000000000000000000000000000000000000000000000000000',
    '817de36ab2d57feb077634bca77819c8e0bd298c04f6fed0e6a83cc1356ca155',
    'ffe9fc03f18b176c998806439ff0bb8ad193afdb27b2ccbc88856916dd804e34',
    'd8283386ef2ef07ebdbb4383c12a739a953a4d6e0d6fb1139a4036d693bfbb6c',
    'e110de65c907b9dea4ae0bd83a4b0a51bea175646a64c12b4c9f931b2cb31b49',
    '912d82b2c2bca231f71efcf61737fbf0a08befa0416215aeef53e8bb6d23390a',
    '8ac9cf9c391e3fd42891d27238a81a8a5c1d3a72b1bcbea8cf44a58ce7389613',
    'd6c639ac24b46bd19341c91b13fdcab31581ddaf7f1411336a271f3d0aa52813',
    '7b99abdc3730991cc9274727d7d82d28cb794edbc7034b4f0053ff7c4b680444',
    '43ff5457f13b926b61df552d4e402ee6dc1463f99a535f9a713439264d5b616b',
    'ba49b659fbd0b7334211ea6a9d9df185c757e70aa81da562fb912b84f49bce72',
    '4777c8776a3b1e69b73a62fa701fa4f7a6282d9aee2c7a6b82e7937d7081c23c',
    'ec677114c27206f5debc1c1ed66f95e2b1885da5b7be3d736b1de98579473048',
    '1b77dac4d24fb7258c3c528704c59430b630718bec486421837021cf75dab651',
    'bd74b25aacb92378a871bf27d225cfc26baca344a1ea35fdd94510f3d157082c',
    'd6acdedf95f608e09fa53fb43dcd0990475726c5131210c9e5caeab97f0e642f',
    '1ea6675f9551eeb9dfaaa9247bc9858270d3d3a4c5afa7177a984d5ed1be2451',
    '6edb16d01907b759977d7650dad7e3ec049af1a3d875380b697c862c9ec5d51c',
    'cd1c8dbf6e3acc7a80439bc4962cf25b9dce7c896f3a5bd70803fc5a0e33cf00',
    '6aca8448d8263e547d5ff2950e2ed3839e998d31cbc6ac9fd57bc6002b159216',
    '8d5fa43e5a10d11605ac7430ba1f5d81fb1b68d29a640405767749e841527673',
    '08eeab0c13abd6069e6310197bf80f9c1ea6de78fd19cbae24d4a520e6cf3023',
    '0769557bc682b1bf308646fd0b22e648e8b9e98f57e29f5af40f6edb833e2c49',
    '4c6937d78f42685f84b43ad3b7b00f81285662f85c6a68ef11d62ad1a3ee0850',
    'fee0e52802cb0c46b1eb4d376c62697f4759f6c8917fa352571202fd778fd712',
    '16d6252968971a83da8521d65382e61f0176646d771c91528e3276ee45383e4a',
    'd2e1642c9a462229289e5b0e3b7f9008e0301cbb93385ee0e21da2545073cb58',
    'a5122c08ff9c161d9ca6fc462073396c7d7d38e8ee48cdb3bea7e2230134ed6a',
    '28e7b841dcbc47cceb69d7cb8d94245fb7cb2ba3a7a6bc18f13f945f7dbd6e2a',
    'e1f34b034d4a3cd28557e2907ebf990c918f64ecb50a94f01d6fda5ca5c7ef72',
    '12935f14b676509b81eb49ef25f39269ed72309238b4c145803544b646dca62d',
    'b2eed031d4d6a4f02a097f80b54cc1541d4163c6b6f5971f88b6e41d35c53814',
    'fbc2f4300c01f0b7820d00e3347c8da4ee614674376cbc45359daa54f9b5493e',
  ];

  final int position;
  final List<String> path;
  final String anchor;
  final int anchorHeight;
  final String commitment;
  final String source;
  final Map<String, dynamic> raw;

  SaplingWitnessResult({
    required this.position,
    required this.path,
    required this.anchor,
    required this.anchorHeight,
    required this.commitment,
    this.source = sourceUnknown,
    required this.raw,
  });

  factory SaplingWitnessResult.fromJson(Map<String, dynamic> json) {
    final rawPath = _normalizeWitnessPath(json['path'] ?? json['witness']);
    final path = _expandWitnessPath(rawPath);
    final anchor = json['anchor'] as String? ?? json['root'] as String?;
    final anchorHeight = _optionalInt(json['anchor_height']) ??
        _optionalInt(json['height']) ??
        _optionalInt(json['anchorHeight']);
    final commitment = json['commitment'] as String? ??
        json['cmu'] as String? ??
        json['commitment_hex'] as String?;
    final position = _optionalInt(json['position']) ??
        _optionalInt(json['tree_position']) ??
        _optionalInt(json['global_position']);

    if (rawPath == null || rawPath.isEmpty) {
      throw SaplingRpcException('PIVX Sapling witness response has no path');
    }
    if (path == null) {
      throw SaplingRpcException(
          'PIVX Sapling witness response has invalid path');
    }
    if (anchor == null || anchor.isEmpty) {
      throw SaplingRpcException('PIVX Sapling witness response has no anchor');
    }
    if (anchorHeight == null) {
      throw SaplingRpcException(
          'PIVX Sapling witness response has no anchor height');
    }
    if (commitment == null || commitment.isEmpty) {
      throw SaplingRpcException(
          'PIVX Sapling witness response has no commitment');
    }
    if (position == null) {
      throw SaplingRpcException(
          'PIVX Sapling witness response has no note position');
    }

    return SaplingWitnessResult(
      position: position,
      path: path,
      anchor: anchor,
      anchorHeight: anchorHeight,
      commitment: commitment,
      source: _optionalString(json['source']) ?? sourceUnknown,
      raw: Map<String, dynamic>.from(json),
    );
  }

  SaplingWitnessResult withSource(String source) => SaplingWitnessResult(
        position: position,
        path: path,
        anchor: anchor,
        anchorHeight: anchorHeight,
        commitment: commitment,
        source: source,
        raw: {
          ...raw,
          'source': source,
        },
      );

  static List<String>? _normalizeWitnessPath(Object? rawPath) {
    if (rawPath == null) return null;
    if (rawPath is String) {
      final normalized = _normalizeWitnessPathElement(rawPath);
      return normalized == null ? null : <String>[normalized];
    }
    if (rawPath is! List) return null;

    final path = <String>[];
    for (final element in rawPath) {
      final normalized = _normalizeWitnessPathElement(element);
      if (normalized == null) return null;
      path.add(normalized);
    }
    return path;
  }

  static String? _normalizeWitnessPathElement(Object? element) {
    if (element == null) return null;
    if (element is String) {
      return element;
    }
    if (element is Map) {
      for (final key in const [
        'hash',
        'hex',
        'node',
        'sibling',
        'value',
        'cmu',
      ]) {
        final value = element[key];
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
      return null;
    }
    if (element is List) {
      for (final value in element) {
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
    }
    return null;
  }

  static List<String>? _expandWitnessPath(List<String>? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return rawPath;
    final path = _splitWitnessPath(rawPath);
    if (path == null || path.length > saplingTreeDepth) return null;

    final expanded = _padWitnessPath(path);
    final invalidIndex = _firstNonCanonicalNodeIndex(expanded);
    if (invalidIndex == null) return expanded;

    final reversedPath = path.map(_reverseNodeHex).toList(growable: false);
    final reversedExpanded = _padWitnessPath(reversedPath);
    final reversedInvalidIndex = _firstNonCanonicalNodeIndex(reversedExpanded);
    if (reversedInvalidIndex == null) {
      printV('[PIVX Sapling] Witness path byte order corrected');
      return reversedExpanded;
    }

    final originalCanonical = path
        .where(
            (node) => _littleEndianHexToBigInt(node) < _jubjubBaseFieldModulus)
        .length;
    final reversedCanonical = reversedPath
        .where(
            (node) => _littleEndianHexToBigInt(node) < _jubjubBaseFieldModulus)
        .length;
    printV(
        '[PIVX Sapling] Witness path has non-canonical node at index $invalidIndex; canonical_original=$originalCanonical/${path.length}, canonical_reversed=$reversedCanonical/${reversedPath.length}');
    return null;
  }

  static List<String>? _splitWitnessPath(List<String> rawPath) {
    final path = <String>[];
    for (final element in rawPath) {
      final hexElement = element.trim();
      if (hexElement.isEmpty ||
          hexElement.length % saplingNodeHexLength != 0 ||
          !RegExp(r'^[0-9a-fA-F]+$').hasMatch(hexElement)) {
        return null;
      }
      for (var offset = 0;
          offset < hexElement.length;
          offset += saplingNodeHexLength) {
        path.add(hexElement
            .substring(offset, offset + saplingNodeHexLength)
            .toLowerCase());
      }
    }
    return path;
  }

  static List<String> _padWitnessPath(List<String> path) {
    final expanded = List<String>.from(path);
    if (path.length < saplingTreeDepth) {
      expanded.addAll(_emptyRoots.skip(path.length).take(
            saplingTreeDepth - path.length,
          ));
    }
    return expanded;
  }

  static int? _firstNonCanonicalNodeIndex(List<String> path) {
    for (var i = 0; i < path.length; i++) {
      if (_littleEndianHexToBigInt(path[i]) >= _jubjubBaseFieldModulus) {
        return i;
      }
    }
    return null;
  }

  static BigInt _littleEndianHexToBigInt(String hexValue) {
    final buffer = StringBuffer();
    for (var offset = hexValue.length; offset > 0; offset -= 2) {
      buffer.write(hexValue.substring(offset - 2, offset));
    }
    return BigInt.parse(buffer.toString(), radix: 16);
  }

  static String _reverseNodeHex(String hexValue) {
    final buffer = StringBuffer();
    for (var offset = hexValue.length; offset > 0; offset -= 2) {
      buffer.write(hexValue.substring(offset - 2, offset));
    }
    return buffer.toString();
  }
}

/// Parsed v1 `blockchain.sapling.get_active_heights` response.
class SaplingActiveHeightsResult {
  const SaplingActiveHeightsResult({
    required this.heights,
    required this.start,
    required this.end,
    required this.complete,
    this.dbHeight,
  });

  /// Ascending, unique block heights with >=1 Sapling tx in this page.
  final List<int> heights;

  /// First / last height covered by this page. On truncation resume at [end]+1.
  final int start;
  final int end;

  /// False when the page was truncated by the server's limit.
  final bool complete;

  /// Indexed ceiling (`db_height`) at the time of the call, when reported.
  final int? dbHeight;

  factory SaplingActiveHeightsResult.fromJson(
    Map<String, dynamic> json,
    int requestStart,
    int requestEnd,
  ) {
    final rawHeights = json['heights'];
    final heights = <int>[];
    if (rawHeights is List) {
      for (final h in rawHeights) {
        final v = _optionalInt(h);
        if (v != null) heights.add(v);
      }
    }
    heights.sort();
    return SaplingActiveHeightsResult(
      heights: heights,
      start: _optionalInt(json['start']) ?? requestStart,
      end: _optionalInt(json['end']) ?? requestEnd,
      complete: json['complete'] == true,
      dbHeight: _optionalInt(json['db_height']),
    );
  }
}

/// Wraps an ElectrumX client to add Sapling-specific RPC methods.
class PIVXSaplingElectrumX {
  /// Underlying ElectrumX client (ElectrumWallet.electrumClient).
  final dynamic _client;

  final bool isTestnet;

  /// Verifies witness Merkle roots locally before a witness is accepted.
  /// Defaults to the native sapling_ffi implementation; tests inject a fake.
  final WitnessRootVerifier _witnessRootVerifier;

  PIVXSaplingElectrumX({
    required dynamic electrumClient,
    this.isTestnet = false,
    WitnessRootVerifier? witnessRootVerifier,
    SaplingRpcCapabilities? capabilities,
  })  : _client = electrumClient,
        _capabilities = capabilities,
        _witnessRootVerifier =
            witnessRootVerifier ?? sapling_ffi.verifyWitnessRoot;

  SaplingRpcCapabilities? _capabilities;

  /// The capabilities negotiated for the active node, if already probed.
  SaplingRpcCapabilities? get capabilities => _capabilities;

  int get activationHeight =>
      isTestnet ? SaplingActivation.testnet : SaplingActivation.mainnet;

  Future<dynamic> _callFirstSupported({
    required List<String> methods,
    required List<Object> params,
    bool fallbackOnServerError = false,
  }) async {
    Object? lastError;
    for (final method in methods) {
      try {
        int? requestId;
        final result = await _client.call(
          method: method,
          params: params,
          idCallback: (id) => requestId = id,
        );
        final errorMessage = _errorMessageForRequest(requestId);
        if (errorMessage != null) {
          throw SaplingRpcException(errorMessage);
        }
        return result;
      } catch (e) {
        lastError = e;
        if (!_looksLikeUnsupportedMethod(e) &&
            !(fallbackOnServerError && _looksLikeServerMethodFailure(e))) {
          rethrow;
        }
      }
    }
    throw SaplingRpcException('PIVX Sapling RPC method unavailable', lastError);
  }

  String? _errorMessageForRequest(int? requestId) {
    if (requestId == null) return null;
    try {
      final message = _client.getErrorMessage(requestId);
      if (message is String && message.isNotEmpty) {
        return message;
      }
    } catch (_) {}
    return null;
  }

  bool _looksLikeUnsupportedMethod(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('method not found') ||
        text.contains('unknown method') ||
        text.contains('unsupported') ||
        text.contains('not implemented') ||
        text.contains('method unavailable');
  }

  bool _looksLikeServerMethodFailure(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('internal server error') ||
        text.contains('server error');
  }

  /// probe attempts before surfacing a not-supported result. a healthy node can
  /// briefly return an incomplete caps payload after a reconnect (methods list
  /// missing get_block_range); retrying keeps that blip from reading as an
  /// unsupported node and firing a "switch nodes" error on the sync poll.
  static const int _capabilityProbeAttempts = 3;

  /// Probe the Sapling RPC policy/capabilities for the active node. Caches the
  /// first good result; retries a transient/incomplete payload before giving up.
  Future<SaplingRpcCapabilities> probeCapabilities() async {
    if (_capabilities != null) return _capabilities!;

    Object? lastCause;
    for (var attempt = 0; attempt < _capabilityProbeAttempts; attempt++) {
      try {
        return await _probeCapabilitiesOnce();
      } on _RetryableCapabilityProbe catch (e) {
        // only an incomplete/garbled payload retries; definitive rejections
        // (wrong network, half-upgraded v1, unsupported node) aren't
        // _RetryableCapabilityProbe and propagate immediately.
        lastCause = e.cause;
        if (attempt < _capabilityProbeAttempts - 1) {
          await Future<void>.delayed(
              Duration(milliseconds: 300 * (attempt + 1)));
        }
      }
    }
    throw lastCause!;
  }

  /// live index ceiling (`index_status.db_height`), fetched fresh each call, not
  /// the value cached in [capabilities] at probe time. the cached ceiling never
  /// moves, so it stalls the sync at the first-observed height (new receives
  /// never scanned). null when unavailable; caller falls back to cached ceiling
  /// or header tip.
  Future<int?> fetchLiveIndexHeight() async {
    try {
      final result = await _callFirstSupported(
        methods: const [
          'blockchain.sapling.capabilities',
          'blockchain.sapling.get_capabilities',
        ],
        params: <Object>[],
        fallbackOnServerError: true,
      );
      if (result is Map) {
        final idx = result['index_status'];
        if (idx is Map) return _optionalInt(idx['db_height']);
      }
    } catch (_) {
      // fall through to null; caller uses the cached ceiling / header tip
    }
    return null;
  }

  /// Current unconfirmed Sapling mempool snapshot for 0-conf incoming detection.
  /// null on not-ready/error (transient, caller keeps prior state); a non-null
  /// result with empty txs is an authoritative empty mempool (caller clears).
  /// best-effort: mempool is display-only, never fatal to the block sync.
  Future<SaplingMempoolResult?> fetchMempool() async {
    try {
      final result = await _callFirstSupported(
        methods: const [
          'blockchain.sapling.get_mempool',
          'sapling.get_mempool',
        ],
        params: <Object>[],
        fallbackOnServerError: true,
      );
      if (result is! Map) return null;
      // mempool_not_ready (server trails its daemon / no snapshot) is retryable;
      // a healthy empty mempool returns success with txs: []. only the latter
      // clears prior state, so any error/failure maps to null.
      if (result['success'] == false || result['error'] != null) return null;
      return SaplingMempoolResult.fromJson(Map<String, dynamic>.from(result));
    } catch (_) {
      return null;
    }
  }

  /// Subscribe to the Sapling mempool push feed. Emits the current snapshot
  /// first, then the same envelope on every change (full state replacement).
  /// null when unsupported or not connected; caller falls back to polling.
  Stream<SaplingMempoolResult>? mempoolSubscribe() {
    try {
      final subject = _client.saplingMempoolSubscribe();
      if (subject is! Stream) return null;
      return subject
          .map<SaplingMempoolResult?>(_parseMempoolPush)
          .where((result) => result != null)
          .cast<SaplingMempoolResult>();
    } catch (_) {
      return null;
    }
  }

  Future<void> mempoolUnsubscribe() async {
    try {
      await _client.call(
        method: 'blockchain.sapling.mempool.unsubscribe',
        params: <Object>[],
      );
    } catch (_) {}
  }

  /// Parse a mempool subscribe payload (initial snapshot or push) into a result.
  /// May arrive as the envelope map or wrapped in a params list; a not-ready or
  /// error payload yields null so the caller keeps its prior state.
  SaplingMempoolResult? _parseMempoolPush(dynamic event) {
    dynamic payload = event;
    if (payload is List && payload.isNotEmpty) payload = payload.first;
    if (payload is! Map) return null;
    if (payload['success'] == false || payload['error'] != null) return null;
    return SaplingMempoolResult.fromJson(Map<String, dynamic>.from(payload));
  }

  Future<SaplingRpcCapabilities> _probeCapabilitiesOnce() async {
    try {
      final result = await _callFirstSupported(
        methods: const [
          'blockchain.sapling.capabilities',
          'blockchain.sapling.get_capabilities',
        ],
        params: <Object>[],
        fallbackOnServerError: true,
      );
      if (result is! Map) {
        throw _RetryableCapabilityProbe(SaplingRpcException(
            'PIVX Sapling capability probe returned ${result.runtimeType}'));
      }
      final capabilities =
          SaplingRpcCapabilities.fromJson(Map<String, dynamic>.from(result));
      if (!capabilities.supportsBlockRange) {
        throw _RetryableCapabilityProbe(SaplingRpcException(
            'PIVX Sapling node does not advertise get_block_range'));
      }
      if (capabilities.advertisesV1Contract &&
          !capabilities.supportsV1ReleaseContract) {
        throw SaplingRpcException(
            'PIVX Sapling node advertises v1 but is missing required release contract features');
      }
      if (capabilities.network != null) {
        final expected = isTestnet ? 'testnet' : 'mainnet';
        if (capabilities.network!.toLowerCase() != expected) {
          throw SaplingRpcException(
              'PIVX Sapling node network mismatch: expected $expected');
        }
      }
      if (capabilities.activationHeight != null &&
          capabilities.activationHeight != activationHeight) {
        throw SaplingRpcException(
            'PIVX Sapling activation height mismatch for current network');
      }
      if (capabilities.supportsV1ReleaseContract) {
        await _validateLiveV1ReleaseMethods();
      }
      _capabilities = capabilities;
      return capabilities;
    } catch (e) {
      if (e is _RetryableCapabilityProbe) rethrow; // let the wrapper retry it
      if (!_looksLikeUnsupportedMethod(e)) rethrow;

      // Legacy sapling_integration fork: prove block-range support, but do not
      // assume global positions, witnesses, or v1 policy metadata exist.
      await getBlockRange(activationHeight, endHeight: activationHeight);
      _capabilities = SaplingRpcCapabilities.legacyBlockRangeOnly();
      return _capabilities!;
    }
  }

  Future<void> _validateLiveV1ReleaseMethods() async {
    try {
      final anchorResult = await _callFirstSupported(
        methods: const ['blockchain.sapling.get_best_anchor'],
        params: <Object>[],
      );
      if (anchorResult is! Map) {
        throw SaplingRpcException(
            'get_best_anchor returned ${anchorResult.runtimeType}');
      }
      BestAnchorResult.fromJson(Map<String, dynamic>.from(anchorResult));

      final nullifierResult = await _callFirstSupported(
        methods: const ['blockchain.sapling.get_nullifier_status'],
        params: const <Object>[_v1LiveProbeHex32],
      );
      if (nullifierResult is! Map) {
        throw SaplingRpcException(
            'get_nullifier_status returned ${nullifierResult.runtimeType}');
      }
      NullifierStatus.fromJson(Map<String, dynamic>.from(nullifierResult));

      final commitmentResult = await _callFirstSupported(
        methods: const ['blockchain.sapling.get_commitment_info'],
        params: const <Object>[_v1LiveProbeHex32],
      );
      if (commitmentResult is! Map) {
        throw SaplingRpcException(
            'get_commitment_info returned ${commitmentResult.runtimeType}');
      }
      CommitmentInfo.fromJson(Map<String, dynamic>.from(commitmentResult));
    } catch (e) {
      throw SaplingRpcException(
        'PIVX Sapling node advertises v1 but live release method validation failed',
        e,
      );
    }
  }

  /// Check if [nullifier] (32-byte hex) has been spent.
  Future<NullifierStatus> getNullifierStatus(String nullifier) async {
    final result = await _callFirstSupported(
      methods: const [
        'blockchain.sapling.get_nullifier_status',
        'blockchain.nullifier.get_spend',
      ],
      params: <Object>[nullifier],
    );
    return NullifierStatus.fromJson(result as Map<String, dynamic>);
  }

  /// Info about a note commitment [commitment] (32-byte cmu hex).
  Future<CommitmentInfo> getCommitmentInfo(String commitment) async {
    final result = await _callFirstSupported(
      methods: const [
        'blockchain.sapling.get_commitment_info',
        'blockchain.commitment.get_info',
      ],
      params: <Object>[commitment],
    );
    return CommitmentInfo.fromJson(result as Map<String, dynamic>);
  }

  /// Sapling outputs in a block range (inclusive; [endHeight] defaults to
  /// [startHeight]). [limit] default 1000, max 5000; max 100 blocks per request.
  Future<SaplingOutputsResult> getOutputsByHeight(
    int startHeight, {
    int? endHeight,
    int? limit,
  }) async {
    final params = <Object>[startHeight];
    if (endHeight != null) params.add(endHeight);
    if (limit != null) params.add(limit);

    final result = await _callFirstSupported(
      methods: const [
        'blockchain.sapling.get_outputs_by_height',
        'blockchain.sapling.get_outputs',
      ],
      params: params,
    );
    return SaplingOutputsResult.fromJson(result as Map<String, dynamic>);
  }

  /// sparse block heights in [startHeight, endHeight] with >=1 Sapling tx (v1
  /// active-height index). one response may be truncated (complete == false);
  /// use [fetchActiveHeights] to page the whole range.
  Future<SaplingActiveHeightsResult> getActiveHeights(
    int startHeight, {
    int? endHeight,
    int? limit,
  }) async {
    final params = <Object>[startHeight];
    if (endHeight != null) params.add(endHeight);
    if (limit != null) params.add(limit);

    final result = await _callFirstSupported(
      methods: const [
        'blockchain.sapling.get_active_heights',
        'sapling.get_active_heights',
      ],
      params: params,
    );
    return SaplingActiveHeightsResult.fromJson(
      result as Map<String, dynamic>,
      startHeight,
      endHeight ?? startHeight,
    );
  }

  /// page [getActiveHeights] across [fromHeight]..[toHeight] until complete.
  /// returns the full ascending set, or null when the node can't serve the index
  /// (capability off / unknown method / not ready) so the caller full-scans.
  Future<List<int>?> fetchActiveHeights(int fromHeight, int toHeight) async {
    if (!(capabilities?.supportsActiveHeights ?? false)) return null;
    if (toHeight < fromHeight) return const <int>[];

    final limit = capabilities?.activeHeightsMaxLimit ?? 10000;
    final heights = <int>[];
    var cursor = fromHeight;
    var covered = false;
    // Bound the paging so a misbehaving node can't loop forever.
    for (var page = 0; page < 512; page++) {
      if (cursor > toHeight) {
        covered = true; // paged the entire requested range
        break;
      }
      final SaplingActiveHeightsResult result;
      try {
        result =
            await getActiveHeights(cursor, endHeight: toHeight, limit: limit);
      } catch (_) {
        return null; // unknown method / not ready -> full-scan fallback
      }
      heights.addAll(
          result.heights.where((h) => h >= cursor && h <= toHeight));
      if (result.complete) {
        covered = true;
        break;
      }
      final nextCursor = result.end + 1;
      if (nextCursor <= cursor) break; // no forward progress -> incomplete
      cursor = nextCursor;
    }
    // only trust the set if we fully covered the range. a truncated/no-progress/
    // page-capped result must full-scan, or _syncActiveWindows advances the
    // cursor past active blocks never returned and drops their notes.
    if (!covered) return null;
    return heights;
  }

  /// Blocks with Sapling txs in pivx-shield format (inclusive; [endHeight]
  /// defaults to [startHeight]). Max 100 blocks per request; only blocks with
  /// Sapling txs are returned.
  Future<List<SaplingBlock>> getBlockRange(
    int startHeight, {
    int? endHeight,
  }) async =>
      (await getBlockRangeResult(startHeight, endHeight: endHeight)).blocks;

  /// Get blocks plus v1 envelope metadata for a Sapling height range.
  Future<SaplingBlockRangeResult> getBlockRangeResult(
    int startHeight, {
    int? endHeight,
  }) async {
    final expectedEnd = endHeight ?? startHeight;
    final params = <Object>[startHeight];
    if (endHeight != null) params.add(endHeight);

    final result = await _callFirstSupported(
      methods: const ['blockchain.sapling.get_block_range'],
      params: params,
    );

    if (result == null) {
      throw SaplingRpcException(
        'PIVX Sapling get_block_range returned null for $startHeight-$expectedEnd',
      );
    }

    dynamic blocksResult = result;
    var blockHashes = <int, String>{};
    if (result is Map) {
      // v1 envelope: a range above the indexed tip returns
      // success:false / complete:false with a structured error. Classify
      // indexer-lag / backend-timeout errors as retryable so the sync loop
      // retries instead of advancing the synced height past them.
      final errorType = _rangeErrorType(result['error']);
      if (result['success'] == false || errorType != null) {
        final detail = errorType ?? 'unknown';
        if (_retryableRangeErrorTypes.contains(errorType)) {
          throw SaplingRetryableRangeException(
            'PIVX Sapling get_block_range not ready for $startHeight-$expectedEnd (error=$detail)',
          );
        }
        throw SaplingRpcException(
          'PIVX Sapling get_block_range failed for $startHeight-$expectedEnd (error=$detail)',
        );
      }
      if (result['complete'] != true) {
        throw SaplingRpcException(
          'PIVX Sapling get_block_range returned an incomplete range for $startHeight-$expectedEnd',
        );
      }
      final responseStart = _optionalInt(result['from_height']) ??
          _optionalInt(result['start_height']) ??
          _optionalInt(result['from']);
      final responseEnd = _optionalInt(result['to_height']) ??
          _optionalInt(result['end_height']) ??
          _optionalInt(result['to']);
      if (responseStart != null && responseStart != startHeight) {
        throw SaplingRpcException(
          'PIVX Sapling get_block_range returned a mismatched start height',
        );
      }
      if (responseEnd != null && responseEnd != expectedEnd) {
        throw SaplingRpcException(
          'PIVX Sapling get_block_range returned a mismatched end height',
        );
      }
      blockHashes = _parseBlockHashes(
        result['block_hashes'] ?? result['blockHashes'],
        responseStart ?? startHeight,
      );
      blocksResult = result['blocks'];
    }

    if (blocksResult is! List) {
      throw SaplingRpcException(
        'PIVX Sapling get_block_range returned ${blocksResult.runtimeType} for $startHeight-$expectedEnd',
      );
    }

    final List<SaplingBlock> blocks;
    try {
      blocks = blocksResult
          .map((e) => SaplingBlock.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw SaplingRpcException(
        'PIVX Sapling get_block_range returned malformed block data',
        e,
      );
    }
    for (final block in blocks) {
      if (block.hash.isNotEmpty) {
        blockHashes[block.height] = block.hash;
      }
    }

    return SaplingBlockRangeResult(
      startHeight: startHeight,
      endHeight: expectedEnd,
      blocks: blocks,
      blockHashes: blockHashes,
    );
  }

  Map<int, String> _parseBlockHashes(Object? raw, int startHeight) {
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
    } else if (raw is List) {
      for (var i = 0; i < raw.length; i++) {
        final item = raw[i];
        if (item is Map) {
          final height = _optionalInt(item['height']) ??
              _optionalInt(item['block_height']);
          final hash = _optionalString(item['hash']) ??
              _optionalString(item['block_hash']);
          if (height != null && hash != null) {
            hashes[height] = hash;
          }
        } else if (item != null) {
          final hash = item.toString();
          if (hash.isNotEmpty) {
            hashes[startHeight + i] = hash;
          }
        }
      }
    }
    return hashes;
  }

  /// Block height where [anchor] (32-byte Merkle root hex) was valid; null if
  /// not found.
  Future<int?> getAnchorHeight(String anchor) async {
    final result = await _callFirstSupported(
      methods: const [
        'blockchain.sapling.get_anchor_height',
        'blockchain.anchor.get_height',
      ],
      params: <Object>[anchor],
    );
    return result as int?;
  }

  /// Best (most recent) anchor and its height. Searches for the most recent
  /// height with a tree state (only blocks with Sapling activity have one);
  /// [maxHeight] defaults to the chain tip.
  Future<BestAnchorResult> getBestAnchor({int? maxHeight}) async {
    try {
      final result = await _client.call(
        method: 'blockchain.sapling.get_best_anchor',
        params: maxHeight == null ? <Object>[] : <Object>[maxHeight],
      );
      if (result is Map<String, dynamic>) {
        return BestAnchorResult.fromJson(result);
      }
    } catch (e) {
      if (!_looksLikeUnsupportedMethod(e)) rethrow;
    }

    int searchHeight = maxHeight ?? 0;
    if (searchHeight == 0) {
      final headersResult = await _client.call(
        method: 'blockchain.headers.subscribe',
        params: <Object>[],
      );
      searchHeight = headersResult['height'] as int;
    }

    var treeState = await getTreeState(searchHeight);

    // the server may only have tree states for blocks with Sapling txs
    if (treeState == null) {
      int step = 1000;
      int minHeight = activationHeight;

      while (treeState == null && searchHeight > minHeight) {
        searchHeight -= step;
        if (searchHeight < minHeight) searchHeight = minHeight;
        treeState = await getTreeState(searchHeight);

        if (treeState == null && step > 10) {
          searchHeight += step;
          step = step ~/ 10;
        }
      }
    }

    if (treeState == null) {
      throw Exception(
          'Could not find any tree state from height $maxHeight down to $activationHeight');
    }

    final parsedTreeState = SaplingTreeState.fromJson(treeState);
    final anchor = parsedTreeState.root ?? parsedTreeState.anchor;
    if (anchor == null) {
      throw Exception('Tree state at height $searchHeight has no root/anchor');
    }

    return BestAnchorResult(
      anchor: anchor,
      height: searchHeight,
    );
  }

  /// Sapling commitment tree state at [height].
  Future<Map<String, dynamic>?> getTreeState(int height) async {
    final result = await _callFirstSupported(
        methods: const ['blockchain.sapling.get_tree_state'],
        params: <Object>[height]);
    return result as Map<String, dynamic>?;
  }

  /// Get Merkle witness for spend proof construction.
  ///
  /// The v1 release contract uses commitment + anchor root. Some simulator and
  /// development nodes have exposed compatible witness data behind position or
  /// height-bound parameter shapes, so callers that need compatibility should
  /// use [getAnchorBoundWitness] instead of calling this low-level method.
  Future<Map<String, dynamic>?> getWitness(
      Object commitmentOrPosition, Object? anchorOrHeight) async {
    final params = <Object>[commitmentOrPosition];
    if (anchorOrHeight != null) {
      params.add(anchorOrHeight);
    }
    final result = await _callFirstSupported(
        methods: const ['blockchain.sapling.get_witness'], params: params);
    return result as Map<String, dynamic>?;
  }

  /// Get a witness that is explicitly bound to the selected anchor.
  ///
  /// Shielded spend construction must sign with the same anchor used to build
  /// every witness path. Nodes that omit anchor metadata, return a witness for
  /// a different anchor height/root, or return a different commitment are
  /// rejected before proving starts.
  Future<SaplingWitnessResult> getAnchorBoundWitness({
    required String commitment,
    required BestAnchorResult anchor,
    int? notePosition,
  }) async {
    final attempts = <Map<String, Object>>[
      {
        'label': 'commitment_anchor',
        'params': <Object?>[commitment, anchor.anchor],
        'retries': 1,
      },
      {
        'label': 'commitment_only',
        'params': <Object?>[commitment, null],
        'retries': 2,
      },
    ];

    final failures = <String>[];
    for (final attempt in attempts) {
      final params = attempt['params'] as List<Object?>;
      final label = attempt['label'] as String;
      final retries = attempt['retries'] as int;
      for (var retry = 1; retry <= retries; retry++) {
        try {
          final witnessData = await getWitness(params[0]!, params[1]);
          if (witnessData == null) {
            throw SaplingRpcException('PIVX Sapling witness response is null');
          }

          final witness = SaplingWitnessResult.fromJson(
              Map<String, dynamic>.from(witnessData));
          if (label == 'commitment_only') {
            _validateWitnessCommitment(
              witness: witness,
              commitment: commitment,
            );
          } else {
            _validateAnchorBoundWitness(
              witness: witness,
              commitment: commitment,
              anchor: anchor,
            );
          }
          // SECURITY: the anchor this witness will be spent against must be
          // recomputable locally from (cmu, position, path). For the
          // commitment-only fallback the server-selected witness anchor
          // becomes the spend anchor, so verify against that root.
          _verifyWitnessRoot(
            witness: witness,
            commitment: commitment,
            expectedAnchor:
                label == 'commitment_only' ? witness.anchor : anchor.anchor,
          );
          final source = label == 'commitment_only'
              ? SaplingWitnessResult.sourceCommitmentOnlyFallback
              : SaplingWitnessResult.sourceAnchorBound;
          printV('[PIVX Sapling] Witness accepted via $source');
          return witness.withSource(source);
        } catch (e) {
          final reason = _witnessFailureReason(e);
          failures.add('$label:$reason');
          printV(
              '[PIVX Sapling] Witness attempt $label $retry/$retries failed: $reason');
        }
      }
    }

    throw SaplingRpcException(
      'PIVX Sapling witness lookup failed for selected note position; attempts=${failures.join(',')}',
    );
  }

  /// Reject the witness unless its Merkle root, recomputed locally from the
  /// note commitment, position, and sibling path, equals [expectedAnchor].
  void _verifyWitnessRoot({
    required SaplingWitnessResult witness,
    required String commitment,
    required String expectedAnchor,
  }) {
    // The native verifier (and the prover) work in serialization order. When
    // the node speaks display order, reverse cmu and anchor to serialization
    // before verifying. The witness PATH is already serialization order
    // (raw sapling_node_to_bytes_hex) and must NOT be reversed. Proven against
    // real chainster data in rust/src/notes.rs
    // (chainster_v1_witness_needs_display_to_serialization_reversal).
    final display = _capabilities?.usesDisplayByteOrder == true;
    final cmuHex = display ? reverseSaplingHexBytes(commitment) : commitment;
    final anchorHex =
        display ? reverseSaplingHexBytes(expectedAnchor) : expectedAnchor;
    final bool valid;
    try {
      valid = _witnessRootVerifier(
        witnessHex: witness.path.join(),
        cmuHex: cmuHex,
        anchorHex: anchorHex,
        position: witness.position,
      );
    } catch (e) {
      // Verification unavailable or inputs unparseable: fail closed.
      throw SaplingRpcException(
          'PIVX Sapling witness root verification failed (witness_root_mismatch)',
          e);
    }
    if (!valid) {
      throw SaplingRpcException(
          'PIVX Sapling witness root does not match the spend anchor (witness_root_mismatch)');
    }
  }

  static String _witnessFailureReason(Object error) {
    final text = error.toString().toLowerCase();

    if (text.contains('witness_root_mismatch')) {
      return 'witness_root_mismatch';
    }
    if (text.contains('canonical_witness_unavailable') ||
        text.contains('witness not found') ||
        text.contains('commitment not found')) {
      return 'canonical_witness_unavailable';
    }
    if (text.contains('response is null')) {
      return 'null_response';
    }
    if (text.contains('no path')) {
      return 'missing_path';
    }
    if (text.contains('invalid path') || text.contains('non-canonical node')) {
      return 'invalid_path';
    }
    if (text.contains('no anchor')) {
      return 'missing_anchor';
    }
    if (text.contains('anchor does not match')) {
      return 'anchor_mismatch';
    }
    if (text.contains('height does not match')) {
      return 'anchor_height_mismatch';
    }
    if (text.contains('no commitment')) {
      return 'missing_commitment';
    }
    if (text.contains('commitment does not match')) {
      return 'commitment_mismatch';
    }
    if (text.contains('no note position')) {
      return 'missing_position';
    }
    if (text.contains('rpc method unavailable') ||
        text.contains('unknown method') ||
        text.contains('method not found')) {
      return 'witness_method_unavailable';
    }
    if (text.contains('internal server error') ||
        text.contains('server error')) {
      return 'server_error';
    }

    return 'witness_lookup_failed';
  }

  void _validateAnchorBoundWitness({
    required SaplingWitnessResult witness,
    required String commitment,
    required BestAnchorResult anchor,
  }) {
    if (witness.anchor.toLowerCase() != anchor.anchor.toLowerCase()) {
      throw SaplingRpcException(
          'PIVX Sapling witness anchor does not match selected anchor');
    }
    if (witness.anchorHeight != anchor.height) {
      throw SaplingRpcException(
          'PIVX Sapling witness height does not match selected anchor height');
    }
    _validateWitnessCommitment(witness: witness, commitment: commitment);
  }

  void _validateWitnessCommitment({
    required SaplingWitnessResult witness,
    required String commitment,
  }) {
    if (witness.commitment.toLowerCase() != commitment.toLowerCase()) {
      throw SaplingRpcException(
          'PIVX Sapling witness commitment does not match requested note');
    }
  }

  /// Sapling data for transaction [txid] (hex).
  Future<Map<String, dynamic>?> getTransactionSapling(String txid) async {
    final result = await _callFirstSupported(
        methods: const ['blockchain.transaction.get_sapling'],
        params: <Object>[txid]);
    return result as Map<String, dynamic>?;
  }

  /// Sync blocks in batches. [onRangeComplete] fires per range, even if empty.
  Future<void> syncBlocks({
    required int fromHeight,
    required int toHeight,
    int batchSize = 100,
    int parallelBatches = 5,
    required Future<void> Function(List<SaplingBlock> blocks) onBatch,
    Future<void> Function(
      int rangeStart,
      int rangeEnd,
      Map<int, String> blockHashes,
    )? onRangeComplete,
    bool Function()? shouldCancel,
  }) async {
    // Server enforces max 100 blocks per request
    final effectiveBatchSize = batchSize.clamp(1, 100);

    // fast path: with the active-height index, skip every empty window (most of
    // a restore) and fetch only windows with Sapling activity. falls back to the
    // full scan below when unavailable.
    final activeHeights = await fetchActiveHeights(fromHeight, toHeight);
    if (activeHeights != null) {
      await _syncActiveWindows(
        fromHeight: fromHeight,
        toHeight: toHeight,
        batchSize: effectiveBatchSize,
        parallelBatches: parallelBatches,
        activeHeights: activeHeights,
        onBatch: onBatch,
        onRangeComplete: onRangeComplete,
        shouldCancel: shouldCancel,
      );
      return;
    }

    int currentStart = fromHeight;

    while (currentStart <= toHeight) {
      if (shouldCancel?.call() ?? false) break;
      final batchFutures = <Future<_BatchResult?>>[];

      for (int i = 0;
          i < parallelBatches &&
              currentStart + i * effectiveBatchSize <= toHeight;
          i++) {
        final start = currentStart + i * effectiveBatchSize;
        final end =
            (start + effectiveBatchSize - 1).clamp(fromHeight, toHeight);

        batchFutures.add(_fetchBatchWithRetry(start, end));
      }

      final results = await Future.wait(batchFutures);

      // Batches are ordered low->high. A null marks the first batch at/above the
      // node's indexed ceiling (or a transient backend stall): process the
      // contiguous prefix we did get, then end this pass. The next pass (driven
      // by a new-block notification or the periodic poll) resumes once the
      // Sapling index advances, no hot-loop, no hard failure.
      var reachedCeiling = false;
      for (final result in results) {
        if (result == null) {
          reachedCeiling = true;
          break;
        }
        if (result.blocks.isNotEmpty) {
          await onBatch(result.blocks);
        }
        await onRangeComplete?.call(
          result.startHeight,
          result.endHeight,
          result.blockHashes,
        );
      }
      if (reachedCeiling) break;

      currentStart += parallelBatches * effectiveBatchSize;
    }
  }

  /// aligned, non-overlapping windows (relative to [fromHeight]) holding >=1
  /// active height. each height maps to one window, so blocks never overlap
  /// (overlap would double-apply the note commitment tree). ascending; each
  /// window is `[start, end]` inclusive.
  static List<List<int>> computeActiveWindows(
    int fromHeight,
    int toHeight,
    int batchSize,
    List<int> activeHeights,
  ) {
    if (batchSize < 1 || toHeight < fromHeight) return const [];
    final windowStarts = <int>{};
    for (final h in activeHeights) {
      if (h < fromHeight || h > toHeight) continue;
      final k = (h - fromHeight) ~/ batchSize;
      windowStarts.add(fromHeight + k * batchSize);
    }
    final sorted = windowStarts.toList()..sort();
    return [
      for (final start in sorted)
        <int>[start, (start + batchSize - 1).clamp(fromHeight, toHeight)],
    ];
  }

  /// scan only windows with Sapling activity, in ascending parallel waves, then
  /// advance the persisted cursor across the trailing empty gap to [toHeight].
  /// empty blocks add zero commitments, so skipping them leaves the tree
  /// position correct.
  Future<void> _syncActiveWindows({
    required int fromHeight,
    required int toHeight,
    required int batchSize,
    required int parallelBatches,
    required List<int> activeHeights,
    required Future<void> Function(List<SaplingBlock> blocks) onBatch,
    Future<void> Function(int, int, Map<int, String>)? onRangeComplete,
    bool Function()? shouldCancel,
  }) async {
    final windows =
        computeActiveWindows(fromHeight, toHeight, batchSize, activeHeights);
    final waveSize = parallelBatches < 1 ? 1 : parallelBatches;

    var idx = 0;
    var stopped = false;
    while (idx < windows.length) {
      if (shouldCancel?.call() ?? false) {
        stopped = true;
        break;
      }
      final waveEnd =
          (idx + waveSize) > windows.length ? windows.length : idx + waveSize;
      final wave = windows.sublist(idx, waveEnd);
      final results = await Future.wait(
        wave.map((w) => _fetchBatchWithRetry(w[0], w[1])),
      );

      // Same low->high ordering + ceiling handling as the full scan.
      var reachedCeiling = false;
      for (final result in results) {
        if (result == null) {
          reachedCeiling = true;
          break;
        }
        if (result.blocks.isNotEmpty) {
          await onBatch(result.blocks);
        }
        await onRangeComplete?.call(
          result.startHeight,
          result.endHeight,
          result.blockHashes,
        );
      }
      if (reachedCeiling) {
        stopped = true;
        break;
      }
      idx = waveEnd;
    }

    // confirmed-empty gap after the last active window: advance the persisted
    // sync height to toHeight so a resume doesn't re-scan it. skipped on early
    // stop (cancel/ceiling) so progress isn't over-reported.
    if (!stopped) {
      await onRangeComplete?.call(fromHeight, toHeight, const <int, String>{});
    }
  }

  /// Returns null when the range is at/above the node's indexed ceiling or the
  /// backend is transiently not ready, so the caller ends the pass and resumes
  /// later. Only genuinely malformed/hard failures throw.
  Future<_BatchResult?> _fetchBatchWithRetry(int start, int end,
      {int retries = 2}) async {
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        final result = await getBlockRangeResult(start, endHeight: end)
            .timeout(kSaplingBlockRangeFetchTimeout);
        return _BatchResult(result.blocks, start, end, result.blockHashes);
      } on SaplingRetryableRangeException {
        return null;
      } on TimeoutException {
        // socket alive (ping answers) but node stalled on the range. treat like
        // a not-ready range: end the pass, resume next poll.
        return null;
      } catch (e) {
        if (attempt == retries) {
          throw SaplingRpcException(
            'PIVX Sapling block range $start-$end failed after ${retries + 1} attempts',
            e,
          );
        }
        await Future.delayed(Duration(milliseconds: 100 * (attempt + 1)));
      }
    }
    return null;
  }

  /// Spent status for multiple nullifiers (nullifier -> spent).
  Future<Map<String, bool>> checkNullifiers(List<String> nullifiers) async {
    final results = <String, bool>{};

    final futures = nullifiers.map((nf) async {
      final status = await getNullifierStatus(nf);
      return MapEntry(nf, status.spent);
    });

    final entries = await Future.wait(futures);
    results.addEntries(entries);

    return results;
  }
}
