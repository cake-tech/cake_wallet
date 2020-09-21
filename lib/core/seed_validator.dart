import 'package:bip39/src/wordlists/english.dart' as bitcoin_english;
import 'package:cake_wallet/core/validator.dart';
import 'package:cake_wallet/entities/mnemonic_item.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/monero/mnemonics/chinese_simplified.dart';
import 'package:cake_wallet/monero/mnemonics/dutch.dart';
import 'package:cake_wallet/monero/mnemonics/english.dart';
import 'package:cake_wallet/monero/mnemonics/german.dart';
import 'package:cake_wallet/monero/mnemonics/japanese.dart';
import 'package:cake_wallet/monero/mnemonics/portuguese.dart';
import 'package:cake_wallet/monero/mnemonics/russian.dart';
import 'package:cake_wallet/monero/mnemonics/spanish.dart';
import 'package:cake_wallet/utils/language_list.dart';

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
    switch (language) {
      case LanguageList.english:
        return EnglishMnemonics.words;
        break;
      case LanguageList.chineseSimplified:
        return ChineseSimplifiedMnemonics.words;
        break;
      case LanguageList.dutch:
        return DutchMnemonics.words;
        break;
      case LanguageList.german:
        return GermanMnemonics.words;
        break;
      case LanguageList.japanese:
        return JapaneseMnemonics.words;
        break;
      case LanguageList.portuguese:
        return PortugueseMnemonics.words;
        break;
      case LanguageList.russian:
        return RussianMnemonics.words;
        break;
      case LanguageList.spanish:
        return SpanishMnemonics.words;
        break;
      default:
        return EnglishMnemonics.words;
    }
  }

  static List<String> getBitcoinWordList(String language) {
    assert(language.toLowerCase() == LanguageList.english.toLowerCase());
    return bitcoin_english.WORDLIST;
  }

  @override
  bool isValid(MnemonicItem value) => _words.contains(value.text);
}
