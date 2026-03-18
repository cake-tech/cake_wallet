import 'package:cw_starknet/cw_starknet.dart';
import 'package:flutter_test/flutter_test.dart';

const _testMnemonic =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
const _testMnemonicAlt = 'zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong';
const _accountClassHashHex = '0x01d1777db36cdd06dd62cfde77b1b6ae06412af95d57a13dc40ac77b8a702381';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ensureStarknetRustInitialized();
  });

  group('Stark key derivation', () {
    test('derives a valid account from mnemonic', () async {
      final account = unwrapDerivedAccountDataResponse(await deriveAccount(
        mnemonic: _testMnemonic,
        accountClassHashHex: _accountClassHashHex,
      ));

      expect(account.privateKeyHex, startsWith('0x'));
      expect(account.publicKeyHex, startsWith('0x'));
      expect(account.accountAddressHex, startsWith('0x'));
    });

    test('derivation is deterministic', () async {
      final account1 = unwrapDerivedAccountDataResponse(await deriveAccount(
        mnemonic: _testMnemonic,
        accountClassHashHex: _accountClassHashHex,
      ));
      final account2 = unwrapDerivedAccountDataResponse(await deriveAccount(
        mnemonic: _testMnemonic,
        accountClassHashHex: _accountClassHashHex,
      ));

      expect(account1, equals(account2));
    });

    test('different mnemonics produce different accounts', () async {
      final account1 = unwrapDerivedAccountDataResponse(await deriveAccount(
        mnemonic: _testMnemonic,
        accountClassHashHex: _accountClassHashHex,
      ));
      final account2 = unwrapDerivedAccountDataResponse(await deriveAccount(
        mnemonic: _testMnemonicAlt,
        accountClassHashHex: _accountClassHashHex,
      ));

      expect(account1, isNot(equals(account2)));
    });

    test('passphrase changes the derived account', () async {
      final account1 = unwrapDerivedAccountDataResponse(await deriveAccount(
        mnemonic: _testMnemonic,
        accountClassHashHex: _accountClassHashHex,
      ));
      final account2 = unwrapDerivedAccountDataResponse(await deriveAccount(
        mnemonic: _testMnemonic,
        passphrase: 'my-passphrase',
        accountClassHashHex: _accountClassHashHex,
      ));

      expect(account1, isNot(equals(account2)));
    });

    test('empty passphrase equals no passphrase', () async {
      final account1 = unwrapDerivedAccountDataResponse(await deriveAccount(
        mnemonic: _testMnemonic,
        accountClassHashHex: _accountClassHashHex,
      ));
      final account2 = unwrapDerivedAccountDataResponse(await deriveAccount(
        mnemonic: _testMnemonic,
        passphrase: '',
        accountClassHashHex: _accountClassHashHex,
      ));

      expect(account1, equals(account2));
    });
  });

  group('Signing', () {
    test('signs a message hash and returns valid signature', () async {
      final account = unwrapDerivedAccountDataResponse(await deriveAccount(
        mnemonic: _testMnemonic,
        accountClassHashHex: _accountClassHashHex,
      ));

      final signature = unwrapSignatureResponse(await signMessageHash(
        privateKeyHex: account.privateKeyHex,
        messageHashHex: '0xdeadbeef',
      ));

      expect(signature.rHex, startsWith('0x'));
      expect(signature.sHex, startsWith('0x'));
    });

    test('signing is deterministic', () async {
      final account = unwrapDerivedAccountDataResponse(await deriveAccount(
        mnemonic: _testMnemonic,
        accountClassHashHex: _accountClassHashHex,
      ));

      final sig1 = unwrapSignatureResponse(await signMessageHash(
        privateKeyHex: account.privateKeyHex,
        messageHashHex: '0xcafebabe',
      ));
      final sig2 = unwrapSignatureResponse(await signMessageHash(
        privateKeyHex: account.privateKeyHex,
        messageHashHex: '0xcafebabe',
      ));

      expect(sig1, equals(sig2));
    });

    test('different messages produce different signatures', () async {
      final account = unwrapDerivedAccountDataResponse(await deriveAccount(
        mnemonic: _testMnemonic,
        accountClassHashHex: _accountClassHashHex,
      ));

      final sig1 = unwrapSignatureResponse(await signMessageHash(
        privateKeyHex: account.privateKeyHex,
        messageHashHex: '0x1',
      ));
      final sig2 = unwrapSignatureResponse(await signMessageHash(
        privateKeyHex: account.privateKeyHex,
        messageHashHex: '0x2',
      ));

      expect(sig1, isNot(equals(sig2)));
    });

    test('signature can be verified', () async {
      final account = unwrapDerivedAccountDataResponse(await deriveAccount(
        mnemonic: _testMnemonic,
        accountClassHashHex: _accountClassHashHex,
      ));
      final signature = unwrapSignatureResponse(await signMessageHash(
        privateKeyHex: account.privateKeyHex,
        messageHashHex: '0xdeadbeef',
      ));

      final isValid = unwrapBoolResponse(await verifyMessageHashSignature(
        publicKeyHex: account.publicKeyHex,
        messageHashHex: '0xdeadbeef',
        rHex: signature.rHex,
        sHex: signature.sHex,
      ));

      expect(isValid, true);
    });

    test('verification fails with wrong public key', () async {
      final account = unwrapDerivedAccountDataResponse(await deriveAccount(
        mnemonic: _testMnemonic,
        accountClassHashHex: _accountClassHashHex,
      ));
      final wrongAccount = unwrapDerivedAccountDataResponse(await deriveAccount(
        mnemonic: _testMnemonicAlt,
        accountClassHashHex: _accountClassHashHex,
      ));
      final signature = unwrapSignatureResponse(await signMessageHash(
        privateKeyHex: account.privateKeyHex,
        messageHashHex: '0xdeadbeef',
      ));

      final isValid = unwrapBoolResponse(await verifyMessageHashSignature(
        publicKeyHex: wrongAccount.publicKeyHex,
        messageHashHex: '0xdeadbeef',
        rHex: signature.rHex,
        sHex: signature.sHex,
      ));

      expect(isValid, false);
    });
  });
}
