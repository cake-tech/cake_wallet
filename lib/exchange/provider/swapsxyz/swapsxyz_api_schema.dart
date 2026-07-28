// spec reference: https://docs.swaps.xyz/swap-api-reference/openapi.json

import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/exchange/utils/json_converters.dart";
import "package:json_annotation/json_annotation.dart";

part "swapsxyz_api_schema.g.dart";



class SwapsXyzBigIntAmountConverter implements JsonConverter<BigInt, String> {
  const SwapsXyzBigIntAmountConverter();

  @override
  BigInt fromJson(String json) => BigInt.parse(json.replaceAll("n", ""));

  @override
  String toJson(BigInt value) => value.toString();
}


// docs literally say "integer or string"
class SwapsXyzTimestampConverter implements JsonConverter<DateTime, Object> {
  const SwapsXyzTimestampConverter();

  @override
  DateTime fromJson(Object json) {
    if (json is num) {
      return DateTime.fromMillisecondsSinceEpoch(json.toInt() * 1000, isUtc: true);
    }
    final seconds = int.tryParse(json.toString());
    if (seconds != null) {
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
    }
    return DateTime.parse(json.toString());
  }

  @override
  Object toJson(DateTime value) => value.millisecondsSinceEpoch ~/ 1000;
}



enum SwapsXyzVmId {
  @JsonValue("evm")
  evm,
  @JsonValue("solana")
  solana,
  @JsonValue("alt-vm")
  altVm,
  @JsonValue("hypercore")
  hypercore,
  @JsonValue("tron")
  tron,
  unknown,
}

enum SwapsXyzActionType {
  @JsonValue("swap-action")
  swapAction,
  @JsonValue("evm-calldata-tx")
  evmCalldataTx,
  @JsonValue("polymarket")
  polymarket,
  unknown,
}

enum SwapsXyzExecutionsType {
  @JsonValue("DEFAULT")
  standard,
  @JsonValue("GASLESS")
  gasless,
  unknown,
}

enum SwapsXyzSwapDirection {
  @JsonValue("exact-amount-in")
  exactAmountIn,
  @JsonValue("exact-amount-out")
  exactAmountOut,
  unknown,
}

enum SwapsXyzTxStatusValue {
  @JsonValue("not yet created")
  notYetCreated,
  @JsonValue("submitted")
  submitted,
  @JsonValue("pending")
  pending,
  @JsonValue("success")
  success,
  @JsonValue("completed")
  completed,
  @JsonValue("requires refund")
  requiresRefund,
  @JsonValue("refunded")
  refunded,
  @JsonValue("expired")
  expired,
  @JsonValue("failed")
  failed,
  unknown,
}

extension StatusToState on SwapsXyzTxStatusValue {
  TradeState get toState => switch (this) {
    .notYetCreated => .toBeCreated,
    .submitted => .pending,
    .pending => .pending,
    .success => .success,
    .completed => .success,
    .requiresRefund => .refund,
    .refunded => .refunded,
    .expired => .expired,
    .failed => .failed,
    _ => .notFound,
  };
}

@JsonSerializable(createToJson: false)
class SwapsXyzError {
  const SwapsXyzError({
    this.code,
    this.name,
    this.message,
    this.title,
    this.statusCode,
    this.timestamp,
    this.details,
  });

  factory SwapsXyzError.fromJson(Map<String, dynamic> json) => _$SwapsXyzErrorFromJson(json);

  @JsonKey(name: "code")
  final String? code;
  @JsonKey(name: "name")
  final String? name;
  @JsonKey(name: "message")
  final String? message;
  @JsonKey(name: "title")
  final String? title;
  @JsonKey(name: "statusCode")
  final int? statusCode;
  @JsonKey(name: "timestamp")
  final DateTime? timestamp;

  @JsonKey(name: "details")
  final Map<String, dynamic>? details;
}

@JsonSerializable(createToJson: false)
class SwapsXyzErrorResponse {
  const SwapsXyzErrorResponse({required this.success, this.error});

  factory SwapsXyzErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$SwapsXyzErrorResponseFromJson(json);

  @JsonKey(name: "success")
  final bool success;
  @JsonKey(name: "error")
  final SwapsXyzError? error;
}


@JsonSerializable(createToJson: false)
class SwapsXyzChain {
  const SwapsXyzChain({required this.chainId, required this.name, required this.vmId});

  factory SwapsXyzChain.fromJson(Map<String, dynamic> json) => _$SwapsXyzChainFromJson(json);

  @JsonKey(name: "chainId")
  final int chainId;
  @JsonKey(name: "name")
  final String name;
  @JsonKey(name: "vmId", unknownEnumValue: SwapsXyzVmId.unknown)
  final SwapsXyzVmId vmId;
}


@JsonSerializable(createToJson: false)
class SwapsXyzTokenInfo {
  const SwapsXyzTokenInfo({
    required this.chainId,
    required this.address,
    required this.name,
    required this.symbol,
    required this.decimals,
    required this.isNative,
    this.logo,
    this.swapsXyzCode,
  });

  factory SwapsXyzTokenInfo.fromJson(Map<String, dynamic> json) =>
      _$SwapsXyzTokenInfoFromJson(json);

  @JsonKey(name: "chainId")
  final int chainId;
  @JsonKey(name: "address")
  final String address;
  @JsonKey(name: "name")
  final String name;
  @JsonKey(name: "symbol")
  final String symbol;
  @JsonKey(name: "decimals")
  final int decimals;
  @JsonKey(name: "isNative")
  final bool isNative;
  @JsonKey(name: "logo")
  final String? logo;
  @JsonKey(name: "swapsXyzCode")
  final String? swapsXyzCode;
}

@JsonSerializable(createToJson: false)
class SwapsXyzTokenInfoWithAmounts {
  const SwapsXyzTokenInfoWithAmounts({
    required this.chainId,
    required this.address,
    required this.name,
    required this.symbol,
    required this.decimals,
    required this.isNative,
    this.logo,
    this.swapsXyzCode,
    this.minAmount,
    this.maxAmount,
  });

  factory SwapsXyzTokenInfoWithAmounts.fromJson(Map<String, dynamic> json) =>
      _$SwapsXyzTokenInfoWithAmountsFromJson(json);

  @JsonKey(name: "chainId")
  final int chainId;
  @JsonKey(name: "address")
  final String address;
  @JsonKey(name: "name")
  final String name;
  @JsonKey(name: "symbol")
  final String symbol;
  @JsonKey(name: "decimals")
  final int decimals;
  @JsonKey(name: "isNative")
  final bool isNative;
  @JsonKey(name: "logo")
  final String? logo;
  @JsonKey(name: "swapsXyzCode")
  final String? swapsXyzCode;

  @JsonKey(name: "minAmount")
  final String? minAmount;
  @JsonKey(name: "maxAmount")
  final String? maxAmount;
}

@JsonSerializable(createToJson: false)
class SwapsXyzAmountLimits {
  const SwapsXyzAmountLimits({this.minAmount, this.maxAmount});

  factory SwapsXyzAmountLimits.fromJson(Map<String, dynamic> json) =>
      _$SwapsXyzAmountLimitsFromJson(json);

  @JsonKey(name: "minAmount")
  final String? minAmount;
  @JsonKey(name: "maxAmount")
  final String? maxAmount;
}

class SwapsXyzPathTokens {
  const SwapsXyzPathTokens.all() : tokens = null;

  const SwapsXyzPathTokens.list(this.tokens);

  final List<SwapsXyzTokenInfoWithAmounts>? tokens;

  bool get isEmpty => tokens?.isEmpty ?? true;

  bool get isNotEmpty => !isEmpty;

  bool get isAll => tokens == null;
}

class SwapsXyzPathTokensConverter implements JsonConverter<SwapsXyzPathTokens, Object> {
  const SwapsXyzPathTokensConverter();

  @override
  SwapsXyzPathTokens fromJson(Object json) {
    if (json is List) {
      return SwapsXyzPathTokens.list(
        json
            .map((e) => SwapsXyzTokenInfoWithAmounts.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }
    return const SwapsXyzPathTokens.all();
  }

  @override
  Object toJson(SwapsXyzPathTokens value) => value.tokens ?? "all";
}

@JsonSerializable(createToJson: false)
class SwapsXyzChainPath {
  const SwapsXyzChainPath({
    required this.chainId,
    required this.tokens,
    required this.supportsExactAmountIn,
    required this.supportsExactAmountOut,
    this.amountLimits,
  });

  factory SwapsXyzChainPath.fromJson(Map<String, dynamic> json) =>
      _$SwapsXyzChainPathFromJson(json);

  @JsonKey(name: "chainId")
  final int chainId;
  @JsonKey(name: "tokens")
  @SwapsXyzPathTokensConverter()
  final SwapsXyzPathTokens tokens;
  @JsonKey(name: "supportsExactAmountIn")
  final bool supportsExactAmountIn;
  @JsonKey(name: "supportsExactAmountOut")
  final bool supportsExactAmountOut;

  @JsonKey(name: "amountLimits")
  final SwapsXyzAmountLimits? amountLimits;
}

/// query for GET /api/getPaths. leave dstChainId and dstToken off to get every path out of the
/// source token
@JsonSerializable()
class SwapsXyzPathsRequest {
  const SwapsXyzPathsRequest({
    required this.srcChainId,
    required this.srcToken,
    this.dstChainId,
    this.dstToken,
    this.excludeBridgeIds,
    this.excludeDexIds,
  });

  @JsonKey(name: "srcChainId")
  final String srcChainId;
  @JsonKey(name: "srcToken")
  final String srcToken;
  @JsonKey(name: "dstChainId", includeIfNull: false)
  final String? dstChainId;
  @JsonKey(name: "dstToken", includeIfNull: false)
  final String? dstToken;

  @JsonKey(name: "excludeBridgeIds", includeIfNull: false)
  final List<String>? excludeBridgeIds;
  @JsonKey(name: "excludeDexIds", includeIfNull: false)
  final List<String>? excludeDexIds;

  Map<String, dynamic> toJson() => _$SwapsXyzPathsRequestToJson(this);
}

@JsonSerializable(createToJson: false)
class SwapsXyzPathsResponse {
  const SwapsXyzPathsResponse({
    required this.srcChainId,
    required this.srcToken,
    required this.paths,
    this.timestamp,
  });

  factory SwapsXyzPathsResponse.fromJson(Map<String, dynamic> json) =>
      _$SwapsXyzPathsResponseFromJson(json);

  @JsonKey(name: "srcChainId")
  final int srcChainId;

  @JsonKey(name: "srcToken")
  final SwapsXyzTokenInfoWithAmounts srcToken;
  @JsonKey(name: "paths")
  final List<SwapsXyzChainPath> paths;
  @JsonKey(name: "timestamp")
  final String? timestamp;
}


/// query for GET /api/getQuote. undocumented like the response, so there may be more params it
/// accepts - these are the ones we send
@JsonSerializable()
class SwapsXyzQuoteRequest {
  const SwapsXyzQuoteRequest({
    required this.srcChainId,
    required this.srcToken,
    required this.dstChainId,
    required this.dstToken,
    required this.amount,
    this.swapDirection,
  });

  @JsonKey(name: "srcChainId")
  final String srcChainId;
  @JsonKey(name: "srcToken")
  final String srcToken;
  @JsonKey(name: "dstChainId")
  final String dstChainId;
  @JsonKey(name: "dstToken")
  final String dstToken;

  // base units of the source token for exact-amount-in, of the destination for exact-amount-out
  @JsonKey(name: "amount")
  final String amount;
  @JsonKey(name: "swapDirection", includeIfNull: false)
  final SwapsXyzSwapDirection? swapDirection;

  Map<String, dynamic> toJson() => _$SwapsXyzQuoteRequestToJson(this);
}

// getQuote is undocumented, this is based on curled response
@JsonSerializable(createToJson: false)
class SwapsXyzQuote {
  const SwapsXyzQuote({
    required this.amountIn,
    required this.amountInMax,
    required this.amountOut,
    required this.amountOutMin,
    required this.exchangeRate,
    required this.vmId,
    this.protocolFee,
    this.applicationFee,
    this.bridgeFee,
    this.estimatedTxTime,
    this.estimatedPriceImpact,
    this.requiresTokenApproval,
    this.requiresRegisterTransaction,
    this.executionsType,
  });

  factory SwapsXyzQuote.fromJson(Map<String, dynamic> json) => _$SwapsXyzQuoteFromJson(json);

  @JsonKey(name: "amountIn")
  final SwapsXyzPayment amountIn;

  @JsonKey(name: "amountInMax")
  final SwapsXyzPayment amountInMax;
  @JsonKey(name: "amountOut")
  final SwapsXyzPayment amountOut;

  @JsonKey(name: "amountOutMin")
  final SwapsXyzPayment amountOutMin;
  @JsonKey(name: "protocolFee")
  final SwapsXyzPayment? protocolFee;

  @JsonKey(name: "applicationFee")
  final SwapsXyzPayment? applicationFee;
  @JsonKey(name: "bridgeFee")
  final SwapsXyzPayment? bridgeFee;

  @JsonKey(name: "exchangeRate")
  final double exchangeRate;

  @JsonKey(name: "estimatedTxTime")
  final double? estimatedTxTime;
  @JsonKey(name: "estimatedPriceImpact")
  final double? estimatedPriceImpact;
  @JsonKey(name: "vmId", unknownEnumValue: SwapsXyzVmId.unknown)
  final SwapsXyzVmId vmId;
  @JsonKey(name: "requiresTokenApproval")
  final bool? requiresTokenApproval;
  @JsonKey(name: "requiresRegisterTransaction")
  final bool? requiresRegisterTransaction;
  @JsonKey(name: "executionsType", unknownEnumValue: SwapsXyzExecutionsType.unknown)
  final SwapsXyzExecutionsType? executionsType;
}


@JsonSerializable()
@StringBoolConverter()
class SwapsXyzActionRequest {
  const SwapsXyzActionRequest({
    required this.actionType,
    required this.sender,
    required this.srcChainId,
    required this.srcToken,
    required this.dstChainId,
    required this.dstToken,
    required this.slippage,
    this.amount,
    this.swapDirection,
    this.recipient,
    this.to,
    this.data,
    this.value,
    this.erc20Amount,
    this.erc20Spender,
    this.solanaSponsor,
    this.bridgeIds,
    this.refundTo,
    this.returnDepositAddress,
    this.appFees,
    this.userId,
    this.gasless,
  });

  factory SwapsXyzActionRequest.fromJson(Map<String, dynamic> json) =>
      _$SwapsXyzActionRequestFromJson(json);

  @JsonKey(name: "actionType")
  final SwapsXyzActionType actionType;
  @JsonKey(name: "sender")
  final String sender;

  @JsonKey(name: "srcChainId")
  final String srcChainId;
  @JsonKey(name: "srcToken")
  final String srcToken;
  @JsonKey(name: "dstChainId")
  final String dstChainId;
  @JsonKey(name: "dstToken")
  final String dstToken;

  @JsonKey(name: "slippage")
  final String slippage;

  @JsonKey(name: "amount", includeIfNull: false)
  final String? amount;
  @JsonKey(name: "swapDirection", includeIfNull: false)
  final SwapsXyzSwapDirection? swapDirection;

  @JsonKey(name: "recipient", includeIfNull: false)
  final String? recipient;

  @JsonKey(name: "to", includeIfNull: false)
  final String? to;
  @JsonKey(name: "data", includeIfNull: false)
  final String? data;
  @JsonKey(name: "value", includeIfNull: false)
  final String? value;
  @JsonKey(name: "erc20Amount", includeIfNull: false)
  final String? erc20Amount;
  @JsonKey(name: "erc20Spender", includeIfNull: false)
  final String? erc20Spender;
  @JsonKey(name: "solanaSponsor", includeIfNull: false)
  final String? solanaSponsor;
  @JsonKey(name: "bridgeIds", includeIfNull: false)
  final List<String>? bridgeIds;
  @JsonKey(name: "refundTo", includeIfNull: false)
  final String? refundTo;
  @JsonKey(name: "returnDepositAddress", includeIfNull: false)
  final bool? returnDepositAddress;

  @JsonKey(name: "appFees", includeIfNull: false)
  final String? appFees;
  @JsonKey(name: "userId", includeIfNull: false)
  final String? userId;
  @JsonKey(name: "gasless", includeIfNull: false)
  final bool? gasless;

  Map<String, dynamic> toJson() => _$SwapsXyzActionRequestToJson(this);
}

@JsonSerializable(createToJson: false)
class SwapsXyzPayment {
  const SwapsXyzPayment({
    required this.chainId,
    required this.address,
    required this.name,
    required this.symbol,
    required this.decimals,
    required this.isNative,
    required this.amount,
    this.logo,
    this.swapsXyzCode,
    this.usdAmount,
  });

  factory SwapsXyzPayment.fromJson(Map<String, dynamic> json) => _$SwapsXyzPaymentFromJson(json);

  @JsonKey(name: "chainId")
  final int chainId;
  @JsonKey(name: "address")
  final String address;
  @JsonKey(name: "name")
  final String name;
  @JsonKey(name: "symbol")
  final String symbol;
  @JsonKey(name: "decimals")
  final int decimals;
  @JsonKey(name: "isNative")
  final bool isNative;
  @JsonKey(name: "amount")
  @SwapsXyzBigIntAmountConverter()
  final BigInt amount;
  @JsonKey(name: "logo")
  final String? logo;
  @JsonKey(name: "swapsXyzCode")
  final String? swapsXyzCode;
  @JsonKey(name: "usdAmount")
  final double? usdAmount;
}

@JsonSerializable(createToJson: false)
class SwapsXyzEvmTransaction {
  const SwapsXyzEvmTransaction({
    required this.to,
    required this.data,
    required this.value,
    this.chainId,
  });

  factory SwapsXyzEvmTransaction.fromJson(Map<String, dynamic> json) =>
      _$SwapsXyzEvmTransactionFromJson(json);

  @JsonKey(name: "to")
  final String to;

  @JsonKey(name: "data")
  final String data;
  @JsonKey(name: "value")
  final String value;
  @JsonKey(name: "chainId")
  final int? chainId;
}

@JsonSerializable(createToJson: false)
class SwapsXyzSolanaTransaction {
  const SwapsXyzSolanaTransaction({
    required this.base64Tx,
    required this.recentBlockhash,
    required this.payer,
  });

  factory SwapsXyzSolanaTransaction.fromJson(Map<String, dynamic> json) =>
      _$SwapsXyzSolanaTransactionFromJson(json);

  @JsonKey(name: "base64Tx")
  final String base64Tx;
  @JsonKey(name: "recentBlockhash")
  final String recentBlockhash;
  @JsonKey(name: "payer")
  final String payer;
}

@JsonSerializable(createToJson: false)
class SwapsXyzActionResponse {
  const SwapsXyzActionResponse({
    required this.tx,
    required this.txId,
    required this.vmId,
    required this.amountIn,
    required this.amountInMax,
    required this.amountOut,
    required this.amountOutMin,
    required this.protocolFee,
    required this.applicationFee,
    required this.exchangeRate,
    required this.estimatedTxTime,
    required this.requiresTokenApproval,
    required this.requiresRegisterTransaction,
    this.estimatedPriceImpact,
    this.bridgeFee,
    this.bridgeIds,
    this.allRoutes,
    this.executionsType,
  });

  factory SwapsXyzActionResponse.fromJson(Map<String, dynamic> json) =>
      _$SwapsXyzActionResponseFromJson(json);

  @JsonKey(name: "tx")
  final Map<String, dynamic> tx;
  @JsonKey(name: "txId")
  final String txId;
  @JsonKey(name: "vmId", unknownEnumValue: SwapsXyzVmId.unknown)
  final SwapsXyzVmId vmId;
  @JsonKey(name: "amountIn")
  final SwapsXyzPayment amountIn;
  @JsonKey(name: "amountInMax")
  final SwapsXyzPayment amountInMax;
  @JsonKey(name: "amountOut")
  final SwapsXyzPayment amountOut;
  @JsonKey(name: "amountOutMin")
  final SwapsXyzPayment amountOutMin;
  @JsonKey(name: "protocolFee")
  final SwapsXyzPayment protocolFee;
  @JsonKey(name: "applicationFee")
  final SwapsXyzPayment applicationFee;
  @JsonKey(name: "bridgeFee")
  final SwapsXyzPayment? bridgeFee;
  @JsonKey(name: "bridgeIds")
  final List<String>? bridgeIds;
  @JsonKey(name: "exchangeRate")
  final double exchangeRate;

  @JsonKey(name: "estimatedTxTime")
  final double estimatedTxTime;
  @JsonKey(name: "estimatedPriceImpact")
  final double? estimatedPriceImpact;
  @JsonKey(name: "requiresTokenApproval")
  final bool requiresTokenApproval;
  @JsonKey(name: "requiresRegisterTransaction")
  final bool requiresRegisterTransaction;
  @JsonKey(name: "allRoutes")
  final List<Map<String, dynamic>>? allRoutes;
  @JsonKey(name: "executionsType", unknownEnumValue: SwapsXyzExecutionsType.unknown)
  final SwapsXyzExecutionsType? executionsType;

  SwapsXyzEvmTransaction get evmTx => SwapsXyzEvmTransaction.fromJson(tx);

  SwapsXyzSolanaTransaction get solanaTx => SwapsXyzSolanaTransaction.fromJson(tx);
}


@JsonSerializable()
class SwapsXyzTxRegistrationRequest {
  const SwapsXyzTxRegistrationRequest({
    required this.txId,
    this.txHash,
    this.vmId,
    this.chainId,
  });

  @JsonKey(name: "txId")
  final String txId;
  @JsonKey(name: "txHash", includeIfNull: false)
  final String? txHash;

  @JsonKey(name: "vmId", includeIfNull: false)
  final String? vmId;
  @JsonKey(name: "chainId", includeIfNull: false)
  final int? chainId;

  Map<String, dynamic> toJson() => _$SwapsXyzTxRegistrationRequestToJson(this);
}

@JsonSerializable(createToJson: false)
class SwapsXyzValidatedTxId {
  const SwapsXyzValidatedTxId({required this.success, this.error});

  factory SwapsXyzValidatedTxId.fromJson(Map<String, dynamic> json) =>
      _$SwapsXyzValidatedTxIdFromJson(json);

  @JsonKey(name: "success")
  final bool success;
  @JsonKey(name: "error")
  final String? error;
}


/// query for GET /api/getStatus. all three are optional in the spec: look up by txId, or by
/// txHash plus the chainId it was sent on
@JsonSerializable()
class SwapsXyzStatusRequest {
  const SwapsXyzStatusRequest({this.txId, this.txHash, this.chainId});

  @JsonKey(name: "txId", includeIfNull: false)
  final String? txId;
  @JsonKey(name: "txHash", includeIfNull: false)
  final String? txHash;
  @JsonKey(name: "chainId", includeIfNull: false)
  final String? chainId;

  Map<String, dynamic> toJson() => _$SwapsXyzStatusRequestToJson(this);
}

@JsonSerializable(createToJson: false)
class SwapsXyzToken {
  const SwapsXyzToken({
    required this.name,
    required this.symbol,
    required this.decimals,
    required this.amount,
    required this.chainId,
    this.address,
    this.isNative,
    this.usdAmount,
  });

  factory SwapsXyzToken.fromJson(Map<String, dynamic> json) => _$SwapsXyzTokenFromJson(json);

  @JsonKey(name: "name")
  final String name;
  @JsonKey(name: "symbol")
  final String symbol;
  @JsonKey(name: "decimals")
  final int decimals;
  @JsonKey(name: "amount")
  @SwapsXyzBigIntAmountConverter()
  final BigInt amount;
  @JsonKey(name: "chainId")
  final int chainId;

  @JsonKey(name: "address")
  final String? address;
  @JsonKey(name: "isNative")
  final bool? isNative;
  @JsonKey(name: "usdAmount")
  final double? usdAmount;
}

@JsonSerializable(createToJson: false)
class SwapsXyzOnchainTx {
  const SwapsXyzOnchainTx({
    required this.txHash,
    required this.chainId,
    required this.timestamp,
    this.toAddress,
    this.value,
    this.paymentToken,
    this.revertReason,
  });

  factory SwapsXyzOnchainTx.fromJson(Map<String, dynamic> json) =>
      _$SwapsXyzOnchainTxFromJson(json);

  @JsonKey(name: "txHash")
  final String txHash;
  @JsonKey(name: "chainId")
  final int chainId;
  @JsonKey(name: "timestamp")
  @SwapsXyzTimestampConverter()
  final DateTime timestamp;
  @JsonKey(name: "toAddress")
  final String? toAddress;
  @JsonKey(name: "value")
  final String? value;

  @JsonKey(name: "paymentToken")
  final SwapsXyzToken? paymentToken;
  @JsonKey(name: "revertReason")
  final String? revertReason;
}

@JsonSerializable(createToJson: false)
class SwapsXyzTxNode {
  const SwapsXyzTxNode({required this.chainId, this.txHash, this.timestamp, this.nextBridge});

  factory SwapsXyzTxNode.fromJson(Map<String, dynamic> json) => _$SwapsXyzTxNodeFromJson(json);

  @JsonKey(name: "chainId")
  final int chainId;
  @JsonKey(name: "txHash")
  final String? txHash;
  @JsonKey(name: "timestamp")
  @SecondsDateTimeConverter()
  final DateTime? timestamp;

  @JsonKey(name: "nextBridge")
  final String? nextBridge;
}

@JsonSerializable(createToJson: false)
class SwapsXyzBridgeDetails {
  const SwapsXyzBridgeDetails({required this.isBridge, this.bridgeTime, this.txPath});

  factory SwapsXyzBridgeDetails.fromJson(Map<String, dynamic> json) =>
      _$SwapsXyzBridgeDetailsFromJson(json);

  @JsonKey(name: "isBridge")
  final bool isBridge;

  @JsonKey(name: "bridgeTime")
  final double? bridgeTime;
  @JsonKey(name: "txPath")
  final List<SwapsXyzTxNode>? txPath;
}

@JsonSerializable(createToJson: false)
class SwapsXyzTxDetails {
  const SwapsXyzTxDetails({
    required this.status,
    required this.sender,
    required this.srcChainId,
    required this.txId,
    this.dstChainId,
    this.srcTxHash,
    this.dstTxHash,
    this.bridgeDetails,
    this.srcTx,
    this.dstTx,
    this.usdValue,
    this.actionRequest,
    this.actionResponse,
  });

  factory SwapsXyzTxDetails.fromJson(Map<String, dynamic> json) =>
      _$SwapsXyzTxDetailsFromJson(json);

  @JsonKey(name: "status", unknownEnumValue: SwapsXyzTxStatusValue.unknown)
  final SwapsXyzTxStatusValue status;

  @JsonKey(name: "sender")
  final String sender;
  @JsonKey(name: "srcChainId")
  final int srcChainId;
  @JsonKey(name: "dstChainId")
  final int? dstChainId;
  @JsonKey(name: "txId")
  final String txId;
  @JsonKey(name: "srcTxHash")
  final String? srcTxHash;
  @JsonKey(name: "dstTxHash")
  final String? dstTxHash;
  @JsonKey(name: "bridgeDetails")
  final SwapsXyzBridgeDetails? bridgeDetails;
  @JsonKey(name: "srcTx")
  final SwapsXyzOnchainTx? srcTx;
  @JsonKey(name: "dstTx")
  final SwapsXyzOnchainTx? dstTx;
  @JsonKey(name: "usdValue")
  final double? usdValue;
  @JsonKey(name: "actionRequest")
  final SwapsXyzActionRequest? actionRequest;
  @JsonKey(name: "actionResponse")
  final SwapsXyzActionResponse? actionResponse;
}
