import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cw_core/currency.dart";
import "package:cw_core/exceptions/cake_exception.dart";

class ExchangeProviderResponseException extends ServerResponseException {
  const ExchangeProviderResponseException(super.message);
}



class ExchangeProviderResponseCodeException extends ExchangeProviderResponseException with ResponseCodeException {
  ExchangeProviderResponseCodeException(super.message, this.code);

  @override
  final int code;
}

class RateNotFoundException extends ExchangeProviderResponseException {
  const RateNotFoundException(this.from, this.to, {required this.provider, this.description = ''}) : super("");

  final Currency from;
  final Currency to;
  final ExchangeProviderDescription provider;
  final String description;

  @override
  String get message => 'no rate ${from.symbol} -> ${to.symbol} at $provider, $description';

}

class TradeNotFoundException extends ExchangeProviderResponseException {
  const TradeNotFoundException(this.tradeId, {required this.provider, this.description = ''}) : super("");

  final String tradeId;
  final ExchangeProviderDescription provider;
  final String description;

  @override
  String get message => '${S.current.trade_id_not_found(tradeId, provider.title)} $description';
}


class TradeExecutionException extends ExchangeProviderResponseException {
  const TradeExecutionException(super.message);
}