import 'package:cw_core/crypto_currency.dart';
import 'package:cw_tron/tron_token.dart';

class DefaultTronTokens {
  final List<TronToken> _defaultTokens = [
    TronToken(
      name: "Wrapped Ether",
      symbol: "WETH",
      contractAddress: "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619",
      decimal: 18,
      enabled: false,
    ),
    TronToken(
      name: "Tether USD (PoS)",
      symbol: "USDT",
      contractAddress: "0xc2132D05D31c914a87C6611C10748AEb04B58e8F",
      decimal: 6,
      enabled: true,
    ),
    TronToken(
      name: "USD Coin",
      symbol: "USDC",
      contractAddress: "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359",
      decimal: 6,
      enabled: true,
    ),
    TronToken(
      name: "USD Coin (POS)",
      symbol: "USDC.e",
      contractAddress: "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174",
      decimal: 6,
      enabled: true,
    ),
    TronToken(
      name: "Avalanche Token",
      symbol: "AVAX",
      contractAddress: "0x2C89bbc92BD86F8075d1DEcc58C7F4E0107f286b",
      decimal: 18,
      enabled: false,
    ),
    TronToken(
      name: "Wrapped BTC (PoS)",
      symbol: "WBTC",
      contractAddress: "0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6",
      decimal: 8,
      enabled: false,
    ),
    TronToken(
      name: "Dai (PoS)",
      symbol: "DAI",
      contractAddress: "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063",
      decimal: 18,
      enabled: true,
    ),
    TronToken(
      name: "SHIBA INU (PoS)",
      symbol: "SHIB",
      contractAddress: "0x6f8a06447Ff6FcF75d803135a7de15CE88C1d4ec",
      decimal: 18,
      enabled: false,
    ),
    TronToken(
      name: "Uniswap (PoS)",
      symbol: "UNI",
      contractAddress: "0xb33EaAd8d922B1083446DC23f610c2567fB5180f",
      decimal: 18,
      enabled: false,
    ),
  ];

  List<TronToken> get initialTronTokens => _defaultTokens.map((token) {
        String? iconPath;
        try {
          iconPath = CryptoCurrency.all
              .firstWhere((element) =>
                  element.title.toUpperCase() == token.symbol.split(".").first.toUpperCase())
              .iconPath;
        } catch (_) {}

        return TronToken.copyWith(token, iconPath, 'POLY');
      }).toList();
}
