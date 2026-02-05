import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';

/// Default ERC20 tokens for Binance Smart Chain
class BSCTokens {
  static List<Erc20Token> get tokens {
    final tokens = [
      Erc20Token(
        name: "USD Coin",
        symbol: "USDC",
        contractAddress: "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d",
        decimal: 18,
        enabled: true,
      ),
      Erc20Token(
        name: "Ethereum",
        symbol: "ETH",
        contractAddress: "0x2170Ed0880ac9A755fd29B2688956BD959F933F8",
        decimal: 18,
        enabled: true,
      ),
      Erc20Token(
        name: "Tether USD",
        symbol: "USDT",
        contractAddress: "0x55d398326f99059fF775485246999027B3197955",
        decimal: 18,
        enabled: true,
      ),
      Erc20Token(
        name: "USDe",
        symbol: "USDe",
        contractAddress: "0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34",
        decimal: 18,
        enabled: true,
      ),
      Erc20Token(
        name: "PancakeSwap Token",
        symbol: "CAKE",
        contractAddress: "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82",
        decimal: 18,
        enabled: false,
      ),
      Erc20Token(
        name: "Cardano Token",
        symbol: "ADA",
        contractAddress: "0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47",
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
        contractAddress: "0x0555E30da8f98308EdB960aa94C0Db47230d2B9c",
        decimal: 8,
        enabled: false,
      ),
      Erc20Token(
        name: "Wrapped BNB",
        symbol: "WBNB",
        contractAddress: "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",
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
