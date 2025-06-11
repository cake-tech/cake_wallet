import 'package:flutter_test/flutter_test.dart';
import 'package:cw_digibyte/cw_digibyte.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:hive/hive.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/utils.dart';
import 'dart:typed_data';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';

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

    test('Restore from WIF', () async {
      final walletInfoBox = await Hive.openBox<WalletInfo>('walletInfo');
      final unspentCoinsBox = await Hive.openBox<UnspentCoinsInfo>('unspentCoins');

      final walletInfo = WalletInfo.external(
        id: WalletBase.idFor('wif_wallet', WalletType.digibyte),
        name: 'wif_wallet',
        type: WalletType.digibyte,
        isRecovery: true,
        restoreHeight: 0,
        date: DateTime.now(),
        path: '',
        dirPath: '',
        address: '',
      );

      final priv = List<int>.filled(32, 1);
      final wif =
          WifEncoder.encode(priv, netVer: DigibyteNetwork.mainnet.wifNetVer);

      final credentials = BitcoinRestoreWalletFromWIFCredentials(
        name: 'wif_wallet',
        password: 'test',
        wif: wif,
        walletInfo: walletInfo,
      );

      final service = DigibyteWalletService(
        walletInfoBox,
        unspentCoinsBox,
        false,
        true,
      );

      final wallet = await service.restoreFromKeys(credentials);

      final hd = Bip32Slip10Secp256k1.fromSeed(Uint8List.fromList(priv))
          .derivePath(electrum_path) as Bip32Slip10Secp256k1;

      final expected = generateP2WPKHAddress(
        hd: hd,
        index: 0,
        network: DigibyteNetwork.mainnet,
      );

      expect(wallet.walletAddresses.address, expected);

      await walletInfoBox.close();
      await unspentCoinsBox.close();
    });

    test('Set ledger connection', () async {
      final walletInfoBox = await Hive.openBox<WalletInfo>('walletInfoHW');
      final unspentCoinsBox = await Hive.openBox<UnspentCoinsInfo>('unspentHW');

      final walletInfo = WalletInfo.external(
        id: WalletBase.idFor('hw_wallet', WalletType.digibyte),
        name: 'hw_wallet',
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

      final connection = _FakeLedgerConnection();

      expect(() => wallet.setLedgerConnection(connection), returnsNormally);

      await walletInfoBox.close();
      await unspentCoinsBox.close();
    });
  });
}

class _FakeLedgerConnection implements LedgerConnection {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
