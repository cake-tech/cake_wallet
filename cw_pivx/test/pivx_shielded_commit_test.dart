import 'dart:io';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/electrum.dart' as electrum;
import 'package:cw_bitcoin/exceptions.dart';
import 'package:cw_pivx/src/pending_pivx_shielded_transaction.dart';
import 'package:cw_pivx/src/sapling/sapling_factories.dart';
import 'package:cw_pivx/src/sapling/sapling_note_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

class _FakeBroadcastElectrumClient extends electrum.ElectrumClient {
  _FakeBroadcastElectrumClient({
    required this.broadcastResponse,
    this.throwOnBroadcast = false,
    this.sendsCall = true,
    this.errorMessage = 'bad-txns-nullifier-double-spent',
  });

  /// Response to return from broadcast; an empty string simulates a rejected
  /// broadcast (double spend, network error, ...).
  String broadcastResponse;
  final bool throwOnBroadcast;
  final bool sendsCall;
  final String errorMessage;
  int broadcastCalls = 0;

  @override
  Future<String> broadcastTransaction({
    required String transactionRaw,
    BasedUtxoNetwork? network,
    Function(int)? idCallback,
  }) async {
    broadcastCalls++;
    if (sendsCall) idCallback?.call(1);
    if (throwOnBroadcast) throw const SocketException('connection reset');
    return broadcastResponse;
  }

  @override
  String getErrorMessage(int id) => errorMessage;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    PathProviderPlatform.instance = _MockPathProviderPlatform();
  });

  group('shielded commit', () {

    // Commits once; returns whether onCommit ran and the error message.
    Future<List<Object?>> commitOutcome(_FakeBroadcastElectrumClient client,
        {List<String> nullifiers = const ['n1']}) async {
      final result = _transactionResult(txId: 'b' * 64, spentNullifiers: nullifiers);
      var reserved = false;
      String? error;
      try {
        await PendingPivxShieldedTransaction(
          result: result,
          electrumClient: client,
          amount: 2000000,
          fee: result.fee,
          onCommit: (_) async => reserved = true,
        ).commit();
      } on BitcoinTransactionCommitFailed catch (e) {
        error = e.errorMessage;
      }
      return [reserved, error];
    }

    test('a server rejection leaves the inputs free', () async {
      final o = await commitOutcome(_FakeBroadcastElectrumClient(broadcastResponse: ''));
      expect(o, [false, isNotNull]);
    });

    test('no server verdict reserves the notes and warns against a resend',
        () async {
      for (final throws in [true, false]) {
        final o = await commitOutcome(_FakeBroadcastElectrumClient(
            broadcastResponse: '', throwOnBroadcast: throws, errorMessage: ''));
        expect(o, [true, contains('Do not resend')]);
      }
    });

    test('an offline commit that never sent leaves the notes free', () async {
      final o = await commitOutcome(_FakeBroadcastElectrumClient(
          broadcastResponse: '', sendsCall: false, errorMessage: ''));
      expect(o, [false, isNotNull]);
    });

    test('a txid mismatch reserves the notes', () async {
      final o = await commitOutcome(
          _FakeBroadcastElectrumClient(broadcastResponse: '9' * 64));
      expect(o, [true, contains('Do not resend')]);
    });

    test('an unknown t-to-z broadcast records nothing and names the txid',
        () async {
      // No notes to lock and no eviction path for a phantom row.
      final o = await commitOutcome(
          _FakeBroadcastElectrumClient(
              broadcastResponse: '', throwOnBroadcast: true, errorMessage: ''),
          nullifiers: const []);
      expect(o, [false, contains('b' * 64)]);
    });

    test('post-broadcast bookkeeping failure is swallowed', () async {
      final txId = 'c' * 64;
      final client = _FakeBroadcastElectrumClient(broadcastResponse: txId);
      final result = _transactionResult(txId: txId, spentNullifiers: ['n1']);
      final pending = PendingPivxShieldedTransaction(
        result: result,
        electrumClient: client,
        amount: 2000000,
        fee: result.fee,
        onCommit: (_) async => throw Exception('post-broadcast bookkeeping'),
      );

      // Surfacing it as a broadcast failure would prompt a double send.
      await pending.commit();
      expect(client.broadcastCalls, 1);
    });

    test('commit marks notes pending spent in storage', () async {
      final txId = 'd' * 64;
      final client = _FakeBroadcastElectrumClient(broadcastResponse: txId);
      final storage = SaplingNoteStorage(
        walletId: 'commit_test_${DateTime.now().millisecondsSinceEpoch}',
        allowUnencryptedStorage: true,
      );
      await storage.load();
      await storage.addNote(_spendableNote(id: 'tx0:0', nullifier: 'n1'));
      const chainHeight =
          100 + PivxShieldedConfirmationPolicy.spendConfirmations - 1;
      expect(storage.spendableNotesAt(chainHeight: chainHeight).length, 1);

      final result = _transactionResult(txId: txId, spentNullifiers: ['n1']);
      final pending = PendingPivxShieldedTransaction(
        result: result,
        electrumClient: client,
        amount: 2000000,
        fee: result.fee,
        noteStorage: storage, // as PivxWallet passes it
      );

      await pending.commit();

      expect(storage.spendableNotesAt(chainHeight: chainHeight), isEmpty);
      expect(storage.pendingSpentNotes.map((n) => n.nullifier), ['n1']);
    });
  });
}

SaplingTransactionResult _transactionResult({
  required String txId,
  required List<String> spentNullifiers,
}) {
  return SaplingTransactionResult(
    txHex: '0300',
    txId: txId,
    fee: 1417000,
    spentNullifiers: spentNullifiers,
  );
}

StoredSaplingNote _spendableNote({
  required String id,
  required String nullifier,
}) {
  return StoredSaplingNote(
    id: id,
    value: 3000000,
    height: 100,
    txid: id.split(':').first,
    outputIndex: 0,
    treePosition: 0,
    cmu: 'cm_$id',
    nullifier: nullifier,
    rseed: 'aa' * 32,
    diversifier: 'bb' * 11,
    pkD: 'cc' * 32,
  );
}
