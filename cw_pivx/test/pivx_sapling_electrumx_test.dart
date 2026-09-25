import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cw_pivx/src/sapling/pivx_sapling_electrumx.dart';
import 'package:cw_pivx/src/sapling/sapling_constants.dart';
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
      'height': 2701004,
      'anchor_height': 2701000,
    };

// Raw `result` payloads captured from electrum02.chainster.org:50002.
Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>;

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
      'sapling_activation_height':
          PivxSaplingNetwork.mainnetSaplingActivationHeight,
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

    test('parses the captured chainster v1 capabilities', () {
      final caps = SaplingRpcCapabilities.fromJson(fixture('v1_capabilities'));

      expect(caps.supportsV1ReleaseContract, isTrue);
      expect(caps.usesDisplayByteOrder, isTrue);
      expect(caps.canonicalWitnesses, isTrue);
      expect(caps.supportsActiveHeights, isTrue);
      expect(caps.activeHeightsMaxLimit, 50000);
      expect(caps.supportsConsistentDbHeight, isTrue);
      expect(caps.supportsMempool, isTrue);
      expect(caps.supportsMempoolSubscribe, isTrue);
      expect(caps.activationHeight,
          PivxSaplingNetwork.mainnetSaplingActivationHeight);
      expect(caps.indexHeight, 5598158);
      expect(caps.daemonHeight, 5598158);
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

    test('a nullifier reply without a spent flag is an error, not unspent', () {
      expect(() => NullifierStatus.fromJson(<String, dynamic>{}),
          throwsA(isA<SaplingRpcException>()));
      expect(NullifierStatus.fromJson({'spent': true}).spent, isTrue);
    });

    test('a malformed or capped active-heights page falls back to a full scan',
        () async {
      PIVXSaplingElectrumX withReply(Map<String, dynamic> reply) =>
          PIVXSaplingElectrumX(
            electrumClient: FakeElectrumClient([reply]),
            capabilities: SaplingRpcCapabilities.fromJson(v1CapabilitiesJson(
              methods: [
                'blockchain.sapling.get_block_range',
                'blockchain.sapling.get_active_heights',
              ],
            )),
          );
      // No heights list: must not read as "no activity".
      expect(
          await withReply({'start': 100, 'end': 199, 'complete': true})
              .fetchActiveHeights(100, 199),
          isNull);
      // Starts past the cursor: block 100 would never be revisited.
      expect(
          await withReply({
            'heights': <int>[],
            'start': 101,
            'end': 199,
            'complete': true,
          }).fetchActiveHeights(100, 199),
          isNull);
      // complete but capped below toHeight: the tail was never listed.
      expect(
          await withReply({
            'heights': <int>[],
            'start': 100,
            'end': 150,
            'complete': true,
          }).fetchActiveHeights(100, 199),
          isNull);
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

    test('rejects a node without the v1 contract', () async {
      final client = FakeElectrumClient([
        v1CapabilitiesJson(contract: 'legacy.block_range'),
      ]);
      final sapling = PIVXSaplingElectrumX(electrumClient: client);

      await expectLater(
        sapling.probeCapabilities(),
        throwsA(isA<SaplingRpcException>()),
      );
      expect(client.calls, equals(1));
    });
  });

  group('PIVXSaplingElectrumX getBlockRange', () {
    test('accepts complete empty v1 envelopes', () async {
      final client = FakeElectrumClient([
        {
          'start_height': 2700500,
          'end_height': 2700599,
          'complete': true,
          'block_hashes': [
            {'height': 2700500, 'block_hash': 'hash_a'},
            {'height': 2700501, 'block_hash': 'hash_b'},
          ],
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

    test('parses the captured chainster v1 block range', () async {
      final client =
          FakeElectrumClient([fixture('v1_block_range_5597590_5597599')]);
      final sapling = PIVXSaplingElectrumX(electrumClient: client);

      final result =
          await sapling.getBlockRangeResult(5597590, endHeight: 5597599);

      expect(result.blockHashes, hasLength(10));
      // v1 returns every height, empty ones with no txs.
      expect(result.blocks, hasLength(10));
      final block = result.blocks.singleWhere((b) => b.txs.isNotEmpty);
      expect(block.height, 5597595);
      final output = block.txs.single.outputs.single;
      expect(output.globalPosition, 46856);
      expect(output.cmu,
          '015f4fd097563002d9ea37e85b0d70b25680b084a44fd417c3cadfc2c92a8c6c');
      expect(output.ciphertextBytes, hasLength(580));
    });

    test('rejects incomplete v1 envelopes', () async {
      final client = FakeElectrumClient([
        {
          'start_height': 2700500,
          'end_height': 2700599,
          'complete': false,
          'blocks': <Map<String, dynamic>>[],
        }
      ]);
      final sapling = PIVXSaplingElectrumX(electrumClient: client);

      expect(
        sapling.getBlockRangeResult(2700500, endHeight: 2700599),
        throwsA(isA<SaplingRpcException>()),
      );
    });

    test('rejects a range reply that states no bounds', () async {
      final client = FakeElectrumClient([
        {'complete': true, 'blocks': <Map<String, dynamic>>[]},
      ]);
      final sapling = PIVXSaplingElectrumX(electrumClient: client);

      // An empty, boundless reply must not advance the cursor over the range.
      expect(
        sapling.getBlockRangeResult(2700500, endHeight: 2700599),
        throwsA(isA<SaplingRpcException>()),
      );
    });

    test('rejects mismatched v1 envelope ranges', () async {
      final client = FakeElectrumClient([
        {
          'start_height': 2700501,
          'end_height': 2700599,
          'complete': true,
          'blocks': <Map<String, dynamic>>[],
        }
      ]);
      final sapling = PIVXSaplingElectrumX(electrumClient: client);

      expect(
        sapling.getBlockRangeResult(2700500, endHeight: 2700599),
        throwsA(isA<SaplingRpcException>()),
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
          'start_height': 2700500,
          'end_height': 2700599,
          'complete': true,
          'blocks': <Map<String, dynamic>>[],
        },
        {
          'start_height': 2700700,
          'end_height': 2700799,
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
        client.calledMethods.where((m) => m.contains('get_block_range')).length,
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

    // The lookup swallows each attempt's error, so assert the reason it logged:
    // any failure (an exhausted fake included) would satisfy a bare type check.
    Matcher rejectedFor(String attemptReason) => throwsA(
        isA<SaplingRpcException>().having(
            (e) => e.toString(), 'attempts', contains(attemptReason)));

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
        rejectedFor('commitment_only:commitment_mismatch'),
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
        rejectedFor('commitment_anchor:anchor_mismatch'),
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
        rejectedFor('commitment_anchor:missing_anchor'),
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
        rejectedFor('commitment_anchor:commitment_mismatch'),
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
        anchor:
            BestAnchorResult(anchor: chainsterAnchorDisplay, height: 5493519),
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

    test('accepts the captured chainster v1 witness', () async {
      final json = fixture('v1_witness_46856');
      final client = FakeElectrumClient([json]);
      final verifier = RecordingWitnessVerifier();
      final sapling = PIVXSaplingElectrumX(
        electrumClient: client,
        witnessRootVerifier: verifier.call,
        capabilities:
            SaplingRpcCapabilities.fromJson(fixture('v1_capabilities')),
      );

      final witness = await sapling.getAnchorBoundWitness(
        commitment: json['commitment'] as String,
        anchor:
            BestAnchorResult(anchor: json['anchor'] as String, height: 5597595),
      );

      expect(witness.position, 46856);
      expect(witness.path, (json['path'] as List).cast<String>());
      expect(verifier.calls.single['cmuHex'],
          reverseSaplingHexBytes(json['commitment'] as String));
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
        anchor:
            BestAnchorResult(anchor: chainsterAnchorDisplay, height: 5493519),
        notePosition: 0,
      );

      final call = verifier.calls.single;
      expect(call['cmuHex'], equals(chainsterCmuDisplay));
      expect(call['anchorHex'], equals(chainsterAnchorDisplay));
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
    test(
        'processes the prefix and stops at the indexed ceiling without failing',
        () async {
      // First batch is served; the second is above the node's indexed ceiling.
      final client = FakeElectrumClient([
        {
          'start_height': 100,
          'end_height': 100,
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
      final reached = await sapling.syncBlocks(
        fromHeight: 100,
        toHeight: 101,
        batchSize: 1,
        parallelBatches: 1,
        onBatch: (_) async {},
        onRangeComplete: (start, end, _) async => ranges.add('$start-$end'),
      );

      // Below-ceiling range completed; the pass stopped at the ceiling instead
      // of throwing and repolling, and says it fell short.
      expect(ranges, ['100-100']);
      expect(reached, isFalse);
    });

    test('halves a window the server rejects as too large', () async {
      Map<String, dynamic> range(int start, int end) => {
            'start_height': start,
            'end_height': end,
            'complete': true,
            'blocks': <Map<String, dynamic>>[],
          };
      // Captured from electrum02 on 5407501-5407600.
      final client = FakeElectrumClient([
        FakeRpcError('response too large (over 2,000,000 bytes'),
        range(100, 149),
        range(150, 199),
      ]);
      final sapling = PIVXSaplingElectrumX(electrumClient: client);

      final ranges = <String>[];
      final reached = await sapling.syncBlocks(
        fromHeight: 100,
        toHeight: 199,
        batchSize: 100,
        parallelBatches: 1,
        onBatch: (_) async {},
        onRangeComplete: (start, end, _) async => ranges.add('$start-$end'),
      );

      expect(ranges, ['100-199']);
      expect(reached, isTrue);
      expect(client.calledParams.skip(1).map((p) => p.take(2).toList()), [
        [100, 149],
        [150, 199],
      ]);
    });

    test('stops issuing requests once shouldCancel returns true', () async {
      final client = FakeElectrumClient([
        {
          'start_height': 100,
          'end_height': 100,
          'complete': true,
          'blocks': <Map<String, dynamic>>[],
        },
        // A second response is intentionally not queued: a second request would
        // throw, proving cancellation prevented it.
      ]);
      final sapling = PIVXSaplingElectrumX(electrumClient: client);

      var rounds = 0;
      final reached = await sapling.syncBlocks(
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
      expect(reached, isFalse);
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
