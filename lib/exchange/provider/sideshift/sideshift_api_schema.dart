// spec reference: https://docs.sideshift.ai/openapi.yaml

import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/exchange/utils/json_converters.dart";
import "package:json_annotation/json_annotation.dart";

part "sideshift_api_schema.g.dart";

enum SideShiftShiftType {
  @JsonValue("fixed")
  fixed,
  @JsonValue("variable")
  variable,
  unknown,
}

@JsonSerializable(createToJson: false)
class SideShiftPermissions {
  const SideShiftPermissions({required this.createShift});

  factory SideShiftPermissions.fromJson(Map<String, dynamic> json) =>
      _$SideShiftPermissionsFromJson(json);

  @JsonKey(name: "createShift")
  final bool createShift;
}

@JsonSerializable(createToJson: false)
class SideShiftPair {
  const SideShiftPair({
    required this.rate,
    required this.depositCoin,
    required this.settleCoin,
    required this.depositNetwork,
    required this.settleNetwork,
    this.min,
    this.max,
  });

  factory SideShiftPair.fromJson(Map<String, dynamic> json) => _$SideShiftPairFromJson(json);

  @JsonKey(name: "min")
  final String? min;
  @JsonKey(name: "max")
  final String? max;
  @JsonKey(name: "rate")
  final String rate;
  @JsonKey(name: "depositCoin")
  final String depositCoin;
  @JsonKey(name: "settleCoin")
  final String settleCoin;
  @JsonKey(name: "depositNetwork")
  final String depositNetwork;
  @JsonKey(name: "settleNetwork")
  final String settleNetwork;
}

@JsonSerializable()
class SideShiftQuoteRequest {
  const SideShiftQuoteRequest({
    required this.depositCoin,
    required this.settleCoin,
    required this.affiliateId,
    this.depositNetwork,
    this.settleNetwork,
    this.depositAmount,
    this.settleAmount,
  });

  @JsonKey(name: "depositCoin")
  final String depositCoin;
  @JsonKey(name: "depositNetwork", includeIfNull: false)
  final String? depositNetwork;
  @JsonKey(name: "settleCoin")
  final String settleCoin;
  @JsonKey(name: "settleNetwork", includeIfNull: false)
  final String? settleNetwork;
  @JsonKey(name: "depositAmount", includeIfNull: false)
  final String? depositAmount;
  @JsonKey(name: "settleAmount", includeIfNull: false)
  final String? settleAmount;
  @JsonKey(name: "affiliateId")
  final String affiliateId;

  Map<String, dynamic> toJson() => _$SideShiftQuoteRequestToJson(this);
}

@JsonSerializable(createToJson: false)
class SideShiftQuote {
  const SideShiftQuote({
    required this.id,
    required this.createdAt,
    required this.depositCoin,
    required this.settleCoin,
    required this.depositNetwork,
    required this.settleNetwork,
    required this.expiresAt,
    required this.depositAmount,
    required this.settleAmount,
    required this.rate,
    this.affiliateId,
  });

  factory SideShiftQuote.fromJson(Map<String, dynamic> json) => _$SideShiftQuoteFromJson(json);

  @JsonKey(name: "id")
  final String id;
  @JsonKey(name: "createdAt")
  final DateTime createdAt;
  @JsonKey(name: "depositCoin")
  final String depositCoin;
  @JsonKey(name: "settleCoin")
  final String settleCoin;
  @JsonKey(name: "depositNetwork")
  final String depositNetwork;
  @JsonKey(name: "settleNetwork")
  final String settleNetwork;
  @JsonKey(name: "expiresAt")
  final DateTime expiresAt;
  @JsonKey(name: "depositAmount")
  final String depositAmount;
  @JsonKey(name: "settleAmount")
  final String settleAmount;
  @JsonKey(name: "rate")
  final String rate;
  @JsonKey(name: "affiliateId")
  final String? affiliateId;
}


@JsonSerializable()
class SideShiftCreateFixedShiftRequest {
  const SideShiftCreateFixedShiftRequest({
    required this.settleAddress,
    required this.affiliateId,
    required this.quoteId,
    this.refundAddress,
    this.settleMemo,
  });

  @JsonKey(name: "settleAddress")
  final String settleAddress;
  @JsonKey(name: "affiliateId")
  final String affiliateId;
  @JsonKey(name: "quoteId")
  final String quoteId;
  @JsonKey(name: "refundAddress", includeIfNull: false)
  final String? refundAddress;
  @JsonKey(name: "settleMemo", includeIfNull: false)
  final String? settleMemo;

  Map<String, dynamic> toJson() => _$SideShiftCreateFixedShiftRequestToJson(this);
}

@JsonSerializable()
class SideShiftCreateVariableShiftRequest {
  const SideShiftCreateVariableShiftRequest({
    required this.settleAddress,
    required this.affiliateId,
    required this.depositCoin,
    required this.settleCoin,
    this.depositNetwork,
    this.settleNetwork,
    this.refundAddress,
    this.settleMemo,
  });

  @JsonKey(name: "settleAddress")
  final String settleAddress;
  @JsonKey(name: "refundAddress", includeIfNull: false)
  final String? refundAddress;
  @JsonKey(name: "affiliateId")
  final String affiliateId;
  @JsonKey(name: "depositCoin")
  final String depositCoin;
  @JsonKey(name: "settleCoin")
  final String settleCoin;
  @JsonKey(name: "depositNetwork", includeIfNull: false)
  final String? depositNetwork;
  @JsonKey(name: "settleNetwork", includeIfNull: false)
  final String? settleNetwork;
  @JsonKey(name: "settleMemo", includeIfNull: false)
  final String? settleMemo;

  Map<String, dynamic> toJson() => _$SideShiftCreateVariableShiftRequestToJson(this);
}

@JsonSerializable(createToJson: false)
@TradeStateConverter()
class SideShiftShift {
  const SideShiftShift({
    required this.id,
    required this.createdAt,
    required this.depositCoin,
    required this.settleCoin,
    required this.depositNetwork,
    required this.settleNetwork,
    required this.depositAddress,
    required this.settleAddress,
    required this.depositMin,
    required this.depositMax,
    required this.type,
    required this.expiresAt,
    required this.updatedAt,
    required this.averageShiftSeconds,
    this.status,
    this.refundAddress,
    this.depositMemo,
    this.settleMemo,
    this.quoteId,
    this.depositAmount,
    this.settleAmount,
    this.rate,
    this.depositHash,
    this.settleHash,
    this.depositReceivedAt,
  });

  factory SideShiftShift.fromJson(Map<String, dynamic> json) => _$SideShiftShiftFromJson(json);

  @JsonKey(name: "id")
  final String id;
  @JsonKey(name: "createdAt")
  final DateTime createdAt;
  @JsonKey(name: "depositCoin")
  final String depositCoin;
  @JsonKey(name: "settleCoin")
  final String settleCoin;
  @JsonKey(name: "depositNetwork")
  final String depositNetwork;
  @JsonKey(name: "settleNetwork")
  final String settleNetwork;
  @JsonKey(name: "depositAddress")
  final String depositAddress;
  @JsonKey(name: "settleAddress")
  final String settleAddress;
  @JsonKey(name: "depositMin")
  final String depositMin;
  @JsonKey(name: "depositMax")
  final String depositMax;
  @JsonKey(name: "type", unknownEnumValue: SideShiftShiftType.unknown)
  final SideShiftShiftType type;
  @JsonKey(name: "expiresAt")
  final DateTime expiresAt;
  @JsonKey(name: "updatedAt")
  final DateTime updatedAt;
  @JsonKey(name: "averageShiftSeconds")
  final String averageShiftSeconds;
  @JsonKey(name: "status")
  final TradeState? status;
  @JsonKey(name: "refundAddress")
  final String? refundAddress;
  @JsonKey(name: "depositMemo")
  final String? depositMemo;
  @JsonKey(name: "settleMemo")
  final String? settleMemo;
  @JsonKey(name: "quoteId")
  final String? quoteId;
  @JsonKey(name: "depositAmount")
  final String? depositAmount;
  @JsonKey(name: "settleAmount")
  final String? settleAmount;
  @JsonKey(name: "rate")
  final String? rate;
  @JsonKey(name: "depositHash")
  final String? depositHash;
  @JsonKey(name: "settleHash")
  final String? settleHash;
  @JsonKey(name: "depositReceivedAt")
  final DateTime? depositReceivedAt;
}
