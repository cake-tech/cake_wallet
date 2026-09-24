// spec reference: https://1click.chaindefuser.com/docs/v0/openapi.yaml

import "package:cake_wallet/exchange/trade_state.dart";
import "package:json_annotation/json_annotation.dart";

part "near_intents_api_schema.g.dart";


enum NearIntentsSwapType {
  @JsonValue("EXACT_INPUT")
  exactInput,
  @JsonValue("EXACT_OUTPUT")
  exactOutput,
  @JsonValue("FLEX_INPUT")
  flexInput,
  @JsonValue("ANY_INPUT")
  anyInput,
  unknown,
}

enum NearIntentsDepositType {
  @JsonValue("ORIGIN_CHAIN")
  originChain,
  @JsonValue("INTENTS")
  intents,
  @JsonValue("CONFIDENTIAL_INTENTS")
  confidentialIntents,
  unknown,
}

enum NearIntentsRecipientType {
  @JsonValue("DESTINATION_CHAIN")
  destinationChain,
  @JsonValue("INTENTS")
  intents,
  @JsonValue("CONFIDENTIAL_INTENTS")
  confidentialIntents,
  unknown,
}

enum NearIntentsDepositMode {
  @JsonValue("SIMPLE")
  simple,
  @JsonValue("MEMO")
  memo,
  unknown,
}

enum NearIntentsStatus {
  @JsonValue("KNOWN_DEPOSIT_TX")
  knownDepositTx,
  @JsonValue("PENDING_DEPOSIT")
  pendingDeposit,
  @JsonValue("INCOMPLETE_DEPOSIT")
  incompleteDeposit,
  @JsonValue("PROCESSING")
  processing,
  @JsonValue("SUCCESS")
  success,
  @JsonValue("REFUNDED")
  refunded,
  @JsonValue("FAILED")
  failed,
  unknown,
}

extension StatusToState on NearIntentsStatus {
  TradeState get toState => switch(this) {
    .pendingDeposit => .pending,
    .processing => .processing,
    .success => .success,
    .incompleteDeposit => .underpaid,
    .refunded => .refunded,
    .failed => .failed,
    _ => .notFound,
  };
}

@JsonSerializable(createToJson: false)
class NearIntentsErrorResponse {
  const NearIntentsErrorResponse({required this.message});

  factory NearIntentsErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$NearIntentsErrorResponseFromJson(json);

  @JsonKey(name: "message")
  final String message;
}


@JsonSerializable(createToJson: false)
class NearIntentsToken {
  const NearIntentsToken({
    required this.assetId,
    required this.decimals,
    required this.blockchain,
    required this.symbol,
    required this.price,
    required this.priceUpdatedAt,
    this.contractAddress,
    this.coingeckoId,
  });

  factory NearIntentsToken.fromJson(Map<String, dynamic> json) =>
      _$NearIntentsTokenFromJson(json);

  @JsonKey(name: "assetId")
  final String assetId;
  @JsonKey(name: "decimals")
  final int decimals;

  @JsonKey(name: "blockchain")
  final String blockchain;
  @JsonKey(name: "symbol")
  final String symbol;

  @JsonKey(name: "price")
  final double price;
  @JsonKey(name: "priceUpdatedAt")
  final DateTime priceUpdatedAt;
  @JsonKey(name: "contractAddress")
  final String? contractAddress;
  @JsonKey(name: "coingeckoId")
  final String? coingeckoId;
}


@JsonSerializable()
class NearIntentsAppFee {
  const NearIntentsAppFee({required this.recipient, required this.fee});

  factory NearIntentsAppFee.fromJson(Map<String, dynamic> json) =>
      _$NearIntentsAppFeeFromJson(json);

  @JsonKey(name: "recipient")
  final String recipient;

  @JsonKey(name: "fee")
  final int fee;

  Map<String, dynamic> toJson() => _$NearIntentsAppFeeToJson(this);
}

@JsonSerializable()
class NearIntentsRebate {
  const NearIntentsRebate({required this.recipient, required this.share});

  factory NearIntentsRebate.fromJson(Map<String, dynamic> json) =>
      _$NearIntentsRebateFromJson(json);

  @JsonKey(name: "recipient")
  final String recipient;

  @JsonKey(name: "share")
  final int share;

  Map<String, dynamic> toJson() => _$NearIntentsRebateToJson(this);
}

@JsonSerializable(explicitToJson: true)
class NearIntentsQuoteRequest {
  const NearIntentsQuoteRequest({
    required this.dry,
    required this.swapType,
    required this.slippageTolerance,
    required this.originAsset,
    required this.depositType,
    required this.destinationAsset,
    required this.amount,
    required this.refundTo,
    required this.refundType,
    required this.recipient,
    required this.recipientType,
    required this.deadline,
    this.depositMode,
    this.connectedWallets,
    this.sessionId,
    this.virtualChainRecipient,
    this.virtualChainRefundRecipient,
    this.customRecipientMsg,
    this.confidentiality,
    this.referral,
    this.rebates,
    this.quoteWaitingTimeMs,
    this.appFees,
    this.insured,
  });

  factory NearIntentsQuoteRequest.fromJson(Map<String, dynamic> json) =>
      _$NearIntentsQuoteRequestFromJson(json);

  @JsonKey(name: "dry")
  final bool dry;
  @JsonKey(name: "depositMode", includeIfNull: false)
  final NearIntentsDepositMode? depositMode;
  @JsonKey(name: "swapType")
  final NearIntentsSwapType swapType;

  @JsonKey(name: "slippageTolerance")
  final int slippageTolerance;

  @JsonKey(name: "originAsset")
  final String originAsset;
  @JsonKey(name: "destinationAsset")
  final String destinationAsset;
  @JsonKey(name: "depositType")
  final NearIntentsDepositType depositType;

  @JsonKey(name: "amount")
  final BigInt amount;
  @JsonKey(name: "refundTo")
  final String refundTo;
  @JsonKey(name: "refundType")
  final NearIntentsDepositType refundType;
  @JsonKey(name: "recipient")
  final String recipient;
  @JsonKey(name: "recipientType")
  final NearIntentsRecipientType recipientType;

  @JsonKey(name: "deadline")
  final DateTime deadline;
  @JsonKey(name: "connectedWallets", includeIfNull: false)
  final List<String>? connectedWallets;
  @JsonKey(name: "sessionId", includeIfNull: false)
  final String? sessionId;
  @JsonKey(name: "virtualChainRecipient", includeIfNull: false)
  final String? virtualChainRecipient;
  @JsonKey(name: "virtualChainRefundRecipient", includeIfNull: false)
  final String? virtualChainRefundRecipient;
  @JsonKey(name: "customRecipientMsg", includeIfNull: false)
  final String? customRecipientMsg;

  @JsonKey(name: "confidentiality", includeIfNull: false)
  final String? confidentiality;
  @JsonKey(name: "referral", includeIfNull: false)
  final String? referral;
  @JsonKey(name: "rebates", includeIfNull: false)
  final List<NearIntentsRebate>? rebates;

  @JsonKey(name: "quoteWaitingTimeMs", includeIfNull: false)
  final int? quoteWaitingTimeMs;
  @JsonKey(name: "appFees", includeIfNull: false)
  final List<NearIntentsAppFee>? appFees;
  @JsonKey(name: "insured", includeIfNull: false)
  final bool? insured;

  Map<String, dynamic> toJson() => _$NearIntentsQuoteRequestToJson(this);
}

@JsonSerializable(createToJson: false)
class NearIntentsChainDepositAddress {
  const NearIntentsChainDepositAddress({
    required this.blockchain,
    required this.address,
    this.memo,
  });

  factory NearIntentsChainDepositAddress.fromJson(Map<String, dynamic> json) =>
      _$NearIntentsChainDepositAddressFromJson(json);

  @JsonKey(name: "blockchain")
  final String blockchain;
  @JsonKey(name: "address")
  final String address;
  @JsonKey(name: "memo")
  final String? memo;
}

@JsonSerializable(createToJson: false)
class NearIntentsQuote {
  const NearIntentsQuote({
    required this.amountIn,
    required this.amountInFormatted,
    required this.amountInUsd,
    required this.minAmountIn,
    required this.amountOut,
    required this.amountOutFormatted,
    required this.amountOutUsd,
    required this.minAmountOut,
    required this.timeEstimate,
    this.depositAddress,
    this.depositMemo,
    this.chainDepositAddresses,
    this.deadline,
    this.timeWhenInactive,
    this.virtualChainRecipient,
    this.virtualChainRefundRecipient,
    this.customRecipientMsg,
    this.refundFee,
    this.withdrawFee,
  });

  factory NearIntentsQuote.fromJson(Map<String, dynamic> json) => _$NearIntentsQuoteFromJson(json);

  @JsonKey(name: "depositAddress")
  final String? depositAddress;

  @JsonKey(name: "depositMemo")
  final String? depositMemo;

  @JsonKey(name: "chainDepositAddresses")
  final List<NearIntentsChainDepositAddress>? chainDepositAddresses;
  @JsonKey(name: "amountIn")
  final BigInt amountIn;
  @JsonKey(name: "amountInFormatted")
  final String amountInFormatted;
  @JsonKey(name: "amountInUsd")
  final String amountInUsd;
  @JsonKey(name: "minAmountIn")
  final BigInt minAmountIn;
  @JsonKey(name: "amountOut")
  final BigInt amountOut;
  @JsonKey(name: "amountOutFormatted")
  final String amountOutFormatted;
  @JsonKey(name: "amountOutUsd")
  final String amountOutUsd;
  @JsonKey(name: "minAmountOut")
  final BigInt minAmountOut;
  @JsonKey(name: "deadline")
  final DateTime? deadline;

  @JsonKey(name: "timeWhenInactive")
  final DateTime? timeWhenInactive;

  @JsonKey(name: "timeEstimate")
  final int timeEstimate;
  @JsonKey(name: "virtualChainRecipient")
  final String? virtualChainRecipient;
  @JsonKey(name: "virtualChainRefundRecipient")
  final String? virtualChainRefundRecipient;
  @JsonKey(name: "customRecipientMsg")
  final String? customRecipientMsg;
  @JsonKey(name: "refundFee")
  final BigInt? refundFee;
  @JsonKey(name: "withdrawFee")
  final BigInt? withdrawFee;
}

@JsonSerializable(createToJson: false)
class NearIntentsQuoteResponse {
  const NearIntentsQuoteResponse({
    this.correlationId,
    required this.timestamp,
    required this.signature,
    required this.quoteRequest,
    required this.quote,
  });

  factory NearIntentsQuoteResponse.fromJson(Map<String, dynamic> json) =>
      _$NearIntentsQuoteResponseFromJson(json);

  @JsonKey(name: "correlationId")
  final String? correlationId;

  @JsonKey(name: "timestamp")
  final DateTime timestamp;

  @JsonKey(name: "signature")
  final String signature;
  @JsonKey(name: "quoteRequest")
  final NearIntentsQuoteRequest quoteRequest;
  @JsonKey(name: "quote")
  final NearIntentsQuote quote;
}


@JsonSerializable(createToJson: false)
class NearIntentsTransactionDetails {
  const NearIntentsTransactionDetails({required this.hash, required this.explorerUrl});

  factory NearIntentsTransactionDetails.fromJson(Map<String, dynamic> json) =>
      _$NearIntentsTransactionDetailsFromJson(json);

  @JsonKey(name: "hash")
  final String hash;
  @JsonKey(name: "explorerUrl")
  final String explorerUrl;
}

@JsonSerializable(createToJson: false)
class NearIntentsSwapDetails {
  const NearIntentsSwapDetails({
    required this.intentHashes,
    required this.nearTxHashes,
    required this.originChainTxHashes,
    required this.destinationChainTxHashes,
    this.amountIn,
    this.amountInFormatted,
    this.amountInUsd,
    this.amountOut,
    this.amountOutFormatted,
    this.amountOutUsd,
    this.slippage,
    this.refundedAmount,
    this.refundedAmountFormatted,
    this.refundedAmountUsd,
    this.refundReason,
    this.depositedAmount,
    this.depositedAmountFormatted,
    this.depositedAmountUsd,
    this.withdrawFee,
    this.referral,
  });

  factory NearIntentsSwapDetails.fromJson(Map<String, dynamic> json) =>
      _$NearIntentsSwapDetailsFromJson(json);

  @JsonKey(name: "intentHashes")
  final List<String> intentHashes;
  @JsonKey(name: "nearTxHashes")
  final List<String> nearTxHashes;

  @JsonKey(name: "originChainTxHashes")
  final List<NearIntentsTransactionDetails> originChainTxHashes;

  @JsonKey(name: "destinationChainTxHashes")
  final List<NearIntentsTransactionDetails> destinationChainTxHashes;

  @JsonKey(name: "amountIn")
  final BigInt? amountIn;
  @JsonKey(name: "amountInFormatted")
  final String? amountInFormatted;
  @JsonKey(name: "amountInUsd")
  final String? amountInUsd;
  @JsonKey(name: "amountOut")
  final BigInt? amountOut;
  @JsonKey(name: "amountOutFormatted")
  final String? amountOutFormatted;
  @JsonKey(name: "amountOutUsd")
  final String? amountOutUsd;

  @JsonKey(name: "slippage")
  final int? slippage;

  @JsonKey(name: "depositedAmount")
  final BigInt? depositedAmount;
  @JsonKey(name: "depositedAmountFormatted")
  final String? depositedAmountFormatted;
  @JsonKey(name: "depositedAmountUsd")
  final String? depositedAmountUsd;
  @JsonKey(name: "refundedAmount")
  final BigInt? refundedAmount;
  @JsonKey(name: "refundedAmountFormatted")
  final String? refundedAmountFormatted;
  @JsonKey(name: "refundedAmountUsd")
  final String? refundedAmountUsd;

  @JsonKey(name: "refundReason")
  final String? refundReason;
  @JsonKey(name: "withdrawFee")
  final BigInt? withdrawFee;
  @JsonKey(name: "referral")
  final String? referral;
}

@JsonSerializable(createToJson: false)
class NearIntentsStatusResponse {
  const NearIntentsStatusResponse({
    required this.correlationId,
    required this.status,
    required this.updatedAt,
    required this.quoteResponse,
    required this.swapDetails,
  });

  factory NearIntentsStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$NearIntentsStatusResponseFromJson(json);

  @JsonKey(name: "correlationId")
  final String correlationId;
  @JsonKey(name: "status", unknownEnumValue: NearIntentsStatus.unknown)
  final NearIntentsStatus status;
  @JsonKey(name: "updatedAt")
  final DateTime updatedAt;

  @JsonKey(name: "quoteResponse")
  final NearIntentsQuoteResponse quoteResponse;
  @JsonKey(name: "swapDetails")
  final NearIntentsSwapDetails swapDetails;
}
