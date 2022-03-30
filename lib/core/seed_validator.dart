import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/haven/haven.dart';
import 'package:cake_wallet/core/validator.dart';
import 'package:cake_wallet/entities/mnemonic_item.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/monero/monero.dart';
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
      case WalletType.litecoin:
        return getBitcoinWordList(language);
      case WalletType.monero:
        return monero.getMoneroWordList(language);
      case WalletType.haven:
        return haven.getMoneroWordList(language);
      default:
        return [];
    }
  }

  static List<String> getBitcoinWordList(String language) {
    assert(language.toLowerCase() == LanguageList.english.toLowerCase());
    return bitcoin.getWordList();
  }

  @override
  bool isValid(MnemonicItem value) => _words.contains(value.text);
}
