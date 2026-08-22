// spec reference: https://www.xoswap.com/docs/v3

import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/exchange/utils/json_converters.dart";
import "package:json_annotation/json_annotation.dart";

part "xoswap_api_schema.g.dart";

@JsonSerializable(createToJson: false)
class XOSwapErrorResponse {
  const XOSwapErrorResponse({this.code, this.error, this.message, this.details});

  factory XOSwapErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$XOSwapErrorResponseFromJson(json);

  @JsonKey(name: "code")
  final String? code;
  @JsonKey(name: "error")
  final String? error;
  @JsonKey(name: "message")
  final String? message;
  @JsonKey(name: "details")
  final String? details;
}

// /v3/pairs/{id}/rates sends amount.value as a number while
// /v3/orders sends it as a string, so a plain double throws on every order response
class XOSwapAmountValueConverter implements JsonConverter<double, Object> {
  const XOSwapAmountValueConverter();

  @override
  double fromJson(Object json) {
    if (json is num) {
      return json.toDouble();
    }
    if (json is String) {
      return double.parse(json);
    }
    throw ArgumentError("unexpected XOSwap amount value: $json");
  }

  @override
  Object toJson(double value) => value;
}

@JsonSerializable(createToJson: false)
class XOSwapAmount {
  const XOSwapAmount({required this.value, this.assetId});

  factory XOSwapAmount.fromJson(Map<String, dynamic> json) => _$XOSwapAmountFromJson(json);

  @JsonKey(name: "value")
  @XOSwapAmountValueConverter()
  final double value;

  @JsonKey(name: "assetId")
  final String? assetId;
}


@JsonSerializable()
class XOSwapAssetsRequest {
  const XOSwapAssetsRequest({this.networks, this.query});

  @JsonKey(name: "networks", includeIfNull: false)
  final String? networks;

  @JsonKey(name: "query", includeIfNull: false)
  final String? query;

  Map<String, dynamic> toJson() => _$XOSwapAssetsRequestToJson(this);
}

@JsonSerializable(createToJson: false)
class XOSwapAsset {
  const XOSwapAsset({required this.id, this.symbol, this.meta});

  factory XOSwapAsset.fromJson(Map<String, dynamic> json) => _$XOSwapAssetFromJson(json);

  @JsonKey(name: "id")
  final String id;

  @JsonKey(name: "symbol")
  final String? symbol;

  @JsonKey(name: "meta")
  final Map<String, dynamic>? meta;
}


@JsonSerializable(createToJson: false)
class XOSwapRate {
  const XOSwapRate({
    required this.amount,
    required this.minerFee,
    required this.min,
    required this.max,
    required this.expiry,
  });

  factory XOSwapRate.fromJson(Map<String, dynamic> json) => _$XOSwapRateFromJson(json);

  @JsonKey(name: "amount")
  final XOSwapAmount amount;
  @JsonKey(name: "minerFee")
  final XOSwapAmount minerFee;
  @JsonKey(name: "min")
  final XOSwapAmount min;
  @JsonKey(name: "max")
  final XOSwapAmount max;
  @JsonKey(name: "expiry")
  @MillisDateTimeConverter()
  final DateTime expiry;
}


@JsonSerializable()
class XOSwapCreateOrderRequest {
  const XOSwapCreateOrderRequest({
    required this.pairId,
    required this.fromAmount,
    required this.fromAddress,
    required this.toAmount,
    required this.toAddress,
    this.fromAddressTag,
    this.toAddressTag,
    this.slippage,
  });

  @JsonKey(name: "pairId")
  final String pairId;

  @JsonKey(name: "fromAmount")
  final String fromAmount;

  @JsonKey(name: "toAmount")
  final String toAmount;

  @JsonKey(name: "fromAddress")
  final String fromAddress;
  @JsonKey(name: "fromAddressTag", includeIfNull: false)
  final String? fromAddressTag;

  @JsonKey(name: "toAddress")
  final String toAddress;
  @JsonKey(name: "toAddressTag", includeIfNull: false)
  final String? toAddressTag;

  @JsonKey(name: "slippage", includeIfNull: false)
  final double? slippage;

  Map<String, dynamic> toJson() => _$XOSwapCreateOrderRequestToJson(this);
}

@JsonSerializable(createToJson: false)
@TradeStateConverter()
class XOSwapOrder {
  const XOSwapOrder({
    required this.id,
    required this.pairId,
    required this.status,
    required this.amount,
    required this.payInAddress,
    required this.fromAddress,
    required this.toAddress,
    required this.createdAt,
    this.toAmount,
    this.payInAddressTag,
    this.fromAddressTag,
    this.toAddressTag,
    this.fromTransactionId,
    this.toTransactionId,
    this.providerOrderId,
    this.rateId,
    this.message,
    this.updatedAt,
    this.extraFeatures,
  });

  factory XOSwapOrder.fromJson(Map<String, dynamic> json) => _$XOSwapOrderFromJson(json);

  @JsonKey(name: "id")
  final String id;
  @JsonKey(name: "pairId")
  final String pairId;

  @JsonKey(name: "status")
  final TradeState status;

  @JsonKey(name: "amount")
  final XOSwapAmount amount;
  @JsonKey(name: "toAmount")
  final XOSwapAmount? toAmount;

  @JsonKey(name: "payInAddress")
  final String payInAddress;
  @JsonKey(name: "payInAddressTag")
  final String? payInAddressTag;
  @JsonKey(name: "fromAddress")
  final String fromAddress;
  @JsonKey(name: "fromAddressTag")
  final String? fromAddressTag;
  @JsonKey(name: "toAddress")
  final String toAddress;
  @JsonKey(name: "toAddressTag")
  final String? toAddressTag;
  @JsonKey(name: "fromTransactionId")
  final String? fromTransactionId;
  @JsonKey(name: "toTransactionId")
  final String? toTransactionId;
  @JsonKey(name: "providerOrderId")
  final String? providerOrderId;
  @JsonKey(name: "rateId")
  final String? rateId;
  @JsonKey(name: "message")
  final String? message;
  @JsonKey(name: "createdAt")
  final DateTime createdAt;
  @JsonKey(name: "updatedAt")
  final DateTime? updatedAt;

  // don't you love when apis just don't document some part of the json
  @JsonKey(name: "extraFeatures")
  final Map<String, dynamic>? extraFeatures;
}
