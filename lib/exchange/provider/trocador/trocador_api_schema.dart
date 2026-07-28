// spec reference: https://trocador.app/en/docs/

import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/exchange/utils/json_converters.dart";
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

enum TrocadorRating {
  @JsonValue("A")
  a,
  @JsonValue("B")
  b,
  @JsonValue("C")
  c,
  @JsonValue("D")
  d,
  unknown,
}


@JsonSerializable()
class TrocadorCoinRequest {
  const TrocadorCoinRequest({this.ticker, this.name});

  @JsonKey(name: "ticker", includeIfNull: false)
  final String? ticker;
  @JsonKey(name: "name", includeIfNull: false)
  final String? name;

  Map<String, dynamic> toJson() => _$TrocadorCoinRequestToJson(this);
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
  final String? minimum;
  @JsonKey(name: "maximum")
  final String? maximum;
}


@JsonSerializable()
@TrocadorBoolConverter()
class TrocadorNewRateRequest {
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

  Map<String, dynamic> toJson() => _$TrocadorNewRateRequestToJson(this);
}

@JsonSerializable(createToJson: false)
class TrocadorQuote {
  const TrocadorQuote({required this.provider});

  factory TrocadorQuote.fromJson(Map<String, dynamic> json) => _$TrocadorQuoteFromJson(json);

  @JsonKey(name: "provider")
  final String provider;
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
  final String amountFrom;
  @JsonKey(name: "amount_to")
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
class TrocadorNewTradeRequest {
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

  Map<String, dynamic> toJson() => _$TrocadorNewTradeRequestToJson(this);
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
  final String amountFrom;
  @JsonKey(name: "amount_to")
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

@JsonSerializable(createToJson: false)
class TrocadorExchangesResponse {
  const TrocadorExchangesResponse({required this.list});

  factory TrocadorExchangesResponse.fromJson(Map<String, dynamic> json) =>
      _$TrocadorExchangesResponseFromJson(json);

  @JsonKey(name: "list")
  final List<TrocadorPartner> list;
}
