import 'package:bip39/src/wordlists/english.dart' as bitcoin_english;
import 'package:cake_wallet/core/validator.dart';
import 'package:cake_wallet/src/domain/common/mnemonic_item.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/src/domain/monero/mnemonics/chinese_simplified.dart';
import 'package:cake_wallet/src/domain/monero/mnemonics/dutch.dart';
import 'package:cake_wallet/src/domain/monero/mnemonics/english.dart';
import 'package:cake_wallet/src/domain/monero/mnemonics/german.dart';
import 'package:cake_wallet/src/domain/monero/mnemonics/japanese.dart';
import 'package:cake_wallet/src/domain/monero/mnemonics/portuguese.dart';
import 'package:cake_wallet/src/domain/monero/mnemonics/russian.dart';
import 'package:cake_wallet/src/domain/monero/mnemonics/spanish.dart';

class SeedValidator extends Validator<MnemonicItem> {
  SeedValidator({this.type, this.language})
      : _words = getWordList(type: type, language: language);

  final WalletType type;
  final String language;
  final List<String> _words;

  static List<String> getWordList({WalletType type, String language}) {
    switch (type) {
      case WalletType.bitcoin:
        return getBitcoinWordList(language);
      case WalletType.monero:
        return getMoneroWordList(language);
      default:
        return [];
    }
  }

  static List<String> getMoneroWordList(String language) {
    // FIXME: Unnamed constants; Need to be sure that string are in same case;

    switch (language) {
      case 'English':
        return EnglishMnemonics.words;
        break;
      case 'Chinese (simplified)':
        return ChineseSimplifiedMnemonics.words;
        break;
      case 'Dutch':
        return DutchMnemonics.words;
        break;
      case 'German':
        return GermanMnemonics.words;
        break;
      case 'Japanese':
        return JapaneseMnemonics.words;
        break;
      case 'Portuguese':
        return PortugueseMnemonics.words;
        break;
      case 'Russian':
        return RussianMnemonics.words;
        break;
      case 'Spanish':
        return SpanishMnemonics.words;
        break;
      default:
        return EnglishMnemonics.words;
    }
  }

  static List<String> getBitcoinWordList(String language) {
    assert(language.toLowerCase() == 'english');
    return bitcoin_english.WORDLIST;
  }

  @override
  bool isValid(MnemonicItem value) => _words.contains(value.text);
}
