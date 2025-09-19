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

  group('CWDigibyte credential factories', () {
    final digibyte = CWDigibyte();

    test('new wallet credentials expose optional mnemonic', () {
      final credentials = digibyte.createDigibyteNewWalletCredentials(
        name: 'Test Wallet',
        password: 'pass',
        mnemonic: 'test mnemonic',
      ) as DigibyteNewWalletCredentials;

      expect(credentials.mnemonic, 'test mnemonic');
    });

    test('WIF credentials capture provided key', () {
      final credentials = digibyte.createDigibyteRestoreWalletFromWIFCredentials(
        name: 'Test Wallet',
        password: 'pass',
        wif: 'L1aW4aubDFB7yfras2S1mMEcb3z1Hn7uK4fF7ZzJqxyWb7C4Y3bW',
      ) as DigibyteRestoreWalletFromWIFCredentials;

      expect(credentials.wif, 'L1aW4aubDFB7yfras2S1mMEcb3z1Hn7uK4fF7ZzJqxyWb7C4Y3bW');
    });
  });
}
