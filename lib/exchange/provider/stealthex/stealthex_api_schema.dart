// spec reference: https://api.stealthex.io/docs/openapi.json

import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/exchange/utils/json_converters.dart";
import "package:cw_core/crypto_currency.dart";
import "package:json_annotation/json_annotation.dart";

part "stealthex_api_schema.g.dart";

enum StealthExEstimation {
  @JsonValue("direct")
  direct,
  @JsonValue("reversed")
  reversed,
  unknown,
}

enum StealthExRateType {
  @JsonValue("floating")
  floating,
  @JsonValue("fixed")
  fixed,
  unknown,
}

enum StealthExErrorKind {
  @JsonValue("NoPair")
  noPair,
  @JsonValue("NotFound")
  notFound,
  @JsonValue("NotAllowed")
  notAllowed,
  @JsonValue("NoExchangeRoute")
  noExchangeRoute,
  @JsonValue("RouteIsDisabled")
  routeIsDisabled,
  @JsonValue("MarketUnavailable")
  marketUnavailable,
  @JsonValue("InvalidAmount")
  invalidAmount,
  @JsonValue("InvalidData")
  invalidData,
  @JsonValue("RateId")
  rateId,
  @JsonValue("ExtraId")
  extraId,
  @JsonValue("NoUserApiKey")
  noUserApiKey,
  @JsonValue("RoutesMismatch")
  routesMismatch,
  unknown,
}

@JsonSerializable(createToJson: false)
class StealthExError {
  const StealthExError({required this.kind, required this.details});

  factory StealthExError.fromJson(Map<String, dynamic> json) => _$StealthExErrorFromJson(json);

  @JsonKey(name: "kind", unknownEnumValue: StealthExErrorKind.unknown)
  final StealthExErrorKind kind;
  @JsonKey(name: "details")
  final String details;
}

@JsonSerializable(createToJson: false)
class StealthExErrorResponse {
  const StealthExErrorResponse({required this.err});

  factory StealthExErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$StealthExErrorResponseFromJson(json);

  @JsonKey(name: "err")
  final StealthExError err;
}


class StealthExCurrencyConverter implements JsonConverter<CryptoCurrency, Map<String, String>> {
  const StealthExCurrencyConverter();

  @override
  Map<String, String> toJson(CryptoCurrency currency) => {
    "symbol": _symbolFor(currency),
    "network": _networkFor(currency),
  };

  @override
  CryptoCurrency fromJson(Map<String, String> json) {
    final network = json["network"];
    final currency = CryptoCurrency.safeParseCurrencyFromString(
      json["symbol"],
      tag: network == "mainnet" ? null : network,
    );
    if (currency == null) {
      throw ArgumentError("unknown StealthEx currency: $json");
    }
    return currency;
  }

  String _symbolFor(CryptoCurrency currency) =>
      currency == CryptoCurrency.usdcEPoly ? "usdce" : currency.title.toLowerCase();

  String _networkFor(CryptoCurrency currency) => switch (currency) {
    _ when currency == CryptoCurrency.arb || currency.tag == "ARB" => "arbitrum",
    _ when currency.tag == null => "mainnet",
    _ when currency == CryptoCurrency.maticpoly => "mainnet",
    _ when currency.tag == "POLY" => "matic",
    _ => currency.tag!.toLowerCase(),
  };
}

@JsonSerializable(explicitToJson: true)
@StealthExCurrencyConverter()
class StealthExRoute {
  const StealthExRoute({required this.from, required this.to});

  factory StealthExRoute.fromJson(Map<String, dynamic> json) => _$StealthExRouteFromJson(json);

  @JsonKey(name: "from")
  final CryptoCurrency from;
  @JsonKey(name: "to")
  final CryptoCurrency to;

  Map<String, dynamic> toJson() => _$StealthExRouteToJson(this);
}


@JsonSerializable(explicitToJson: true)
class StealthExRangeRequest {
  const StealthExRangeRequest({
    required this.route,
    required this.estimation,
    required this.rate,
    this.additionalFeePercent,
  });

  @JsonKey(name: "route")
  final StealthExRoute route;
  @JsonKey(name: "estimation")
  final StealthExEstimation estimation;
  @JsonKey(name: "rate")
  final StealthExRateType rate;

  @JsonKey(name: "additional_fee_percent", includeIfNull: false)
  final double? additionalFeePercent;

  Map<String, dynamic> toJson() => _$StealthExRangeRequestToJson(this);
}

@JsonSerializable(createToJson: false)
class StealthExRange {
  const StealthExRange({required this.minAmount, this.maxAmount});

  factory StealthExRange.fromJson(Map<String, dynamic> json) => _$StealthExRangeFromJson(json);

  @JsonKey(name: "min_amount")
  final double minAmount;

  // null means there is no upper limit
  @JsonKey(name: "max_amount")
  final double? maxAmount;
}


@JsonSerializable(explicitToJson: true)
class StealthExEstimateRequest {
  const StealthExEstimateRequest({
    required this.route,
    required this.amount,
    required this.estimation,
    required this.rate,
    this.additionalFeePercent,
  });

  @JsonKey(name: "route")
  final StealthExRoute route;
  @JsonKey(name: "amount")
  final double amount;
  @JsonKey(name: "estimation")
  final StealthExEstimation estimation;
  @JsonKey(name: "rate")
  final StealthExRateType rate;
  @JsonKey(name: "additional_fee_percent", includeIfNull: false)
  final double? additionalFeePercent;

  Map<String, dynamic> toJson() => _$StealthExEstimateRequestToJson(this);
}

@JsonSerializable(createToJson: false)
class StealthExEstimateRate {
  const StealthExEstimateRate({required this.id, required this.validUntil});

  factory StealthExEstimateRate.fromJson(Map<String, dynamic> json) =>
      _$StealthExEstimateRateFromJson(json);

  @JsonKey(name: "id")
  final String id;

  @JsonKey(name: "valid_until")
  final DateTime validUntil;
}

@JsonSerializable(createToJson: false)
class StealthExEstimate {
  const StealthExEstimate({required this.estimatedAmount, this.rate});

  factory StealthExEstimate.fromJson(Map<String, dynamic> json) =>
      _$StealthExEstimateFromJson(json);

  @JsonKey(name: "estimated_amount")
  final double estimatedAmount;

  @JsonKey(name: "rate")
  final StealthExEstimateRate? rate;
}


@JsonSerializable(explicitToJson: true)
class StealthExCreateExchangeRequest {
  const StealthExCreateExchangeRequest({
    required this.route,
    required this.amount,
    required this.estimation,
    required this.rate,
    required this.address,
    this.rateId,
    this.extraId,
    this.refundAddress,
    this.refundExtraId,
    this.additionalFeePercent,
  });

  @JsonKey(name: "route")
  final StealthExRoute route;
  @JsonKey(name: "amount")
  final double amount;
  @JsonKey(name: "estimation")
  final StealthExEstimation estimation;
  @JsonKey(name: "rate")
  final StealthExRateType rate;
  @JsonKey(name: "address")
  final String address;
  @JsonKey(name: "rate_id", includeIfNull: false)
  final String? rateId;
  @JsonKey(name: "extra_id", includeIfNull: false)
  final String? extraId;
  @JsonKey(name: "refund_address", includeIfNull: false)
  final String? refundAddress;
  @JsonKey(name: "refund_extra_id", includeIfNull: false)
  final String? refundExtraId;
  @JsonKey(name: "additional_fee_percent", includeIfNull: false)
  final double? additionalFeePercent;

  Map<String, dynamic> toJson() => _$StealthExCreateExchangeRequestToJson(this);
}

@JsonSerializable(createToJson: false)
class StealthExExchangeSide {
  const StealthExExchangeSide({
    required this.symbol,
    required this.network,
    required this.amount,
    required this.expectedAmount,
    required this.address,
    this.extraId,
    this.txHash,
    this.addressExplorerUrl,
    this.txExplorerUrl,
  });

  factory StealthExExchangeSide.fromJson(Map<String, dynamic> json) =>
      _$StealthExExchangeSideFromJson(json);

  @JsonKey(name: "symbol")
  final String symbol;
  @JsonKey(name: "network")
  final String network;
  @JsonKey(name: "amount")
  final double amount;
  @JsonKey(name: "expected_amount")
  final double expectedAmount;
  @JsonKey(name: "address")
  final String address;
  @JsonKey(name: "extra_id")
  final String? extraId;
  @JsonKey(name: "tx_hash")
  final String? txHash;
  @JsonKey(name: "address_explorer_url")
  final String? addressExplorerUrl;
  @JsonKey(name: "tx_explorer_url")
  final String? txExplorerUrl;
}

@JsonSerializable(createToJson: false)
@TradeStateConverter()
class StealthExExchange {
  const StealthExExchange({
    required this.id,
    required this.status,
    required this.rate,
    required this.deposit,
    required this.withdrawal,
    required this.createdAt,
    this.refundAddress,
    this.refundExtraId,
    this.expiresAt,
  });

  factory StealthExExchange.fromJson(Map<String, dynamic> json) =>
      _$StealthExExchangeFromJson(json);

  @JsonKey(name: "id")
  final String id;
  @JsonKey(name: "status")
  final TradeState status;
  @JsonKey(name: "rate", unknownEnumValue: StealthExRateType.unknown)
  final StealthExRateType rate;
  @JsonKey(name: "deposit")
  final StealthExExchangeSide deposit;
  @JsonKey(name: "withdrawal")
  final StealthExExchangeSide withdrawal;
  @JsonKey(name: "refund_address")
  final String? refundAddress;
  @JsonKey(name: "refund_extra_id")
  final String? refundExtraId;
  @JsonKey(name: "created_at")
  final DateTime createdAt;
  @JsonKey(name: "expires_at")
  final DateTime? expiresAt;
}
