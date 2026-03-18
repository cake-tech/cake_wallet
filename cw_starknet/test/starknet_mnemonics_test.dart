import 'package:flutter_test/flutter_test.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:cw_starknet/starknet_mnemonics.dart';

void main() {
  group('StarknetMnemonics', () {
    test('english wordlist is not empty', () {
      expect(StarknetMnemonics.englishWordlist.isNotEmpty, true);
    });

    test('english wordlist has 2048 words (BIP39)', () {
      expect(StarknetMnemonics.englishWordlist.length, 2048);
    });

    test('wordlist contains known BIP39 words', () {
      final wordlist = StarknetMnemonics.englishWordlist;
      expect(wordlist.contains('abandon'), true);
      expect(wordlist.contains('zoo'), true);
      expect(wordlist.contains('abstract'), true);
    });

    test('wordlist does not contain non-BIP39 words', () {
      final wordlist = StarknetMnemonics.englishWordlist;
      expect(wordlist.contains('starknet'), false);
      expect(wordlist.contains(''), false);
    });

    test('generated mnemonic uses words from wordlist', () {
      final mnemonic = bip39.generateMnemonic();
      final words = mnemonic.split(' ');
      final wordlist = StarknetMnemonics.englishWordlist;

      for (final word in words) {
        expect(wordlist.contains(word), true,
            reason: 'Word "$word" not in wordlist');
      }
    });

    test('12-word mnemonic is valid', () {
      final mnemonic = bip39.generateMnemonic(strength: 128);
      expect(mnemonic.split(' ').length, 12);
      expect(bip39.validateMnemonic(mnemonic), true);
    });

    test('24-word mnemonic is valid', () {
      final mnemonic = bip39.generateMnemonic(strength: 256);
      expect(mnemonic.split(' ').length, 24);
      expect(bip39.validateMnemonic(mnemonic), true);
    });
  });

  group('StarknetMnemonicIsIncorrectException', () {
    test('toString returns descriptive message', () {
      final exception = StarknetMnemonicIsIncorrectException();
      expect(exception.toString(), contains('not valid'));
    });
  });
}
