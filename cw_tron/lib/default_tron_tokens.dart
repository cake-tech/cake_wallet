import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/tron_token.dart';

class DefaultTronTokens {
  final List<TronToken> _defaultTokens = [
    TronToken(
      name: "Tether USD",
      symbol: "USDT",
      contractAddress: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
      decimal: 6,
      enabled: true,
    ),
    TronToken(
      name: "USD Coin",
      symbol: "USDC",
      contractAddress: "TEkxiTehnzSmSe2XqrBj4w32RUN966rdz8",
      decimal: 6,
      enabled: true,
    ),
    TronToken(
      name: "Bitcoin",
      symbol: "BTC",
      contractAddress: "TN3W4H6rK2ce4vX9YnFQHwKENnHjoxb3m9",
      decimal: 8,
      enabled: false,
    ),
    TronToken(
      name: "Ethereum",
      symbol: "ETH",
      contractAddress: "TRFe3hT5oYhjSZ6f3ji5FJ7YCfrkWnHRvh",
      decimal: 18,
      enabled: false,
    ),
    TronToken(
      name: "Wrapped BTC",
      symbol: "WBTC",
      contractAddress: "TXpw8XeWYeTUd4quDskoUqeQPowRh4jY65",
      decimal: 8,
      enabled: true,
    ),
    TronToken(
      name: "Dogecoin",
      symbol: "DOGE",
      contractAddress: "THbVQp8kMjStKNnf2iCY6NEzThKMK5aBHg",
      decimal: 8,
      enabled: true,
    ),
    TronToken(
      name: "JUST Stablecoin",
      symbol: "USDJ",
      contractAddress: "TMwFHYXLJaRUPeW6421aqXL4ZEzPRFGkGT",
      decimal: 18,
      enabled: false,
    ),
    TronToken(
      name: "SUN",
      symbol: "SUN",
      contractAddress: "TSSMHYeV2uE9qYH95DqyoCuNCzEL1NvU3S",
      decimal: 18,
      enabled: false,
    ),
    TronToken(
      name: "Wrapped TRX",
      symbol: "WTRX",
      contractAddress: "TNUC9Qb1rRpS5CbWLmNMxXBjyFoydXjWFR",
      decimal: 6,
      enabled: false,
    ),
    TronToken(
      name: "BitTorent",
      symbol: "BTT",
      contractAddress: "TAFjULxiVgT4qWk6UZwjqwZXTSaGaqnVp4",
      decimal: 18,
      enabled: false,
    ),
    TronToken(
      name: "BUSD Token",
      symbol: "BUSD",
      contractAddress: "TMz2SWatiAtZVVcH2ebpsbVtYwUPT9EdjH",
      decimal: 18,
      enabled: false,
    ),
    TronToken(
      name: "HTX",
      symbol: "HTX",
      contractAddress: "TUPM7K8REVzD2UdV4R5fe5M8XbnR2DdoJ6",
      decimal: 18,
      enabled: false,
    ),
  ];

  List<TronToken> get initialTronTokens => _defaultTokens.map((token) {
        String? iconPath;
        if (token.iconPath?.isEmpty ?? true) {
          try {
            iconPath = CryptoCurrency.all
                .firstWhere((element) =>
                    element.title.toUpperCase() == token.symbol.split(".").first.toUpperCase())
                .iconPath;
          } catch (_) {}
        } else {
          iconPath = token.iconPath;
        }

        return TronToken.copyWith(token, icon: iconPath, tag: 'TRX');
      }).toList();
}
