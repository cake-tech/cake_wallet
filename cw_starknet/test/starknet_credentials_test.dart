import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:cw_starknet/starknet_transaction_credentials.dart';
import 'package:cw_starknet/starknet_wallet_creation_credentials.dart';

void main() {
  group('StarknetTransactionCredentials', () {
    test('stores outputs and currency', () {
      final outputs = [
        OutputInfo(
          address: '0xrecipient',
          cryptoAmount: '1.5',
          sendAll: false,
          isParsedAddress: false,
        ),
      ];

      final credentials = StarknetTransactionCredentials(
        outputs,
        currency: CryptoCurrency.strk,
      );

      expect(credentials.outputs.length, 1);
      expect(credentials.outputs.first.address, '0xrecipient');
      expect(credentials.currency, CryptoCurrency.strk);
    });

    test('supports multiple outputs', () {
      final outputs = [
        OutputInfo(address: '0x1', cryptoAmount: '1.0', sendAll: false, isParsedAddress: false),
        OutputInfo(address: '0x2', cryptoAmount: '2.0', sendAll: false, isParsedAddress: false),
        OutputInfo(address: '0x3', cryptoAmount: '3.0', sendAll: false, isParsedAddress: false),
      ];

      final credentials = StarknetTransactionCredentials(
        outputs,
        currency: CryptoCurrency.strk,
      );

      expect(credentials.outputs.length, 3);
    });

    test('supports sendAll flag', () {
      final outputs = [
        OutputInfo(address: '0xrecipient', sendAll: true, isParsedAddress: false),
      ];

      final credentials = StarknetTransactionCredentials(
        outputs,
        currency: CryptoCurrency.strk,
      );

      expect(credentials.outputs.first.sendAll, true);
    });
  });

  group('StarknetNewWalletCredentials', () {
    test('stores name and password', () {
      final creds = StarknetNewWalletCredentials(
        name: 'my-wallet',
        password: 'secret',
      );

      expect(creds.name, 'my-wallet');
      expect(creds.password, 'secret');
    });

    test('mnemonic is optional', () {
      final creds = StarknetNewWalletCredentials(
        name: 'my-wallet',
        password: 'secret',
      );

      expect(creds.mnemonic, isNull);
    });

    test('passphrase is optional', () {
      final creds = StarknetNewWalletCredentials(
        name: 'my-wallet',
        password: 'secret',
        passphrase: 'my-pass',
      );

      expect(creds.passphrase, 'my-pass');
    });
  });

  group('StarknetRestoreWalletFromSeedCredentials', () {
    test('stores mnemonic and password', () {
      final creds = StarknetRestoreWalletFromSeedCredentials(
        name: 'restored',
        password: 'secret',
        mnemonic: 'abandon abandon abandon abandon abandon abandon '
            'abandon abandon abandon abandon abandon about',
      );

      expect(creds.name, 'restored');
      expect(creds.mnemonic.split(' ').length, 12);
    });
  });

  group('StarknetRestoreWalletFromPrivateKey', () {
    test('stores private key', () {
      final creds = StarknetRestoreWalletFromPrivateKey(
        name: 'imported',
        password: 'secret',
        privateKey: '0x1234567890abcdef',
      );

      expect(creds.name, 'imported');
      expect(creds.privateKey, '0x1234567890abcdef');
    });

    test('supports public-key-only restore', () {
      final creds = StarknetRestoreWalletFromPrivateKey.publicKey(
        name: 'airgapped',
        password: 'secret',
        publicKey: '0xabcdef',
        accountClassHashHex: '0x123',
      );

      expect(creds.name, 'airgapped');
      expect(creds.privateKey, isNull);
      expect(creds.publicKey, '0xabcdef');
      expect(creds.accountClassHashHex, '0x123');
    });
  });

  group('WalletKeysData', () {
    test('preserves Starknet account class hash in JSON', () {
      final keys = WalletKeysData(
        mnemonic: 'seed words',
        privateKey: '0xabc',
        accountClassHashHex: '0x01d1777db36cdd06dd62cfde77b1b6ae06412af95d57a13dc40ac77b8a702381',
      );

      final restored = WalletKeysData.fromJSON(
        Map<String, dynamic>.from(
          const JsonDecoder().convert(keys.toJSON()) as Map,
        ),
      );

      expect(restored.accountClassHashHex, keys.accountClassHashHex);
      expect(restored.privateKey, keys.privateKey);
    });
  });
}
