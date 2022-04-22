import 'package:cake_wallet/exchange/exchange_provider.dart';

class ProviderRate {
  final ExchangeProvider provider;
  final double rate;
  const ProviderRate({this.provider, this.rate});
}