import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/generated/i18n.dart';

class TradeNotFoundException implements Exception {
  TradeNotFoundException(this.tradeId, {this.provider, this.description = ''});

  String tradeId;
  ExchangeProviderDescription provider;
  String description;

  @override
  String toString() {
    var text = tradeId != null && provider != null
        ? S.current.trade_id_not_found(tradeId, provider.title)
        : S.current.trade_not_found;
    text += ' $description';

    return text;
  }
}
