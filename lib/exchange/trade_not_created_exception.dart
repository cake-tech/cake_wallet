import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/generated/i18n.dart';

class TradeNotCreatedException implements Exception {
  TradeNotCreatedException(this.provider, {this.description = ''});

  ExchangeProviderDescription provider;
  String description;

  @override
  String toString() => '${S.current.trade_for_not_created(provider.title)} $description';
}
