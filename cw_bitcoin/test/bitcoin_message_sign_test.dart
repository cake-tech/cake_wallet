import 'package:cw_bitcoin/bitcoin_message_sign.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('blank address still uses the main key', () {
    expect(
      () => assertCanSignBitcoinMessage(address: '', heldByWallet: false, isTaproot: false),
      returnsNormally,
    );
    expect(
      () => assertCanSignBitcoinMessage(address: null, heldByWallet: false, isTaproot: false),
      returnsNormally,
    );
  });

  test('refuses an address the wallet does not hold', () {
    expect(
      () => assertCanSignBitcoinMessage(
        address: 'sp1qqexample',
        heldByWallet: false,
        isTaproot: false,
      ),
      throwsA(isA<UnsupportedError>()),
    );
  });

  test('refuses taproot and allows a held receive address', () {
    expect(
      () => assertCanSignBitcoinMessage(
        address: 'bc1pexample',
        heldByWallet: true,
        isTaproot: true,
      ),
      throwsA(isA<UnsupportedError>()),
    );
    expect(
      () => assertCanSignBitcoinMessage(
        address: 'bc1qexample',
        heldByWallet: true,
        isTaproot: false,
      ),
      returnsNormally,
    );
  });
}
