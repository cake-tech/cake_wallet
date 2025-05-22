import 'package:flutter_test/flutter_test.dart';
import 'package:cw_digibyte/cw_digibyte.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:hive/hive.dart';
import 'package:cw_core/crypto_currency.dart';

void main() {
  group('DigibyteWallet', () {
    setUp(() async {
      Hive.init('./test/data/db');
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
    });

    test('Create wallet and check initial balance', () async {
      final walletInfoBox = await Hive.openBox<WalletInfo>('walletInfo');
      final unspentCoinsBox = await Hive.openBox<UnspentCoinsInfo>('unspentCoins');

      final walletInfo = WalletInfo.external(
        id: WalletBase.idFor('test_wallet', WalletType.digibyte),
        name: 'test_wallet',
        type: WalletType.digibyte,
        isRecovery: false,
        restoreHeight: 0,
        date: DateTime.now(),
        path: '',
        dirPath: '',
        address: '',
      );

      final wallet = await DigibyteWallet.create(
        mnemonic: 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
        password: 'test',
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsBox,
        encryptionFileUtils: encryptionFileUtilsFor(true),
      );

      expect(wallet.walletInfo.type, WalletType.digibyte);
      expect(wallet.balance[CryptoCurrency.digibyte]?.confirmed, 0);
      expect(wallet.balance[CryptoCurrency.digibyte]?.unconfirmed, 0);
      await walletInfoBox.close();
      await unspentCoinsBox.close();
    });
  });
}
