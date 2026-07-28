// spec reference: https://developers.jup.ag/docs/ultra-api

import "package:json_annotation/json_annotation.dart";

part "jupiter_api_schema.g.dart";

// base unit amounts come back as strings, but the execute response fields aren't documented
class JupiterBaseUnitConverter implements JsonConverter<BigInt, Object> {
  const JupiterBaseUnitConverter();

  @override
  BigInt fromJson(Object json) {
    if (json is String) {
      return BigInt.parse(json);
    }
    if (json is num) {
      return BigInt.from(json);
    }
    throw ArgumentError("unexpected Jupiter amount: $json");
  }

  @override
  Object toJson(BigInt value) => value.toString();
}

// the docs don't say whether slot and code are numbers or strings
class JupiterLooseIntConverter implements JsonConverter<int, Object> {
  const JupiterLooseIntConverter();

  @override
  int fromJson(Object json) {
    if (json is num) {
      return json.toInt();
    }
    if (json is String) {
      return int.parse(json);
    }
    throw ArgumentError("unexpected Jupiter integer: $json");
  }

  @override
  Object toJson(int value) => value;
}

enum JupiterSwapMode {
  @JsonValue("ExactIn")
  exactIn,
  @JsonValue("ExactOut")
  exactOut,
  unknown,
}

enum JupiterSwapType {
  @JsonValue("aggregator")
  aggregator,
  @JsonValue("rfq")
  rfq,
  unknown,
}

@JsonSerializable(createToJson: false)
class JupiterErrorResponse {
  const JupiterErrorResponse({this.requestId, this.error});

  factory JupiterErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$JupiterErrorResponseFromJson(json);

  @JsonKey(name: "requestId")
  final String? requestId;
  @JsonKey(name: "error")
  final String? error;
}


@JsonSerializable()
class JupiterOrderRequest {
  const JupiterOrderRequest({
    required this.inputMint,
    required this.outputMint,
    required this.amount,
    this.taker,
    this.receiver,
    this.referralAccount,
    this.referralFee,
  });

  @JsonKey(name: "inputMint")
  final String inputMint;
  @JsonKey(name: "outputMint")
  final String outputMint;

  @JsonKey(name: "amount")
  final BigInt amount;

  @JsonKey(name: "taker", includeIfNull: false)
  final String? taker;

  @JsonKey(name: "receiver", includeIfNull: false)
  final String? receiver;
  @JsonKey(name: "referralAccount", includeIfNull: false)
  final String? referralAccount;

  @JsonKey(name: "referralFee", includeIfNull: false)
  final String? referralFee;

  Map<String, dynamic> toJson() => _$JupiterOrderRequestToJson(this);
}

@JsonSerializable(createToJson: false)
@JupiterBaseUnitConverter()
class JupiterSwapInfo {
  const JupiterSwapInfo({
    required this.inputMint,
    required this.outputMint,
    required this.inAmount,
    required this.outAmount,
    this.ammKey,
    this.label,
  });

  factory JupiterSwapInfo.fromJson(Map<String, dynamic> json) => _$JupiterSwapInfoFromJson(json);

  @JsonKey(name: "ammKey")
  final String? ammKey;

  @JsonKey(name: "label")
  final String? label;
  @JsonKey(name: "inputMint")
  final String inputMint;
  @JsonKey(name: "outputMint")
  final String outputMint;
  @JsonKey(name: "inAmount")
  final BigInt inAmount;
  @JsonKey(name: "outAmount")
  final BigInt outAmount;
}

@JsonSerializable(createToJson: false)
class JupiterRoutePlanStep {
  const JupiterRoutePlanStep({required this.swapInfo, this.percent, this.bps, this.usdValue});

  factory JupiterRoutePlanStep.fromJson(Map<String, dynamic> json) =>
      _$JupiterRoutePlanStepFromJson(json);

  @JsonKey(name: "percent")
  final int? percent;
  @JsonKey(name: "bps")
  final int? bps;
  @JsonKey(name: "usdValue")
  final double? usdValue;
  @JsonKey(name: "swapInfo")
  final JupiterSwapInfo swapInfo;
}

@JsonSerializable(createToJson: false)
class JupiterPlatformFee {
  const JupiterPlatformFee({this.feeBps, this.feeMint});

  factory JupiterPlatformFee.fromJson(Map<String, dynamic> json) =>
      _$JupiterPlatformFeeFromJson(json);

  @JsonKey(name: "feeBps")
  final int? feeBps;
  @JsonKey(name: "feeMint")
  final String? feeMint;
}

@JsonSerializable(createToJson: false)
@JupiterBaseUnitConverter()
class JupiterOrder {
  const JupiterOrder({
    required this.requestId,
    required this.inputMint,
    required this.outputMint,
    required this.inAmount,
    required this.outAmount,
    required this.swapType,
    required this.swapMode,
    this.otherAmountThreshold,
    this.slippageBps,
    this.priceImpactPct,
    this.priceImpact,
    this.routePlan,
    this.transaction,
    this.taker,
    this.router,
    this.mode,
    this.gasless,
    this.jitOptimized,
    this.guaranteedPrice,
    this.feeMint,
    this.feeBps,
    this.platformFee,
    this.signatureFeeLamports,
    this.signatureFeePayer,
    this.prioritizationFeeLamports,
    this.prioritizationFeePayer,
    this.rentFeeLamports,
    this.rentFeePayer,
    this.inUsdValue,
    this.outUsdValue,
    this.swapUsdValue,
    this.totalTime,
    this.errorCode,
    this.errorMessage,
    this.error,
  });

  factory JupiterOrder.fromJson(Map<String, dynamic> json) => _$JupiterOrderFromJson(json);

  @JsonKey(name: "requestId")
  final String requestId;

  @JsonKey(name: "transaction")
  final String? transaction;
  @JsonKey(name: "inputMint")
  final String inputMint;
  @JsonKey(name: "outputMint")
  final String outputMint;
  @JsonKey(name: "inAmount")
  final BigInt inAmount;
  @JsonKey(name: "outAmount")
  final BigInt outAmount;

  @JsonKey(name: "otherAmountThreshold")
  final BigInt? otherAmountThreshold;
  @JsonKey(name: "swapType", unknownEnumValue: JupiterSwapType.unknown)
  final JupiterSwapType swapType;
  @JsonKey(name: "swapMode", unknownEnumValue: JupiterSwapMode.unknown)
  final JupiterSwapMode swapMode;

  @JsonKey(name: "slippageBps")
  final int? slippageBps;
  @JsonKey(name: "priceImpactPct")
  final String? priceImpactPct;
  @JsonKey(name: "priceImpact")
  final double? priceImpact;
  @JsonKey(name: "routePlan")
  final List<JupiterRoutePlanStep>? routePlan;
  @JsonKey(name: "taker")
  final String? taker;

  @JsonKey(name: "router")
  final String? router;
  @JsonKey(name: "mode")
  final String? mode;
  @JsonKey(name: "gasless")
  final bool? gasless;
  @JsonKey(name: "jitOptimized")
  final bool? jitOptimized;
  @JsonKey(name: "guaranteedPrice")
  final bool? guaranteedPrice;

  @JsonKey(name: "feeMint")
  final String? feeMint;
  @JsonKey(name: "feeBps")
  final int? feeBps;
  @JsonKey(name: "platformFee")
  final JupiterPlatformFee? platformFee;

  @JsonKey(name: "signatureFeeLamports")
  final int? signatureFeeLamports;
  @JsonKey(name: "signatureFeePayer")
  final String? signatureFeePayer;
  @JsonKey(name: "prioritizationFeeLamports")
  final int? prioritizationFeeLamports;
  @JsonKey(name: "prioritizationFeePayer")
  final String? prioritizationFeePayer;
  @JsonKey(name: "rentFeeLamports")
  final int? rentFeeLamports;
  @JsonKey(name: "rentFeePayer")
  final String? rentFeePayer;
  @JsonKey(name: "inUsdValue")
  final double? inUsdValue;
  @JsonKey(name: "outUsdValue")
  final double? outUsdValue;
  @JsonKey(name: "swapUsdValue")
  final double? swapUsdValue;

  @JsonKey(name: "totalTime")
  final int? totalTime;
  @JsonKey(name: "errorCode")
  final int? errorCode;
  @JsonKey(name: "errorMessage")
  final String? errorMessage;
  @JsonKey(name: "error")
  final String? error;
}


@JsonSerializable()
class JupiterExecuteRequest {
  const JupiterExecuteRequest({required this.signedTransaction, required this.requestId});

  @JsonKey(name: "signedTransaction")
  final String signedTransaction;
  @JsonKey(name: "requestId")
  final String requestId;

  Map<String, dynamic> toJson() => _$JupiterExecuteRequestToJson(this);
}

enum JupiterExecuteStatus {
  @JsonValue("Success")
  success,
  @JsonValue("Failed")
  failed,
  @JsonValue("Pending")
  pending,
  @JsonValue("Processing")
  processing,
  unknown,
}

@JsonSerializable(createToJson: false)
@JupiterBaseUnitConverter()
class JupiterSwapEvent {
  const JupiterSwapEvent({this.inputMint, this.inputAmount, this.outputMint, this.outputAmount});

  factory JupiterSwapEvent.fromJson(Map<String, dynamic> json) => _$JupiterSwapEventFromJson(json);

  @JsonKey(name: "inputMint")
  final String? inputMint;
  @JsonKey(name: "inputAmount")
  final BigInt? inputAmount;
  @JsonKey(name: "outputMint")
  final String? outputMint;
  @JsonKey(name: "outputAmount")
  final BigInt? outputAmount;
}

@JsonSerializable(createToJson: false)
@JupiterBaseUnitConverter()
class JupiterExecuteResponse {
  const JupiterExecuteResponse({
    required this.status,
    this.signature,
    this.slot,
    this.code,
    this.error,
    this.inputAmountResult,
    this.outputAmountResult,
    this.swapEvents,
  });

  factory JupiterExecuteResponse.fromJson(Map<String, dynamic> json) =>
      _$JupiterExecuteResponseFromJson(json);

  @JsonKey(name: "status", unknownEnumValue: JupiterExecuteStatus.unknown)
  final JupiterExecuteStatus status;

  @JsonKey(name: "signature")
  final String? signature;
  @JsonKey(name: "slot")
  @JupiterLooseIntConverter()
  final int? slot;

  @JsonKey(name: "code")
  @JupiterLooseIntConverter()
  final int? code;
  @JsonKey(name: "error")
  final String? error;

  @JsonKey(name: "inputAmountResult")
  final BigInt? inputAmountResult;
  @JsonKey(name: "outputAmountResult")
  final BigInt? outputAmountResult;
  @JsonKey(name: "swapEvents")
  final List<JupiterSwapEvent>? swapEvents;
}
