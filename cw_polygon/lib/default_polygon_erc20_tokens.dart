import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';

class DefaultPolygonErc20Tokens {
  final List<Erc20Token> _defaultTokens = [
    Erc20Token(
      name: "Wrapped Ether",
      symbol: "WETH",
      contractAddress: "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619",
      decimal: 18,
      enabled: false,
    ),
    Erc20Token(
      name: "Tether USD (PoS)",
      symbol: "USDT",
      contractAddress: "0xc2132D05D31c914a87C6611C10748AEb04B58e8F",
      decimal: 6,
      enabled: true,
    ),
    Erc20Token(
      name: "USD Coin",
      symbol: "USDC",
      contractAddress: "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359",
      decimal: 6,
      enabled: true,
    ),
    Erc20Token(
      name: "USD Coin (POS)",
      symbol: "USDC.e",
      contractAddress: "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174",
      decimal: 6,
      enabled: true,
    ),
    Erc20Token(
      name: "Avalanche Token",
      symbol: "AVAX",
      contractAddress: "0x2C89bbc92BD86F8075d1DEcc58C7F4E0107f286b",
      decimal: 18,
      enabled: false,
    ),
    Erc20Token(
      name: "Wrapped BTC (PoS)",
      symbol: "WBTC",
      contractAddress: "0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6",
      decimal: 8,
      enabled: false,
    ),
    Erc20Token(
      name: "Dai (PoS)",
      symbol: "DAI",
      contractAddress: "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063",
      decimal: 18,
      enabled: true,
    ),
    Erc20Token(
      name: "SHIBA INU (PoS)",
      symbol: "SHIB",
      contractAddress: "0x6f8a06447Ff6FcF75d803135a7de15CE88C1d4ec",
      decimal: 18,
      enabled: false,
    ),
    Erc20Token(
      name: "Uniswap (PoS)",
      symbol: "UNI",
      contractAddress: "0xb33EaAd8d922B1083446DC23f610c2567fB5180f",
      decimal: 18,
      enabled: false,
    ),
  ];

  List<Erc20Token> get initialPolygonErc20Tokens => _defaultTokens.map((token) {
        String? iconPath;
        try {
          iconPath = CryptoCurrency.all
              .firstWhere((element) =>
                  element.title.toUpperCase() == token.symbol.split(".").first.toUpperCase())
              .iconPath;
        } catch (_) {}

        return Erc20Token.copyWith(token, iconPath, 'POLY');
      }).toList();
}
