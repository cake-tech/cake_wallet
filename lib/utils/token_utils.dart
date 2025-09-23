import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/wallet_base.dart';

/// Utility class for token-related operations
class TokenUtils {
  static Erc20Token? findErc20Token(CryptoCurrency currency, WalletBase wallet) {
    if (currency is Erc20Token) return currency;

    // More of a fallback for us
    for (final balanceCurrency in wallet.balance.keys) {
      if (balanceCurrency is Erc20Token && _matchesToken(balanceCurrency, currency)) {
        return balanceCurrency;
      }
    }

    return null;
  }

  static bool isNativeToken(CryptoCurrency currency) {
    final title = currency.title.toLowerCase();
    final tag = currency.tag?.toLowerCase();

    return title == 'eth' ||
        title == 'ethereum' ||
        title == 'matic' ||
        title == 'polygon' ||
        title == 'bnb' ||
        title == 'bsc' ||
        title == 'avax' ||
        title == 'avalanche' ||
        tag == 'polygon' ||
        tag == 'bsc' ||
        tag == 'avalanche';
  }

  static int getChainId(CryptoCurrency currency) {
    final title = currency.title.toLowerCase();
    final tag = currency.tag?.toLowerCase();

    // Polygon
    if (title == 'polygon' || title == 'matic' || tag == 'polygon') {
      return 137;
    }

    // BSC (Binance Smart Chain)
    if (title == 'bsc' || title == 'bnb' || tag == 'bsc') {
      return 56;
    }

    // Avalanche C-Chain
    if (title == 'avalanche' || title == 'avax' || tag == 'avalanche') {
      return 43114;
    }

    // Arbitrum One
    if (title == 'arbitrum' || title == 'arb' || tag == 'arbitrum') {
      return 42161;
    }

    // Optimism
    if (title == 'optimism' || title == 'op' || tag == 'optimism') {
      return 10;
    }

    // Base
    if (title == 'base' || tag == 'base') {
      return 8453;
    }

    // Fantom Opera
    if (title == 'fantom' || title == 'ftm' || tag == 'fantom') {
      return 250;
    }

    // Default to Ethereum mainnet
    return 1;
  }

  /// Checks if two currencies match (by title and tag)
  static bool _matchesToken(Erc20Token token, CryptoCurrency currency) {
    return token.title.toLowerCase() == currency.title.toLowerCase() &&
        (token.tag?.toLowerCase() == currency.tag?.toLowerCase() ||
            (token.tag == null && currency.tag == null));
  }
}
