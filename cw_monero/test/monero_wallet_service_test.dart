import 'dart:io';

import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_monero/monero_wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'mock/path_provider.dart';
import 'utils/setup_monero_c.dart';

Future<void> main() async {
  Hive.init('./test/data/db');
  final Box<WalletInfo> walletInfoSource = await Hive.openBox('testWalletInfo');
  final Box<UnspentCoinsInfo> unspentCoinsInfoSource =
      await Hive.openBox('testUnspentCoinsInfo');

  group("Restore wallet", () {
    late MoneroWalletService walletService;
    late File moneroCBinary;

    setUp(() {
      PathProviderPlatform.instance = MockPathProviderPlatform();
      walletService =
          MoneroWalletService(walletInfoSource, unspentCoinsInfoSource);

      moneroCBinary = getMoneroCBinary().copySync(moneroCBinaryName);
    });

    tearDown(() {
      Directory('./test/data').deleteSync(recursive: true);
      moneroCBinary.deleteSync();
    });

    test('Legacy Seed', () async {
      final credentials = MoneroRestoreWalletFromSeedCredentials(
          name: 'Test Wallet LS',
          mnemonic:
              'ability pockets lordship tomorrow gypsy match neutral uncle avatar betting bicycle junk unzip pyramid lynx mammal edgy empty uneven knowledge juvenile wiring paradise psychic betting',
          passphrase: '',
          password: "test");

      credentials.walletInfo = WalletInfo.external(
        id: WalletBase.idFor('Test Wallet LS', WalletType.monero),
        name: 'Test Wallet LS',
        type: WalletType.monero,
        isRecovery: true,
        restoreHeight: credentials.height ?? 0,
        date: DateTime.now(),
        path: '',
        dirPath: '',
        address: '',
      );

      final wallet = await walletService.restoreFromSeed(credentials);
      expect(wallet.walletAddresses.primaryAddress,
          '48tLyQXpcwt8w6uKHyb5Zs3vdnoDWAEKFQr1c198o7aX9dBzXP3BTSMVsDiuH3ozDCNqwojb4vNeQZf7xg6URimDLaNtGSN');
    });

    test('Bip39 Seed', () async {
      final credentials = _getTestCredentials(
          name: 'Test Wallet BS',
          mnemonic:
              'color ranch color remove subway public water embrace before begin liberty fault');

      final wallet = await walletService.restoreFromSeed(credentials);
      expect(wallet.walletAddresses.primaryAddress,
          '49MggvPosJugF8Zq7WAKbsSchz6vbyL6YiUxM4ryfGQDXphs6wiWiXLFWCSshnLPcceGTWUaKfWWMHQAAKESV3TQJVQsL9a');
    });
  }, skip: true);
}

MoneroRestoreWalletFromSeedCredentials _getTestCredentials({
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
