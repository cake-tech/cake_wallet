import 'dart:io';
import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_mnemonics_bip39.dart';
import 'package:cw_bitcoin/electrum.dart' as electrum;
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_bitcoin/exceptions.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/db/sqlite.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_pivx/src/pending_pivx_shielded_transaction.dart';
import 'package:cw_pivx/src/pivx_network.dart';
import 'package:cw_pivx/src/pivx_transaction_priority.dart';
import 'package:cw_pivx/src/pivx_wallet.dart';
import 'package:cw_pivx/src/sapling/sapling_factories.dart';
import 'package:cw_pivx/src/sapling/sapling_note_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

class _FakeEncryptionFileUtils extends EncryptionFileUtils {
  @override
  Future<void> write({
    required String path,
    required String password,
    required String data,
  }) async {}

  @override
  Future<String> read({
    required String path,
    required String password,
  }) async {
    throw UnimplementedError();
  }
}

class _FakeBroadcastElectrumClient extends electrum.ElectrumClient {
  _FakeBroadcastElectrumClient({required this.broadcastResponse});

  /// Response to return from broadcast; an empty string simulates a rejected
  /// broadcast (double spend, network error, ...).
  String broadcastResponse;
  int broadcastCalls = 0;

  @override
  Future<String> broadcastTransaction({
    required String transactionRaw,
    BasedUtxoNetwork? network,
    Function(int)? idCallback,
  }) async {
    broadcastCalls++;
    idCallback?.call(1);
    return broadcastResponse;
  }

  @override
  String getErrorMessage(int id) => 'bad-txns-nullifier-double-spent';
}

final _lockedError = throwsA(isA<Exception>().having(
  (e) => e.toString(),
  'message',
  contains(PivxWalletBase.shieldedNotesLockedMessage),
));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dbDir;
  late Directory hiveDir;
  late Box<UnspentCoinsInfo> unspentCoinsInfo;
  var dbInitialized = false;

  setUpAll(() async {
    PathProviderPlatform.instance = _MockPathProviderPlatform();
    SharedPreferences.setMockInitialValues({});
    dbDir = await Directory.systemTemp.createTemp('pivx_reservation_db_');
    hiveDir = await Directory.systemTemp.createTemp('pivx_reservation_hive_');
    databaseFactory = databaseFactoryFfi;
    await initDb(pathOverride: '${dbDir.path}/cake.db');
    CakeHive.init(hiveDir.path);
    if (!CakeHive.isAdapterRegistered(UnspentCoinsInfo.typeId)) {
      CakeHive.registerAdapter(UnspentCoinsInfoAdapter());
    }
    unspentCoinsInfo = await CakeHive.openBox<UnspentCoinsInfo>(
      '${UnspentCoinsInfo.boxName}_pivx_reservation_test',
    );
    dbInitialized = true;
  });

  tearDownAll(() async {
    await unspentCoinsInfo.close();
    if (dbInitialized) {
      await db?.close();
    }
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
    if (await dbDir.exists()) {
      await dbDir.delete(recursive: true);
    }
  });

  PivxWallet testWallet(electrum.ElectrumClient electrumClient) =>
      _testWallet(
        unspentCoinsInfo: unspentCoinsInfo,
        electrumClient: electrumClient,
      );

  group('shielded note reservations', () {
    test('two sequential builds cannot reserve overlapping notes', () {
      final wallet = testWallet(_FakeBroadcastElectrumClient(
        broadcastResponse: '',
      ));

      wallet.reserveShieldedNotes('tx1', ['n1', 'n2']);

      // Second pending transaction touching a reserved note fails with the
      // locked-funds flavor of the insufficient shielded funds error.
      expect(
        () => wallet.reserveShieldedNotes('tx2', ['n2', 'n3']),
        _lockedError,
      );
      // The failed attempt must not leave a partial reservation behind.
      expect(wallet.reservedShieldedNullifiers, {'n1', 'n2'});

      // A build over disjoint notes succeeds.
      wallet.reserveShieldedNotes('tx2', ['n3', 'n4']);
      expect(wallet.reservedShieldedNullifiers, {'n1', 'n2', 'n3', 'n4'});
    });

    test('release is idempotent and only affects the released transaction',
        () {
      final wallet = testWallet(_FakeBroadcastElectrumClient(
        broadcastResponse: '',
      ));

      wallet.reserveShieldedNotes('tx1', ['n1']);
      wallet.reserveShieldedNotes('tx2', ['n2']);

      wallet.releaseReservedShieldedNotes('tx1');
      wallet.releaseReservedShieldedNotes('tx1'); // no-op, no throw
      wallet.releaseReservedShieldedNotes('unknown'); // no-op, no throw

      expect(wallet.reservedShieldedNullifiers, {'n2'});

      // Released notes are selectable again.
      wallet.reserveShieldedNotes('tx3', ['n1']);
      expect(wallet.reservedShieldedNullifiers, {'n1', 'n2'});
    });
  });

  group('ensureShieldedNotesNotLocked (build pre-check)', () {
    const notes = {'n1': 3000000, 'n2': 500000};

    test('passes when nothing is reserved', () {
      PivxWalletBase.ensureShieldedNotesNotLocked(
        spendableNoteValuesByNullifier: notes,
        reservedNullifiers: const {},
        amount: 3400000,
        spendAll: false,
      );
    });

    test('fails with locked-funds error when reserved notes are the shortfall',
        () {
      expect(
        () => PivxWalletBase.ensureShieldedNotesNotLocked(
          spendableNoteValuesByNullifier: notes,
          reservedNullifiers: const {'n1'},
          amount: 1000000,
          spendAll: false,
        ),
        _lockedError,
      );
    });

    test('passes when unreserved notes still cover the amount', () {
      PivxWalletBase.ensureShieldedNotesNotLocked(
        spendableNoteValuesByNullifier: notes,
        reservedNullifiers: const {'n2'},
        amount: 2500000,
        spendAll: false,
      );
    });

    test('fails a spend-all while any spendable note is reserved', () {
      expect(
        () => PivxWalletBase.ensureShieldedNotesNotLocked(
          spendableNoteValuesByNullifier: notes,
          reservedNullifiers: const {'n2'},
          amount: 100,
          spendAll: true,
        ),
        _lockedError,
      );
    });

    test(
        'stays silent when balance is insufficient regardless of reservations '
        'so the standard insufficient-balance error surfaces', () {
      PivxWalletBase.ensureShieldedNotesNotLocked(
        spendableNoteValuesByNullifier: notes,
        reservedNullifiers: const {'n1'},
        amount: 9000000,
        spendAll: false,
      );
    });
  });

  group('broadcast failure releases the reservation', () {
    test('failed broadcast frees the notes so a rebuild can use them',
        () async {
      final client = _FakeBroadcastElectrumClient(broadcastResponse: '');
      final wallet = testWallet(client);
      final result = _transactionResult(
        txId: 'a' * 64,
        spentNullifiers: ['n1', 'n2'],
      );

      wallet.reserveShieldedNotes(result.txId, result.spentNullifiers);
      final pending = PendingPivxShieldedTransaction(
        result: result,
        electrumClient: client,
        amount: 2000000,
        fee: result.fee,
        onBroadcastFailure: () =>
            wallet.releaseReservedShieldedNotes(result.txId),
      );

      await expectLater(
        pending.commit(),
        throwsA(isA<BitcoinTransactionCommitFailed>()),
      );

      expect(client.broadcastCalls, 1);
      expect(wallet.reservedShieldedNullifiers, isEmpty);

      // A rebuilt transaction may now select the same notes again.
      wallet.reserveShieldedNotes('b' * 64, ['n1', 'n2']);
      expect(wallet.reservedShieldedNullifiers, {'n1', 'n2'});
    });

    test(
        'post-broadcast bookkeeping failure is swallowed and still releases '
        'the reservation', () async {
      final txId = 'c' * 64;
      final client = _FakeBroadcastElectrumClient(broadcastResponse: txId);
      final wallet = testWallet(client);
      final result = _transactionResult(
        txId: txId,
        spentNullifiers: ['n1'],
      );

      wallet.reserveShieldedNotes(result.txId, result.spentNullifiers);
      var broadcastFailureCalled = false;
      final pending = PendingPivxShieldedTransaction(
        result: result,
        electrumClient: client,
        amount: 2000000,
        fee: result.fee,
        onBroadcastFailure: () {
          broadcastFailureCalled = true;
          wallet.releaseReservedShieldedNotes(result.txId);
        },
        // Mirrors the wallet's real onCommit wiring: bookkeeping may throw, but
        // the reservation is released in a finally.
        onCommit: (_) async {
          try {
            throw Exception('post-broadcast bookkeeping');
          } finally {
            wallet.releaseReservedShieldedNotes(result.txId);
          }
        },
      );

      // The broadcast succeeded, so a bookkeeping failure afterward must not be
      // surfaced as a broadcast failure (which would prompt a double send)...
      await pending.commit();

      expect(client.broadcastCalls, 1);
      // ...the broadcast-failure hook must not fire (the notes really are
      // spent)...
      expect(broadcastFailureCalled, isFalse);
      // ...and the reservation must not be left locked for the session.
      expect(wallet.reservedShieldedNullifiers, isEmpty);
    });
  });

  group('successful commit keeps notes unavailable', () {
    test('commit marks notes pending spent in storage and drops reservation',
        () async {
      final txId = 'd' * 64;
      final client = _FakeBroadcastElectrumClient(broadcastResponse: txId);
      final wallet = testWallet(client);
      final storage = SaplingNoteStorage(
        walletId:
            'reservation_test_${DateTime.now().millisecondsSinceEpoch}',
        isTestnet: true,
        allowUnencryptedStorage: true,
      );
      await storage.load();
      await storage.addNote(_spendableNote(id: 'tx0:0', nullifier: 'n1'));
      const chainHeight =
          100 + PivxShieldedConfirmationPolicy.spendConfirmations - 1;
      expect(
        storage.spendableNotesAt(chainHeight: chainHeight).length,
        1,
      );

      final result = _transactionResult(txId: txId, spentNullifiers: ['n1']);
      wallet.reserveShieldedNotes(result.txId, result.spentNullifiers);

      var broadcastFailureCalled = false;
      final pending = PendingPivxShieldedTransaction(
        result: result,
        electrumClient: client,
        amount: 2000000,
        fee: result.fee,
        onBroadcastFailure: () => broadcastFailureCalled = true,
        // Mirrors the wallet's real onCommit wiring: storage takes over the
        // exclusion, then the in-memory reservation is released.
        onCommit: (_) async {
          await storage.markPendingSpentByNullifiers(
            result.spentNullifiers,
            result.txId,
          );
          wallet.releaseReservedShieldedNotes(result.txId);
        },
      );

      await pending.commit();

      expect(broadcastFailureCalled, isFalse);
      expect(wallet.reservedShieldedNullifiers, isEmpty);
      // Terminal pending-spent path unchanged: the note stays out of the
      // spendable set even though the in-memory reservation is gone.
      expect(storage.spendableNotesAt(chainHeight: chainHeight), isEmpty);
      expect(storage.pendingSpentNotes.map((n) => n.nullifier), ['n1']);
    });
  });

  group('transparent fee rate', () {
    test('uses PIVX fixed rates, not the zero electrum server rate', () {
      final wallet = testWallet(_FakeBroadcastElectrumClient(
        broadcastResponse: '',
      ));
      // Base feeRate reads _feeRates (0 for PIVX's server, no estimatefee); the
      // override must return PIVX's fixed rates so a transparent send is not a
      // rejected zero-fee tx.
      expect(wallet.feeRate(PivxTransactionPriority.slow), 10000);
      expect(wallet.feeRate(PivxTransactionPriority.medium), 20000);
      expect(wallet.feeRate(PivxTransactionPriority.fast), 50000);
      expect(
        wallet.feeAmountForPriority(PivxTransactionPriority.slow, 1, 2),
        greaterThan(0),
      );
    });
  });
}

SaplingTransactionResult _transactionResult({
  required String txId,
  required List<String> spentNullifiers,
}) {
  return SaplingTransactionResult(
    rawTx: Uint8List.fromList(const [0x03, 0x00]),
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

PivxWallet _testWallet({
  required Box<UnspentCoinsInfo> unspentCoinsInfo,
  required electrum.ElectrumClient electrumClient,
}) {
  const mnemonic =
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
  return PivxWallet(
    mnemonic: mnemonic,
    password: 'password',
    walletInfo: WalletInfo.external(
      id: 'pivx_reservation_test',
      name: 'pivx_reservation_test',
      type: WalletType.pivx,
      isRecovery: false,
      restoreHeight: 0,
      date: DateTime.fromMillisecondsSinceEpoch(0),
      dirPath: '',
      path: '',
      address: '',
    ),
    derivationInfo: DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/44'/119'/0'",
      scriptType: 'p2pkh',
    ),
    unspentCoinsInfo: unspentCoinsInfo,
    seedBytes: MnemonicBip39.toSeed(mnemonic),
    encryptionFileUtils: _FakeEncryptionFileUtils(),
    initialAddresses: [
      BitcoinAddressRecord(
        generateP2PKHAddress(
          hd: _testMainHd,
          index: 0,
          network: PivxNetwork.mainnet,
        ),
        index: 0,
        isHidden: false,
        type: P2pkhAddressType.p2pkh,
        network: null,
      ),
    ],
    initialBalance: ElectrumBalance(
      confirmed: Money.fromInt(7000, CryptoCurrency.pivx),
      unconfirmed: Money.fromInt(300, CryptoCurrency.pivx),
      frozen: Money.fromInt(9, CryptoCurrency.pivx),
      secondConfirmed: Money.fromInt(0, CryptoCurrency.pivx),
      secondUnconfirmed: Money.fromInt(0, CryptoCurrency.pivx),
    ),
    electrumClient: electrumClient,
  );
}

final _testAccountHd = Bip32Slip10Secp256k1.fromSeed(Uint8List(64));
final _testMainHd = _testAccountHd.childKey(Bip32KeyIndex(0));
