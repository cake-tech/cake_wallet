import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/bitcoin_mnemonics_bip39.dart';
import 'package:cw_bitcoin/electrum.dart' as electrum;
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/db/sqlite.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_bitcoin/bitcoin_transaction_credentials.dart';
import 'package:cw_bitcoin/pending_bitcoin_transaction.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_pivx/src/sapling/sapling_constants.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cw_pivx/src/pivx_network.dart';
import 'package:cw_pivx/src/pivx_transaction_priority.dart';
import 'package:cw_pivx/src/pivx_wallet.dart';
import 'package:cw_pivx/src/sapling/sapling_note_storage.dart';
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
    });

    test('isValidAddress validates correctly', () {
      // Valid P2PKH address (starts with D)
      expect(PivxNetwork.isValidAddress('D'), false); // Too short

      // EXM is 36 chars (3-byte prefix); the old 35 cap rejected every real one.
      expect(
          PivxNetwork.isValidAddress('EXMVfkJoGAcaCDzSNqNVurYKgb3BFDEVAkGQ'),
          true);
      expect(
          PivxNetwork.isValidAddress('EXMVfkJoGAcaCDzSNqNVurYKgb3BFDEVAkG'),
          false);
      // Cold-staking P2CS: no builder here can pay it.
      expect(
          PivxNetwork.isValidAddress('SNvRfEBuZbxk9vBRdSMDpmMFsr4uVnbFmU'),
          false);
      expect(PivxNetwork.isValidAddress('6Z3tiXrVsu9fmQ7sd4kniTZYzWzmcohiiv'),
          true);

      // Invalid addresses
      expect(PivxNetwork.isValidAddress(''), false);
      expect(PivxNetwork.isValidAddress('1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2'),
          false);
    });
  });

  group('PIVX transparent derivation', () {
    test('receive and change branches use SLIP-44 coin type 119', () {
      final wallet = _testWallet(
        unspentCoinsInfo: unspentCoinsInfo,
        electrumClient: _FakeElectrumClient([]),
      );
      const type = P2pkhAddressType.p2pkh;
      // abandon..about at m/44'/119'/0'/{0,1}/0. The Bitcoin coin type this
      // wallet once fell back to gives DQyGohGYpVsq1oyLh35PpRz5kf3qwZonzL.
      expect(
        generateP2PKHAddress(
            hd: wallet.mainHdByTypeAndAccount[0]![type]!, index: 0, network: PivxNetwork.mainnet),
        'DPo9TNvPwy2ZfmVM3CRCxbBvh6NojguWXJ',
      );
      expect(
        generateP2PKHAddress(
            hd: wallet.sideHdByTypeAndAccount[0]![type]!, index: 0, network: PivxNetwork.mainnet),
        'D7JWR2yAaeKiWbq93CYaasrQt494NX35iQ',
      );
    });

    test('parses exchange and P2SH recipients the Dogecoin branch cannot', () {
      final wallet = _testWallet(
        unspentCoinsInfo: unspentCoinsInfo,
        electrumClient: _FakeElectrumClient([]),
      );
      // All three carry hash160 cca48133ff2474bf4d9922e0cd8f72057fe47e5a.
      const hash = 'cca48133ff2474bf4d9922e0cd8f72057fe47e5a';
      final p2sh = wallet.addressFromString('6Z3tiXrVsu9fmQ7sd4kniTZYzWzmcohiiv');
      expect(p2sh, isA<P2shAddress>());
      expect(BytesUtils.toHexString(p2sh.toScriptPubKey().toBytes()),
          'a914${hash}87');
      final exm =
          wallet.addressFromString('EXMVfkJoGAcaCDzSNqNVurYKgb3BFDEVAkGQ');
      expect(BytesUtils.toHexString(exm.toScriptPubKey().toBytes()),
          'e076a914${hash}88ac');
      final p2pkh =
          wallet.addressFromString('DPo9TNvPwy2ZfmVM3CRCxbBvh6NojguWXJ');
      expect(p2pkh, isA<P2pkhAddress>());
      expect(BytesUtils.toHexString(p2pkh.toScriptPubKey().toBytes()),
          '76a914${hash}88ac');
    });

    test('signs with the DarkNet magic and the key of the claimed branch',
        () async {
      final wallet = _testWallet(
        unspentCoinsInfo: unspentCoinsInfo,
        electrumClient: _FakeElectrumClient([]),
      );
      const type = P2pkhAddressType.p2pkh;
      const receive = 'DPo9TNvPwy2ZfmVM3CRCxbBvh6NojguWXJ';
      const change = 'D7JWR2yAaeKiWbq93CYaasrQt494NX35iQ';
      wallet.walletAddresses.addAddresses([
        BitcoinAddressRecord(receive,
            index: 0, isHidden: false, type: type, network: null),
        BitcoinAddressRecord(change,
            index: 0, isHidden: true, type: type, network: null),
      ]);
      const message = 'PIVX';

      final signature = await wallet.signMessage(message, address: receive);
      // RFC6979 makes this stable. Recovered to the address above with an
      // independent secp256k1 implementation under the DarkNet magic only;
      // check on a node with: pivx-cli verifymessage <receive> <sig> PIVX
      expect(signature,
          'ILqVUqPNMFN6LRdhmxFJs8OkgT0os+V4dfbcRAp7qWjdDf0KEcP4oI2w1QU5pB6aIVhjBFYXE+T1lBPj5fdv9KM=');
      expect(await wallet.verifyMessage(message, signature, address: receive),
          isTrue);

      // The Bitcoin magic must not verify, or pivx-cli verifymessage would
      // reject what this wallet accepts.
      final priv = ECPrivate.fromHex(wallet.mainHdByTypeAndAccount[0]![type]!
          .childKey(Bip32KeyIndex(0))
          .privateKey
          .privKey
          .toHex());
      final bitcoinMagic = base64Encode(
          BytesUtils.fromHexString(priv.signMessage(utf8.encode(message))));
      expect(bitcoinMagic, isNot(signature));
      expect(
          await wallet.verifyMessage(message, bitcoinMagic, address: receive),
          isFalse);

      // Change addresses sign with the change-branch key, not the receive one.
      final changeSignature = await wallet.signMessage(message, address: change);
      expect(
          await wallet.verifyMessage(message, changeSignature, address: change),
          isTrue);
    });
  });

  group('PIVX restore discovery', () {

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

    test('a failed batch on a live socket keeps the status', () async {
      final wallet = _testWallet(
        unspentCoinsInfo: unspentCoinsInfo,
        electrumClient: _BusyElectrumClient(),
      );
      wallet.syncStatus = SyncedSyncStatus();

      final balance = await wallet.fetchBalances();

      expect(balance.confirmed.amount.toInt(), 7000);
      expect(balance.unconfirmed.amount.toInt(), 300);
      // A timeout behind a dense Sapling range is not a dead connection.
      expect(wallet.syncStatus, isA<SyncedSyncStatus>());
    });

    test('a partial miss keeps that address\'s confirmed and unconfirmed apart',
        () async {
      final wallet = _testWallet(
        unspentCoinsInfo: unspentCoinsInfo,
        electrumClient: _FakeElectrumClient([
          {'confirmed': 100, 'unconfirmed': 50},
          {'confirmed': 7, 'unconfirmed': 3},
          {'confirmed': 100, 'unconfirmed': 50},
          <String, dynamic>{},
        ]),
      );
      wallet.walletAddresses.addAddresses([_addressRecord(index: 1)]);

      final first = await wallet.fetchBalances();
      expect(first.confirmed.amount.toInt(), 107);
      expect(first.unconfirmed.amount.toInt(), 53);

      // Falls back to its last split, not the folded record that moves 3 into
      // confirmed.
      final second = await wallet.fetchBalances();
      expect(second.confirmed.amount.toInt(), 107);
      expect(second.unconfirmed.amount.toInt(), 53);
      expect(wallet.syncStatus, isNot(isA<LostConnectionSyncStatus>()));
    });
  });

  group('PIVX transparent unspent fetch', () {
    test('offline reads as unknown, never as no coins', () async {
      final wallet = _testWallet(
        unspentCoinsInfo: unspentCoinsInfo,
        electrumClient: _FakeElectrumClient([]),
      );
      final results = await wallet
          .fetchUnspentsForAddresses([_addressRecord(index: 0)]);
      expect(results, [null]);
    });

    test('a short batch or an error item keeps that address\'s known coins',
        () async {
      final client = _BatchFakeClient([
        <dynamic>[],
        {'code': -32600, 'message': 'busy'},
      ]);
      final wallet = _testWallet(
        unspentCoinsInfo: unspentCoinsInfo,
        electrumClient: client,
      );
      final erroring = _addressRecord(index: 1);
      final missing = _addressRecord(index: 2);
      final knownCoin = BitcoinUnspent(erroring, 'aa' * 32, 5000, 0);
      wallet.unspentCoins = [knownCoin];

      final results = await wallet
          .fetchUnspentsForAddresses([_addressRecord(index: 0), erroring, missing]);
      // An empty list is a real "no coins". A failed item must not read as
      // empty, or base drops the address's coins and coin-control rows.
      expect(results[0], isEmpty);
      expect(results[1], [knownCoin]);
      expect(results[2], isEmpty); // nothing known for it either
      expect(results.every((r) => r != null), isTrue);
    });

    test('an EXM send pays min relay on its serialized size', () async {
      final wallet = _testWallet(
        unspentCoinsInfo: unspentCoinsInfo,
        electrumClient: _FakeElectrumClient([]),
      );
      wallet.unspentCoins = [
        BitcoinUnspent(_addressRecord(index: 0), 'b' * 64, 50000000, 0)
          ..confirmations = 6,
      ];
      final pending = await wallet.createTransaction(BitcoinTransactionCredentials(
        [
          OutputInfo(
            address: 'EXMQ3t6kSpkdbLj714JheTo4sSsZ1Tiw7Dne',
            sendAll: false,
            isParsedAddress: false,
            cryptoAmount: Money.fromInt(1000000, CryptoCurrency.pivx),
          ),
        ],
        priority: PivxTransactionPriority.slow,
        coinTypeToSpendFrom: UnspentCoinType.transparent,
      )) as PendingBitcoinTransaction;
      expect(pending.hex, contains('e076a914')); // OP_EXCHANGEADDR script
      // PIVX Core CFeeRate::GetFee: minRelayTxFee * serialized size / 1000.
      final size = pending.hex.length ~/ 2;
      expect(pending.fee.amount.toInt(),
          greaterThanOrEqualTo(PivxFeePolicy.minRelayFeePerKb * size ~/ 1000));
    });

    test('changeless selection prices inputs at the PIVX rate', () async {
      final wallet = _testWallet(
        unspentCoinsInfo: unspentCoinsInfo,
        electrumClient: _FakeElectrumClient([]),
      );
      const amount = 1000000;
      // 10 sat/byte: target = amount + (10 + 34) * 10, input cost 148 * 10.
      // 1000 over target + cost, inside the 5460 dust window: changeless.
      const exact = amount + 440 + 1480 + 1000;
      final recipient = _fakeAddress(index: 7, isHidden: false);
      // Selection order is random per coin, so 9 decoys would win the draw ~90%
      // of the time; 8 rounds make a sat/vB regression fail at 1 - 1e-8.
      for (var round = 0; round < 8; round++) {
        wallet.unspentCoins = [
          for (var i = 0; i < 9; i++)
            BitcoinUnspent(_addressRecord(index: 0), '$round$i'.padLeft(64, 'a'),
                5000000, 0)
              ..confirmations = 6,
          BitcoinUnspent(_addressRecord(index: 0), '$round'.padLeft(64, 'e'),
              exact, 0)
            ..confirmations = 6,
        ];
        final outputs = [
          BitcoinOutput(
            address: wallet.addressFromString(recipient),
            value: BigInt.from(amount),
          ),
        ];
        final tx = await wallet.estimateTxForAmount(
          Money.fromInt(amount, CryptoCurrency.pivx),
          outputs,
          List.of(outputs),
          PivxTransactionPriority.slow.feeRate,
        );
        expect(tx.utxos.map((u) => u.utxo.value.toInt()), [exact]);
        expect(tx.hasChange, isFalse);
      }
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

  // fetchBalances always batches; one queued response per scripthash, in order.
  @override
  Future<Map<String, Map<String, dynamic>>> getBatchBalance(
    List<String> scriptHashes, {
    int timeout = 10000,
    bool keepIndexes = false,
  }) async {
    return {for (final sh in scriptHashes) sh: responses[_nextResponse++]};
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

final _testAccountHd = Bip32Slip10Secp256k1.fromSeed(Uint8List(64));
final _testMainHd = _testAccountHd.childKey(Bip32KeyIndex(0));
final _testSideHd = _testAccountHd.childKey(Bip32KeyIndex(1));

// Connected, answers every batch with a fixed reply list and the tip at 100.
class _BatchFakeClient extends electrum.ElectrumClient {
  _BatchFakeClient(this.reply);

  final List<dynamic> reply;

  @override
  bool get isConnected => true;

  @override
  Future<List<dynamic>> callBatchWithTimeout({
    required String method,
    required List<List<Object>> paramsList,
    int timeout = 10000,
    bool keepIndexes = false,
  }) async =>
      reply;

  @override
  Future<int?> getCurrentBlockChainTip() async => 100;
}

class _BusyElectrumClient extends electrum.ElectrumClient {
  @override
  bool get isConnected => true;

  @override
  Future<Map<String, Map<String, dynamic>>> getBatchBalance(
    List<String> scriptHashes, {
    int timeout = 10000,
    bool keepIndexes = false,
  }) =>
      throw TimeoutException('busy behind a Sapling range');
}
