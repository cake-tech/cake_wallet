import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';

/// Default ERC20 tokens for Arbitrum
class ArbitrumTokens {
  static List<Erc20Token> get tokens {
    final tokens = [
      Erc20Token(
        name: "Arbitrum",
        symbol: "ARB",
        contractAddress: "0x912ce59144191c1204e64559fe8253a0e49e6548",
        decimal: 18,
        enabled: true,
      ),
      Erc20Token(
        name: "USD Coin",
        symbol: "USDC",
        contractAddress: "0xaf88d065e77c8cc2239327c5edb3a432268e5831",
        decimal: 6,
        enabled: true,
      ),
      Erc20Token(
        name: "USDC.e",
        symbol: "USDC.e",
        contractAddress: "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8",
        decimal: 6,
        enabled: true,
      ),
      Erc20Token(
        name: "Wrapped BTC",
        symbol: "WBTC",
        contractAddress: "0x2f2a2543b76a4166549f7aab2e75bef0aefc5b0f",
        decimal: 8,
        enabled: true,
      ),
      Erc20Token(
        name: "Chainlink Token",
        symbol: "LINK",
        contractAddress: "0xf97f4df75117a78c1a5a0dbb814af92458539fb4",
        decimal: 18,
        enabled: true,
      ),
      Erc20Token(
        name: "Wrapped liquid staked Ether 2.0",
        symbol: "wstETH",
        contractAddress: "0x0fbcbaea96ce0cf7ee00a8c19c3ab6f5dc8e1921",
        decimal: 18,
        enabled: false,
      ),
      Erc20Token(
        name: "Wrapped Ether",
        symbol: "WETH",
        contractAddress: "0x82af49447d8a07e3bd95bd0d56f35241523fbab1",
        decimal: 18,
        enabled: false,
      ),
      Erc20Token(
        name: "DAI",
        symbol: "DAI",
        contractAddress: "0xda10009cbd5d07dd0cecc66161fc93d7c9000da1",
        decimal: 18,
        enabled: false,
      ),
    ];

    return tokens.map((token) {
      String? iconPath;
      if (token.iconPath?.isEmpty ?? true) {
        try {
          iconPath = CryptoCurrency.all
              .firstWhere((element) =>
                  element.title.toUpperCase() == token.symbol.toUpperCase())
              .iconPath;
        } catch (_) {}
      } else {
        iconPath = token.iconPath;
      }

      return Erc20Token.copyWith(token, icon: iconPath, tag: 'ARB');
    }).toList();
  }
}

