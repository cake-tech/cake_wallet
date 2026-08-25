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
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/db/sqlite.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/payment_uris.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cw_pivx/src/pending_pivx_shielded_transaction.dart';
import 'package:cw_pivx/src/pivx_network.dart';
import 'package:cw_pivx/src/pivx_wallet.dart';
import 'package:cw_pivx/src/pivx_wallet_creation_credentials.dart';
import 'package:cw_pivx/src/sapling/sapling_factories.dart' as sapling;
import 'package:cw_pivx/src/sapling/sapling_note_storage.dart';
import 'package:convert/convert.dart' as convert;
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => Directory.systemTemp.path,
  );

  late Directory dbDir;
  late Directory hiveDir;
  late Box<UnspentCoinsInfo> unspentCoinsInfo;
  var dbInitialized = false;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    dbDir = await Directory.systemTemp.createTemp('pivx_restore_test_');
    hiveDir = await Directory.systemTemp.createTemp('pivx_hive_test_');
    databaseFactory = databaseFactoryFfi;
    await initDb(pathOverride: '${dbDir.path}/cake.db');
    CakeHive.init(hiveDir.path);
    if (!CakeHive.isAdapterRegistered(UnspentCoinsInfo.typeId)) {
      CakeHive.registerAdapter(UnspentCoinsInfoAdapter());
    }
    unspentCoinsInfo = await CakeHive.openBox<UnspentCoinsInfo>(
      '${UnspentCoinsInfo.boxName}_pivx_test',
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

  group('PivxNetwork', () {
    test('mainnet has correct prefixes', () {
      expect(PivxNetwork.mainnet.p2pkhNetVer, [30]);
      expect(PivxNetwork.mainnet.p2shNetVer, [13]);
      expect(PivxNetwork.mainnet.wifNetVer, [212]);
      expect(PivxNetwork.coinType, 119);
    });

    test('testnet has correct prefixes', () {
      expect(PivxNetwork.testnet.p2pkhNetVer, [139]);
      expect(PivxNetwork.testnet.p2shNetVer, [19]);
      expect(PivxNetwork.testnet.wifNetVer, [239]);
      expect(PivxNetwork.coinType, 119);
    });

    test('mainnet has correct network parameters', () {
      expect(PivxNetwork.defaultPort, 51472);
      expect(PivxNetwork.rpcPort, 51473);
      expect(PivxNetwork.coinbaseMaturity, 100);
      expect(PivxNetwork.targetBlockTime, 60);
      expect(PivxNetwork.minRelayTxFee, 10000);
    });

    test('isValidAddress validates correctly', () {
      // Valid P2PKH address (starts with D)
      expect(PivxNetwork.isValidAddress('D'), false); // Too short

      // Valid staking address (starts with S)
      // Note: Full validation requires proper base58 check

      // Invalid addresses
      expect(PivxNetwork.isValidAddress(''), false);
      expect(PivxNetwork.isValidAddress('1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2'),
          false);
    });
  });

  group('PivxRestoreWalletFromSeedCredentials', () {
    test('preserves restore height for transparent and shielded rescans', () {
      final credentials = PivxRestoreWalletFromSeedCredentials(
        name: 'restore-height',
        password: 'password',
        mnemonic:
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
        height: 2700500,
      );

      expect(credentials.height, 2700500);
    });
  });

  group('PIVX shielded sync errors', () {
    test('explains missing v1 global output position support', () {
      final message = PivxWalletBase.sanitizeShieldSyncError(Exception(
          'PIVX Sapling sync cannot start after activation without a persisted tree cursor or server global output positions'));

      expect(
        message,
        'PIVX Sapling sync requires a Sapling v1 ElectrumX node with global output positions. Switch nodes and retry.',
      );
    });

    test('keeps unknown shielded sync errors generic', () {
      final message = PivxWalletBase.sanitizeShieldSyncError(
        Exception('some unexpected sanitized failure'),
      );

      expect(
        message,
        'PIVX Sapling sync failed. Check node capability and retry.',
      );
    });

    test('explains incomplete advertised v1 support', () {
      final message = PivxWalletBase.sanitizeShieldSyncError(Exception(
          'PIVX Sapling node advertises v1 but is missing required release contract features'));

      expect(
        message,
        'Current PIVX node advertises incomplete Sapling v1 support. Switch to a fully upgraded Sapling v1 node and retry.',
      );
    });

    test('explains retryable incomplete block ranges', () {
      final message = PivxWalletBase.sanitizeShieldSyncError(Exception(
          'PIVX Sapling block range 5441053-5441053 failed after 3 attempts: PIVX Sapling get_block_range returned an incomplete range for 5441053-5441053'));

      expect(
        message,
        'Current PIVX node did not return a complete Sapling block range yet. Wait for the node to finish indexing and retry.',
      );
    });
  });

  group('PIVX restore discovery', () {
    test('extends transparent receive batches until a full unused gap is found',
        () async {
      final initialReceiveAddresses =
          List.generate(22, (index) => _addressRecord(index: index));
      final walletAddresses = _TestElectrumWalletAddresses(
          initialAddresses: initialReceiveAddresses);
      final queriedIndexes = <int>[];

      await walletAddresses.discoverAddresses(
        initialReceiveAddresses,
        false,
        (address) async {
          queriedIndexes.add(address.index);
          return {41, 61}.contains(address.index) ? address.address : null;
        },
        type: P2pkhAddressType.p2pkh,
        isLegacyDerivation: false,
      );

      final receiveAddresses = walletAddresses.allAddresses
          .where((address) =>
              !address.isHidden && address.type == P2pkhAddressType.p2pkh)
          .toList();
      expect(receiveAddresses.length, 82);
      expect(receiveAddresses.map((address) => address.index),
          containsAll([41, 61, 81]));
      expect(queriedIndexes.first, 22);
      expect(queriedIndexes.last, 81);
    });

    test('extends transparent change batches until a full unused gap is found',
        () async {
      final initialChangeAddresses = List.generate(
          17, (index) => _addressRecord(index: index, isHidden: true));
      final walletAddresses = _TestElectrumWalletAddresses(
          initialAddresses: initialChangeAddresses);
      final queriedIndexes = <int>[];

      await walletAddresses.discoverAddresses(
        initialChangeAddresses,
        true,
        (address) async {
          queriedIndexes.add(address.index);
          return {36, 56}.contains(address.index) ? address.address : null;
        },
        type: P2pkhAddressType.p2pkh,
        isLegacyDerivation: false,
      );

      final changeAddresses = walletAddresses.allAddresses
          .where((address) =>
              address.isHidden && address.type == P2pkhAddressType.p2pkh)
          .toList();
      expect(changeAddresses.length, 77);
      expect(changeAddresses.map((address) => address.index),
          containsAll([36, 56, 76]));
      expect(queriedIndexes.first, 17);
      expect(queriedIndexes.last, 76);
    });

    test('advances shielded receive index past observed diversified recipients',
        () async {
      final nextIndex = await PivxWalletBase
          .nextShieldedDiversifierIndexAfterObservedAddresses(
        currentNextDiversifierIndex: 1,
        observedAddressHexes: {'aa', 'cc'},
        deriveAddressHex: (index) async => {
          2: 'AA',
          9: 'bb',
          27: 'cc',
        }[index],
        scanLimit: 50,
      );

      expect(nextIndex, 28);
    });

    test('does not move shielded receive index backwards or past scan limit',
        () async {
      final nextIndex = await PivxWalletBase
          .nextShieldedDiversifierIndexAfterObservedAddresses(
        currentNextDiversifierIndex: 10,
        observedAddressHexes: {'aa', 'late'},
        deriveAddressHex: (index) async => {
          2: 'aa',
          75: 'late',
        }[index],
        scanLimit: 50,
      );

      expect(nextIndex, 10);
    });
  });

  group('PIVX transparent balance response handling', () {
    test('preserves previous balance and marks lost connection on null confirmed',
        () async {
      final wallet = _testWallet(
        unspentCoinsInfo: unspentCoinsInfo,
        electrumClient: _FakeElectrumClient([
          {'confirmed': null, 'unconfirmed': 123},
        ]),
      );
      wallet.shieldedBalance = 4444;
      wallet.pendingShieldedBalance = 55;

      final balance = await wallet.fetchBalances();

      expect(balance.confirmed.amount.toInt(), 7000);
      expect(balance.unconfirmed.amount.toInt(), 300);
      expect(balance.frozen.amount.toInt(), 9);
      expect(balance.secondConfirmed!.amount.toInt(), 4444);
      expect(balance.secondUnconfirmed!.amount.toInt(), 55);
      expect(wallet.syncStatus, isA<LostConnectionSyncStatus>());
    });

    test(
        'preserves previous balance and marks lost connection on null unconfirmed',
        () async {
      final wallet = _testWallet(
        unspentCoinsInfo: unspentCoinsInfo,
        electrumClient: _FakeElectrumClient([
          {'confirmed': 123, 'unconfirmed': null},
        ]),
      );
      wallet.shieldedBalance = 2222;
      wallet.pendingShieldedBalance = 33;

      final balance = await wallet.fetchBalances();

      expect(balance.confirmed.amount.toInt(), 7000);
      expect(balance.unconfirmed.amount.toInt(), 300);
      expect(balance.frozen.amount.toInt(), 9);
      expect(balance.secondConfirmed!.amount.toInt(), 2222);
      expect(balance.secondUnconfirmed!.amount.toInt(), 33);
      expect(wallet.syncStatus, isA<LostConnectionSyncStatus>());
    });
  });

  group('PIVX shielded sync status', () {
    test('clears shielded block progress when shielded sync completes', () {
      final syncingStatus = PivxWalletBase.syncStatusForShieldProgress(
        sapling.SyncStatus(
          lastSyncedBlock: 5440918,
          chainTip: 5440973,
          blocksRemaining: 56,
          progress: 0.9,
        ),
      );
      final completeStatus = PivxWalletBase.syncStatusForShieldProgress(
        sapling.SyncStatus(
          lastSyncedBlock: 5440973,
          chainTip: 5440973,
          blocksRemaining: 0,
          progress: 1.0,
        ),
      );
      final initialStatus = PivxWalletBase.syncStatusForShieldProgress(
        sapling.SyncStatus(
          lastSyncedBlock: 5440418,
          chainTip: 5440418,
          blocksRemaining: 0,
          progress: 0.0,
        ),
      );

      expect(syncingStatus, isA<SyncingSyncStatus>());
      expect((syncingStatus as SyncingSyncStatus).blocksLeft, 56);
      expect(completeStatus, isA<SyncedSyncStatus>());
      expect(initialStatus, isNull);
    });
  });

  group('PIVX shielded header sync cadence', () {
    test('uses the PIVX 60 second target block time as sync throttle', () {
      final now = DateTime.utc(2026, 6, 5, 12);

      expect(
        PivxWalletBase.shouldRunShieldedHeaderSync(
          lastSyncAt: null,
          now: now,
        ),
        isTrue,
      );
      expect(
        PivxWalletBase.shouldRunShieldedHeaderSync(
          lastSyncAt: now.subtract(
            const Duration(seconds: PivxNetwork.shieldedHeaderSyncMinInterval - 1),
          ),
          now: now,
        ),
        isFalse,
      );
      expect(
        PivxWalletBase.shouldRunShieldedHeaderSync(
          lastSyncAt: now.subtract(
            const Duration(seconds: PivxNetwork.shieldedHeaderSyncMinInterval),
          ),
          now: now,
        ),
        isTrue,
      );
    });
  });

  group('PIVX shielded receive address selection', () {
    test('restores latest generated shielded address as current', () {
      final current = PivxWalletBase.currentShieldedReceiveAddressFromStorage([
        StoredShieldedAddress(
          diversifierIndex: 1,
          address: 'ps1generated1',
          label: 'first',
        ),
        StoredShieldedAddress(
          diversifierIndex: 4,
          address: 'ps1generated4',
          label: 'latest',
        ),
        StoredShieldedAddress(
          diversifierIndex: 2,
          address: 'ps1generated2',
          label: 'middle',
        ),
      ]);

      expect(current.address, equals('ps1generated4'));
      expect(current.label, equals('latest'));
    });

    test('fails closed when no stored generated shielded addresses exist', () {
      expect(
        () => PivxWalletBase.currentShieldedReceiveAddressFromStorage([]),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('PIVX shielded broadcast diagnostics', () {
    test('summarizes PIVX Sapling transaction shape without raw shielded data',
        () {
      final summary = PivxShieldedTransactionDebugSummary.fromHex(
        _fakeShieldedTransactionHex(
          valueBalance: 1417000,
          spendCount: 1,
          outputCount: 2,
        ),
      );

      expect(summary.version, 3);
      expect(summary.type, 0);
      expect(summary.transparentInputCount, 0);
      expect(summary.transparentOutputCount, 0);
      expect(summary.hasSaplingData, true);
      expect(summary.valueBalance, 1417000);
      expect(summary.shieldedSpendCount, 1);
      expect(summary.shieldedOutputCount, 2);
      expect(summary.hasBindingSignature, true);
      expect(summary.parseError, isNull);
      expect(summary.toLogString(), contains('shielded_spends=1'));
      expect(summary.toLogString(), isNot(contains('03000000')));
    });

    test('maps Core Sapling rejection strings to actionable messages', () {
      final spendMessage =
          PendingPivxShieldedTransaction.sanitizeBroadcastError(
        'sendrawtransaction RPC error: bad-txns-sapling-spend-description-invalid',
      );
      final requirementMessage =
          PendingPivxShieldedTransaction.sanitizeBroadcastError(
        'bad-txns-shielded-requirements-not-met',
      );

      expect(spendMessage, contains('spend proof/signature validation failed'));
      expect(
        spendMessage,
        contains('bad-txns-sapling-spend-description-invalid'),
      );
      expect(
        requirementMessage,
        contains('anchor or nullifier requirements were not met'),
      );
    });
  });
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
      id: 'pivx_balance_test',
      name: 'pivx_balance_test',
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
    initialAddresses: [_addressRecord(index: 0)],
    initialBalance: ElectrumBalance(
      confirmed: Money.fromInt(7000, CryptoCurrency.pivx),
      unconfirmed: Money.fromInt(300, CryptoCurrency.pivx),
      frozen: Money.fromInt(9, CryptoCurrency.pivx),
      secondConfirmed: Money.fromInt(9999, CryptoCurrency.pivx),
      secondUnconfirmed: Money.fromInt(88, CryptoCurrency.pivx),
    ),
    electrumClient: electrumClient,
  );
}

class _FakeElectrumClient extends electrum.ElectrumClient {
  _FakeElectrumClient(this.responses);

  final List<Map<String, dynamic>> responses;
  int _nextResponse = 0;

  @override
  Future<Map<String, dynamic>> getBalance(
    String scriptHash, {
    bool throwOnError = false,
  }) async {
    return responses[_nextResponse++];
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

class _TestElectrumWalletAddresses extends ElectrumWalletAddressesBase {
  _TestElectrumWalletAddresses({
    required List<BitcoinAddressRecord> initialAddresses,
  }) : super(
          WalletInfo.external(
            id: 'pivx_restore_discovery_test',
            name: 'pivx_restore_discovery_test',
            type: WalletType.pivx,
            isRecovery: true,
            restoreHeight: 0,
            date: DateTime.fromMillisecondsSinceEpoch(0),
            dirPath: '',
            path: '',
            address: '',
          ),
          mainHdByType: {P2pkhAddressType.p2pkh: _testMainHd},
          sideHdByType: {P2pkhAddressType.p2pkh: _testSideHd},
          legacyMainHd: _testMainHd,
          legacySideHd: _testSideHd,
          network: PivxNetwork.mainnet,
          isHardwareWallet: false,
          initialAddresses: initialAddresses,
          initialAddressPageType: P2pkhAddressType.p2pkh,
        );

  @override
  String getAddress({
    required int index,
    required Bip32Slip10Secp256k1 hd,
    BitcoinAddressType? addressType,
  }) {
    return _fakeAddress(
      index: index,
      isHidden: identical(hd, _testSideHd),
    );
  }

  @override
  PaymentURI getPaymentUri(String amount) =>
      PivxURI(amount: amount, address: address);
}

BitcoinAddressRecord _addressRecord({
  required int index,
  bool isHidden = false,
}) {
  return BitcoinAddressRecord(
    _fakeAddress(index: index, isHidden: isHidden),
    index: index,
    isHidden: isHidden,
    type: P2pkhAddressType.p2pkh,
    network: null,
  );
}

String _fakeAddress({
  required int index,
  required bool isHidden,
}) {
  return generateP2PKHAddress(
    hd: isHidden ? _testSideHd : _testMainHd,
    index: index,
    network: PivxNetwork.mainnet,
  );
}

String _fakeShieldedTransactionHex({
  required int valueBalance,
  required int spendCount,
  required int outputCount,
}) {
  final bytes = <int>[
    0x03, 0x00, // nVersion = Sapling
    0x00, 0x00, // nType = Normal
    0x00, // transparent vin count
    0x00, // transparent vout count
    0x00, 0x00, 0x00, 0x00, // nLockTime
    0x01, // Optional<SaplingTxData> present
    ..._int64Le(valueBalance),
    spendCount,
    ...List<int>.filled(spendCount * 384, 0),
    outputCount,
    ...List<int>.filled(outputCount * 948, 0),
    ...List<int>.filled(64, 0),
  ];

  return convert.hex.encode(bytes);
}

List<int> _int64Le(int value) {
  final bytes = Uint8List(8);
  var remaining = value;
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = remaining & 0xff;
    remaining >>= 8;
  }
  return bytes;
}

final _testAccountHd = Bip32Slip10Secp256k1.fromSeed(Uint8List(64));
final _testMainHd = _testAccountHd.childKey(Bip32KeyIndex(0));
final _testSideHd = _testAccountHd.childKey(Bip32KeyIndex(1));
