// spec reference: https://documenter.getpostman.com/view/8180765/SVfTPnM8?version=latest

import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/exchange/utils/json_converters.dart";
import "package:json_annotation/json_annotation.dart";

part "changenow_api_schema.g.dart";

enum ChangeNowFlow {
  @JsonValue("standard")
  standard,
  @JsonValue("fixed-rate")
  fixedRate,
  unknown,
}

enum ChangeNowExchangeType {
  @JsonValue("direct")
  direct,
  @JsonValue("reverse")
  reverse,
  unknown,
}


@JsonSerializable()
class ChangeNowErrorResponse {
  const ChangeNowErrorResponse({required this.error, required this.message});

  factory ChangeNowErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ChangeNowErrorResponseFromJson(json);

  @JsonKey(name: "error")
  final String error;

  @JsonKey(name: "message")
  final String message;
}


@JsonSerializable()
class ChangeNowRangeRequest {
  const ChangeNowRangeRequest({
    required this.fromCurrency,
    required this.toCurrency,
    required this.fromNetwork,
    required this.toNetwork,
    required this.flow,
  });

  @JsonKey(name: "fromCurrency")
  final String fromCurrency;
  @JsonKey(name: "toCurrency")
  final String toCurrency;
  @JsonKey(name: "fromNetwork")
  final String fromNetwork;
  @JsonKey(name: "toNetwork")
  final String toNetwork;
  @JsonKey(name: "flow")
  final ChangeNowFlow flow;

  Map<String, dynamic> toJson() => _$ChangeNowRangeRequestToJson(this);
}

@JsonSerializable(createToJson: false)
class ChangeNowRangeResponse {
  const ChangeNowRangeResponse({
    required this.fromCurrency,
    required this.fromNetwork,
    required this.toCurrency,
    required this.toNetwork,
    required this.flow,
    this.minAmount,
    this.maxAmount,
  });

  factory ChangeNowRangeResponse.fromJson(Map<String, dynamic> json) =>
      _$ChangeNowRangeResponseFromJson(json);

  @JsonKey(name: "fromCurrency")
  final String fromCurrency;
  @JsonKey(name: "fromNetwork")
  final String fromNetwork;
  @JsonKey(name: "toCurrency")
  final String toCurrency;
  @JsonKey(name: "toNetwork")
  final String toNetwork;
  @JsonKey(name: "flow", unknownEnumValue: ChangeNowFlow.unknown)
  final ChangeNowFlow flow;
  @JsonKey(name: "minAmount")
  final double? minAmount;
  @JsonKey(name: "maxAmount")
  final double? maxAmount;
}


@JsonSerializable()
class ChangeNowEstimatedAmountRequest {
  const ChangeNowEstimatedAmountRequest({
    required this.fromCurrency,
    required this.toCurrency,
    required this.fromNetwork,
    required this.toNetwork,
    required this.flow,
    required this.type,
    this.fromAmount,
    this.toAmount,
    this.useRateId,
  });

  @JsonKey(name: "fromCurrency")
  final String fromCurrency;
  @JsonKey(name: "toCurrency")
  final String toCurrency;
  @JsonKey(name: "fromNetwork")
  final String fromNetwork;
  @JsonKey(name: "toNetwork")
  final String toNetwork;
  @JsonKey(name: "flow")
  final ChangeNowFlow flow;
  @JsonKey(name: "type")
  final ChangeNowExchangeType type;
  @JsonKey(name: "fromAmount", includeIfNull: false)
  final String? fromAmount;
  @JsonKey(name: "toAmount", includeIfNull: false)
  final String? toAmount;
  @JsonKey(name: "useRateId", includeIfNull: false)
  final String? useRateId;

  Map<String, dynamic> toJson() => _$ChangeNowEstimatedAmountRequestToJson(this);
}

@JsonSerializable(createToJson: false)
class ChangeNowEstimatedAmountResponse {
  const ChangeNowEstimatedAmountResponse({
    required this.fromCurrency,
    required this.fromNetwork,
    required this.toCurrency,
    required this.toNetwork,
    required this.flow,
    required this.type,
    required this.fromAmount,
    required this.toAmount,
    this.rateId,
    this.validUntil,
    this.transactionSpeedForecast,
    this.warningMessage,
    this.depositFee,
    this.withdrawalFee,
    this.userId,
  });

  factory ChangeNowEstimatedAmountResponse.fromJson(Map<String, dynamic> json) =>
      _$ChangeNowEstimatedAmountResponseFromJson(json);

  @JsonKey(name: "fromCurrency")
  final String? fromCurrency;
  @JsonKey(name: "fromNetwork")
  final String? fromNetwork;
  @JsonKey(name: "toCurrency")
  final String? toCurrency;
  @JsonKey(name: "toNetwork")
  final String? toNetwork;
  @JsonKey(name: "flow", unknownEnumValue: ChangeNowFlow.unknown)
  final ChangeNowFlow? flow;
  @JsonKey(name: "type", unknownEnumValue: ChangeNowExchangeType.unknown)
  final ChangeNowExchangeType? type;
  @JsonKey(name: "rateId")
  final String? rateId;
  @JsonKey(name: "validUntil")
  final DateTime? validUntil;
  @JsonKey(name: "transactionSpeedForecast")
  final String? transactionSpeedForecast;
  @JsonKey(name: "warningMessage")
  final String? warningMessage;
  @JsonKey(name: "depositFee")
  final double? depositFee;
  @JsonKey(name: "withdrawalFee")
  final double? withdrawalFee;
  @JsonKey(name: "userId")
  final String? userId;
  @JsonKey(name: "fromAmount")
  final double fromAmount;
  @JsonKey(name: "toAmount")
  final double toAmount;
}

@JsonSerializable()
class ChangeNowCreateExchangePayload {
  const ChangeNowCreateExchangePayload({
    required this.app,
    required this.device,
    required this.distribution,
    required this.version,
  });

  factory ChangeNowCreateExchangePayload.fromJson(Map<String, dynamic> json) =>
      _$ChangeNowCreateExchangePayloadFromJson(json);

  @JsonKey(name: "app")
  final String app;
  @JsonKey(name: "device")
  final String device;
  @JsonKey(name: "distribution")
  final String distribution;
  @JsonKey(name: "version")
  final int version;

  Map<String, dynamic> toJson() => _$ChangeNowCreateExchangePayloadToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ChangeNowCreateExchangeRequest {
  const ChangeNowCreateExchangeRequest({
    required this.fromCurrency,
    required this.toCurrency,
    required this.fromNetwork,
    required this.toNetwork,
    required this.address,
    required this.flow,
    required this.type,
    this.fromAmount,
    this.toAmount,
    this.extraId,
    this.refundAddress,
    this.refundExtraId,
    this.userId,
    this.payload,
    this.contactEmail,
    this.source,
    this.rateId,
  });

  @JsonKey(name: "fromCurrency")
  final String fromCurrency;
  @JsonKey(name: "toCurrency")
  final String toCurrency;
  @JsonKey(name: "fromNetwork")
  final String fromNetwork;
  @JsonKey(name: "toNetwork")
  final String toNetwork;
  @JsonKey(name: "address")
  final String address;
  @JsonKey(name: "flow")
  final ChangeNowFlow flow;
  @JsonKey(name: "type")
  final ChangeNowExchangeType type;
  @JsonKey(name: "fromAmount", includeIfNull: false)
  final String? fromAmount;
  @JsonKey(name: "toAmount", includeIfNull: false)
  final String? toAmount;
  @JsonKey(name: "extraId", includeIfNull: false)
  final String? extraId;
  @JsonKey(name: "refundAddress", includeIfNull: false)
  final String? refundAddress;
  @JsonKey(name: "refundExtraId", includeIfNull: false)
  final String? refundExtraId;
  @JsonKey(name: "userId", includeIfNull: false)
  final String? userId;
  @JsonKey(name: "payload", includeIfNull: false)
  final ChangeNowCreateExchangePayload? payload;
  @JsonKey(name: "contactEmail", includeIfNull: false)
  final String? contactEmail;
  @JsonKey(name: "source", includeIfNull: false)
  final String? source;
  @JsonKey(name: "rateId", includeIfNull: false)
  final String? rateId;

  Map<String, dynamic> toJson() => _$ChangeNowCreateExchangeRequestToJson(this);
}

@JsonSerializable(createToJson: false)
class ChangeNowCreateExchangeResponse {
  const ChangeNowCreateExchangeResponse({
    required this.fromAmount,
    required this.toAmount,
    required this.flow,
    required this.type,
    required this.payinAddress,
    required this.payoutAddress,
    required this.fromCurrency,
    required this.toCurrency,
    required this.id,
    required this.fromNetwork,
    required this.toNetwork,
    this.refundAddress,
    this.payinExtraId,
    this.payoutExtraId,
    this.validUntil,
  });

  factory ChangeNowCreateExchangeResponse.fromJson(Map<String, dynamic> json) =>
      _$ChangeNowCreateExchangeResponseFromJson(json);

  @JsonKey(name: "fromAmount")
  final double fromAmount;
  @JsonKey(name: "toAmount")
  final double toAmount;
  @JsonKey(name: "flow", unknownEnumValue: ChangeNowFlow.unknown)
  final ChangeNowFlow flow;
  @JsonKey(name: "type", unknownEnumValue: ChangeNowExchangeType.unknown)
  final ChangeNowExchangeType type;
  @JsonKey(name: "payinAddress")
  final String payinAddress;
  @JsonKey(name: "payoutAddress")
  final String payoutAddress;
  @JsonKey(name: "fromCurrency")
  final String fromCurrency;
  @JsonKey(name: "toCurrency")
  final String toCurrency;
  @JsonKey(name: "refundAddress")
  final String? refundAddress;
  @JsonKey(name: "id")
  final String id;
  @JsonKey(name: "fromNetwork")
  final String fromNetwork;
  @JsonKey(name: "toNetwork")
  final String toNetwork;
  @JsonKey(name: "payinExtraId")
  final String? payinExtraId;
  @JsonKey(name: "payoutExtraId")
  final String? payoutExtraId;
  @JsonKey(name: "validUntil")
  final DateTime? validUntil;
}


@JsonSerializable()
class ChangeNowByIdRequest {
  const ChangeNowByIdRequest({required this.id});

  @JsonKey(name: "id")
  final String id;

  Map<String, dynamic> toJson() => _$ChangeNowByIdRequestToJson(this);
}

@JsonSerializable(createToJson: false)
@TradeStateConverter()
class ChangeNowRelatedExchangeInfo {
  const ChangeNowRelatedExchangeInfo({
    required this.id,
    required this.status,
    required this.createdAt,
    this.fromCurrency,
    this.fromNetwork,
    this.amountFrom,
    this.amountTo,
  });

  factory ChangeNowRelatedExchangeInfo.fromJson(Map<String, dynamic> json) =>
      _$ChangeNowRelatedExchangeInfoFromJson(json);

  @JsonKey(name: "id")
  final String id;
  @JsonKey(name: "status")
  final TradeState status;
  @JsonKey(name: "createdAt")
  final DateTime createdAt;
  @JsonKey(name: "fromCurrency")
  final String? fromCurrency;
  @JsonKey(name: "fromNetwork")
  final String? fromNetwork;
  @JsonKey(name: "amountFrom")
  final double? amountFrom;
  @JsonKey(name: "amountTo")
  final double? amountTo;
}

@JsonSerializable(createToJson: false)
@TradeStateConverter()
class ChangeNowTransactionResponse {
  const ChangeNowTransactionResponse({
    required this.id,
    required this.status,
    required this.fromCurrency,
    required this.toCurrency,
    required this.payinAddress,
    required this.payoutAddress,
    required this.createdAt,
    this.actionsAvailable,
    this.fromNetwork,
    this.toNetwork,
    this.expectedAmountFrom,
    this.expectedAmountTo,
    this.amountFrom,
    this.amountTo,
    this.payinExtraId,
    this.payoutExtraId,
    this.refundAddress,
    this.refundExtraId,
    this.updatedAt,
    this.validUntil,
    this.depositReceivedAt,
    this.payinHash,
    this.payoutHash,
    this.fromLegacyTicker,
    this.toLegacyTicker,
    this.refundHash,
    this.refundAmount,
    this.userId,
  });

  factory ChangeNowTransactionResponse.fromJson(Map<String, dynamic> json) =>
      _$ChangeNowTransactionResponseFromJson(json);

  @JsonKey(name: "id")
  final String id;
  @JsonKey(name: "status")
  final TradeState status;
  @JsonKey(name: "actionsAvailable")
  final bool? actionsAvailable;
  @JsonKey(name: "fromCurrency")
  final String fromCurrency;
  @JsonKey(name: "fromNetwork")
  final String? fromNetwork;
  @JsonKey(name: "toCurrency")
  final String toCurrency;
  @JsonKey(name: "toNetwork")
  final String? toNetwork;
  @JsonKey(name: "expectedAmountFrom")
  final double? expectedAmountFrom;
  @JsonKey(name: "expectedAmountTo")
  final double? expectedAmountTo;
  @JsonKey(name: "amountFrom")
  final double? amountFrom;
  @JsonKey(name: "amountTo")
  final double? amountTo;
  @JsonKey(name: "payinAddress")
  final String payinAddress;
  @JsonKey(name: "payoutAddress")
  final String payoutAddress;
  @JsonKey(name: "payinExtraId")
  final String? payinExtraId;
  @JsonKey(name: "payoutExtraId")
  final String? payoutExtraId;
  @JsonKey(name: "refundAddress")
  final String? refundAddress;
  @JsonKey(name: "refundExtraId")
  final String? refundExtraId;
  @JsonKey(name: "createdAt")
  final DateTime createdAt;
  @JsonKey(name: "updatedAt")
  final DateTime? updatedAt;
  @JsonKey(name: "validUntil")
  final DateTime? validUntil;
  @JsonKey(name: "depositReceivedAt")
  final DateTime? depositReceivedAt;
  @JsonKey(name: "payinHash")
  final String? payinHash;
  @JsonKey(name: "payoutHash")
  final String? payoutHash;
  @JsonKey(name: "fromLegacyTicker")
  final String? fromLegacyTicker;
  @JsonKey(name: "toLegacyTicker")
  final String? toLegacyTicker;
  @JsonKey(name: "refundHash")
  final String? refundHash;
  @JsonKey(name: "refundAmount")
  final double? refundAmount;
  @JsonKey(name: "userId")
  final String? userId;
  // these are present in the schema but in the examples they're null
  // we don't use them anyway so i don't care
  // @JsonKey(name: "originalExchangeInfo")
  // final ChangeNowRelatedExchangeInfo? originalExchangeInfo;
  // @JsonKey(name: "relatedExchangesInfo")
  // final List<ChangeNowRelatedExchangeInfo>? relatedExchangesInfo;
  // @JsonKey(name: "repeatedExchangesInfo")
  // final List<ChangeNowRelatedExchangeInfo>? repeatedExchangesInfo;
}
