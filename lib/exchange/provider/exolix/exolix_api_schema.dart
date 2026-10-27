// spec reference: https://exolix.com/developers

import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/exchange/utils/json_converters.dart";
import "package:json_annotation/json_annotation.dart";

part "exolix_api_schema.g.dart";

enum ExolixRateType {
  @JsonValue("float")
  float,
  @JsonValue("fixed")
  fixed,
  unknown,
}

enum ExolixTransactionSource {
  @JsonValue("api")
  api,
  @JsonValue("referral")
  referral,
  unknown,
}


@JsonSerializable()
class ExolixRateRequest {
  const ExolixRateRequest({
    required this.coinFrom,
    required this.coinTo,
    required this.networkFrom,
    required this.networkTo,
    required this.rateType,
    required this.apiToken,
    this.amount,
    this.withdrawalAmount,
  });

  @JsonKey(name: "coinFrom")
  final String coinFrom;
  @JsonKey(name: "coinTo")
  final String coinTo;
  @JsonKey(name: "networkFrom")
  final String networkFrom;
  @JsonKey(name: "networkTo")
  final String networkTo;
  @JsonKey(name: "rateType")
  final ExolixRateType rateType;
  @JsonKey(name: "amount", includeIfNull: false)
  final String? amount;
  @JsonKey(name: "withdrawalAmount", includeIfNull: false)
  final String? withdrawalAmount;
  @JsonKey(name: "apiToken")
  final String apiToken;

  Map<String, dynamic> toJson() => _$ExolixRateRequestToJson(this);
}

@JsonSerializable(createToJson: false)
class ExolixRateResponse {
  const ExolixRateResponse({
    required this.fromAmount,
    required this.toAmount,
    this.rate,
    this.message,
    this.minAmount,
    this.withdrawMin,
    this.maxAmount,
  });

  factory ExolixRateResponse.fromJson(Map<String, dynamic> json) =>
      _$ExolixRateResponseFromJson(json);

  @JsonKey(name: "fromAmount")
  final double fromAmount;
  @JsonKey(name: "toAmount")
  final double toAmount;
  @JsonKey(name: "rate")
  final double? rate;
  @JsonKey(name: "message")
  final String? message;
  @JsonKey(name: "minAmount")
  final double? minAmount;
  @JsonKey(name: "withdrawMin")
  final double? withdrawMin;
  @JsonKey(name: "maxAmount")
  final double? maxAmount;
}


@JsonSerializable(createToJson: false)
class ExolixCoin {
  const ExolixCoin({
    required this.coinCode,
    required this.coinName,
    required this.network,
    required this.networkName,
    required this.icon,
    this.networkShortName,
    this.memoName,
    this.contract,
  });

  factory ExolixCoin.fromJson(Map<String, dynamic> json) => _$ExolixCoinFromJson(json);

  @JsonKey(name: "coinCode")
  final String coinCode;
  @JsonKey(name: "coinName")
  final String coinName;
  @JsonKey(name: "network")
  final String network;
  @JsonKey(name: "networkName")
  final String networkName;
  @JsonKey(name: "networkShortName")
  final String? networkShortName;
  @JsonKey(name: "icon")
  final String icon;
  @JsonKey(name: "memoName")
  final String? memoName;
  @JsonKey(name: "contract")
  final String? contract;
}

@JsonSerializable(createToJson: false)
class ExolixHash {
  const ExolixHash({this.hash, this.link});

  factory ExolixHash.fromJson(Map<String, dynamic> json) => _$ExolixHashFromJson(json);

  @JsonKey(name: "hash")
  final String? hash;
  @JsonKey(name: "link")
  final String? link;
}

@JsonSerializable()
class ExolixCreateTransactionRequest {
  const ExolixCreateTransactionRequest({
    required this.coinFrom,
    required this.coinTo,
    required this.networkFrom,
    required this.networkTo,
    required this.withdrawalAddress,
    required this.rateType,
    required this.apiToken,
    this.amount,
    this.withdrawalAmount,
    this.withdrawalExtraId,
    this.refundAddress,
    this.refundExtraId,
    this.slippage,
  });

  @JsonKey(name: "coinFrom")
  final String coinFrom;
  @JsonKey(name: "coinTo")
  final String coinTo;
  @JsonKey(name: "networkFrom")
  final String networkFrom;
  @JsonKey(name: "networkTo")
  final String networkTo;
  @JsonKey(name: "withdrawalAddress")
  final String withdrawalAddress;
  @JsonKey(name: "rateType")
  final ExolixRateType rateType;
  @JsonKey(name: "amount", includeIfNull: false)
  final String? amount;
  @JsonKey(name: "withdrawalAmount", includeIfNull: false)
  final String? withdrawalAmount;
  @JsonKey(name: "withdrawalExtraId", includeIfNull: false)
  final String? withdrawalExtraId;
  @JsonKey(name: "refundAddress", includeIfNull: false)
  final String? refundAddress;
  @JsonKey(name: "refundExtraId", includeIfNull: false)
  final String? refundExtraId;
  @JsonKey(name: "slippage", includeIfNull: false)
  final double? slippage;
  @JsonKey(name: "apiToken")
  final String apiToken;

  Map<String, dynamic> toJson() => _$ExolixCreateTransactionRequestToJson(this);
}


@JsonSerializable(createToJson: false)
@TradeStateConverter()
class ExolixTransactionResponse {
  const ExolixTransactionResponse({
    required this.id,
    required this.amount,
    required this.coinFrom,
    required this.coinTo,
    required this.createdAt,
    required this.depositAddress,
    required this.withdrawalAddress,
    required this.hashIn,
    required this.hashOut,
    required this.rate,
    required this.rateType,
    required this.status,
    this.amountTo,
    this.comment,
    this.depositExtraId,
    this.withdrawalExtraId,
    this.refundAddress,
    this.refundExtraId,
    this.source,
  });

  factory ExolixTransactionResponse.fromJson(Map<String, dynamic> json) =>
      _$ExolixTransactionResponseFromJson(json);

  @JsonKey(name: "id")
  final String id;
  @JsonKey(name: "amount")
  final double amount;
  @JsonKey(name: "amountTo")
  final double? amountTo;
  @JsonKey(name: "coinFrom")
  final ExolixCoin coinFrom;
  @JsonKey(name: "coinTo")
  final ExolixCoin coinTo;
  @JsonKey(name: "comment")
  final String? comment;
  @JsonKey(name: "createdAt")
  final DateTime createdAt;
  @JsonKey(name: "depositAddress")
  final String depositAddress;
  @JsonKey(name: "depositExtraId")
  final String? depositExtraId;
  @JsonKey(name: "withdrawalAddress")
  final String withdrawalAddress;
  @JsonKey(name: "withdrawalExtraId")
  final String? withdrawalExtraId;
  @JsonKey(name: "hashIn")
  final ExolixHash hashIn;
  @JsonKey(name: "hashOut")
  final ExolixHash hashOut;
  @JsonKey(name: "rate")
  final double rate;
  @JsonKey(name: "rateType", unknownEnumValue: ExolixRateType.unknown)
  final ExolixRateType rateType;
  @JsonKey(name: "refundAddress")
  final String? refundAddress;
  @JsonKey(name: "refundExtraId")
  final String? refundExtraId;
  @JsonKey(name: "status")
  final TradeState status;
  @JsonKey(name: "source", unknownEnumValue: ExolixTransactionSource.unknown)
  final ExolixTransactionSource? source;
}
