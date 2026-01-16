import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';

/// Default ERC20 tokens for Ethereum Mainnet
class EthereumTokens {
  static List<Erc20Token> get tokens {
    final tokens = [
      Erc20Token(
        name: "USD Coin",
        symbol: "USDC",
        contractAddress: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
        decimal: 6,
        enabled: true,
      ),
      Erc20Token(
        name: "USDT Tether",
        symbol: "USDT",
        contractAddress: "0xdac17f958d2ee523a2206206994597c13d831ec7",
        decimal: 6,
        enabled: true,
      ),
      Erc20Token(
        name: "Decentralized Euro",
        symbol: "DEURO",
        contractAddress: "0xbA3f535bbCcCcA2A154b573Ca6c5A49BAAE0a3ea",
        decimal: 18,
        enabled: true,
      ),
      Erc20Token(
        name: "Dai",
        symbol: "DAI",
        contractAddress: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
        decimal: 18,
        enabled: true,
      ),
      Erc20Token(
        name: "Wrapped Ether",
        symbol: "WETH",
        contractAddress: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
        decimal: 18,
        enabled: false,
      ),
      Erc20Token(
        name: "Pepe",
        symbol: "PEPE",
        contractAddress: "0x6982508145454ce325ddbe47a25d4ec3d2311933",
        decimal: 18,
        enabled: false,
      ),
      Erc20Token(
        name: "SHIBA INU",
        symbol: "SHIB",
        contractAddress: "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce",
        decimal: 18,
        enabled: false,
      ),
      Erc20Token(
        name: "ApeCoin",
        symbol: "APE",
        contractAddress: "0x4d224452801aced8b2f0aebe155379bb5d594381",
        decimal: 18,
        enabled: false,
      ),
      Erc20Token(
        name: "Matic Token",
        symbol: "MATIC",
        contractAddress: "0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0",
        decimal: 18,
        enabled: false,
      ),
      Erc20Token(
        name: "Wrapped BTC",
        symbol: "WBTC",
        contractAddress: "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
        decimal: 8,
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

      return Erc20Token.copyWith(token, icon: iconPath, tag: 'ETH');
    }).toList();
  }
}

