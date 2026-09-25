import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:cw_pivx/src/sapling/sapling_note_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Mock path provider for testing
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  group('SaplingNoteStorage Thread Safety', () {
    late SaplingNoteStorage storage;

    setUp(() async {
      storage = SaplingNoteStorage(
        walletId: 'test_wallet_${DateTime.now().millisecondsSinceEpoch}',
        allowUnencryptedStorage: true,
      );
      await storage.load();
    });

    test('advances shielded receive index without moving backwards', () async {
      expect(storage.nextDiversifierIndex, 1);

      await storage.advanceNextDiversifierIndexAtLeast(8);
      expect(storage.nextDiversifierIndex, 8);

      await storage.advanceNextDiversifierIndexAtLeast(3);
      expect(storage.nextDiversifierIndex, 8);
    });

    test('pending spent nullifiers are reserved and excluded from balance',
        () async {
      await storage.addNote(StoredSaplingNote(
        id: 'tx0:0',
        value: 5000,
        height: 1000,
        txid: 'tx0',
        outputIndex: 0,
        treePosition: 0,
        cmu: 'cmu_0',
        nullifier: 'nf_0',
      ));
      await storage.addNote(StoredSaplingNote(
        id: 'tx1:0',
        value: 7000,
        height: 1001,
        txid: 'tx1',
        outputIndex: 0,
        treePosition: 1,
        cmu: 'cmu_1',
        nullifier: 'nf_1',
      ));

      final reserved = await storage.markPendingSpentByNullifiers(
        ['nf_0'],
        'pending_txid',
      );

      expect(reserved, equals(5000));
      expect(storage.balance, equals(7000));
      expect(storage.pendingOutgoingBalance, equals(5000));
      expect(storage.notes.first.isPendingSpend, isTrue);

      await storage.markSpentByNullifier('nf_0', 'mined_txid');

      expect(storage.notes.first.isSpent, isTrue);
      expect(storage.notes.first.isPendingSpend, isFalse);
      expect(storage.notes.first.spendingTxid, equals('mined_txid'));
      expect(storage.notes.first.pendingSpendingTxid, isNull);
      expect(storage.pendingOutgoingBalance, equals(0));
    });

    test('shielded balance separates pending, confirmed, and spendable notes',
        () async {
      await storage.addNote(StoredSaplingNote(
        id: 'young_tx:0',
        value: 5000,
        height: 100,
        txid: 'young_tx',
        outputIndex: 0,
        treePosition: 0,
        cmu: 'cmu_young',
        nullifier: 'nf_young',
        rseed: 'rseed_young',
        diversifier: 'diversifier_young',
        pkD: 'pkd_young',
      ));
      await storage.addNote(StoredSaplingNote(
        id: 'missing_spend_data_tx:0',
        value: 7000,
        height: 99,
        txid: 'missing_spend_data_tx',
        outputIndex: 0,
        treePosition: 1,
        cmu: 'cmu_missing',
      ));

      expect(
        storage.pendingReceivedBalanceAt(
          chainHeight: 104,
          minConfirmations: 6,
        ),
        equals(5000),
      );
      expect(
        storage.spendableBalanceAt(
          chainHeight: 104,
          minConfirmations: 6,
        ),
        equals(0),
      );
      expect(
        storage.spendableBalanceAt(
          chainHeight: 105,
          minConfirmations: 6,
        ),
        equals(5000),
      );
    });

    test('nextTreePosition persists independently from owned notes', () async {
      final walletId =
          'tree_position_test_${DateTime.now().millisecondsSinceEpoch}';
      final storage1 = SaplingNoteStorage(
        walletId: walletId,
        allowUnencryptedStorage: true,
      );
      await storage1.load();

      await storage1.setNextTreePosition(42);
      expect(storage1.nextTreePosition, equals(42));

      final storage2 = SaplingNoteStorage(
        walletId: walletId,
        allowUnencryptedStorage: true,
      );
      await storage2.load();

      expect(storage2.notes, isEmpty);
      expect(storage2.nextTreePosition, equals(42));
      expect(storage2.hasPersistedTreePosition, isTrue);
    });

    test('rename moves the file and the live store saves to the new path',
        () async {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final oldId = 'rename_old_$stamp';
      final newId = 'rename_new_$stamp';
      final live = SaplingNoteStorage(
        walletId: oldId,
        allowUnencryptedStorage: true,
      );
      await live.load();
      await live.setNextTreePosition(7);

      await SaplingNoteStorage.rename(oldId, newId);
      // The open wallet keeps saving after the service renamed it.
      await live.setNextTreePosition(9);

      expect(await File(await SaplingNoteStorage.pathFor(oldId)).exists(),
          isFalse);
      final reopened = SaplingNoteStorage(
        walletId: newId,
        allowUnencryptedStorage: true,
      );
      await reopened.load();
      expect(reopened.nextTreePosition, 9);
    });

    test('legacy note-derived tree position is not treated as persisted',
        () async {
      final walletId =
          'legacy_tree_position_${DateTime.now().millisecondsSinceEpoch}';
      final legacyFile = File(
          '${Directory.systemTemp.path}/pivx_sapling_${walletId}_mainnet.json.enc');

      if (await legacyFile.exists()) await legacyFile.delete();

      await legacyFile.writeAsString(jsonEncode({
        'lastSyncedHeight': 2700510,
        'nextDiversifierIndex': 1,
        'notes': [
          {
            'id': 'txid:0',
            'value': 1000,
            'height': 2700501,
            'txid': 'txid',
            'outputIndex': 0,
            'treePosition': 41,
            'cmu': 'cmu',
            'isSpent': false,
          }
        ],
        'addresses': <Map<String, dynamic>>[],
      }));

      final legacyStorage = SaplingNoteStorage(
        walletId: walletId,
        allowUnencryptedStorage: true,
      );

      await legacyStorage.load();

      expect(legacyStorage.nextTreePosition, equals(42));
      expect(legacyStorage.hasPersistedTreePosition, isFalse);
    });

    test('sync height and tree position persist atomically', () async {
      final walletId =
          'complete_range_${DateTime.now().millisecondsSinceEpoch}';
      final storage1 = SaplingNoteStorage(
        walletId: walletId,
        allowUnencryptedStorage: true,
      );
      await storage1.load();

      await storage1.completeSyncRange(
        lastSyncedHeight: 2700600,
        nextTreePosition: 99,
        treePositionIsTrusted: true,
      );

      final storage2 = SaplingNoteStorage(
        walletId: walletId,
        allowUnencryptedStorage: true,
      );
      await storage2.load();

      expect(storage2.lastSyncedHeight, equals(2700600));
      expect(storage2.nextTreePosition, equals(99));
      expect(storage2.hasPersistedTreePosition, isTrue);
    });

    test('untrusted sync completion does not persist tree cursor', () async {
      final walletId =
          'untrusted_complete_${DateTime.now().millisecondsSinceEpoch}';
      final storage1 = SaplingNoteStorage(
        walletId: walletId,
        allowUnencryptedStorage: true,
      );
      await storage1.load();

      await storage1.completeSyncRange(
        lastSyncedHeight: 2700600,
        nextTreePosition: 99,
        treePositionIsTrusted: false,
      );

      final storage2 = SaplingNoteStorage(
        walletId: walletId,
        allowUnencryptedStorage: true,
      );
      await storage2.load();

      expect(storage2.lastSyncedHeight, equals(2700600));
      expect(storage2.nextTreePosition, equals(0));
      expect(storage2.hasPersistedTreePosition, isFalse);
    });

    test('clear removes trusted tree cursor', () async {
      final walletId = 'clear_cursor_${DateTime.now().millisecondsSinceEpoch}';
      final storage1 = SaplingNoteStorage(
        walletId: walletId,
        allowUnencryptedStorage: true,
      );
      await storage1.load();

      await storage1.setNextTreePosition(42);
      await storage1.clear();

      final storage2 = SaplingNoteStorage(
        walletId: walletId,
        allowUnencryptedStorage: true,
      );
      await storage2.load();

      expect(storage2.lastSyncedHeight, equals(0));
      expect(storage2.nextTreePosition, equals(0));
      expect(storage2.hasPersistedTreePosition, isFalse);
    });

    test('sync completion persists scanned block hashes', () async {
      final walletId =
          'scanned_hashes_${DateTime.now().millisecondsSinceEpoch}';
      final storage1 = SaplingNoteStorage(
        walletId: walletId,
        allowUnencryptedStorage: true,
      );
      await storage1.load();

      await storage1.completeSyncRange(
        lastSyncedHeight: 2700502,
        nextTreePosition: 0,
        treePositionIsTrusted: false,
        blockHashes: {
          2700500: 'hash_0',
          2700501: 'hash_1',
          2700502: 'hash_2',
        },
      );

      final storage2 = SaplingNoteStorage(
        walletId: walletId,
        allowUnencryptedStorage: true,
      );
      await storage2.load();

      expect(storage2.scannedBlockHashes[2700500], equals('hash_0'));
      expect(storage2.scannedBlockHashes[2700502], equals('hash_2'));
    });

    test('keeps only the recent block hashes reorg detection reads', () async {
      final storage = SaplingNoteStorage(
        walletId: 'bounded_hashes_${DateTime.now().millisecondsSinceEpoch}',
        allowUnencryptedStorage: true,
      );
      await storage.load();

      await storage.completeSyncRange(
        lastSyncedHeight: 3000,
        nextTreePosition: 0,
        treePositionIsTrusted: false,
        blockHashes: {for (var h = 1; h <= 3000; h++) h: 'hash_$h'},
      );

      expect(storage.scannedBlockHashes.length, 200);
      expect(storage.scannedBlockHashes.keys.reduce(min), 2801);
      expect(storage.scannedBlockHashes[3000], 'hash_3000');
    });

    test('rewind removes stale notes and clears reorged spend markers',
        () async {
      final walletId = 'rewind_${DateTime.now().millisecondsSinceEpoch}';
      final storage1 = SaplingNoteStorage(
        walletId: walletId,
        allowUnencryptedStorage: true,
      );
      await storage1.load();

      await storage1.addNote(StoredSaplingNote(
        id: 'kept_tx:0',
        value: 5000,
        height: 2700501,
        txid: 'kept_tx',
        outputIndex: 0,
        treePosition: 0,
        cmu: 'cmu_kept',
        nullifier: 'nf_kept',
      ));
      await storage1.addNote(StoredSaplingNote(
        id: 'removed_tx:0',
        value: 7000,
        height: 2700504,
        txid: 'removed_tx',
        outputIndex: 0,
        treePosition: 1,
        cmu: 'cmu_removed',
      ));
      await storage1.markSpentByNullifier(
        'nf_kept',
        'spending_tx',
        spendingHeight: 2700504,
      );
      await storage1.completeSyncRange(
        lastSyncedHeight: 2700505,
        nextTreePosition: 12,
        treePositionIsTrusted: true,
        blockHashes: {
          2700501: 'hash_1',
          2700504: 'hash_4',
          2700505: 'hash_5',
        },
      );

      await storage1.rewindToHeight(2700502);

      expect(storage1.lastSyncedHeight, equals(2700502));
      expect(storage1.notes.map((note) => note.id), equals(['kept_tx:0']));
      expect(storage1.notes.single.isSpent, isFalse);
      expect(storage1.notes.single.spendingTxid, isNull);
      expect(storage1.nextTreePosition, equals(0));
      expect(storage1.hasPersistedTreePosition, isFalse);
      expect(storage1.scannedBlockHashes.containsKey(2700504), isFalse);
    });

    test('unencrypted storage is rejected unless explicitly allowed', () async {
      final protectedStorage = SaplingNoteStorage(
        walletId: 'encrypted_required_${DateTime.now().millisecondsSinceEpoch}',
      );

      expect(protectedStorage.load(), throwsA(isA<StateError>()));
    });

    test('concurrent clear and addNote persist one consistent snapshot',
        () async {
      final walletId = 'clear_race_${DateTime.now().millisecondsSinceEpoch}';
      final racingStorage = SaplingNoteStorage(
        walletId: walletId,
        allowUnencryptedStorage: true,
      );
      await racingStorage.load();

      for (var i = 0; i < 25; i++) {
        // Seed non-reset state so a persisted file mixing pre-clear sync
        // metadata with post-clear notes (or vice versa) is detectable.
        await racingStorage.completeSyncRange(
          lastSyncedHeight: 2700000 + i,
          nextTreePosition: 500 + i,
          treePositionIsTrusted: true,
          blockHashes: {2700000 + i: 'hash_$i'},
        );

        final note = StoredSaplingNote(
          id: 'race$i:0',
          value: 1000,
          height: 2600000 + i,
          txid: 'race$i',
          outputIndex: 0,
          treePosition: i,
          cmu: 'cmu_race_$i',
        );

        // Race clear() against addNote(), alternating start order.
        final ops = i.isEven
            ? [racingStorage.clear(), racingStorage.addNote(note)]
            : [racingStorage.addNote(note), racingStorage.clear()];
        await Future.wait(ops);

        // Reload from disk: the persisted state must equal one of the two
        // serial outcomes (clear-then-add or add-then-clear), never a mix of
        // old sync metadata with cleared notes or vice versa.
        final reloaded = SaplingNoteStorage(
          walletId: walletId,
          allowUnencryptedStorage: true,
        );
        await reloaded.load();

        expect(reloaded.lastSyncedHeight, equals(0),
            reason: 'clear() ran, so sync height must be reset (iteration $i)');
        // With no persisted cursor, load() falls back to the legacy
        // max(note.treePosition)+1 hint, so clear-then-add yields i + 1.
        expect(reloaded.nextTreePosition,
            equals(reloaded.notes.isEmpty ? 0 : i + 1),
            reason: 'clear() ran, so no trusted cursor may survive '
                '(iteration $i)');
        expect(reloaded.hasPersistedTreePosition, isFalse,
            reason: 'clear() ran, so cursor trust must be reset (iteration $i)');
        expect(reloaded.scannedBlockHashes, isEmpty,
            reason: 'clear() ran, so block hashes must be reset (iteration $i)');
        final noteIds = reloaded.notes.map((n) => n.id).toList();
        expect(
          noteIds.isEmpty ||
              (noteIds.length == 1 && noteIds.single == 'race$i:0'),
          isTrue,
          reason: 'notes must be empty (add-then-clear) or exactly the added '
              'note (clear-then-add), got $noteIds (iteration $i)',
        );
      }
    });

    test('unexpected server-reported spend is quarantined, not terminal',
        () async {
      final walletId = 'quarantine_${DateTime.now().millisecondsSinceEpoch}';
      final storage1 = SaplingNoteStorage(
        walletId: walletId,
        allowUnencryptedStorage: true,
      );
      await storage1.load();

      StoredSaplingNote buildNote() => StoredSaplingNote(
            id: 'victim_tx:0',
            value: 5000,
            height: 100,
            txid: 'victim_tx',
            outputIndex: 0,
            treePosition: 0,
            cmu: 'cmu_victim',
            nullifier: 'nf_victim',
            rseed: 'rseed_victim',
            diversifier: 'diversifier_victim',
            pkD: 'pkd_victim',
          );

      await storage1.addNote(buildNote());

      // No pending/outgoing state: a server-reported spend must quarantine.
      final handled = await storage1.recordObservedSpendByNullifier(
        'nf_victim',
        'evil_tx',
        spendingHeight: 105,
      );

      expect(handled, isTrue);
      final note = storage1.notes.single;
      expect(note.isSpent, isFalse);
      expect(note.isProvisionallySpent, isTrue);
      expect(note.spendingTxid, equals('evil_tx'));
      expect(storage1.quarantinedNullifiers, equals(['nf_victim']));

      // Excluded from every spendable-balance surface.
      expect(storage1.balance, equals(0));
      expect(storage1.spendableBalance, equals(0));
      expect(
        storage1.spendableBalanceAt(chainHeight: 200, minConfirmations: 6),
        equals(0),
      );
      expect(storage1.unspentNotes, isEmpty);

      // Quarantine state persists across reload.
      final reloaded = SaplingNoteStorage(
        walletId: walletId,
        allowUnencryptedStorage: true,
      );
      await reloaded.load();
      expect(reloaded.notes.single.isProvisionallySpent, isTrue);
      expect(reloaded.notes.single.isSpent, isFalse);
      expect(reloaded.quarantinedNullifiers, equals(['nf_victim']));

      // Reversible by reorg rewind past the claimed spending height.
      await storage1.rewindToHeight(102);
      expect(storage1.notes.single.isProvisionallySpent, isFalse);
      expect(storage1.quarantinedNullifiers, isEmpty);
      expect(storage1.balance, equals(5000));

      // Re-quarantine, then verify the clear()/rescan path resets it.
      await storage1.recordObservedSpendByNullifier(
        'nf_victim',
        'evil_tx',
        spendingHeight: 105,
      );
      expect(storage1.quarantinedNullifiers, equals(['nf_victim']));

      await storage1.clear();
      expect(storage1.quarantinedNullifiers, isEmpty);

      // Rescan rediscovers the note fresh and spendable.
      await storage1.addNote(buildNote());
      expect(storage1.notes.single.isProvisionallySpent, isFalse);
      expect(storage1.balance, equals(5000));
      expect(storage1.quarantinedNullifiers, isEmpty);
    });

    test('expected spend matching pending outgoing stays terminal', () async {
      await storage.addNote(StoredSaplingNote(
        id: 'mine_tx:0',
        value: 5000,
        height: 100,
        txid: 'mine_tx',
        outputIndex: 0,
        treePosition: 0,
        cmu: 'cmu_mine',
        nullifier: 'nf_mine',
      ));

      await storage.markPendingSpentByNullifiers(['nf_mine'], 'my_broadcast');

      final handled = await storage.recordObservedSpendByNullifier(
        'nf_mine',
        'my_broadcast',
        spendingHeight: 110,
      );

      expect(handled, isTrue);
      final note = storage.notes.single;
      expect(note.isSpent, isTrue);
      expect(note.isProvisionallySpent, isFalse);
      expect(note.isPendingSpend, isFalse);
      expect(note.spendingTxid, equals('my_broadcast'));
      expect(note.spendingHeight, equals(110));
      expect(note.pendingSpendingTxid, isNull);
      expect(storage.quarantinedNullifiers, isEmpty);
      expect(storage.pendingOutgoingBalance, equals(0));
    });
  });
}
