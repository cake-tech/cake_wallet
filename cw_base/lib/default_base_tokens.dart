import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';

class DefaultBaseTokens {
  final List<Erc20Token> _defaultTokens = [
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
      contractAddress: "0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34",
      decimal: 18,
      enabled: true,
    ),
    Erc20Token(
      name: "Dai",
      symbol: "DAI",
      contractAddress: "0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb",
      decimal: 18,
      enabled: true,
    ),
    Erc20Token(
      name: "Bridged Tether USD",
      symbol: "USDT",
      contractAddress: "0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2",
      decimal: 6,
      enabled: false,
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
      contractAddress: "0x0555E30da8f98308EdB960aa94C0Db47230d2B9c",
      decimal: 8,
      enabled: false,
    ),
    Erc20Token(
      name: "SPX6900",
      symbol: "SPX",
      contractAddress: "0x50dA645f148798F68EF2d7dB7C1CB22A6819bb2C",
      decimal: 8,
      enabled: false,
    ),
  ];

  List<Erc20Token> get initialBaseTokens => _defaultTokens.map((token) {
        String? iconPath;
        try {
          iconPath = CryptoCurrency.all
              .firstWhere((element) => element.title.toUpperCase() == token.symbol.toUpperCase())
              .iconPath;
        } catch (_) {}

        return Erc20Token.copyWith(token, iconPath, 'BASE');
      }).toList();
}
