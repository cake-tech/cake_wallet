import 'dart:io';

import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_tari/tari_wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'mock/path_provider.dart';

Future<void> main() async {
  print(Directory.current);

  group("TariWalletService Tests", () {
    Hive.init('./test/data/db');
    late TariWalletService walletService;

    setUpAll(() async {
      PathProviderPlatform.instance = MockPathProviderPlatform();

      final Box<WalletInfo> walletInfoSource =
          await Hive.openBox('testWalletInfo');

      walletService = TariWalletService(walletInfoSource);
    });

    tearDownAll(() {
      Directory('./test/data').deleteSync(recursive: true);
    });

    group("Create wallet", () {
      test("Create Tari Wallet", () async {
        final credentials = _getTestCreateCredentials(name: 'Create Wallet');
        final wallet = await walletService.create(credentials);

        expect(wallet.seed.split(" ").length, 24);
      });
    });

    group("Restore wallet", () {
      test('Tari Seed', () async {
        final credentials = _getTestRestoreCredentials(
            name: 'Restore Wallet',
            mnemonic:
                'park snow bring damp venture palm rocket cactus hole hunt save broken swallow coach state relief census pride penalty sound jazz romance obvious canyon');

        final wallet = await walletService.restoreFromSeed(credentials);
        expect(wallet.walletAddresses.primaryAddress,
            '🌈🌊🏁🚲🍌😱💦🔫🍋📎👣🐛🌙🤖👀💻🌊🏰🏆🎷🤢🚜🎷🎯🍺👾🛵🐼🎰🍒🚽🔔🐑🎰🔨🦀🍣🍍🏭😇🎻🍀💨👖👛💐🔧🍐🎁🐯🏰🍚🌽🧢🎡🚂🎡🍩🐮🚢🚦💼🤠💍🤠🎓🔒');
      });
    });
  });
}

TariRestoreWalletFromSeedCredentials _getTestRestoreCredentials({
  required String name,
  required String mnemonic,
}) {
  final credentials = TariRestoreWalletFromSeedCredentials(
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

TariNewWalletCredentials _getTestCreateCredentials({
  required String name,
}) {
  final credentials = TariNewWalletCredentials(
    name: name,
    password: "test",
    passphrase: '',
  );

  credentials.walletInfo = WalletInfo.external(
    id: WalletBase.idFor(name, WalletType.tari),
    name: name,
    type: WalletType.tari,
    isRecovery: false,
    restoreHeight: credentials.height ?? 0,
    date: DateTime.now(),
    path: '',
    dirPath: '',
    address: '',
  );
  return credentials;
}
