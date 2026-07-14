import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';

/// Default ERC20 tokens for Polygon
class PolygonTokens {
  static List<Erc20Token> get tokens {
    final tokens = [
      Erc20Token(
        name: "Wrapped Ether",
        symbol: "WETH",
        contractAddress: "0x7ceb23fd6bc0add59e62ac25578270cff1b9f619",
        decimal: 18,
        enabled: false,
      ),
      Erc20Token(
        name: "Tether USD (PoS)",
        symbol: "USDT",
        contractAddress: "0xc2132d05d31c914a87c6611c10748aeb04b58e8f",
        decimal: 6,
        enabled: true,
      ),
      Erc20Token(
        name: "USD Coin",
        symbol: "USDC",
        contractAddress: "0x3c499c542cef5e3811e1192ce70d8cc03d5c3359",
        decimal: 6,
        enabled: true,
      ),
      Erc20Token(
        name: "USD Coin (POS)",
        symbol: "USDC.e",
        contractAddress: "0x2791bca1f2de4661ed88a30c99a7a9449aa84174",
        decimal: 6,
        enabled: true,
      ),
      Erc20Token(
        name: "Decentralized Euro",
        symbol: "DEURO",
        contractAddress: "0xc2ff25dd99e467d2589b2c26edd270f220f14e47",
        decimal: 18,
        enabled: true,
      ),
      Erc20Token(
        name: "Avalanche Token",
        symbol: "AVAX",
        contractAddress: "0x2c89bbc92bd86f8075d1decc58c7f4e0107f286b",
        decimal: 18,
        enabled: false,
      ),
      Erc20Token(
        name: "Wrapped BTC (PoS)",
        symbol: "WBTC",
        contractAddress: "0x1bfd67037b42cf73acf2047067bd4f2c47d9bfd6",
        decimal: 8,
        enabled: false,
      ),
      Erc20Token(
        name: "Dai (PoS)",
        symbol: "DAI",
        contractAddress: "0x8f3cf7ad23cd3cadbd9735aff958023239c6a063",
        decimal: 18,
        enabled: true,
      ),
      Erc20Token(
        name: "SHIBA INU (PoS)",
        symbol: "SHIB",
        contractAddress: "0x6f8a06447ff6fcf75d803135a7de15ce88c1d4ec",
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

      return Erc20Token.copyWith(token, icon: iconPath, tag: 'POL');
    }).toList();
  }
}

