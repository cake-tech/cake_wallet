import 'package:cw_core/amount/money.dart';
import 'package:cw_core/currency/currency.dart';

class FiatCurrency implements Currency {
  const FiatCurrency({
    required this.symbol,
    required this.countryCode,
    required this.fullName,
    this.decimals = 2,
  });

  final String countryCode;

  @override
  final String fullName;

  @override
  final int decimals;

  @override
  final String symbol;

  @override
  String? get iconPath => throw UnimplementedError();

  @override
  String get name => throw UnimplementedError();

  @override
  String? get tag => throw UnimplementedError();

  @override
  Money parseAmount(String value) => Money.parse(value, this);

  @override
  Money? tryParseAmount(String value) => Money.tryParse(value, this);
}

const EUR = FiatCurrency(symbol: 'EUR', countryCode: "eur", fullName: "Euro");
const USD = FiatCurrency(symbol: 'USD', countryCode: "usd", fullName: "US Dollar");
const JPY = FiatCurrency(symbol: 'JPY', countryCode: "jpn", fullName: "Japanese Yen", decimals: 0);
