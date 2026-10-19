// spec reference: https://trocador.app/en/docs/

import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/exchange/utils/json_converters.dart";
import "package:cake_wallet/exchange/utils/provider_api.dart";
import "package:json_annotation/json_annotation.dart";

part "trocador_api_schema.g.dart";

// api uses python spelling of bools
class TrocadorBoolConverter implements JsonConverter<bool, Object> {
  const TrocadorBoolConverter();

  @override
  bool fromJson(Object json) {
    if (json is bool) {
      return json;
    }
    return json.toString().toLowerCase() == "true";
  }

  @override
  Object toJson(bool value) => value ? "True" : "False";
}

// the top level amount_from, amount_to, minimum and
// maximum come back as json numbers, while the same values inside a quote come back as strings
class TrocadorAmountConverter implements JsonConverter<String, Object> {
  const TrocadorAmountConverter();

  @override
  String fromJson(Object json) => json.toString();

  @override
  Object toJson(String value) => value;
}

enum TrocadorRating {
  @JsonValue("A")
  a,
  @JsonValue("B")
  b,
  @JsonValue("C")
  c,
  @JsonValue("D")
  d,
  unknown;

  String get label => switch (this) {
    a => "A",
    b => "B",
    c => "C",
    d => "D",
    unknown => "N/A",
  };
}


@JsonSerializable()
class TrocadorCoinRequest extends ApiRequest<List<TrocadorCoin>> {
  const TrocadorCoinRequest({this.ticker, this.name});

  @JsonKey(name: "ticker", includeIfNull: false)
  final String? ticker;
  @JsonKey(name: "name", includeIfNull: false)
  final String? name;

  @override
  String path() => "/coin";

  @override
  Map<String, dynamic> toJson() => _$TrocadorCoinRequestToJson(this);

  @override
  List<TrocadorCoin> decode(Object json) => (json as List<dynamic>)
      .map((item) => TrocadorCoin.fromJson(item as Map<String, dynamic>))
      .toList();
}

@JsonSerializable(createToJson: false)
@TrocadorBoolConverter()
class TrocadorCoin {
  const TrocadorCoin({
    required this.name,
    required this.ticker,
    required this.network,
    this.memo,
    this.image,
    this.minimum,
    this.maximum,
  });

  factory TrocadorCoin.fromJson(Map<String, dynamic> json) => _$TrocadorCoinFromJson(json);

  @JsonKey(name: "name")
  final String name;
  @JsonKey(name: "ticker")
  final String ticker;
  @JsonKey(name: "network")
  final String network;

  @JsonKey(name: "memo")
  final bool? memo;
  @JsonKey(name: "image")
  final String? image;
  @JsonKey(name: "minimum")
  @TrocadorAmountConverter()
  final String? minimum;
  @JsonKey(name: "maximum")
  @TrocadorAmountConverter()
  final String? maximum;
}


@JsonSerializable()
@TrocadorBoolConverter()
class TrocadorNewRateRequest extends ApiRequest<TrocadorRate> {
  const TrocadorNewRateRequest({
    required this.tickerFrom,
    required this.networkFrom,
    required this.tickerTo,
    required this.networkTo,
    this.amountFrom,
    this.amountTo,
    this.payment,
    this.minKycrating,
    this.minLogpolicy,
    this.markup,
    this.bestOnly,
  });

  @JsonKey(name: "ticker_from")
  final String tickerFrom;
  @JsonKey(name: "network_from")
  final String networkFrom;
  @JsonKey(name: "ticker_to")
  final String tickerTo;
  @JsonKey(name: "network_to")
  final String networkTo;

  @JsonKey(name: "amount_from", includeIfNull: false)
  final String? amountFrom;
  @JsonKey(name: "amount_to", includeIfNull: false)
  final String? amountTo;
  @JsonKey(name: "payment", includeIfNull: false)
  final bool? payment;
  @JsonKey(name: "min_kycrating", includeIfNull: false)
  final TrocadorRating? minKycrating;
  @JsonKey(name: "min_logpolicy", includeIfNull: false)
  final TrocadorRating? minLogpolicy;
  @JsonKey(name: "markup", includeIfNull: false)
  final String? markup;
  @JsonKey(name: "best_only", includeIfNull: false)
  final bool? bestOnly;

  @override
  String path() => "/new_rate";

  @override
  Map<String, dynamic> toJson() => _$TrocadorNewRateRequestToJson(this);

  @override
  TrocadorRate decode(Object json) => TrocadorRate.fromJson(json as Map<String, dynamic>);
}

// every provider is quoted once per rate type, so the same provider can show up twice.
// a swap quote carries amount_to, a payment quote carries amount_from instead
@JsonSerializable(createToJson: false)
@TrocadorBoolConverter()
class TrocadorQuote {
  const TrocadorQuote({required this.provider, this.fixed, this.amountFrom, this.amountTo});

  factory TrocadorQuote.fromJson(Map<String, dynamic> json) => _$TrocadorQuoteFromJson(json);

  @JsonKey(name: "provider")
  final String provider;
  @JsonKey(name: "fixed")
  final bool? fixed;
  @JsonKey(name: "amount_from")
  @TrocadorAmountConverter()
  final String? amountFrom;
  @JsonKey(name: "amount_to")
  @TrocadorAmountConverter()
  final String? amountTo;
}

@JsonSerializable(createToJson: false)
class TrocadorQuotes {
  const TrocadorQuotes({this.quotes});

  factory TrocadorQuotes.fromJson(Map<String, dynamic> json) => _$TrocadorQuotesFromJson(json);

  @JsonKey(name: "quotes")
  final List<TrocadorQuote>? quotes;
}

@JsonSerializable(createToJson: false)
@TradeStateConverter()
@TrocadorBoolConverter()
class TrocadorRate {
  const TrocadorRate({
    required this.tradeId,
    required this.tickerFrom,
    required this.tickerTo,
    required this.coinFrom,
    required this.coinTo,
    required this.networkFrom,
    required this.networkTo,
    required this.amountFrom,
    required this.amountTo,
    required this.provider,
    required this.status,
    this.date,
    this.fixed,
    this.payment,
    this.quotes,
  });

  factory TrocadorRate.fromJson(Map<String, dynamic> json) => _$TrocadorRateFromJson(json);

  @JsonKey(name: "trade_id")
  final String tradeId;
  @JsonKey(name: "date")
  final DateTime? date;
  @JsonKey(name: "ticker_from")
  final String tickerFrom;
  @JsonKey(name: "ticker_to")
  final String tickerTo;
  @JsonKey(name: "coin_from")
  final String coinFrom;
  @JsonKey(name: "coin_to")
  final String coinTo;
  @JsonKey(name: "network_from")
  final String networkFrom;
  @JsonKey(name: "network_to")
  final String networkTo;
  @JsonKey(name: "amount_from")
  @TrocadorAmountConverter()
  final String amountFrom;
  @JsonKey(name: "amount_to")
  @TrocadorAmountConverter()
  final String amountTo;

  @JsonKey(name: "provider")
  final String provider;

  @JsonKey(name: "fixed")
  final bool? fixed;
  @JsonKey(name: "status")
  final TradeState status;
  @JsonKey(name: "quotes")
  final TrocadorQuotes? quotes;
  @JsonKey(name: "payment")
  final bool? payment;
}


@JsonSerializable()
@TrocadorBoolConverter()
class TrocadorNewTradeRequest extends ApiRequest<TrocadorTrade> {
  const TrocadorNewTradeRequest({
    required this.tickerFrom,
    required this.networkFrom,
    required this.tickerTo,
    required this.networkTo,
    required this.address,
    required this.provider,
    required this.fixed,
    this.id,
    this.amountFrom,
    this.amountTo,
    this.addressMemo,
    this.refund,
    this.refundMemo,
    this.payment,
    this.minKycrating,
    this.minLogpolicy,
    this.webhook,
    this.webhookKey,
    this.markup,
  });

  @JsonKey(name: "id", includeIfNull: false)
  final String? id;
  @JsonKey(name: "ticker_from")
  final String tickerFrom;
  @JsonKey(name: "network_from")
  final String networkFrom;
  @JsonKey(name: "ticker_to")
  final String tickerTo;
  @JsonKey(name: "network_to")
  final String networkTo;
  @JsonKey(name: "amount_from", includeIfNull: false)
  final String? amountFrom;
  @JsonKey(name: "amount_to", includeIfNull: false)
  final String? amountTo;
  @JsonKey(name: "address")
  final String address;
  @JsonKey(name: "address_memo", includeIfNull: false)
  final String? addressMemo;
  @JsonKey(name: "refund", includeIfNull: false)
  final String? refund;
  @JsonKey(name: "refund_memo", defaultValue: "0")
  final String? refundMemo;
  @JsonKey(name: "provider")
  final String provider;
  @JsonKey(name: "fixed")
  final bool fixed;
  @JsonKey(name: "payment", includeIfNull: false)
  final bool? payment;
  @JsonKey(name: "min_kycrating", includeIfNull: false)
  final TrocadorRating? minKycrating;
  @JsonKey(name: "min_logpolicy", includeIfNull: false)
  final TrocadorRating? minLogpolicy;

  @JsonKey(name: "webhook", includeIfNull: false)
  final String? webhook;
  @JsonKey(name: "webhook_key", includeIfNull: false)
  final String? webhookKey;
  @JsonKey(name: "markup", includeIfNull: false)
  final String? markup;

  @override
  String path() => "/new_trade";

  @override
  Map<String, dynamic> toJson() => _$TrocadorNewTradeRequestToJson(this);

  @override
  TrocadorTrade decode(Object json) => TrocadorTrade.fromJson(json as Map<String, dynamic>);
}

@JsonSerializable(createFactory: false)
class TrocadorTradeRequest extends ApiRequest<TrocadorTrade> {
  const TrocadorTradeRequest({required this.id});

  @JsonKey(name: "id")
  final String id;

  @override
  String path() => "/trade";

  @override
  Map<String, dynamic> toJson() => _$TrocadorTradeRequestToJson(this);

  @override
  TrocadorTrade decode(Object json) =>
      TrocadorTrade.fromJson((json as List<dynamic>).first as Map<String, dynamic>);
}

@JsonSerializable(createToJson: false)
class TrocadorTradeDetails {
  const TrocadorTradeDetails({this.hashout});

  factory TrocadorTradeDetails.fromJson(Map<String, dynamic> json) =>
      _$TrocadorTradeDetailsFromJson(json);

  @JsonKey(name: "hashout")
  final String? hashout;
}

@JsonSerializable(createToJson: false)
@TradeStateConverter()
@TrocadorBoolConverter()
class TrocadorTrade {
  const TrocadorTrade({
    required this.tradeId,
    required this.tickerFrom,
    required this.tickerTo,
    required this.coinFrom,
    required this.coinTo,
    required this.networkFrom,
    required this.networkTo,
    required this.amountFrom,
    required this.amountTo,
    required this.provider,
    required this.status,
    required this.addressProvider,
    required this.addressUser,
    this.date,
    this.fixed,
    this.payment,
    this.addressProviderMemo,
    this.addressUserMemo,
    this.refundAddress,
    this.refundAddressMemo,
    this.password,
    this.idProvider,
    this.quotes,
    this.details,
  });

  factory TrocadorTrade.fromJson(Map<String, dynamic> json) => _$TrocadorTradeFromJson(json);

  @JsonKey(name: "trade_id")
  final String tradeId;
  @JsonKey(name: "date")
  final DateTime? date;
  @JsonKey(name: "ticker_from")
  final String tickerFrom;
  @JsonKey(name: "ticker_to")
  final String tickerTo;
  @JsonKey(name: "coin_from")
  final String coinFrom;
  @JsonKey(name: "coin_to")
  final String coinTo;
  @JsonKey(name: "network_from")
  final String networkFrom;
  @JsonKey(name: "network_to")
  final String networkTo;
  @JsonKey(name: "amount_from")
  @TrocadorAmountConverter()
  final String amountFrom;
  @JsonKey(name: "amount_to")
  @TrocadorAmountConverter()
  final String amountTo;
  @JsonKey(name: "provider")
  final String provider;
  @JsonKey(name: "fixed")
  final bool? fixed;
  @JsonKey(name: "status")
  final TradeState status;

  @JsonKey(name: "address_provider")
  final String addressProvider;
  @JsonKey(name: "address_provider_memo")
  final String? addressProviderMemo;

  @JsonKey(name: "address_user")
  final String addressUser;
  @JsonKey(name: "address_user_memo")
  final String? addressUserMemo;
  @JsonKey(name: "refund_address")
  final String? refundAddress;
  @JsonKey(name: "refund_address_memo")
  final String? refundAddressMemo;

  @JsonKey(name: "password")
  final String? password;
  @JsonKey(name: "id_provider")
  final String? idProvider;
  @JsonKey(name: "quotes")
  final TrocadorQuotes? quotes;
  @JsonKey(name: "details")
  final TrocadorTradeDetails? details;
  @JsonKey(name: "payment")
  final bool? payment;
}


@JsonSerializable(createToJson: false)
@TrocadorBoolConverter()
class TrocadorPartner {
  const TrocadorPartner({
    required this.name,
    this.rating,
    this.insurance,
    this.enabledMarkup,
    this.eta,
  });

  factory TrocadorPartner.fromJson(Map<String, dynamic> json) => _$TrocadorPartnerFromJson(json);

  @JsonKey(name: "name")
  final String name;
  @JsonKey(name: "rating", unknownEnumValue: TrocadorRating.unknown)
  final TrocadorRating? rating;
  @JsonKey(name: "insurance")
  final double? insurance;
  @JsonKey(name: "enabledmarkup")
  final bool? enabledMarkup;
  @JsonKey(name: "eta")
  final double? eta;
}

@JsonSerializable(createFactory: false)
class TrocadorExchangesRequest extends ApiRequest<TrocadorExchangesResponse> {
  const TrocadorExchangesRequest({required this.apiKey});

  @JsonKey(name: "api_key")
  final String apiKey;

  @override
  String path() => "/exchanges";

  @override
  Map<String, dynamic> toJson() => _$TrocadorExchangesRequestToJson(this);

  @override
  TrocadorExchangesResponse decode(Object json) =>
      TrocadorExchangesResponse.fromJson(json as Map<String, dynamic>);
}

@JsonSerializable(createToJson: false)
class TrocadorExchangesResponse {
  const TrocadorExchangesResponse({required this.list});

  factory TrocadorExchangesResponse.fromJson(Map<String, dynamic> json) =>
      _$TrocadorExchangesResponseFromJson(json);

  @JsonKey(name: "list")
  final List<TrocadorPartner> list;
}
