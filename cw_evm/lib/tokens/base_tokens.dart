import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';

/// Default ERC20 tokens for Base
class BaseTokens {
  static List<Erc20Token> get tokens {
    final tokens = [
      Erc20Token(
        name: "USD Coin",
        symbol: "USDC",
        contractAddress: "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
        decimal: 6,
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
        name: "Dai",
        symbol: "DAI",
        contractAddress: "0x50c5725949a6f0c72e6c4a641f24049a917db0cb",
        decimal: 18,
        enabled: true,
      ),
      Erc20Token(
        name: "Bridged Tether USD",
        symbol: "USDT",
        contractAddress: "0xfde4c96c8593536e31f229ea8f37b2ada2699bb2",
        decimal: 6,
        enabled: true,
      ),
      Erc20Token(
        name: "Wrapped Ether",
        symbol: "WETH",
        contractAddress: "0x4200000000000000000000000000000000000006",
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
        name: "SPX6900",
        symbol: "SPX",
        contractAddress: "0x50da645f148798f68ef2d7db7c1cb22a6819bb2c",
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

      return Erc20Token.copyWith(token, icon: iconPath, tag: 'BASE');
    }).toList();
  }
}

