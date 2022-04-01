import 'package:cake_wallet/exchange/exchange_provider.dart';

class ProviderPrice {
  final ExchangeProvider provider;
  final double price;
  const ProviderPrice({this.provider, this.price});
}