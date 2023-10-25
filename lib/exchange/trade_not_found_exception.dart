import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/generated/i18n.dart';

class TradeNotFoundException implements Exception {
  TradeNotFoundException(this.tradeId, {required this.provider, this.description = ''});

  String tradeId;
  ExchangeProviderDescription provider;
  String description;

  @override
  String toString() => '${S.current.trade_id_not_found(tradeId, provider.title)} $description';
}
