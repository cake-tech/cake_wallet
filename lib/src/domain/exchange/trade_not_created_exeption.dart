import 'package:cake_wallet/src/domain/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/generated/i18n.dart';

class TradeNotCreatedException implements Exception {
  ExchangeProviderDescription provider;
  String description;

  TradeNotCreatedException(this.provider, {this.description = ''});

  @override
  String toString() {
    var text = provider != null
        ? S.current.trade_for_not_created(provider.title)
        : S.current.trade_not_created;
    text += ' $description';

    return text;
  }
}
