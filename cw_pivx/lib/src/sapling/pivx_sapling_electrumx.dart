/// PIVX Sapling ElectrumX client for the `blockchain.sapling.*` v1 contract
/// (pivx.sapling.electrumx.v1, chainster default nodes). Non-v1 nodes are rejected.

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_pivx/src/sapling/sapling_constants.dart';
import 'package:cw_pivx/src/sapling/sapling_ffi.dart' as sapling_ffi;

/// false on a clean root mismatch; throws when verification cannot run.
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

/// v1 nodes with `hex_byte_order: "display"` emit every 32-byte field (cmu,
/// epk, anchor, nullifier) via uint256 GetHex; native crypto wants serialization
/// order. Witness path nodes and variable-length blobs are never reversed.
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

String? _rangeErrorType(Object? error) =>
    error is Map ? _optionalString(error['type']) ?? 'unknown' : null;

const String _v1LiveProbeHex32 =
    '0000000000000000000000000000000000000000000000000000000000000000';

class SaplingRpcException implements Exception {
  final String message;
  final Object? cause;

  SaplingRpcException(this.message, [this.cause]);

  @override
  String toString() => cause == null ? message : '$message: $cause';
}

/// get_block_range "not ready yet" (indexer lag, backend timeout): end the pass
/// without advancing the synced height.
class SaplingRetryableRangeException extends SaplingRpcException {
  SaplingRetryableRangeException(super.message, [super.cause]);
}

/// Incomplete caps payload, worth retrying; definitive rejections (wrong network,
/// half-upgraded v1) are not wrapped and propagate immediately.
class _RetryableCapabilityProbe implements Exception {
  _RetryableCapabilityProbe(this.cause);
  final Object cause;
  @override
  String toString() => 'RetryableCapabilityProbe: $cause';
}

// call() has no timeout; a node that answers pings but stalls a range query
// would otherwise wedge the sync.
const Duration kSaplingBlockRangeFetchTimeout = Duration(seconds: 30);

class SaplingRpcCapabilities {
  static const String v1ContractId = 'pivx.sapling.electrumx.v1';

  final bool supportsBlockRange;
  final bool supportsGlobalOutputPositions;
  final bool supportsBestAnchor;
  final bool supportsWitness;
  final bool supportsBlockHashes;
  final bool supportsStructuredErrors;
  final String? network;
  final int? activationHeight;
  final String? contract;
  final Set<String> methods;

  /// "display" or "serialization".
  final String? hexByteOrder;

  /// `features.canonical_witnesses` AND a `witness_backend`; gates shielded sends.
  final bool canonicalWitnesses;

  final Map<String, dynamic>? indexStatus;

  /// get_active_heights: a restore skips empty windows instead of scanning all.
  final bool supportsActiveHeights;

  final int? activeHeightsMaxLimit;

  /// db_height only passes a block once its Sapling data is queryable, so the
  /// sync can scan right at db_height with no safety margin.
  final bool supportsConsistentDbHeight;

  final bool supportsMempool;
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
    this.contract,
    this.methods = const {},
    this.hexByteOrder,
    this.canonicalWitnesses = false,
    this.indexStatus,
    this.supportsActiveHeights = false,
    this.activeHeightsMaxLimit,
    this.supportsConsistentDbHeight = false,
    this.supportsMempool = false,
    this.supportsMempoolSubscribe = false,
  });

  bool get usesDisplayByteOrder => hexByteOrder?.toLowerCase() == 'display';

  /// get_block_range ceiling: `to > db_height` returns index_incomplete.
  int? get indexHeight => _optionalInt(indexStatus?['db_height']);

  /// Header tip; leads db_height slightly, so confirmations count from here.
  int? get daemonHeight => _optionalInt(indexStatus?['daemon_height']);

  factory SaplingRpcCapabilities.fromJson(Map<String, dynamic> json) {
    final methods = <String>{
      ...?(json['methods'] as List<dynamic>?)?.map((e) => e.toString()),
    };
    final rawFeatures = json['features'];
    final features = rawFeatures is Map ? rawFeatures : const {};
    final indexStatusRaw = json['index_status'];

    return SaplingRpcCapabilities(
      supportsBlockRange:
          methods.contains('blockchain.sapling.get_block_range'),
      supportsGlobalOutputPositions:
          features['global_output_positions'] == true,
      supportsBestAnchor:
          methods.contains('blockchain.sapling.get_best_anchor'),
      supportsWitness: methods.contains('blockchain.sapling.get_witness'),
      supportsBlockHashes: features['block_hashes'] == true,
      supportsStructuredErrors: features['structured_errors'] == true,
      network: _optionalString(json['network']),
      activationHeight: _optionalInt(json['sapling_activation_height']),
      contract: _optionalString(json['contract']),
      methods: methods,
      hexByteOrder: _optionalString(json['hex_byte_order']),
      canonicalWitnesses: features['canonical_witnesses'] == true &&
          _optionalString(json['witness_backend']) != null,
      indexStatus: indexStatusRaw is Map
          ? Map<String, dynamic>.from(indexStatusRaw)
          : null,
      supportsActiveHeights:
          methods.contains('blockchain.sapling.get_active_heights'),
      activeHeightsMaxLimit: _optionalInt(json['active_heights_max_limit']),
      supportsConsistentDbHeight: features['consistent_db_height'] == true,
      supportsMempool: methods.contains('blockchain.sapling.get_mempool'),
      supportsMempoolSubscribe:
          methods.contains('blockchain.sapling.mempool.subscribe'),
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
}

/// Result from get_nullifier_status RPC.
class NullifierStatus {
  final bool spent;

  NullifierStatus({required this.spent});

  // A missing field is not "unspent": spend selection trusts this answer.
  factory NullifierStatus.fromJson(Map<String, dynamic> json) {
    final spent = json['spent'];
    if (spent is! bool) {
      throw SaplingRpcException('PIVX Sapling nullifier status has no spent flag');
    }
    return NullifierStatus(spent: spent);
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
  final String cmu;
  final String epk;

  /// 580-byte encrypted note, raw wire bytes.
  final String ciphertext;

  /// Global commitment tree position, when the server returns one.
  final int? globalPosition;

  SaplingShieldedOutput({
    required this.cmu,
    required this.epk,
    required this.ciphertext,
    this.globalPosition,
  });

  factory SaplingShieldedOutput.fromJson(Map<String, dynamic> json) {
    return SaplingShieldedOutput(
      cmu: json['cmu'] as String,
      epk: json['epk'] as String,
      ciphertext: json['ciphertext'] as String,
      globalPosition: _optionalInt(json['global_position']),
    );
  }

  Uint8List get cmuBytes => Uint8List.fromList(hex.decode(cmu));

  Uint8List get epkBytes => Uint8List.fromList(hex.decode(epk));

  Uint8List get ciphertextBytes => Uint8List.fromList(hex.decode(ciphertext));
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
  final String nullifier;

  SaplingSpend({required this.nullifier});

  factory SaplingSpend.fromJson(Map<String, dynamic> json) =>
      SaplingSpend(nullifier: json['nullifier'] as String);

  Uint8List get nullifierBytes => Uint8List.fromList(hex.decode(nullifier));
}

/// A Sapling transaction from get_block_range.
class SaplingTransaction {
  final String txid;
  final List<SaplingShieldedOutput> outputs;
  final List<SaplingSpend> spends;

  /// Mempool entry time (get_mempool only).
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
}

/// Snapshot from get_mempool: unconfirmed Sapling txs (same tx shape as a block,
/// no height/position). [truncated] true when the server hit its output cap.
class SaplingMempoolResult {
  final List<SaplingTransaction> txs;
  final bool truncated;

  SaplingMempoolResult({required this.txs, this.truncated = false});

  /// Callers replace their whole 0-conf state with a snapshot, so a capped or
  /// shapeless one would drop receives it merely left out.
  static bool isComplete(Map<dynamic, dynamic> json) =>
      json['txs'] is List && json['truncated'] != true;

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
  final String anchor;
  final int height;

  BestAnchorResult({
    required this.anchor,
    required this.height,
  });

  factory BestAnchorResult.fromJson(Map<String, dynamic> json) {
    // `height` is the chain tip; the anchor's own height is anchor_height.
    final anchor = json['anchor'] as String?;
    final height = _optionalInt(json['anchor_height']);
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
}

/// Anchor-bound Merkle witness for spend proof construction.
class SaplingWitnessResult {
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
  final String? source;

  SaplingWitnessResult({
    required this.position,
    required this.path,
    required this.anchor,
    required this.anchorHeight,
    required this.commitment,
    this.source,
  });

  factory SaplingWitnessResult.fromJson(Map<String, dynamic> json,
      {String? source}) {
    final rawJsonPath = json['path'];
    final rawPath = rawJsonPath is List && rawJsonPath.every((e) => e is String)
        ? rawJsonPath.cast<String>()
        : null;
    final path = _expandWitnessPath(rawPath);
    final anchor = json['anchor'] as String?;
    final anchorHeight = _optionalInt(json['anchor_height']);
    final commitment = json['commitment'] as String?;
    final position = _optionalInt(json['position']);

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
      source: source,
    );
  }

  static List<String>? _expandWitnessPath(List<String>? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return rawPath;
    final path = _splitWitnessPath(rawPath);
    if (path == null || path.length > saplingTreeDepth) return null;

    final expanded = _padWitnessPath(path);
    final invalidIndex = _firstNonCanonicalNodeIndex(expanded);
    if (invalidIndex == null) return expanded;

    final reversedPath =
        path.map(reverseSaplingHexBytes).toList(growable: false);
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

  static BigInt _littleEndianHexToBigInt(String hexValue) =>
      BigInt.parse(reverseSaplingHexBytes(hexValue), radix: 16);
}

/// Parsed v1 `blockchain.sapling.get_active_heights` response.
class SaplingActiveHeightsResult {
  const SaplingActiveHeightsResult({
    required this.heights,
    required this.start,
    required this.end,
    required this.complete,
  });

  /// Ascending, unique block heights with >=1 Sapling tx in this page.
  final List<int> heights;

  /// First / last height covered by this page. On truncation resume at [end]+1.
  final int start;
  final int end;

  /// False when the page was truncated by the server's limit.
  final bool complete;

  factory SaplingActiveHeightsResult.fromJson(
    Map<String, dynamic> json,
    int requestStart,
    int requestEnd,
  ) {
    // An empty list skips every window in range, so only a well-formed page
    // may say so; fetchActiveHeights falls back to a full scan on a throw.
    final rawHeights = json['heights'];
    final start = _optionalInt(json['start']);
    final end = _optionalInt(json['end']);
    // A page starting past the cursor or listing heights outside its bounds
    // would skip blocks the next page never revisits.
    if (rawHeights is! List ||
        start == null ||
        end == null ||
        start != requestStart ||
        end < start ||
        end > requestEnd) {
      throw SaplingRpcException('PIVX Sapling active-heights page is malformed');
    }
    final heights = <int>[];
    for (final h in rawHeights) {
      final v = _optionalInt(h);
      if (v == null || v < start || v > end) {
        throw SaplingRpcException(
            'PIVX Sapling active height is missing or out of range');
      }
      heights.add(v);
    }
    heights.sort();
    return SaplingActiveHeightsResult(
      heights: heights,
      start: start,
      end: end,
      complete: json['complete'] == true,
    );
  }
}

/// Wraps an ElectrumX client to add Sapling-specific RPC methods.
class PIVXSaplingElectrumX {
  final dynamic _client;

  /// Injectable for tests; defaults to the native verifier.
  final WitnessRootVerifier _witnessRootVerifier;

  PIVXSaplingElectrumX({
    required dynamic electrumClient,
    WitnessRootVerifier? witnessRootVerifier,
    SaplingRpcCapabilities? capabilities,
  })  : _client = electrumClient,
        _capabilities = capabilities,
        _witnessRootVerifier =
            witnessRootVerifier ?? sapling_ffi.verifyWitnessRoot;

  SaplingRpcCapabilities? _capabilities;

  /// The capabilities negotiated for the active node, if already probed.
  SaplingRpcCapabilities? get capabilities => _capabilities;

  int get activationHeight => PivxSaplingNetwork.mainnetSaplingActivationHeight;

  Future<dynamic> _call(String method, [List<Object> params = const []]) async {
    int? requestId;
    final result = await _client.call(
      method: method,
      params: params,
      idCallback: (id) => requestId = id as int,
    );
    final errorMessage = _errorMessageForRequest(requestId);
    if (errorMessage != null) throw SaplingRpcException(errorMessage);
    return result;
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

  /// A healthy node can return an incomplete caps payload right after a
  /// reconnect; retrying keeps that from surfacing a "switch nodes" error.
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
        lastCause = e.cause;
        if (attempt < _capabilityProbeAttempts - 1) {
          await Future<void>.delayed(
              Duration(milliseconds: 300 * (attempt + 1)));
        }
      }
    }
    throw lastCause!;
  }

  /// Fresh db_height each call; the probe-time value never moves and would stall
  /// the sync at the first ceiling seen.
  /// Live value; the probe cache would freeze confirmations at its first read.
  int? get daemonHeight =>
      _liveDaemonHeight ?? _capabilities?.daemonHeight;
  int? _liveDaemonHeight;

  /// db_height from the last fetchLiveIndexHeight, else the probe's.
  int? get liveIndexHeight => _liveIndexHeight ?? _capabilities?.indexHeight;
  int? _liveIndexHeight;

  void invalidateCapabilities() {
    _capabilities = null;
    _liveDaemonHeight = null;
    _liveIndexHeight = null;
    _generation++;
  }

  // Bumped on node switch; a probe begun before it cannot cache its result.
  int _generation = 0;

  Future<int?> fetchLiveIndexHeight() async {
    try {
      final result = await _call('blockchain.sapling.capabilities');
      if (result is Map) {
        final idx = result['index_status'];
        if (idx is Map) {
          _liveDaemonHeight =
              _optionalInt(idx['daemon_height']) ?? _liveDaemonHeight;
          final dbHeight = _optionalInt(idx['db_height']);
          _liveIndexHeight = dbHeight ?? _liveIndexHeight;
          return dbHeight;
        }
      }
    } catch (_) {
      // fall through to null; caller uses the cached ceiling / header tip
    }
    return null;
  }

  /// null on not-ready/error (caller keeps prior state); empty txs is an
  /// authoritative empty mempool (caller clears).
  Future<SaplingMempoolResult?> fetchMempool() async {
    try {
      final result = await _call('blockchain.sapling.get_mempool');
      if (result is! Map) return null;
      if (result['success'] == false || result['error'] != null) return null;
      if (!SaplingMempoolResult.isComplete(result)) return null;
      return SaplingMempoolResult.fromJson(Map<String, dynamic>.from(result));
    } catch (_) {
      return null;
    }
  }

  /// Full-state snapshot first, then on every change. null when unsupported or
  /// disconnected; caller falls back to polling.
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

  /// Envelope map or wrapped in a params list; not-ready/error yields null.
  SaplingMempoolResult? _parseMempoolPush(dynamic event) {
    dynamic payload = event;
    if (payload is List && payload.isNotEmpty) payload = payload.first;
    if (payload is! Map) return null;
    if (payload['success'] == false || payload['error'] != null) return null;
    if (!SaplingMempoolResult.isComplete(payload)) return null;
    return SaplingMempoolResult.fromJson(Map<String, dynamic>.from(payload));
  }

  // A node switch mid-probe fails its RPCs on the closing socket before the
  // generation check; either way the probe is stale, so retry it.
  Future<SaplingRpcCapabilities> _probeCapabilitiesOnce() async {
    final generation = _generation;
    try {
      return await _probeCapabilitiesUnchecked(generation);
    } on _RetryableCapabilityProbe {
      rethrow;
    } catch (e) {
      if (generation != _generation) throw _RetryableCapabilityProbe(e);
      rethrow;
    }
  }

  Future<SaplingRpcCapabilities> _probeCapabilitiesUnchecked(
      int generation) async {
    final result = await _call('blockchain.sapling.capabilities');
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
    if (!capabilities.supportsV1ReleaseContract) {
      throw SaplingRpcException(
          'PIVX Sapling node is not a complete ${SaplingRpcCapabilities.v1ContractId} server');
    }
    if (capabilities.network?.toLowerCase() != 'mainnet') {
      throw SaplingRpcException(
          'PIVX Sapling node network mismatch: expected mainnet');
    }
    if (capabilities.activationHeight != null &&
        capabilities.activationHeight != activationHeight) {
      throw SaplingRpcException(
          'PIVX Sapling activation height mismatch for current network');
    }
    await _validateLiveV1ReleaseMethods();
    if (generation != _generation) {
      throw _RetryableCapabilityProbe(
          SaplingRpcException('PIVX Sapling node changed during probe'));
    }
    _capabilities = capabilities;
    return capabilities;
  }

  Future<void> _validateLiveV1ReleaseMethods() async {
    try {
      final anchorResult = await _call('blockchain.sapling.get_best_anchor');
      if (anchorResult is! Map) {
        throw SaplingRpcException(
            'get_best_anchor returned ${anchorResult.runtimeType}');
      }
      BestAnchorResult.fromJson(Map<String, dynamic>.from(anchorResult));

      final nullifierResult = await _call(
          'blockchain.sapling.get_nullifier_status', const [_v1LiveProbeHex32]);
      if (nullifierResult is! Map) {
        throw SaplingRpcException(
            'get_nullifier_status returned ${nullifierResult.runtimeType}');
      }
      NullifierStatus.fromJson(Map<String, dynamic>.from(nullifierResult));

      final commitmentResult = await _call(
          'blockchain.sapling.get_commitment_info', const [_v1LiveProbeHex32]);
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
    final result =
        await _call('blockchain.sapling.get_nullifier_status', [nullifier]);
    return NullifierStatus.fromJson(result as Map<String, dynamic>);
  }

  /// One page; may be truncated. Use [fetchActiveHeights] for a full range.
  Future<SaplingActiveHeightsResult> getActiveHeights(
    int startHeight, {
    int? endHeight,
    int? limit,
  }) async {
    final params = <Object>[startHeight];
    if (endHeight != null) params.add(endHeight);
    if (limit != null) params.add(limit);

    final result = await _call('blockchain.sapling.get_active_heights', params);
    return SaplingActiveHeightsResult.fromJson(
      result as Map<String, dynamic>,
      startHeight,
      endHeight ?? startHeight,
    );
  }

  /// Ascending active heights, or null when the node cannot serve the index
  /// (caller full-scans).
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
      heights.addAll(result.heights.where((h) => h >= cursor && h <= toHeight));
      if (result.complete) {
        // A server that caps end below toHeight would otherwise advance the
        // cursor across heights it never listed.
        covered = result.end >= toHeight;
        break;
      }
      final nextCursor = result.end + 1;
      if (nextCursor <= cursor) break; // no forward progress -> incomplete
      cursor = nextCursor;
    }
    // A partial set would advance the cursor past unreturned active blocks and
    // drop their notes.
    if (!covered) return null;
    return heights;
  }

  /// Max 100 blocks per request; every height comes back, most with no txs.
  Future<SaplingBlockRangeResult> getBlockRangeResult(
    int startHeight, {
    int? endHeight,
  }) async {
    final expectedEnd = endHeight ?? startHeight;
    final params = <Object>[startHeight];
    if (endHeight != null) params.add(endHeight);

    final result = await _call('blockchain.sapling.get_block_range', params);

    if (result is! Map) {
      throw SaplingRpcException(
        'PIVX Sapling get_block_range returned ${result.runtimeType} for $startHeight-$expectedEnd',
      );
    }
    // Indexer lag is retryable so the sync never advances past it.
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
    // No bounds is not "covered": an empty blocks list would advance the
    // cursor over the whole requested range.
    final responseStart = _optionalInt(result['start_height']);
    final responseEnd = _optionalInt(result['end_height']);
    if (responseStart != startHeight) {
      throw SaplingRpcException(
        'PIVX Sapling get_block_range returned a mismatched start height',
      );
    }
    if (responseEnd != expectedEnd) {
      throw SaplingRpcException(
        'PIVX Sapling get_block_range returned a mismatched end height',
      );
    }
    final blockHashes = _parseBlockHashes(result['block_hashes']);
    final blocksResult = result['blocks'];
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

  /// `[{height, block_hash}, ...]`, one per height in the range.
  Map<int, String> _parseBlockHashes(Object? raw) {
    final hashes = <int, String>{};
    if (raw is! List) return hashes;
    for (final item in raw) {
      if (item is! Map) continue;
      final height = _optionalInt(item['height']);
      final hash = _optionalString(item['block_hash']);
      if (height != null && hash != null) hashes[height] = hash;
    }
    return hashes;
  }

  /// Takes no params: v1 rejects a max-height argument.
  Future<BestAnchorResult> getBestAnchor() async {
    final result = await _call('blockchain.sapling.get_best_anchor');
    if (result is! Map) {
      throw SaplingRpcException(
          'get_best_anchor returned ${result.runtimeType}');
    }
    return BestAnchorResult.fromJson(Map<String, dynamic>.from(result));
  }

  /// Low-level; spends go through [getAnchorBoundWitness].
  Future<Map<String, dynamic>?> getWitness(
      Object commitmentOrPosition, Object? anchorOrHeight) async {
    final params = <Object>[commitmentOrPosition];
    if (anchorOrHeight != null) {
      params.add(anchorOrHeight);
    }
    final result = await _call('blockchain.sapling.get_witness', params);
    return result as Map<String, dynamic>?;
  }

  /// Every witness must bind to the anchor the spend signs with; a mismatched
  /// anchor, height or commitment is rejected before proving.
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

          final source = label == 'commitment_only'
              ? SaplingWitnessResult.sourceCommitmentOnlyFallback
              : SaplingWitnessResult.sourceAnchorBound;
          final witness = SaplingWitnessResult.fromJson(
              Map<String, dynamic>.from(witnessData),
              source: source);
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
          // The spend anchor must be recomputable locally. The commitment-only
          // fallback spends against the server-selected root, so check that.
          _verifyWitnessRoot(
            witness: witness,
            commitment: commitment,
            expectedAnchor:
                label == 'commitment_only' ? witness.anchor : anchor.anchor,
          );
          printV('[PIVX Sapling] Witness accepted via $source');
          return witness;
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

  void _verifyWitnessRoot({
    required SaplingWitnessResult witness,
    required String commitment,
    required String expectedAnchor,
  }) {
    // cmu and anchor go to serialization order; the path already is and must
    // not be reversed (rust/src/notes.rs chainster_v1_witness test).
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

  /// Sync blocks in batches. [onRangeComplete] fires per range, even if empty.
  /// False when the pass stopped short of [toHeight] (index ceiling, stall or
  /// cancel); the caller must not report the range as synced.
  Future<bool> syncBlocks({
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
    final size = batchSize.clamp(1, 100);
    final waveSize = parallelBatches < 1 ? 1 : parallelBatches;

    // With the active-height index only windows holding Sapling activity are
    // fetched (most of a restore is empty); otherwise every window is.
    final activeHeights = await fetchActiveHeights(fromHeight, toHeight);
    final windows = activeHeights != null
        ? computeActiveWindows(fromHeight, toHeight, size, activeHeights)
        : [
            for (var start = fromHeight; start <= toHeight; start += size)
              <int>[start, (start + size - 1).clamp(fromHeight, toHeight)],
          ];

    for (var idx = 0; idx < windows.length; idx += waveSize) {
      if (shouldCancel?.call() ?? false) return false;
      final wave = windows.sublist(idx, min(idx + waveSize, windows.length));
      final results = await Future.wait(
        wave.map((w) => _fetchBatchWithRetry(w[0], w[1])),
      );

      // Ordered low->high. null = at the indexed ceiling or a transient stall:
      // process the contiguous prefix and end the pass; the next header or poll
      // resumes once the index advances.
      for (final result in results) {
        if (result == null) return false;
        if (result.blocks.isNotEmpty) await onBatch(result.blocks);
        await onRangeComplete?.call(
          result.startHeight,
          result.endHeight,
          result.blockHashes,
        );
      }
    }

    // Skipped windows are confirmed empty: advance the persisted height across
    // the trailing gap so a resume does not rescan it.
    if (activeHeights != null) {
      await onRangeComplete?.call(fromHeight, toHeight, const <int, String>{});
    }
    return true;
  }

  /// Aligned, non-overlapping `[start, end]` windows (relative to [fromHeight])
  /// holding >=1 active height; overlap would double-apply the commitment tree.
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

  /// null when the range is at/above the indexed ceiling or the backend is not
  /// ready; only hard failures throw.
  Future<SaplingBlockRangeResult?> _fetchBatchWithRetry(int start, int end,
      {int retries = 2}) async {
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        return await getBlockRangeResult(start, endHeight: end)
            .timeout(kSaplingBlockRangeFetchTimeout);
      } on SaplingRetryableRangeException {
        return null;
      } on TimeoutException {
        return null;
      } catch (e) {
        // Dense Sapling stretches (e.g. 5407501-5407600) exceed the server's 2MB
        // response cap on a 100-block window; retrying the same window never
        // succeeds, so halve it.
        if (end > start && e.toString().contains('response too large')) {
          return _fetchSplit(start, end);
        }
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

  // Both halves or nothing: a partial result would let the caller advance past
  // unscanned heights.
  Future<SaplingBlockRangeResult?> _fetchSplit(int start, int end) async {
    final mid = start + (end - start) ~/ 2;
    final low = await _fetchBatchWithRetry(start, mid);
    if (low == null) return null;
    final high = await _fetchBatchWithRetry(mid + 1, end);
    if (high == null) return null;
    return SaplingBlockRangeResult(
      startHeight: low.startHeight,
      endHeight: high.endHeight,
      blocks: [...low.blocks, ...high.blocks],
      blockHashes: {...low.blockHashes, ...high.blockHashes},
    );
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
