import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/generated/i18n.dart';

class ExchangeProviderUnsupportedException implements Exception {
  ExchangeProviderUnsupportedException(this.provider);

  ExchangeProviderDescription provider;

  @override
  String toString() => S.current.exchange_provider_unsupported(provider.title);
}
