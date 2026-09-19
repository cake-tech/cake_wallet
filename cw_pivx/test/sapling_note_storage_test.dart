import 'dart:convert';
import 'dart:io';
import 'package:cw_core/encryption_file_utils.dart';
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

class FakeEncryptionFileUtils extends EncryptionFileUtils {
  static const _prefix = 'encrypted:';

  @override
  Future<void> write({
    required String path,
    required String password,
    required String data,
  }) async {
    await File(path)
        .writeAsString('$_prefix${base64Encode(utf8.encode(data))}');
  }

  @override
  Future<String> read({
    required String path,
    required String password,
  }) async {
    final encrypted = await File(path).readAsString();
    if (!encrypted.startsWith(_prefix)) {
      throw const FormatException('Missing test encryption prefix');
    }
    return utf8.decode(base64Decode(encrypted.substring(_prefix.length)));
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
        isTestnet: true,
        allowUnencryptedStorage: true,
      );
      await storage.load();
    });

    tearDown(() async {
      // Clean up test files - storage will clean up on its own
      // We don't need to manually delete as temp files will be cleared
    });

    test('concurrent addNote operations do not lose notes', () async {
      // Add 100 notes concurrently
      final futures = List.generate(100, (i) {
        final note = StoredSaplingNote(
          id: 'tx$i:0',
          value: 1000 + i,
          height: 1000 + i,
          txid: 'txid_$i',
          outputIndex: 0,
          treePosition: i,
          cmu: 'cmu_$i',
        );
        return storage.addNote(note);
      });

      await Future.wait(futures);

      // Verify all notes were saved
      expect(storage.notes.length, equals(100));

      // Verify all values are present
      final values = storage.notes.map((n) => n.value).toSet();
      expect(values.length, equals(100));
      for (int i = 0; i < 100; i++) {
        expect(values.contains(1000 + i), true);
      }
    });

    test('advances shielded receive index without moving backwards', () async {
      expect(storage.nextDiversifierIndex, 1);

      await storage.advanceNextDiversifierIndexAtLeast(8);
      expect(storage.nextDiversifierIndex, 8);

      await storage.advanceNextDiversifierIndexAtLeast(3);
      expect(storage.nextDiversifierIndex, 8);

      expect(storage.getAndIncrementDiversifierIndex(), 8);
      expect(storage.nextDiversifierIndex, 9);
    });

    test('persists generated shielded addresses and next receive index',
        () async {
      final walletId =
          'shielded_addresses_${DateTime.now().millisecondsSinceEpoch}';
      final storage1 = SaplingNoteStorage(
        walletId: walletId,
        isTestnet: true,
        allowUnencryptedStorage: true,
      );
      await storage1.load();

      await storage1.addAddress(StoredShieldedAddress(
        diversifierIndex: 1,
        address: 'ptestsapling1generated1',
        label: 'first generated',
      ));
      await storage1.addAddress(StoredShieldedAddress(
        diversifierIndex: 3,
        address: 'ptestsapling1generated3',
        label: 'third generated',
      ));

      final storage2 = SaplingNoteStorage(
        walletId: walletId,
        isTestnet: true,
        allowUnencryptedStorage: true,
      );
      await storage2.load();

      expect(storage2.addresses.map((address) => address.address), [
        'ptestsapling1generated1',
        'ptestsapling1generated3',
      ]);
      expect(storage2.addresses.last.label, equals('third generated'));
      expect(storage2.nextDiversifierIndex, equals(4));
    });

    test('updating an existing shielded address preserves receive index',
        () async {
      await storage.addAddress(StoredShieldedAddress(
        diversifierIndex: 5,
        address: 'ptestsapling1generated5',
        label: 'old label',
      ));
      expect(storage.nextDiversifierIndex, equals(6));

      await storage.addAddress(StoredShieldedAddress(
        diversifierIndex: 5,
        address: 'ptestsapling1generated5',
        label: 'new label',
      ));

      expect(storage.addresses, hasLength(1));
      expect(storage.addresses.single.label, equals('new label'));
      expect(storage.nextDiversifierIndex, equals(6));
    });

    test('concurrent markSpentByNullifier operations are thread-safe',
        () async {
      // Add notes first
      for (int i = 0; i < 50; i++) {
        await storage.addNote(StoredSaplingNote(
          id: 'tx$i:0',
          value: 1000,
          height: 1000 + i,
          txid: 'txid_$i',
          outputIndex: 0,
          treePosition: i,
          cmu: 'cmu_$i',
          nullifier: 'nf_$i',
        ));
      }

      // Mark them all spent concurrently
      final futures = List.generate(50, (i) {
        return storage.markSpentByNullifier('nf_$i', 'spending_tx_$i');
      });

      await Future.wait(futures);

      // Verify all marked as spent
      final spentCount = storage.notes.where((n) => n.isSpent).length;
      expect(spentCount, equals(50));
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
      expect(
        storage.confirmedBalanceAt(
          chainHeight: 105,
          minConfirmations: 6,
          requireSpendingData: false,
        ),
        equals(12000),
      );
      expect(
        storage.confirmedBalanceAt(
          chainHeight: 105,
          minConfirmations: 6,
        ),
        equals(5000),
      );
    });

    test('shielded spend eligibility summary is count-only and maturity-aware',
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
        id: 'mature_tx:0',
        value: 6000,
        height: 99,
        txid: 'mature_tx',
        outputIndex: 0,
        treePosition: 1,
        cmu: 'cmu_mature',
        nullifier: 'nf_mature',
        rseed: 'rseed_mature',
        diversifier: 'diversifier_mature',
        pkD: 'pkd_mature',
      ));
      await storage.addNote(StoredSaplingNote(
        id: 'missing_spend_data_tx:0',
        value: 7000,
        height: 99,
        txid: 'missing_spend_data_tx',
        outputIndex: 0,
        treePosition: 2,
        cmu: 'cmu_missing',
      ));
      await storage.addNote(StoredSaplingNote(
        id: 'pending_spend_tx:0',
        value: 8000,
        height: 99,
        txid: 'pending_spend_tx',
        outputIndex: 0,
        treePosition: 3,
        cmu: 'cmu_pending',
        nullifier: 'nf_pending',
        rseed: 'rseed_pending',
        diversifier: 'diversifier_pending',
        pkD: 'pkd_pending',
        isPendingSpend: true,
      ));
      await storage.addNote(StoredSaplingNote(
        id: 'spent_tx:0',
        value: 9000,
        height: 99,
        txid: 'spent_tx',
        outputIndex: 0,
        treePosition: 4,
        cmu: 'cmu_spent',
        nullifier: 'nf_spent',
        rseed: 'rseed_spent',
        diversifier: 'diversifier_spent',
        pkD: 'pkd_spent',
        isSpent: true,
      ));

      final summary = storage.spendEligibilitySummaryAt(
        chainHeight: 104,
        minConfirmations: 6,
      );

      expect(summary.totalUnspent, equals(4));
      expect(summary.spendable, equals(1));
      expect(summary.pendingConfirmation, equals(1));
      expect(summary.pendingSpend, equals(1));
      expect(summary.missingSpendingData, equals(1));
      expect(summary.sanitizedLogLine, contains('min_confirmations=6'));
      expect(summary.sanitizedLogLine, contains('spendable=1'));
      expect(summary.sanitizedLogLine, isNot(contains('tx')));
      expect(summary.sanitizedLogLine, isNot(contains('nf_')));
      expect(summary.sanitizedLogLine, isNot(contains('cmu_')));
    });

    test('concurrent balance calculations are consistent', () async {
      // Add notes
      for (int i = 0; i < 20; i++) {
        await storage.addNote(StoredSaplingNote(
          id: 'tx$i:0',
          value: 1000,
          height: 1000 + i,
          txid: 'txid_$i',
          outputIndex: 0,
          treePosition: i,
          cmu: 'cmu_$i',
        ));
      }

      // Read balance concurrently using thread-safe method
      final futures = List.generate(100, (_) async {
        return await storage.getBalanceSafe();
      });

      final balances = await Future.wait(futures);

      // All balances should be the same
      expect(balances.toSet().length, equals(1));
      expect(balances.first, equals(20000));
    });

    test('concurrent addNote with duplicate IDs updates existing', () async {
      // Add same note ID multiple times concurrently
      final futures = List.generate(50, (i) {
        final note = StoredSaplingNote(
          id: 'same_tx:0',
          value: 1000 + i, // Different values
          height: 1000,
          txid: 'same_tx',
          outputIndex: 0,
          treePosition: 0,
          cmu: 'cmu',
        );
        return storage.addNote(note);
      });

      await Future.wait(futures);

      // Should only have 1 note (duplicates updated)
      expect(storage.notes.length, equals(1));
      expect(storage.notes.first.id, equals('same_tx:0'));
      // Value will be from one of the concurrent updates
      expect(storage.notes.first.value, greaterThanOrEqualTo(1000));
      expect(storage.notes.first.value, lessThan(1050));
    });

    test('concurrent setLastSyncedHeight operations maintain consistency',
        () async {
      // Update height concurrently
      final futures = List.generate(100, (i) {
        return storage.setLastSyncedHeight(2700000 + i);
      });

      await Future.wait(futures);

      // Last synced height should be one of the values we set
      expect(storage.lastSyncedHeight, greaterThanOrEqualTo(2700000));
      expect(storage.lastSyncedHeight, lessThan(2700100));
    });

    test('nextTreePosition persists independently from owned notes', () async {
      final walletId =
          'tree_position_test_${DateTime.now().millisecondsSinceEpoch}';
      final storage1 = SaplingNoteStorage(
        walletId: walletId,
        isTestnet: true,
        allowUnencryptedStorage: true,
      );
      await storage1.load();

      await storage1.setNextTreePosition(42);
      expect(storage1.nextTreePosition, equals(42));

      final storage2 = SaplingNoteStorage(
        walletId: walletId,
        isTestnet: true,
        allowUnencryptedStorage: true,
      );
      await storage2.load();

      expect(storage2.notes, isEmpty);
      expect(storage2.nextTreePosition, equals(42));
      expect(storage2.hasPersistedTreePosition, isTrue);
    });

    test('legacy note-derived tree position is not treated as persisted',
        () async {
      final walletId =
          'legacy_tree_position_${DateTime.now().millisecondsSinceEpoch}';
      final legacyFile = File(
          '${Directory.systemTemp.path}/pivx_sapling_${walletId}_testnet.json');

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
        isTestnet: true,
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
        isTestnet: true,
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
        isTestnet: true,
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
        isTestnet: true,
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
        isTestnet: true,
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
        isTestnet: true,
        allowUnencryptedStorage: true,
      );
      await storage1.load();

      await storage1.setNextTreePosition(42);
      await storage1.clear();

      final storage2 = SaplingNoteStorage(
        walletId: walletId,
        isTestnet: true,
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
        isTestnet: true,
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
        isTestnet: true,
        allowUnencryptedStorage: true,
      );
      await storage2.load();

      expect(storage2.scannedBlockHashes[2700500], equals('hash_0'));
      expect(storage2.scannedBlockHashes[2700502], equals('hash_2'));
    });

    test('rewind removes stale notes and clears reorged spend markers',
        () async {
      final walletId = 'rewind_${DateTime.now().millisecondsSinceEpoch}';
      final storage1 = SaplingNoteStorage(
        walletId: walletId,
        isTestnet: true,
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
        isTestnet: true,
      );

      expect(protectedStorage.load(), throwsA(isA<StateError>()));
    });

    test('legacy plaintext sidecar migrates to encrypted storage', () async {
      final walletId =
          'legacy_migration_${DateTime.now().millisecondsSinceEpoch}';
      final legacyFile = File(
          '${Directory.systemTemp.path}/pivx_sapling_${walletId}_testnet.json');
      final encryptedFile = File(
          '${Directory.systemTemp.path}/pivx_sapling_${walletId}_testnet.json.enc');

      if (await legacyFile.exists()) await legacyFile.delete();
      if (await encryptedFile.exists()) await encryptedFile.delete();

      await legacyFile.writeAsString(jsonEncode({
        'lastSyncedHeight': 2700501,
        'nextTreePosition': 77,
        'nextDiversifierIndex': 3,
        'notes': <Map<String, dynamic>>[],
        'addresses': <Map<String, dynamic>>[],
      }));

      final encryptedStorage = SaplingNoteStorage(
        walletId: walletId,
        isTestnet: true,
        encryptionFileUtils: FakeEncryptionFileUtils(),
        password: 'test-password',
      );

      await encryptedStorage.load();

      expect(encryptedStorage.lastSyncedHeight, equals(2700501));
      expect(encryptedStorage.nextTreePosition, equals(77));
      expect(await legacyFile.exists(), isFalse);
      expect(await encryptedFile.exists(), isTrue);
      expect(await encryptedFile.readAsString(),
          isNot(contains('lastSyncedHeight')));

      final reloadedStorage = SaplingNoteStorage(
        walletId: walletId,
        isTestnet: true,
        encryptionFileUtils: FakeEncryptionFileUtils(),
        password: 'test-password',
      );

      await reloadedStorage.load();
      expect(reloadedStorage.lastSyncedHeight, equals(2700501));
      expect(reloadedStorage.nextTreePosition, equals(77));
      expect(reloadedStorage.hasPersistedTreePosition, isTrue);
    });

    test('legacy migration does not trust inferred tree cursor', () async {
      final walletId =
          'legacy_untrusted_cursor_${DateTime.now().millisecondsSinceEpoch}';
      final legacyFile = File(
          '${Directory.systemTemp.path}/pivx_sapling_${walletId}_testnet.json');
      final encryptedFile = File(
          '${Directory.systemTemp.path}/pivx_sapling_${walletId}_testnet.json.enc');

      if (await legacyFile.exists()) await legacyFile.delete();
      if (await encryptedFile.exists()) await encryptedFile.delete();

      await legacyFile.writeAsString(jsonEncode({
        'lastSyncedHeight': 2700501,
        'nextDiversifierIndex': 1,
        'notes': [
          {
            'id': 'txid:0',
            'value': 1000,
            'height': 2700501,
            'txid': 'txid',
            'outputIndex': 0,
            'treePosition': 12,
            'cmu': 'cmu',
            'isSpent': false,
          }
        ],
        'addresses': <Map<String, dynamic>>[],
      }));

      final encryptedStorage = SaplingNoteStorage(
        walletId: walletId,
        isTestnet: true,
        encryptionFileUtils: FakeEncryptionFileUtils(),
        password: 'test-password',
      );
      await encryptedStorage.load();

      expect(encryptedStorage.nextTreePosition, equals(13));
      expect(encryptedStorage.hasPersistedTreePosition, isFalse);

      final reloadedStorage = SaplingNoteStorage(
        walletId: walletId,
        isTestnet: true,
        encryptionFileUtils: FakeEncryptionFileUtils(),
        password: 'test-password',
      );
      await reloadedStorage.load();

      expect(reloadedStorage.nextTreePosition, equals(13));
      expect(reloadedStorage.hasPersistedTreePosition, isFalse);
    });

    test('mixed concurrent operations (add, mark spent, read)', () async {
      // Add initial notes
      for (int i = 0; i < 20; i++) {
        await storage.addNote(StoredSaplingNote(
          id: 'tx$i:0',
          value: 1000,
          height: 1000 + i,
          txid: 'txid_$i',
          outputIndex: 0,
          treePosition: i,
          cmu: 'cmu_$i',
          nullifier: 'nf_$i',
        ));
      }

      final futures = <Future>[];

      // Add more notes concurrently
      for (int i = 20; i < 40; i++) {
        futures.add(storage.addNote(StoredSaplingNote(
          id: 'tx$i:0',
          value: 1000,
          height: 1000 + i,
          txid: 'txid_$i',
          outputIndex: 0,
          treePosition: i,
          cmu: 'cmu_$i',
          nullifier: 'nf_$i',
        )));
      }

      // Mark some spent concurrently
      for (int i = 0; i < 10; i++) {
        futures.add(storage.markSpentByNullifier('nf_$i', 'spending_tx'));
      }

      // Read balance concurrently
      for (int i = 0; i < 20; i++) {
        futures.add(storage.getBalanceSafe());
      }

      await Future.wait(futures);

      // Verify final state
      expect(storage.notes.length, equals(40));
      final spentCount = storage.notes.where((n) => n.isSpent).length;
      expect(spentCount, equals(10));

      // Balance should be 30 unspent notes * 1000
      final finalBalance = await storage.getBalanceSafe();
      expect(finalBalance, equals(30000));
    });

    test('persistence survives concurrent writes', () async {
      final storage1 = SaplingNoteStorage(
        walletId: 'persist_test',
        isTestnet: true,
        allowUnencryptedStorage: true,
      );
      await storage1.load();

      // Add notes concurrently
      final futures = List.generate(50, (i) {
        final note = StoredSaplingNote(
          id: 'tx$i:0',
          value: 1000,
          height: 1000 + i,
          txid: 'txid_$i',
          outputIndex: 0,
          treePosition: i,
          cmu: 'cmu_$i',
        );
        return storage1.addNote(note);
      });

      await Future.wait(futures);

      // Load in new instance
      final storage2 = SaplingNoteStorage(
        walletId: 'persist_test',
        isTestnet: true,
        allowUnencryptedStorage: true,
      );
      await storage2.load();

      // Verify all notes persisted
      expect(storage2.notes.length, equals(50));
      final balance = await storage2.getBalanceSafe();
      expect(balance, equals(50000));

      // Cleanup happens automatically with temp directory
    });

    test('concurrent clear and addNote persist one consistent snapshot',
        () async {
      final walletId = 'clear_race_${DateTime.now().millisecondsSinceEpoch}';
      final racingStorage = SaplingNoteStorage(
        walletId: walletId,
        isTestnet: true,
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
          isTestnet: true,
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
        isTestnet: true,
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
        isTestnet: true,
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

    test('stress test with very high concurrency', () async {
      // 1000 concurrent operations
      final futures = <Future>[];

      for (int i = 0; i < 1000; i++) {
        if (i % 2 == 0) {
          // Add note
          futures.add(storage.addNote(StoredSaplingNote(
            id: 'tx$i:0',
            value: i,
            height: 1000 + i,
            txid: 'txid_$i',
            outputIndex: 0,
            treePosition: i,
            cmu: 'cmu_$i',
            nullifier: i % 4 == 0 ? 'nf_$i' : null,
          )));
        } else {
          // Read balance using thread-safe method
          futures.add(storage.getBalanceSafe());
        }
      }

      await Future.wait(futures);

      // Should have 500 notes (half were adds)
      expect(storage.notes.length, equals(500));

      // Verify no corruption
      final ids = storage.notes.map((n) => n.id).toSet();
      expect(ids.length, equals(500)); // All unique
    });
  });
}
