import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';

/// Default ERC20 tokens for Binance Smart Chain
class BSCTokens {
  static List<Erc20Token> get tokens {
    final tokens = [
      Erc20Token(
        name: "USD Coin",
        symbol: "USDC",
        contractAddress: "0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d",
        decimal: 18,
        enabled: true,
      ),
      Erc20Token(
        name: "Ethereum",
        symbol: "ETH",
        contractAddress: "0x2170ed0880ac9a755fd29b2688956bd959f933f8",
        decimal: 18,
        enabled: true,
      ),
      Erc20Token(
        name: "Tether USD",
        symbol: "USDT",
        contractAddress: "0x55d398326f99059ff775485246999027b3197955",
        decimal: 18,
        enabled: true,
      ),
      Erc20Token(
        name: "USDe",
        symbol: "USDe",
        contractAddress: "0x5d3a1ff2b6bab83b63cd9ad0787074081a52ef34",
        decimal: 18,
        enabled: true,
      ),
      Erc20Token(
        name: "PancakeSwap Token",
        symbol: "CAKE",
        contractAddress: "0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82",
        decimal: 18,
        enabled: false,
      ),
      Erc20Token(
        name: "Cardano Token",
        symbol: "ADA",
        contractAddress: "0x3ee2200efb3400fabb9aacf31297cbdd1d435d47",
        decimal: 18,
        enabled: false,
      ),
      Erc20Token(
        name: "PEPE",
        symbol: "PEPE",
        contractAddress: "0x25d887ce7a35172c62febfd67a1856f20faebb00",
        decimal: 18,
        enabled: false,
      ),
      Erc20Token(
        name: "Wrapped BTC",
        symbol: "WBTC",
        contractAddress: "0x0555e30da8f98308edb960aa94c0db47230d2b9c",
        decimal: 8,
        enabled: false,
      ),
      Erc20Token(
        name: "Wrapped BNB",
        symbol: "WBNB",
        contractAddress: "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c",
        decimal: 18,
        enabled: false,
      ),
    ];

    return tokens.map((token) {
      String? iconPath;
      if (token.iconPath?.isEmpty ?? true) {
        try {
          iconPath = CryptoCurrency.all
              .firstWhere((element) => element.title.toUpperCase() == token.symbol.toUpperCase())
              .iconPath;
        } catch (_) {}
      } else {
        iconPath = token.iconPath;
      }

      return Erc20Token.copyWith(token, icon: iconPath, tag: 'BSC');
    }).toList();
  }
}
