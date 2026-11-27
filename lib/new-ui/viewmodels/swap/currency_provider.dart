import "package:cake_wallet/utils/token_utilities.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/spl_token.dart";
import "package:cw_core/tron_token.dart";

class SwapCurrencyStore {
  SwapCurrencyStore()
    : depositCurrencies = CryptoCurrency.all
          .where((cryptoCurrency) => !excludeDepositCurrencies.contains(cryptoCurrency))
          .toList(),
      receiveCurrencies = CryptoCurrency.all
          .where((cryptoCurrency) => !excludeReceiveCurrencies.contains(cryptoCurrency))
          .toList() {
    _injectUserEthTokensIntoCurrencyLists();
  }

  static const excludeDepositCurrencies = [CryptoCurrency.btt];
  static const excludeReceiveCurrencies = [CryptoCurrency.btt];

  final List<CryptoCurrency> receiveCurrencies;
  final List<CryptoCurrency> depositCurrencies;

  Future<void> _injectUserEthTokensIntoCurrencyLists() async {
    final tokens = [
      ...await TokenUtilities.loadEvmTokensForSwap(),
      ...await TokenUtilities.loadSolTokensForSwap(),
      ...await TokenUtilities.loadTronTokensForSwap(),
    ];
    final toAddReceive = <CryptoCurrency>[];
    final toAddDeposit = <CryptoCurrency>[];

    for (final token in tokens) {
      if (!_listContainsToken(receiveCurrencies, token)) {
        toAddReceive.add(token);
      }
      if (!_listContainsToken(depositCurrencies, token)) {
        toAddDeposit.add(token);
      }
    }

    if (toAddReceive.isNotEmpty) {
      receiveCurrencies.addAll(toAddReceive);
    }
    if (toAddDeposit.isNotEmpty) {
      depositCurrencies.addAll(toAddDeposit);
    }
  }

  bool _listContainsToken(List<CryptoCurrency> list, CryptoCurrency token) => list.any((item) {
    if (item is Erc20Token && token is Erc20Token) {
      return item.contractAddress.toLowerCase() == token.contractAddress.toLowerCase();
    }
    if (item is SPLToken && token is SPLToken) {
      return item.mintAddress.toLowerCase() == token.mintAddress.toLowerCase();
    }
    if (item is TronToken && token is TronToken) {
      return item.contractAddress.toLowerCase() == token.contractAddress.toLowerCase();
    }
    return item.title.toUpperCase() == token.symbol.toUpperCase() &&
        (item.tag?.toUpperCase() == token.tag?.toUpperCase() || item.tag == null);
  });
}
