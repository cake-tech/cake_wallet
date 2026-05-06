// ignore: implementation_imports
import 'package:bip39/src/wordlists/english.dart' as english;

class StarknetMnemonics {
  static List<String> englishWordlist = english.WORDLIST.toList();
}

class StarknetMnemonicIsIncorrectException implements Exception {
  @override
  String toString() => 'StarknetMnemonicIsIncorrectException: The mnemonic seed is not valid.';
}
