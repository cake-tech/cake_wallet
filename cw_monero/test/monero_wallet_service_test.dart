import 'dart:io';

import 'package:cw_core/db/sqlite.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_monero/monero_wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'mock/path_provider.dart';
import 'utils/setup_monero_c.dart';

Future<void> main() async {
  group("MoneroWalletService Tests", () {
    late MoneroWalletService walletService;
    late File moneroCBinary;

    setUpAll(() async {
      databaseFactory = databaseFactoryFfi;
      await initDb(pathOverride: './test/data/db');
      Hive.init('./test/data/db');
      PathProviderPlatform.instance = MockPathProviderPlatform();

      final Box<UnspentCoinsInfo> unspentCoinsInfoSource =
          await Hive.openBox('testUnspentCoinsInfo');

      walletService = MoneroWalletService(unspentCoinsInfoSource);
      moneroCBinary = getMoneroCBinary().copySync(moneroCBinaryName);
    });

    tearDownAll(() {
      Directory('./test/data').deleteSync(recursive: true);
      moneroCBinary.deleteSync();
    });

    group("Create wallet", () {
      test("Create Legacy Wallet", () async {
        final credentials = _getTestCreateCredentials(
            name: 'Create Wallet LS',
            language: 'English',
            seedType: MoneroSeedType.legacy);
        final wallet = await walletService.create(credentials);

        expect(wallet.seed.split(" ").length, 25);
        expect(wallet.restoreHeight, greaterThan(3000000));
      });

      test("Create Polyseed Wallet", () async {
        final credentials = _getTestCreateCredentials(
            name: 'Create Wallet PS',
            language: 'English',
            seedType: MoneroSeedType.polyseed);
        final wallet = await walletService.create(credentials);

        expect(wallet.seed.split(" ").length, 16);
        expect(wallet.restoreHeight, greaterThan(3000000));
      });

      test("Create Bip39 Wallet", () async {
        final credentials = _getTestCreateCredentials(
            name: 'Create Wallet BS',
            language: 'English',
            seedType: MoneroSeedType.bip39);
        final wallet = await walletService.create(credentials);

        expect(wallet.seed.split(" ").length, 12);
        expect(wallet.restoreHeight, greaterThan(3000000));
      });
    });

    group("Restore wallet", () {
      test('Legacy Seed', () async {
        final credentials = _getTestRestoreCredentials(
          name: 'Test Wallet LS',
          mnemonic:
              'ability pockets lordship tomorrow gypsy match neutral uncle avatar betting bicycle junk unzip pyramid lynx mammal edgy empty uneven knowledge juvenile wiring paradise psychic betting',
        );

        final wallet = await walletService.restoreFromSeed(credentials);
        expect(wallet.walletAddresses.primaryAddress,
            '48tLyQXpcwt8w6uKHyb5Zs3vdnoDWAEKFQr1c198o7aX9dBzXP3BTSMVsDiuH3ozDCNqwojb4vNeQZf7xg6URimDLaNtGSN');
      });

      test('Bip39 Seed', () async {
        final credentials = _getTestRestoreCredentials(
            name: 'Test Wallet BS',
            mnemonic:
                'color ranch color remove subway public water embrace before begin liberty fault');

        final wallet = await walletService.restoreFromSeed(credentials);
        expect(wallet.walletAddresses.primaryAddress,
            '49MggvPosJugF8Zq7WAKbsSchz6vbyL6YiUxM4ryfGQDXphs6wiWiXLFWCSshnLPcceGTWUaKfWWMHQAAKESV3TQJVQsL9a');
      });
    });
  });
}

MoneroRestoreWalletFromSeedCredentials _getTestRestoreCredentials({
  required String name,
  required String mnemonic,
}) {
  final credentials = MoneroRestoreWalletFromSeedCredentials(
      name: name, mnemonic: mnemonic, passphrase: '', password: "test");

  credentials.walletInfo = WalletInfo.external(
    id: WalletBase.idFor(name, WalletType.monero),
    name: name,
    type: WalletType.monero,
    isRecovery: true,
    restoreHeight: credentials.height ?? 0,
    date: DateTime.now(),
    path: '',
    dirPath: '',
    address: '',
  );
  return credentials;
}

MoneroNewWalletCredentials _getTestCreateCredentials({
  required String name,
  required String language,
  required MoneroSeedType seedType,
  String? mnemonic,
}) {
  final credentials = MoneroNewWalletCredentials(
    name: name,
    language: language,
    seedType: seedType,
    password: "test",
    mnemonic: mnemonic,
    passphrase: '',
  );

  credentials.walletInfo = WalletInfo.external(
    id: WalletBase.idFor(name, WalletType.monero),
    name: name,
    type: WalletType.monero,
    isRecovery: false,
    restoreHeight: credentials.height ?? 0,
    date: DateTime.now(),
    path: '',
    dirPath: '',
    address: '',
  );
  return credentials;
}
