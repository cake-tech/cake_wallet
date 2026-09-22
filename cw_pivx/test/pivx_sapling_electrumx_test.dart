import 'dart:async';

import 'package:cw_pivx/src/sapling/pivx_sapling_electrumx.dart';
import 'package:cw_pivx/src/sapling/sapling_factories.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sentinel response: makes [FakeElectrumClient.call] return a future that never
/// completes, simulating a node that keeps the socket alive but never answers
/// the query.
class FakeHang {
  const FakeHang();
}

class FakeElectrumClient {
  FakeElectrumClient(this.responses);

  final List<dynamic> responses;
  final Map<int, String> errors = {};
  final calledMethods = <String>[];
  final calledParams = <List<Object>>[];
  int calls = 0;
  int _id = 0;

  Future<dynamic> call({
    required String method,
    List<Object> params = const [],
    Function(int)? idCallback,
  }) async {
    calls++;
    calledMethods.add(method);
    calledParams.add(List<Object>.from(params));
    _id++;
    idCallback?.call(_id);
    final response = responses.removeAt(0);
    if (response is FakeHang) {
      return Completer<dynamic>().future; // never completes
    }
    if (response is FakeRpcError) {
      errors[_id] = response.message;
      return null;
    }
    if (response is Exception) {
      throw response;
    }
    return response;
  }

  String getErrorMessage(int id) => errors[id] ?? '';
}

class FakeRpcError {
  FakeRpcError(this.message);

  final String message;
}

/// Fake witness-root verifier that records calls; assignable to
/// [WitnessRootVerifier] through its call method.
class RecordingWitnessVerifier {
  RecordingWitnessVerifier({this.result = true, this.error});

  bool result;
  Object? error;
  final calls = <Map<String, Object>>[];

  bool call({
    required String witnessHex,
    required String cmuHex,
    required String anchorHex,
    required int position,
  }) {
    calls.add({
      'witnessHex': witnessHex,
      'cmuHex': cmuHex,
      'anchorHex': anchorHex,
      'position': position,
    });
    if (error != null) throw error!;
    return result;
  }
}

Map<String, dynamic> bestAnchorJson() => {
      'anchor':
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      'height': 2701000,
    };

Map<String, dynamic> nullifierUnspentJson() => {'spent': false};

Map<String, dynamic> commitmentMissingJson() => {'exists': false};

Map<String, dynamic> v1CapabilitiesJson({
  String contract = SaplingRpcCapabilities.v1ContractId,
  List<String>? methods,
  Map<String, dynamic>? features,
  Map<String, dynamic>? rangeResponseFormat,
}) =>
    {
      'contract': contract,
      'server_version': 'ElectrumX 1.19.0-pivx',
      'pivx_core_version': 'v5.6.1',
      'network': 'mainnet',
      'sapling_activation_height': SaplingActivation.mainnet,
      'max_block_range': 100,
      'methods': methods ??
          [
            'blockchain.sapling.get_block_range',
            'blockchain.sapling.get_best_anchor',
            'blockchain.sapling.get_witness',
            'blockchain.sapling.get_nullifier_status',
            'blockchain.sapling.get_commitment_info',
          ],
      'features': features ??
          {
            'global_output_positions': true,
            'block_hashes': true,
            'structured_errors': true,
          },
      'range_response_format': rangeResponseFormat ??
          {
            'global_output_positions': true,
            'block_hashes': true,
          },
    };

// Real chainster v1 capture (pivx.sapling.electrumx.v1, hex_byte_order=display),
// global_position 0. cmu/anchor are display order; the serialization order the
// native crypto needs is the 32-byte reversal.
const chainsterCmuDisplay =
    '219abc22220f9e133c4414d9462b9d86e3c8fb1b6ccda36ff0d919c5f6588a95';
const chainsterCmuSerialization =
    '958a58f6c519d9f06fa3cd6c1bfbc8e3869d2b46d914443c139e0f2222bc9a21';
const chainsterAnchorDisplay =
    '23ad2c39c720e69af6cf5c7cca8aa501d7a36964ba7d9755659b242fb6dd06db';
const chainsterAnchorSerialization =
    'db06ddb62f249b6555977dba6469a3d701a58aca7c5ccff69ae620c7392cad23';

// The real 32-node leaf-to-root witness path for the note above (already
// serialization order, never reversed).
const chainsterWitnessPath = <String>[
  '7352fa42ff23e572387ba965db04bdc6fd6cab74b97338c4c79948c6dc4bc33c',
  'ce75b04ebdcf92ea0cab93bf5fc2cd675fc867accacb42550f357950b8fc3a14',
  '6875488967e1008d7fec44841dab10a7c244266bdb936a9fad10e798da1a5b39',
  '76fe6c77f4f4603669b1159e519329f97744e69dcffef6b6266cf5c3c916eb31',
  '61022337bf970d2de80803684e0fe6248c3c6a7ad581433ffda690cdc8ec0a42',
  '938988a2c5c64733c988336bff7b5d8416277036363aeaad0968afffe665de1b',
  '30d3896b4ead5b4c9db948361c6466acc6bc0a6d44af52b5ce75a107ff186b51',
  'ac787541cd73929dca61aff447c2995ac74ec0c59f3a769ce02553162ea9162c',
  '3ec002c09ed73b1133790de0cf66a847ba5495e2568e0c05d4a07ce691b14d0a',
  '273e391d61d8df4c83d402ed2e46702c81841092e3a9499bc72082d0c5fc241c',
  'e401f0174fefa0bd37301482536d9541ef16b48d2a5f75077bc9c55eaf35ac4e',
  '53925b451d437417eb98769352a43b8456f444c7e6374a25d6872be946090134',
  'b9e09e33386178a9254c48f516a17321a282fba02d4b77bce690be8563ee3122',
  '10c0eec61907cef40126df0126ff8d0605643116f62aaa6b8cc0b2839ed4af1e',
  '49453ebd0c7871ff489ffc45714ef15cdd027053bcf94c4a64a220d473b7a10a',
  'af1e4b9097509e5be5765725c27ae59e0819e64649aee556c72d773b08ea500a',
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
];

// Faithful trimmed shape of the real capabilities.json response.
Map<String, dynamic> chainsterV1CapabilitiesJson() => {
      'success': true,
      'contract': SaplingRpcCapabilities.v1ContractId,
      'server_version': 'ElectrumX 1.19.0',
      'pivx_core_version': 'PIVX Core:5.6.1',
      'network': 'mainnet',
      'sapling_activation_height': SaplingActivation.mainnet,
      'max_block_range': 100,
      'features': {
        'global_output_positions': true,
        'block_hashes': true,
        'structured_errors': true,
        'canonical_witnesses': true,
      },
      'release_contract_ready': true,
      'index_status': {
        'ready': true,
        'state': 'ready',
        'db_height': 5493846,
        'daemon_height': 5493846,
        'lag': 0,
        'retryable': false,
      },
      'hex_byte_order': 'display',
      'consensus_anchors': true,
      'range_error_types': [
        'invalid_range',
        'daemon_error',
        'backend_timeout',
        'index_not_ready',
        'missing_block',
        'index_incomplete',
        'index_error',
        'unsupported_method',
        'server_error',
      ],
      'witness_backend':
          '/root/electrumx/contrib/pivx_sapling_witness/target/release/pivx_sapling_witness',
      'methods': [
        'blockchain.sapling.get_block_range',
        'blockchain.sapling.get_best_anchor',
        'blockchain.sapling.get_witness',
        'blockchain.sapling.get_nullifier_status',
        'blockchain.sapling.get_commitment_info',
      ],
    };

void main() {
  group('BestAnchorResult', () {
    test('uses anchor_height instead of chain tip height when present', () {
      final bestAnchor = BestAnchorResult.fromJson({
        'anchor':
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        'height': 5440981,
        'anchor_height': 5440977,
      });

      expect(
          bestAnchor.anchor,
          equals(
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'));
      expect(bestAnchor.height, equals(5440977));
    });
  });

  group('SaplingRpcCapabilities', () {
    test('classifies the complete v1 release contract as release ready', () {
      final capabilities =
          SaplingRpcCapabilities.fromJson(v1CapabilitiesJson());

      expect(capabilities.supportsV1ReleaseContract, isTrue);
      expect(capabilities.advertisesV1Contract, isTrue);
      expect(capabilities.supportsBlockRange, isTrue);
      expect(capabilities.supportsGlobalOutputPositions, isTrue);
      expect(capabilities.supportsBestAnchor, isTrue);
      expect(capabilities.supportsWitness, isTrue);
      expect(capabilities.supportsBlockHashes, isTrue);
      expect(capabilities.supportsStructuredErrors, isTrue);
    });

    test('does not classify partial v1 metadata as release ready', () {
      final capabilities = SaplingRpcCapabilities.fromJson(v1CapabilitiesJson(
        methods: [
          'blockchain.sapling.get_block_range',
          'blockchain.sapling.get_witness',
        ],
        features: {
          'global_output_positions': true,
          'block_hashes': true,
          'structured_errors': true,
        },
      ));

      expect(capabilities.advertisesV1Contract, isTrue);
      expect(capabilities.supportsV1ReleaseContract, isFalse);
    });

    test('marks legacy fallback as compatibility only', () {
      final capabilities = SaplingRpcCapabilities.legacyBlockRangeOnly();

      expect(capabilities.supportsBlockRange, isTrue);
      expect(capabilities.isLegacyBlockRangeOnly, isTrue);
      expect(capabilities.supportsV1ReleaseContract, isFalse);
    });

    test('detects active-height index via method, flag, or neither', () {
      final viaMethod = SaplingRpcCapabilities.fromJson(v1CapabilitiesJson(
        methods: [
          'blockchain.sapling.get_block_range',
          'blockchain.sapling.get_active_heights',
        ],
      ));
      expect(viaMethod.supportsActiveHeights, isTrue);

      final viaFlag = SaplingRpcCapabilities.fromJson(v1CapabilitiesJson(
        features: {
          'supports_active_height_index': true,
          'active_heights_max_limit': 50000,
        },
      ));
      expect(viaFlag.supportsActiveHeights, isTrue);
      expect(viaFlag.activeHeightsMaxLimit, 50000);

      final absent = SaplingRpcCapabilities.fromJson(v1CapabilitiesJson());
      expect(absent.supportsActiveHeights, isFalse);
    });
  });

  group('PIVXSaplingElectrumX probeCapabilities', () {
    test('accepts a complete v1 release contract', () async {
      final client = FakeElectrumClient([
        v1CapabilitiesJson(),
        bestAnchorJson(),
        nullifierUnspentJson(),
        commitmentMissingJson(),
      ]);
      final sapling = PIVXSaplingElectrumX(electrumClient: client);

      final capabilities = await sapling.probeCapabilities();

      expect(capabilities.supportsV1ReleaseContract, isTrue);
      expect(client.calledMethods, [
        'blockchain.sapling.capabilities',
        'blockchain.sapling.get_best_anchor',
        'blockchain.sapling.get_nullifier_status',
        'blockchain.sapling.get_commitment_info',
      ]);
    });

    test('rejects an incomplete advertised v1 release contract', () async {
      final client = FakeElectrumClient([
        v1CapabilitiesJson(
          methods: ['blockchain.sapling.get_block_range'],
        )
      ]);
      final sapling = PIVXSaplingElectrumX(electrumClient: client);

      await expectLater(
        sapling.probeCapabilities(),
        throwsA(isA<SaplingRpcException>()),
      );
    });

    test('rejects advertised v1 when live best-anchor helper fails', () async {
      final client = FakeElectrumClient([
        v1CapabilitiesJson(),
        FakeRpcError('internal server error'),
      ]);
      final sapling = PIVXSaplingElectrumX(electrumClient: client);

      await expectLater(
        sapling.probeCapabilities(),
        throwsA(
          isA<SaplingRpcException>().having(
            (error) => error.message,
            'message',
            contains('live release method validation failed'),
          ),
        ),
      );
      expect(client.calledMethods, [
        'blockchain.sapling.capabilities',
        'blockchain.sapling.get_best_anchor',
      ]);
    });

    test('falls back to legacy block-range compatibility only', () async {
      final client = FakeElectrumClient([
        Exception('unknown method'),
        Exception('method not found'),
        <Map<String, dynamic>>[],
      ]);
      final sapling = PIVXSaplingElectrumX(electrumClient: client);

      final capabilities = await sapling.probeCapabilities();

      expect(capabilities.isLegacyBlockRangeOnly, isTrue);
      expect(capabilities.supportsBlockRange, isTrue);
      expect(capabilities.supportsV1ReleaseContract, isFalse);
      expect(client.calls, equals(3));
    });

    test('tries the legacy capability alias after primary server error',
        () async {
      final client = FakeElectrumClient([
        FakeRpcError('internal server error'),
        v1CapabilitiesJson(),
        bestAnchorJson(),
        nullifierUnspentJson(),
        commitmentMissingJson(),
      ]);
      final sapling = PIVXSaplingElectrumX(electrumClient: client);

      final capabilities = await sapling.probeCapabilities();

      expect(capabilities.supportsV1ReleaseContract, isTrue);
      expect(client.calledMethods, [
        'blockchain.sapling.capabilities',
        'blockchain.sapling.get_capabilities',
        'blockchain.sapling.get_best_anchor',
        'blockchain.sapling.get_nullifier_status',
        'blockchain.sapling.get_commitment_info',
      ]);
    });

    test('does not hide non-capability server errors behind fallbacks',
        () async {
      final client = FakeElectrumClient([
        FakeRpcError('internal server error'),
      ]);
      final sapling = PIVXSaplingElectrumX(electrumClient: client);

      expect(
        sapling.getBlockRange(2700500, endHeight: 2700500),
        throwsA(isA<SaplingRpcException>()),
      );
      expect(client.calls, equals(1));
    });

    test('retries then rejects a persistently malformed null response',
        () async {
      final client = FakeElectrumClient([null, null, null]);
      final sapling = PIVXSaplingElectrumX(electrumClient: client);

      await expectLater(
        sapling.probeCapabilities(),
        throwsA(isA<SaplingRpcException>()),
      );
      expect(client.calls, equals(3)); // one probe per retry attempt
    });

    test('retries a transient incomplete capabilities payload', () async {
      // First probe comes back without get_block_range (a reconnect blip); the
      // retry gets the real caps. A blip must not read as an unsupported node.
      final client = FakeElectrumClient([
        {'methods': <String>[]},
        v1CapabilitiesJson(),
        bestAnchorJson(),
        nullifierUnspentJson(),
        commitmentMissingJson(),
      ]);
      final sapling = PIVXSaplingElectrumX(electrumClient: client);

      final capabilities = await sapling.probeCapabilities();

      expect(capabilities.supportsBlockRange, isTrue);
      expect(capabilities.supportsV1ReleaseContract, isTrue);
    });
  });

  group('PIVXSaplingElectrumX getBlockRange', () {
    test('accepts complete empty v1 envelopes', () async {
      final client = FakeElectrumClient([
        {
          'from_height': 2700500,
          'to_height': 2700599,
          'complete': true,
          'block_hashes': {
            '2700500': 'hash_a',
            '2700501': 'hash_b',
          },
          'blocks': <Map<String, dynamic>>[],
        }
      ]);
      final sapling = PIVXSaplingElectrumX(electrumClient: client);

      final result =
          await sapling.getBlockRangeResult(2700500, endHeight: 2700599);

      expect(result.blocks, isEmpty);
      expect(result.blockHashes[2700500], equals('hash_a'));
      expect(result.blockHashes[2700501], equals('hash_b'));
    });

    test('rejects incomplete v1 envelopes', () async {
      final client = FakeElectrumClient([
        {
          'from_height': 2700500,
          'to_height': 2700599,
          'complete': false,
          'blocks': <Map<String, dynamic>>[],
        }
      ]);
      final sapling = PIVXSaplingElectrumX(electrumClient: client);

      expect(
        sapling.getBlockRange(2700500, endHeight: 2700599),
        throwsA(isA<SaplingRpcException>()),
      );
    });

    test('rejects mismatched v1 envelope ranges', () async {
      final client = FakeElectrumClient([
        {
          'from_height': 2700501,
          'to_height': 2700599,
          'complete': true,
          'blocks': <Map<String, dynamic>>[],
        }
      ]);
      final sapling = PIVXSaplingElectrumX(electrumClient: client);

      expect(
        sapling.getBlockRange(2700500, endHeight: 2700599),
        throwsA(isA<SaplingRpcException>()),
      );
    });

    test('wraps malformed block entries with block-range context', () async {
      final client = FakeElectrumClient([
        {
          'from_height': 2700500,
          'to_height': 2700500,
          'complete': true,
          'blocks': [
            {'height': 2700500}
          ],
        }
      ]);
      final sapling = PIVXSaplingElectrumX(electrumClient: client);

      expect(
        sapling.getBlockRange(2700500, endHeight: 2700500),
        throwsA(
          isA<SaplingRpcException>().having(
            (error) => error.message,
            'message',
            contains('get_block_range returned malformed block data'),
          ),
        ),
      );
    });
  });

  group('PIVXSaplingElectrumX syncBlocks', () {
    test('does not complete a failed range', () async {
      final client = FakeElectrumClient([
        Exception('daemon unavailable'),
        Exception('daemon unavailable'),
        Exception('daemon unavailable'),
      ]);
      final sapling = PIVXSaplingElectrumX(electrumClient: client);
      final completedRanges = <String>[];

      await expectLater(
        sapling.syncBlocks(
          fromHeight: 2700500,
          toHeight: 2700500,
          parallelBatches: 1,
          onBatch: (_) async {},
          onRangeComplete: (rangeStart, rangeEnd, blockHashes) async {
            completedRanges.add('$rangeStart-$rangeEnd');
          },
        ),
        throwsA(isA<SaplingRpcException>()),
      );

      expect(completedRanges, isEmpty);
      expect(client.calls, equals(3));
    });

    test('active-height index scans only active windows and reaches toHeight',
        () async {
      // 4 windows in [2700500,2700899]; only 2 hold Sapling activity.
      final client = FakeElectrumClient([
        {
          'heights': [2700550, 2700720],
          'start': 2700500,
          'end': 2700899,
          'complete': true,
          'db_height': 2700899,
        },
        {
          'from_height': 2700500,
          'to_height': 2700599,
          'complete': true,
          'blocks': <Map<String, dynamic>>[],
        },
        {
          'from_height': 2700700,
          'to_height': 2700799,
          'complete': true,
          'blocks': <Map<String, dynamic>>[],
        },
      ]);
      final sapling = PIVXSaplingElectrumX(
        electrumClient: client,
        capabilities: SaplingRpcCapabilities.fromJson(v1CapabilitiesJson(
          methods: [
            'blockchain.sapling.get_block_range',
            'blockchain.sapling.get_active_heights',
          ],
        )),
      );
      final completedRanges = <String>[];

      await sapling.syncBlocks(
        fromHeight: 2700500,
        toHeight: 2700899,
        parallelBatches: 1,
        onBatch: (_) async {},
        onRangeComplete: (rangeStart, rangeEnd, _) async {
          completedRanges.add('$rangeStart-$rangeEnd');
        },
      );

      // Empty windows [2700600-99] and [2700800-99] are never fetched.
      expect(
        client.calledMethods
            .where((m) => m.contains('get_block_range'))
            .length,
        2,
      );
      // Active windows scanned in order, then cursor advanced to toHeight.
      expect(completedRanges, [
        '2700500-2700599',
        '2700700-2700799',
        '2700500-2700899',
      ]);
    });

    test('ends the pass instead of hanging when a range stalls', () {
      fakeAsync((async) {
        // Node keeps the socket alive but never answers get_block_range.
        final client = FakeElectrumClient([const FakeHang()]);
        final sapling = PIVXSaplingElectrumX(electrumClient: client);
        final completedRanges = <String>[];
        var returned = false;

        sapling
            .syncBlocks(
              fromHeight: 2700500,
              toHeight: 2700500,
              parallelBatches: 1,
              onBatch: (_) async {},
              onRangeComplete: (rangeStart, rangeEnd, blockHashes) async {
                completedRanges.add('$rangeStart-$rangeEnd');
              },
            )
            .then((_) => returned = true);

        // Before the fetch timeout the pass is still waiting on the node.
        async.elapse(const Duration(seconds: 5));
        expect(returned, isFalse);

        // Past the timeout the stall maps to a graceful pass-end, not a hang.
        async.elapse(kSaplingBlockRangeFetchTimeout);
        async.flushMicrotasks();
        expect(returned, isTrue);
        expect(completedRanges, isEmpty);
      });
    });

    test('logs first, checkpoint, and final shield sync ranges only', () {
      expect(
        shouldLogPivxShieldSyncCheckpoint(
          rangeStart: 5440400,
          rangeEnd: 5440499,
          startHeight: 5440400,
          targetHeight: 5451000,
        ),
        isTrue,
      );
      expect(
        shouldLogPivxShieldSyncCheckpoint(
          rangeStart: 5440500,
          rangeEnd: 5440599,
          startHeight: 5440400,
          targetHeight: 5451000,
        ),
        isFalse,
      );
      expect(
        shouldLogPivxShieldSyncCheckpoint(
          rangeStart: 5449901,
          rangeEnd: 5450000,
          startHeight: 5440400,
          targetHeight: 5451000,
        ),
        isTrue,
      );
      expect(
        shouldLogPivxShieldSyncCheckpoint(
          rangeStart: 5451000,
          rangeEnd: 5451000,
          startHeight: 5440400,
          targetHeight: 5451000,
        ),
        isTrue,
      );
    });
  });

  group('PIVXSaplingElectrumX getAnchorBoundWitness', () {
    const anchorHex =
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    const commitmentHex =
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

    test('accepts witness bound to selected anchor and commitment', () async {
      final client = FakeElectrumClient([
        {
          'position': 42,
          'path': [
            '0100000000000000000000000000000000000000000000000000000000000000'
          ],
          'anchor': anchorHex,
          'anchor_height': 2700600,
          'commitment': commitmentHex,
        }
      ]);
      final verifier = RecordingWitnessVerifier();
      final sapling = PIVXSaplingElectrumX(
        electrumClient: client,
        witnessRootVerifier: verifier.call,
      );

      final witness = await sapling.getAnchorBoundWitness(
        commitment: commitmentHex,
        anchor: BestAnchorResult(anchor: anchorHex, height: 2700600),
      );

      expect(witness.position, equals(42));
      expect(witness.anchor, equals(anchorHex));
      expect(witness.anchorHeight, equals(2700600));
      expect(witness.commitment, equals(commitmentHex));
      expect(witness.source, equals(SaplingWitnessResult.sourceAnchorBound));
      expect(client.calledMethods, contains('blockchain.sapling.get_witness'));
      expect(client.calledParams.single, equals([commitmentHex, anchorHex]));

      // Root verification must have run against the selected spend anchor
      // with the full padded witness path.
      final call = verifier.calls.single;
      expect(call['cmuHex'], equals(commitmentHex));
      expect(call['anchorHex'], equals(anchorHex));
      expect(call['position'], equals(42));
      expect(
        (call['witnessHex'] as String).length,
        equals(SaplingWitnessResult.saplingTreeDepth *
            SaplingWitnessResult.saplingNodeHexLength),
      );
    });

    test('falls back to commitment-only witness with server-selected anchor',
        () async {
      final client = FakeElectrumClient([
        FakeRpcError('witness not found for 44757'),
        {
          'position': 44757,
          'path': [
            '0100000000000000000000000000000000000000000000000000000000000000'
          ],
          'anchor':
              'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
          'anchor_height': 2700598,
          'commitment': commitmentHex,
        }
      ]);
      final verifier = RecordingWitnessVerifier();
      final sapling = PIVXSaplingElectrumX(
        electrumClient: client,
        witnessRootVerifier: verifier.call,
      );

      final witness = await sapling.getAnchorBoundWitness(
        commitment: commitmentHex,
        anchor: BestAnchorResult(anchor: anchorHex, height: 2700600),
        notePosition: 44757,
      );

      expect(witness.position, equals(44757));
      expect(
          witness.anchor,
          equals(
              'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd'));
      expect(witness.anchorHeight, equals(2700598));
      expect(witness.source,
          equals(SaplingWitnessResult.sourceCommitmentOnlyFallback));
      expect(client.calledParams, [
        [commitmentHex, anchorHex],
        [commitmentHex],
      ]);

      // The commitment-only fallback spends against the server-selected
      // witness anchor, so the root must be verified against that anchor.
      final call = verifier.calls.single;
      expect(
          call['anchorHex'],
          equals(
              'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd'));
      expect(call['cmuHex'], equals(commitmentHex));
      expect(call['position'], equals(44757));
    });

    test('sanitizes failed real-note witness attempt diagnostics', () async {
      final client = FakeElectrumClient([
        FakeRpcError(
            'canonical_witness_unavailable for $commitmentHex at $anchorHex'),
        FakeRpcError('commitment not found: $commitmentHex'),
        FakeRpcError('method not found for anchor $anchorHex'),
      ]);
      final sapling = PIVXSaplingElectrumX(
        electrumClient: client,
        witnessRootVerifier: RecordingWitnessVerifier().call,
      );

      await expectLater(
        sapling.getAnchorBoundWitness(
          commitment: commitmentHex,
          anchor: BestAnchorResult(anchor: anchorHex, height: 2700600),
        ),
        throwsA(
          isA<SaplingRpcException>()
              .having(
                (error) => error.message,
                'message',
                contains('commitment_anchor:canonical_witness_unavailable'),
              )
              .having(
                (error) => error.message,
                'message',
                contains('commitment_only:canonical_witness_unavailable'),
              )
              .having(
                (error) => error.message,
                'message',
                isNot(contains(commitmentHex)),
              )
              .having(
                (error) => error.message,
                'message',
                isNot(contains(anchorHex)),
              ),
        ),
      );
      expect(client.calledParams, [
        [commitmentHex, anchorHex],
        [commitmentHex],
        [commitmentHex],
      ]);
    });

    test('normalizes map-shaped witness path elements', () async {
      final client = FakeElectrumClient([
        {
          'position': 42,
          'path': [
            {
              'hash':
                  '0100000000000000000000000000000000000000000000000000000000000000'
            }
          ],
          'anchor': anchorHex,
          'anchor_height': 2700600,
          'commitment': commitmentHex,
        }
      ]);
      final sapling = PIVXSaplingElectrumX(
        electrumClient: client,
        witnessRootVerifier: RecordingWitnessVerifier().call,
      );

      final witness = await sapling.getAnchorBoundWitness(
        commitment: commitmentHex,
        anchor: BestAnchorResult(anchor: anchorHex, height: 2700600),
      );

      expect(witness.path, hasLength(SaplingWitnessResult.saplingTreeDepth));
      expect(witness.path.first,
          '0100000000000000000000000000000000000000000000000000000000000000');
      expect(witness.path[1],
          '817de36ab2d57feb077634bca77819c8e0bd298c04f6fed0e6a83cc1356ca155');
    });

    test('corrects big-endian witness path elements', () async {
      final client = FakeElectrumClient([
        {
          'position': 42,
          'path': [
            '0000000000000000000000000000000000000000000000000000000000000080'
          ],
          'anchor': anchorHex,
          'anchor_height': 2700600,
          'commitment': commitmentHex,
        }
      ]);
      final sapling = PIVXSaplingElectrumX(
        electrumClient: client,
        witnessRootVerifier: RecordingWitnessVerifier().call,
      );

      final witness = await sapling.getAnchorBoundWitness(
        commitment: commitmentHex,
        anchor: BestAnchorResult(anchor: anchorHex, height: 2700600),
      );

      expect(witness.path.first,
          '8000000000000000000000000000000000000000000000000000000000000000');
      expect(witness.path, hasLength(SaplingWitnessResult.saplingTreeDepth));
    });

    test('rejects commitment-only witness for a different commitment',
        () async {
      final client = FakeElectrumClient([
        FakeRpcError('witness not found for anchor'),
        {
          'position': 42,
          'path': [
            '0100000000000000000000000000000000000000000000000000000000000000'
          ],
          'anchor': anchorHex,
          'anchor_height': 2700600,
          'commitment':
              'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
        }
      ]);
      final sapling = PIVXSaplingElectrumX(
        electrumClient: client,
        witnessRootVerifier: RecordingWitnessVerifier().call,
      );

      expect(
        sapling.getAnchorBoundWitness(
          commitment: commitmentHex,
          anchor: BestAnchorResult(anchor: anchorHex, height: 2700600),
          notePosition: 42,
        ),
        throwsA(isA<SaplingRpcException>()),
      );
    });

    test('rejects witness for a different anchor root', () async {
      final client = FakeElectrumClient([
        {
          'position': 42,
          'path': [
            '0100000000000000000000000000000000000000000000000000000000000000'
          ],
          'anchor':
              'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
          'anchor_height': 2700600,
          'commitment': commitmentHex,
        },
        FakeRpcError('witness not found'),
      ]);
      final sapling = PIVXSaplingElectrumX(
        electrumClient: client,
        witnessRootVerifier: RecordingWitnessVerifier().call,
      );

      expect(
        sapling.getAnchorBoundWitness(
          commitment: commitmentHex,
          anchor: BestAnchorResult(anchor: anchorHex, height: 2700600),
        ),
        throwsA(isA<SaplingRpcException>()),
      );
    });

    test('rejects witness without anchor metadata', () async {
      final client = FakeElectrumClient([
        {
          'position': 42,
          'path': [
            '0100000000000000000000000000000000000000000000000000000000000000'
          ],
          'commitment': commitmentHex,
        }
      ]);
      final sapling = PIVXSaplingElectrumX(
        electrumClient: client,
        witnessRootVerifier: RecordingWitnessVerifier().call,
      );

      expect(
        sapling.getAnchorBoundWitness(
          commitment: commitmentHex,
          anchor: BestAnchorResult(anchor: anchorHex, height: 2700600),
        ),
        throwsA(isA<SaplingRpcException>()),
      );
    });

    test('rejects witness for a different commitment', () async {
      final client = FakeElectrumClient([
        {
          'position': 42,
          'path': [
            '0100000000000000000000000000000000000000000000000000000000000000'
          ],
          'anchor': anchorHex,
          'anchor_height': 2700600,
          'commitment':
              'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
        }
      ]);
      final sapling = PIVXSaplingElectrumX(
        electrumClient: client,
        witnessRootVerifier: RecordingWitnessVerifier().call,
      );

      expect(
        sapling.getAnchorBoundWitness(
          commitment: commitmentHex,
          anchor: BestAnchorResult(anchor: anchorHex, height: 2700600),
        ),
        throwsA(isA<SaplingRpcException>()),
      );
    });

    Map<String, dynamic> witnessJson({String? anchor}) => {
          'position': 42,
          'path': [
            '0100000000000000000000000000000000000000000000000000000000000000'
          ],
          'anchor': anchor ?? anchorHex,
          'anchor_height': 2700600,
          'commitment': commitmentHex,
        };

    test(
        'rejects tampered witness with witness_root_mismatch on both attempt paths',
        () async {
      // Valid-shaped responses for the commitment_anchor attempt and both
      // commitment_only retries; only the local root recomputation fails.
      final client = FakeElectrumClient([
        witnessJson(),
        witnessJson(),
        witnessJson(),
      ]);
      final verifier = RecordingWitnessVerifier(result: false);
      final sapling = PIVXSaplingElectrumX(
        electrumClient: client,
        witnessRootVerifier: verifier.call,
      );

      await expectLater(
        sapling.getAnchorBoundWitness(
          commitment: commitmentHex,
          anchor: BestAnchorResult(anchor: anchorHex, height: 2700600),
        ),
        throwsA(
          isA<SaplingRpcException>()
              .having(
                (error) => error.message,
                'message',
                contains('commitment_anchor:witness_root_mismatch'),
              )
              .having(
                (error) => error.message,
                'message',
                contains('commitment_only:witness_root_mismatch'),
              ),
        ),
      );
      // Verification ran on every attempt: 1 anchor-bound + 2 fallback retries.
      expect(verifier.calls, hasLength(3));
    });

    test('rejects witness when root verification itself errors (fail closed)',
        () async {
      final client = FakeElectrumClient([
        witnessJson(),
        witnessJson(),
        witnessJson(),
      ]);
      final verifier = RecordingWitnessVerifier(
        error: StateError('Witness root verification error: native failure'),
      );
      final sapling = PIVXSaplingElectrumX(
        electrumClient: client,
        witnessRootVerifier: verifier.call,
      );

      await expectLater(
        sapling.getAnchorBoundWitness(
          commitment: commitmentHex,
          anchor: BestAnchorResult(anchor: anchorHex, height: 2700600),
        ),
        throwsA(
          isA<SaplingRpcException>().having(
            (error) => error.message,
            'message',
            contains('witness_root_mismatch'),
          ),
        ),
      );
      expect(verifier.calls, hasLength(3));
    });

    test('verifies the root before accepting a commitment-only fallback',
        () async {
      final serverAnchor =
          'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
      final client = FakeElectrumClient([
        FakeRpcError('witness not found'),
        witnessJson(anchor: serverAnchor),
        witnessJson(anchor: serverAnchor),
      ]);
      final verifier = RecordingWitnessVerifier(result: false);
      final sapling = PIVXSaplingElectrumX(
        electrumClient: client,
        witnessRootVerifier: verifier.call,
      );

      await expectLater(
        sapling.getAnchorBoundWitness(
          commitment: commitmentHex,
          anchor: BestAnchorResult(anchor: anchorHex, height: 2700600),
        ),
        throwsA(
          isA<SaplingRpcException>().having(
            (error) => error.message,
            'message',
            contains('commitment_only:witness_root_mismatch'),
          ),
        ),
      );
      // Both fallback retries verified against the server-selected anchor.
      expect(verifier.calls, hasLength(2));
      for (final call in verifier.calls) {
        expect(call['anchorHex'], equals(serverAnchor));
      }
    });
  });

  group('v1 display byte order', () {
    test('parses hex_byte_order and canonical witness metadata (fixture)', () {
      final capabilities =
          SaplingRpcCapabilities.fromJson(chainsterV1CapabilitiesJson());

      expect(capabilities.hexByteOrder, equals('display'));
      expect(capabilities.usesDisplayByteOrder, isTrue);
      expect(capabilities.canonicalWitnesses, isTrue);
      expect(capabilities.consensusAnchors, isTrue);
      expect(capabilities.indexStatus?['ready'], isTrue);
      expect(capabilities.rangeErrorTypes, contains('index_incomplete'));
    });

    test('canonicalWitnesses requires both feature flag and witness backend',
        () {
      final noBackend = SaplingRpcCapabilities.fromJson(
        chainsterV1CapabilitiesJson()..remove('witness_backend'),
      );
      expect(noBackend.canonicalWitnesses, isFalse);

      final json = chainsterV1CapabilitiesJson();
      (json['features'] as Map)['canonical_witnesses'] = false;
      final noFeature = SaplingRpcCapabilities.fromJson(json);
      expect(noFeature.canonicalWitnesses, isFalse);
    });

    test('non-display order default leaves usesDisplayByteOrder false', () {
      final capabilities = SaplingRpcCapabilities.fromJson(v1CapabilitiesJson());
      expect(capabilities.usesDisplayByteOrder, isFalse);
      expect(capabilities.hexByteOrder, isNull);
    });

    test('reverseSaplingHexBytes maps display cmu to serialization and back',
        () {
      expect(reverseSaplingHexBytes(chainsterCmuDisplay),
          equals(chainsterCmuSerialization));
      expect(reverseSaplingHexBytes(chainsterAnchorDisplay),
          equals(chainsterAnchorSerialization));
      // Round-trips.
      expect(
          reverseSaplingHexBytes(reverseSaplingHexBytes(chainsterCmuDisplay)),
          equals(chainsterCmuDisplay));
    });

    test(
        'getAnchorBoundWitness feeds serialization-order cmu/anchor to the '
        'verifier on a display node', () async {
      final client = FakeElectrumClient([
        {
          'position': 0,
          'path': chainsterWitnessPath,
          'anchor': chainsterAnchorDisplay,
          'anchor_height': 5493519,
          'commitment': chainsterCmuDisplay,
        }
      ]);
      final verifier = RecordingWitnessVerifier();
      final sapling = PIVXSaplingElectrumX(
        electrumClient: client,
        witnessRootVerifier: verifier.call,
        capabilities: const SaplingRpcCapabilities(
          supportsBlockRange: true,
          supportsGlobalOutputPositions: true,
          supportsBestAnchor: true,
          supportsWitness: true,
          canonicalWitnesses: true,
          hexByteOrder: 'display',
        ),
      );

      final witness = await sapling.getAnchorBoundWitness(
        commitment: chainsterCmuDisplay,
        anchor: BestAnchorResult(
            anchor: chainsterAnchorDisplay, height: 5493519),
        notePosition: 0,
      );

      // Request + response validation stay in display order (server contract).
      expect(client.calledParams.single,
          equals([chainsterCmuDisplay, chainsterAnchorDisplay]));
      expect(witness.commitment, equals(chainsterCmuDisplay));
      expect(witness.anchor, equals(chainsterAnchorDisplay));

      // The crypto verifier must receive the reversed (serialization) bytes,
      // and the path must be handed over untouched.
      final call = verifier.calls.single;
      expect(call['cmuHex'], equals(chainsterCmuSerialization));
      expect(call['anchorHex'], equals(chainsterAnchorSerialization));
      expect(call['witnessHex'], equals(chainsterWitnessPath.join()));
      expect(call['position'], equals(0));
    });

    test('non-display node passes cmu/anchor through unreversed', () async {
      final client = FakeElectrumClient([
        {
          'position': 0,
          'path': chainsterWitnessPath,
          'anchor': chainsterAnchorDisplay,
          'anchor_height': 5493519,
          'commitment': chainsterCmuDisplay,
        }
      ]);
      final verifier = RecordingWitnessVerifier();
      // No capabilities -> default (non-display), preserving legacy behavior.
      final sapling = PIVXSaplingElectrumX(
        electrumClient: client,
        witnessRootVerifier: verifier.call,
      );

      await sapling.getAnchorBoundWitness(
        commitment: chainsterCmuDisplay,
        anchor: BestAnchorResult(
            anchor: chainsterAnchorDisplay, height: 5493519),
        notePosition: 0,
      );

      final call = verifier.calls.single;
      expect(call['cmuHex'], equals(chainsterCmuDisplay));
      expect(call['anchorHex'], equals(chainsterAnchorDisplay));
    });
  });

  group('SaplingTreeState', () {
    test('parses the real v1 tree_state fixture without nullifier_count', () {
      final treeState = SaplingTreeState.fromJson({
        'success': true,
        'contract': SaplingRpcCapabilities.v1ContractId,
        'height': 2701500,
        'block_hash':
            'bead1714c264a73c113ab507f83dab12e7e4b17ab60ea01552ac1bf30783aec6',
        'anchor': chainsterAnchorDisplay,
        'root': chainsterAnchorDisplay,
        'latest_anchor': chainsterAnchorDisplay,
        'anchor_first_height': 2701424,
        'tree_size': 118,
        'commitment_count': 118,
        'indexed_height': 5493846,
        'sapling_activation_height': 2700500,
      });

      expect(treeState.anchor, equals(chainsterAnchorDisplay));
      expect(treeState.root, equals(chainsterAnchorDisplay));
      expect(treeState.treeSize, equals(118));
      expect(treeState.commitmentCount, equals(118));
      expect(treeState.indexedHeight, equals(5493846));
      expect(treeState.anchorFirstHeight, equals(2701424));
      expect(treeState.saplingActivationHeight, equals(2700500));
      expect(treeState.height, equals(2701500));
    });
  });

  group('PIVXSaplingElectrumX getBlockRange v1 error envelopes', () {
    test('classifies index_incomplete as retryable', () async {
      final client = FakeElectrumClient([
        {
          'success': false,
          'complete': false,
          'start_height': 2700500,
          'end_height': 2700599,
          'error': {'type': 'index_incomplete', 'message': 'not indexed yet'},
        }
      ]);
      final sapling = PIVXSaplingElectrumX(electrumClient: client);

      await expectLater(
        sapling.getBlockRangeResult(2700500, endHeight: 2700599),
        throwsA(isA<SaplingRetryableRangeException>()),
      );
    });

    test('treats a hard error type as a non-retryable failure', () async {
      final client = FakeElectrumClient([
        {
          'success': false,
          'complete': false,
          'error': {'type': 'daemon_error'},
        }
      ]);
      final sapling = PIVXSaplingElectrumX(electrumClient: client);

      await expectLater(
        sapling.getBlockRangeResult(2700500, endHeight: 2700599),
        throwsA(allOf(
          isA<SaplingRpcException>(),
          isNot(isA<SaplingRetryableRangeException>()),
        )),
      );
    });

    test('treats index_not_ready as a retryable range error', () async {
      final client = FakeElectrumClient([
        {
          'success': false,
          'error': {'type': 'index_not_ready', 'indexed_height': 99},
        },
      ]);
      final sapling = PIVXSaplingElectrumX(electrumClient: client);

      await expectLater(
        sapling.getBlockRangeResult(100, endHeight: 199),
        throwsA(isA<SaplingRetryableRangeException>()),
      );
    });
  });

  group('syncBlocks ceiling and cancellation', () {
    test('processes the prefix and stops at the indexed ceiling without failing',
        () async {
      // First batch is served; the second is above the node's indexed ceiling.
      final client = FakeElectrumClient([
        {
          'from_height': 100,
          'to_height': 100,
          'complete': true,
          'blocks': <Map<String, dynamic>>[],
        },
        {
          'success': false,
          'error': {'type': 'index_incomplete', 'indexed_height': 100},
        },
      ]);
      final sapling = PIVXSaplingElectrumX(electrumClient: client);

      final ranges = <String>[];
      await sapling.syncBlocks(
        fromHeight: 100,
        toHeight: 101,
        batchSize: 1,
        parallelBatches: 1,
        onBatch: (_) async {},
        onRangeComplete: (start, end, _) async => ranges.add('$start-$end'),
      );

      // Below-ceiling range completed; the pass stopped at the ceiling instead
      // of throwing and repolling.
      expect(ranges, ['100-100']);
    });

    test('stops issuing requests once shouldCancel returns true', () async {
      final client = FakeElectrumClient([
        {
          'from_height': 100,
          'to_height': 100,
          'complete': true,
          'blocks': <Map<String, dynamic>>[],
        },
        // A second response is intentionally not queued: a second request would
        // throw, proving cancellation prevented it.
      ]);
      final sapling = PIVXSaplingElectrumX(electrumClient: client);

      var rounds = 0;
      await sapling.syncBlocks(
        fromHeight: 100,
        toHeight: 101,
        batchSize: 1,
        parallelBatches: 1,
        onBatch: (_) async {},
        onRangeComplete: (_, __, ___) async => rounds++,
        shouldCancel: () => rounds >= 1,
      );

      expect(rounds, 1);
      expect(client.calls, 1);
    });
  });

  group('SaplingRpcCapabilities index status', () {
    test('exposes db_height and daemon_height', () {
      final capabilities = SaplingRpcCapabilities.fromJson({
        'index_status': {
          'db_height': 3100000,
          'daemon_height': 3100003,
          'lag': 3,
        },
      });

      expect(capabilities.indexHeight, 3100000);
      expect(capabilities.daemonHeight, 3100003);
    });

    test('reports null heights when index_status is absent', () {
      final capabilities = SaplingRpcCapabilities.fromJson(const {});

      expect(capabilities.indexHeight, isNull);
      expect(capabilities.daemonHeight, isNull);
    });
  });

  group('computeActiveWindows', () {
    test('collapses heights in a window; aligned, ascending, deduped', () {
      final windows = PIVXSaplingElectrumX.computeActiveWindows(
        1000,
        1500,
        100,
        [1005, 1042, 1099, 1310, 1300], // unordered; each trio shares a window
      );
      expect(windows, [
        [1000, 1099],
        [1300, 1399],
      ]);
    });

    test('clamps the final window to toHeight and drops out-of-range heights',
        () {
      final windows = PIVXSaplingElectrumX.computeActiveWindows(
        2000,
        2050,
        100,
        [1999, 2010, 2075], // 1999 below range, 2075 above range
      );
      expect(windows, [
        [2000, 2050], // clamped to toHeight, not 2099
      ]);
    });

    test('no active heights yields no windows', () {
      expect(
        PIVXSaplingElectrumX.computeActiveWindows(1000, 2000, 100, const []),
        isEmpty,
      );
    });
  });
}
