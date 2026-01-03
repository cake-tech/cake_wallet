import 'package:cw_digibyte/cw_digibyte.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DigibyteTransactionPriority', () {
    test('deserialize returns expected priority', () {
      expect(
        DigibyteTransactionPriority.deserialize(raw: 0),
        DigibyteTransactionPriority.slow,
      );
      expect(
        DigibyteTransactionPriority.deserialize(raw: 1),
        DigibyteTransactionPriority.medium,
      );
      expect(
        DigibyteTransactionPriority.deserialize(raw: 2),
        DigibyteTransactionPriority.fast,
      );
    });

    test('available priorities contain defaults', () {
      expect(DigibyteTransactionPriority.all.length, 3);
      expect(DigibyteTransactionPriority.all.first, DigibyteTransactionPriority.slow);
      expect(DigibyteTransactionPriority.all.last, DigibyteTransactionPriority.fast);
    });
  });

  group('DigibyteNetwork configuration', () {
    test('mainnet has correct parameters', () {
      final network = DigibyteNetwork.mainnet;

      expect(network.isMainnet, isTrue);
      expect(network.p2wpkhHrp, 'dgb');
      expect(network.p2pkhNetVer, [0x1e]); // 'D' prefix
      expect(network.p2shNetVer, [0x3f]);  // 'S' prefix
      expect(network.wifNetVer, [0x80]);
    });

    test('testnet has correct parameters', () {
      final network = DigibyteNetwork.testnet;

      expect(network.isMainnet, isFalse);
      expect(network.p2wpkhHrp, 'dgbt');
    });
  });

  group('DigibyteWalletCredentials', () {
    test('new wallet credentials store mnemonic', () {
      final credentials = DigibyteNewWalletCredentials(
        name: 'Test Wallet',
        password: 'pass',
        mnemonic: 'test mnemonic',
      );

      expect(credentials.mnemonic, 'test mnemonic');
      expect(credentials.password, 'pass');
    });

    test('restore from seed credentials validate input', () {
      final credentials = DigibyteRestoreWalletFromSeedCredentials(
        name: 'Test Wallet',
        mnemonic: 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
        password: 'pass',
      );

      expect(credentials.mnemonic, contains('abandon'));
    });

    test('WIF credentials capture provided key', () {
      final credentials = DigibyteRestoreWalletFromWIFCredentials(
        name: 'Test Wallet',
        password: 'pass',
        wif: 'L1aW4aubDFB7yfras2S1mMEcb3z1Hn7uK4fF7ZzJqxyWb7C4Y3bW',
      );

      expect(credentials.wif, 'L1aW4aubDFB7yfras2S1mMEcb3z1Hn7uK4fF7ZzJqxyWb7C4Y3bW');
    });
  });
}
