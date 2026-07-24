// spec reference: https://chainflip-broker.io/docs/v1/docs.json

import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/exchange/utils/json_converters.dart";
import "package:cw_core/crypto_currency.dart";
import "package:json_annotation/json_annotation.dart";

part "chainflip_api_schema.g.dart";

class ChainflipCurrencyConverter implements JsonConverter<CryptoCurrency, String> {
  const ChainflipCurrencyConverter();

  @override
  String toJson(CryptoCurrency currency) {
    if (currency == CryptoCurrency.trx) {
      return "trx.tron";
    }
    if (currency == CryptoCurrency.usdttrc20) {
      return "usdt.tron";
    }

    final tag = currency.tag?.toLowerCase();
    final title = currency.title.toLowerCase();

    if (tag == null) {
      return "$title.$title";
    }

    return "$title.$tag";
  }

  @override
  CryptoCurrency fromJson(String json) {
    if (json == "trx.tron") {
      return CryptoCurrency.trx;
    }
    if (json == "usdt.tron") {
      return CryptoCurrency.usdttrc20;
    }

    final parts = json.split(".");
    if (parts.length != 2) {
      throw ArgumentError("bad currency input, should be title.tag");
    }
    final title = parts.first;
    final tag = parts.last;
    if (title == tag) {
      return CryptoCurrency.fromString(title);
    }
    final currency = CryptoCurrency.safeParseCurrencyFromString(title, tag: tag);
    if (currency == null) {
      throw ArgumentError("unknown Chainflip asset: $json");
    }
    return currency;
  }
}

class ChainflipTradeStateConverter implements JsonConverter<TradeState, String> {
  const ChainflipTradeStateConverter();

  @override
  String toJson(TradeState state) => switch (state) {
    TradeState.waiting => "waiting",
    TradeState.processing => "processing",
    TradeState.success => "completed",
    TradeState.failed => "failed",
    _ => "unknown",
  };

  @override
  TradeState fromJson(String json) => switch (json) {
    "waiting" => TradeState.waiting,
    "receiving" => TradeState.processing,
    "swapping" => TradeState.processing,
    "sending" => TradeState.processing,
    "sent" => TradeState.processing,
    "completed" => TradeState.success,
    "failed" => TradeState.failed,
    _ => TradeState.notFound,
  };
}

@JsonSerializable()
@ChainflipCurrencyConverter()
class ChainflipFetchQuotesRequest {
  const ChainflipFetchQuotesRequest({
    required this.apiKey,
    required this.sourceAsset,
    required this.destinationAsset,
    required this.amount,
    required this.commissionBps,
  });

  @JsonKey(name: "apiKey")
  final String apiKey;
  @JsonKey(name: "sourceAsset")
  final CryptoCurrency sourceAsset;
  @JsonKey(name: "destinationAsset")
  final CryptoCurrency destinationAsset;
  @JsonKey(name: "amount")
  final BigInt amount;
  @JsonKey(name: "commissionBps")
  final String commissionBps;

  Map<String, dynamic> toJson() => _$ChainflipFetchQuotesRequestToJson(this);
}

enum ChainflipFeeType {
  @JsonValue("egress")
  egress,
  @JsonValue("ingress")
  ingress,
  @JsonValue("network")
  network,
  @JsonValue("broker")
  broker,
  @JsonValue("liquidity")
  liquidity,
  @JsonValue("boost")
  boost,
  @JsonValue("refund")
  refund,
  unknown,
}

enum ChainflipQuoteType {
  @JsonValue("regular")
  regular,
  @JsonValue("dca")
  dca,
  unknown,
}

@JsonSerializable(createToJson: false)
@ChainflipCurrencyConverter()
class ChainflipFeeData {
  const ChainflipFeeData({required this.type, required this.asset, required this.amountNative});

  factory ChainflipFeeData.fromJson(Map<String, dynamic> json) => _$ChainflipFeeDataFromJson(json);

  @JsonKey(name: "type", unknownEnumValue: ChainflipFeeType.unknown)
  final ChainflipFeeType type;
  @JsonKey(name: "asset")
  final CryptoCurrency asset;
  @JsonKey(name: "amountNative")
  final BigInt amountNative;
}

@JsonSerializable(createToJson: false)
@ChainflipCurrencyConverter()
class ChainflipPoolFee {
  const ChainflipPoolFee({required this.asset, required this.amountNative});

  factory ChainflipPoolFee.fromJson(Map<String, dynamic> json) => _$ChainflipPoolFeeFromJson(json);

  @JsonKey(name: "asset")
  final CryptoCurrency asset;
  @JsonKey(name: "amountNative")
  final BigInt amountNative;
}

@JsonSerializable(createToJson: false)
@ChainflipCurrencyConverter()
class ChainflipPoolInfo {
  const ChainflipPoolInfo({required this.baseAsset, required this.quoteAsset, required this.fee});

  factory ChainflipPoolInfo.fromJson(Map<String, dynamic> json) =>
      _$ChainflipPoolInfoFromJson(json);

  @JsonKey(name: "baseAsset")
  final CryptoCurrency baseAsset;
  @JsonKey(name: "quoteAsset")
  final CryptoCurrency quoteAsset;
  @JsonKey(name: "fee")
  final ChainflipPoolFee fee;
}

@JsonSerializable(createToJson: false)
class ChainflipEstimatedDurations {
  const ChainflipEstimatedDurations({
    required this.deposit,
    required this.swap,
    required this.egress,
  });

  factory ChainflipEstimatedDurations.fromJson(Map<String, dynamic> json) =>
      _$ChainflipEstimatedDurationsFromJson(json);

  @JsonKey(name: "deposit")
  final double deposit;
  @JsonKey(name: "swap")
  final double swap;
  @JsonKey(name: "egress")
  final double egress;
}

@JsonSerializable(createToJson: false)
@ChainflipCurrencyConverter()
class ChainflipBoostQuote {
  const ChainflipBoostQuote({
    required this.ingressAsset,
    required this.ingressAmountNative,
    required this.egressAsset,
    required this.egressAmountNative,
    required this.includedFees,
    required this.lowLiquidityWarning,
    required this.poolInfo,
    required this.estimatedDurationSeconds,
    required this.estimatedDurationsSeconds,
    required this.estimatedPrice,
    required this.estimatedBoostFeeBps,
    this.intermediateAsset,
    this.intermediateAmountNative,
    this.numberOfChunks,
    this.chunkIntervalBlocks,
  });

  factory ChainflipBoostQuote.fromJson(Map<String, dynamic> json) =>
      _$ChainflipBoostQuoteFromJson(json);

  @JsonKey(name: "ingressAsset")
  final CryptoCurrency ingressAsset;
  @JsonKey(name: "ingressAmountNative")
  final BigInt ingressAmountNative;
  @JsonKey(name: "intermediateAsset")
  final CryptoCurrency? intermediateAsset;
  @JsonKey(name: "intermediateAmountNative")
  final BigInt? intermediateAmountNative;
  @JsonKey(name: "egressAsset")
  final CryptoCurrency egressAsset;
  @JsonKey(name: "egressAmountNative")
  final BigInt egressAmountNative;
  @JsonKey(name: "includedFees")
  final List<ChainflipFeeData> includedFees;
  @JsonKey(name: "lowLiquidityWarning")
  final bool lowLiquidityWarning;
  @JsonKey(name: "poolInfo")
  final List<ChainflipPoolInfo> poolInfo;
  @JsonKey(name: "estimatedDurationSeconds")
  final double estimatedDurationSeconds;
  @JsonKey(name: "estimatedDurationsSeconds")
  final ChainflipEstimatedDurations estimatedDurationsSeconds;
  @JsonKey(name: "estimatedPrice")
  final double estimatedPrice;
  @JsonKey(name: "estimatedBoostFeeBps")
  final double estimatedBoostFeeBps;
  @JsonKey(name: "numberOfChunks")
  final int? numberOfChunks;
  @JsonKey(name: "chunkIntervalBlocks")
  final int? chunkIntervalBlocks;
}

@JsonSerializable(createToJson: false)
@ChainflipCurrencyConverter()
class ChainflipQuote implements Comparable<ChainflipQuote> {
  const ChainflipQuote({
    required this.type,
    required this.ingressAsset,
    required this.ingressAmountNative,
    required this.egressAsset,
    required this.egressAmountNative,
    required this.includedFees,
    required this.recommendedSlippageTolerancePercent,
    required this.lowLiquidityWarning,
    required this.poolInfo,
    required this.estimatedDurationSeconds,
    required this.estimatedDurationsSeconds,
    required this.estimatedPrice,
    this.intermediateAsset,
    this.intermediateAmountNative,
    this.boostQuote,
    this.numberOfChunks,
    this.chunkIntervalBlocks,
    this.platform,
  });

  factory ChainflipQuote.fromJson(Map<String, dynamic> json) => _$ChainflipQuoteFromJson(json);

  @JsonKey(name: "type", unknownEnumValue: ChainflipQuoteType.unknown)
  final ChainflipQuoteType type;
  @JsonKey(name: "ingressAsset")
  final CryptoCurrency ingressAsset;
  @JsonKey(name: "ingressAmountNative")
  final BigInt ingressAmountNative;
  @JsonKey(name: "intermediateAsset")
  final CryptoCurrency? intermediateAsset;
  @JsonKey(name: "intermediateAmountNative")
  final BigInt? intermediateAmountNative;
  @JsonKey(name: "egressAsset")
  final CryptoCurrency egressAsset;
  @JsonKey(name: "egressAmountNative")
  final BigInt egressAmountNative;
  @JsonKey(name: "includedFees")
  final List<ChainflipFeeData> includedFees;
  @JsonKey(name: "recommendedSlippageTolerancePercent")
  final double recommendedSlippageTolerancePercent;
  @JsonKey(name: "lowLiquidityWarning")
  final bool lowLiquidityWarning;
  @JsonKey(name: "poolInfo")
  final List<ChainflipPoolInfo> poolInfo;
  @JsonKey(name: "estimatedDurationSeconds")
  final double estimatedDurationSeconds;
  @JsonKey(name: "estimatedDurationsSeconds")
  final ChainflipEstimatedDurations estimatedDurationsSeconds;
  @JsonKey(name: "estimatedPrice")
  final double estimatedPrice;
  @JsonKey(name: "boostQuote")
  final ChainflipBoostQuote? boostQuote;
  @JsonKey(name: "numberOfChunks")
  final int? numberOfChunks;
  @JsonKey(name: "chunkIntervalBlocks")
  final int? chunkIntervalBlocks;
  @JsonKey(name: "platform")
  final String? platform;

  @override
  int compareTo(ChainflipQuote other) => egressAmountNative.compareTo(other.egressAmountNative);
}

class ChainflipFetchQuotesResponse {
  const ChainflipFetchQuotesResponse({required this.quotes});

  factory ChainflipFetchQuotesResponse.fromJson(List<dynamic> json) => ChainflipFetchQuotesResponse(
    quotes: json.map((quote) => ChainflipQuote.fromJson(quote as Map<String, dynamic>)).toList(),
  );

  final List<ChainflipQuote> quotes;
}

enum ChainflipAssetDirection {
  @JsonValue("both")
  both,
  @JsonValue("ingress")
  ingress,
  @JsonValue("egress")
  egress,
  unknown,
}

enum ChainflipNetwork {
  @JsonValue("Bitcoin")
  bitcoin,
  @JsonValue("Ethereum")
  ethereum,
  @JsonValue("Arbitrum")
  arbitrum,
  @JsonValue("Solana")
  solana,
  @JsonValue("Tron")
  tron,
  @JsonValue("Assethub")
  assethub,
  unknown,
}

@JsonSerializable(createToJson: false)
@ChainflipCurrencyConverter()
class ChainflipAsset {
  const ChainflipAsset({
    required this.enabled,
    required this.id,
    required this.direction,
    required this.ticker,
    required this.name,
    required this.network,
    required this.networkLogo,
    required this.assetLogo,
    required this.decimals,
    required this.minimalAmountNative,
    required this.usdPriceNative,
    required this.platforms,
    this.contractAddress,
  });

  factory ChainflipAsset.fromJson(Map<String, dynamic> json) => _$ChainflipAssetFromJson(json);

  @JsonKey(name: "enabled")
  final bool enabled;
  @JsonKey(name: "id")
  final CryptoCurrency id;
  @JsonKey(name: "direction", unknownEnumValue: ChainflipAssetDirection.unknown)
  final ChainflipAssetDirection direction;
  @JsonKey(name: "ticker")
  final String ticker;
  @JsonKey(name: "name")
  final String name;
  @JsonKey(name: "network", unknownEnumValue: ChainflipNetwork.unknown)
  final ChainflipNetwork network;
  @JsonKey(name: "contractAddress")
  final String? contractAddress;
  @JsonKey(name: "networkLogo")
  final String networkLogo;
  @JsonKey(name: "assetLogo")
  final String assetLogo;
  @JsonKey(name: "decimals")
  final int decimals;
  @JsonKey(name: "minimalAmountNative")
  final BigInt minimalAmountNative;
  @JsonKey(name: "usdPriceNative")
  final BigInt usdPriceNative;
  @JsonKey(name: "platforms")
  final List<String> platforms;
}

class ChainflipAssetsResponse {
  const ChainflipAssetsResponse({required this.assets});

  factory ChainflipAssetsResponse.fromJson(Map<String, dynamic> json) {
    final List<ChainflipAsset> assets = [];
    for (final asset in json["assets"] as List<dynamic>) {
      try {
        assets.add(ChainflipAsset.fromJson(asset as Map<String, dynamic>));
      } on ArgumentError {
        // this is bound to happen because chainflip has assets unsupported by cake
        // we just omit in the deserialization since we can't swap these anyway
      }
    }
    return ChainflipAssetsResponse(assets: assets);
  }

  final List<ChainflipAsset> assets;
}

@JsonSerializable()
@ChainflipCurrencyConverter()
class ChainflipSwapRequest {
  const ChainflipSwapRequest({
    required this.apiKey,
    required this.sourceAsset,
    required this.destinationAsset,
    required this.destinationAddress,
    required this.minimumPrice,
    required this.refundAddress,
    required this.retryDurationInBlocks,
    required this.commissionBps,
    this.boostFee,
    this.numberOfChunks,
    this.chunkIntervalBlocks,
  });

  @JsonKey(name: "apiKey")
  final String apiKey;
  @JsonKey(name: "sourceAsset")
  final CryptoCurrency sourceAsset;
  @JsonKey(name: "destinationAsset")
  final CryptoCurrency destinationAsset;
  @JsonKey(name: "destinationAddress")
  final String destinationAddress;
  @JsonKey(name: "commissionBps")
  final String commissionBps;
  @JsonKey(name: "boostFee", includeIfNull: false)
  final String? boostFee;
  @JsonKey(name: "minimumPrice")
  final String minimumPrice;
  @JsonKey(name: "refundAddress")
  final String refundAddress;
  @JsonKey(name: "retryDurationInBlocks")
  final int retryDurationInBlocks;
  @JsonKey(name: "numberOfChunks", includeIfNull: false)
  final int? numberOfChunks;
  @JsonKey(name: "chunkIntervalBlocks", includeIfNull: false)
  final int? chunkIntervalBlocks;

  Map<String, dynamic> toJson() => _$ChainflipSwapRequestToJson(this);
}

@JsonSerializable(createToJson: false)
class ChainflipSwapResponse {
  const ChainflipSwapResponse({
    required this.address,
    required this.issuedBlock,
    required this.network,
    required this.channelId,
    required this.sourceExpiryBlock,
    required this.explorerUrl,
    required this.channelOpeningFeeNative,
    this.id,
  });

  factory ChainflipSwapResponse.fromJson(Map<String, dynamic> json) =>
      _$ChainflipSwapResponseFromJson(json);

  @JsonKey(name: "id")
  final int? id;
  @JsonKey(name: "address")
  final String address;
  @JsonKey(name: "issuedBlock")
  final int issuedBlock;
  @JsonKey(name: "network", unknownEnumValue: ChainflipNetwork.unknown)
  final ChainflipNetwork network;
  @JsonKey(name: "channelId")
  final int channelId;
  @JsonKey(name: "sourceExpiryBlock")
  final int sourceExpiryBlock;
  @JsonKey(name: "explorerUrl")
  final String explorerUrl;
  @JsonKey(name: "channelOpeningFeeNative")
  final BigInt channelOpeningFeeNative;
}

@JsonSerializable()
class ChainflipStatusRequest {
  const ChainflipStatusRequest({
    required this.apiKey,
    required this.issuedBlock,
    required this.network,
    required this.channelId,
  });

  @JsonKey(name: "apiKey")
  final String apiKey;
  @JsonKey(name: "issuedBlock")
  final int issuedBlock;
  @JsonKey(name: "network")
  final ChainflipNetwork network;
  @JsonKey(name: "channelId")
  final int channelId;

  Map<String, dynamic> toJson() => _$ChainflipStatusRequestToJson(this);
}

@JsonSerializable(createToJson: false)
class ChainflipStatusReason {
  const ChainflipStatusReason({required this.code, required this.message});

  factory ChainflipStatusReason.fromJson(Map<String, dynamic> json) =>
      _$ChainflipStatusReasonFromJson(json);

  @JsonKey(name: "code")
  final String code;
  @JsonKey(name: "message")
  final String message;
}

@JsonSerializable(createToJson: false)
@MillisDateTimeConverter()
class ChainflipStatusFailure {
  const ChainflipStatusFailure({
    required this.failedAt,
    required this.failedBlockIndex,
    required this.mode,
    this.reason,
  });

  factory ChainflipStatusFailure.fromJson(Map<String, dynamic> json) =>
      _$ChainflipStatusFailureFromJson(json);

  @JsonKey(name: "failedAt")
  final DateTime failedAt;
  @JsonKey(name: "failedBlockIndex")
  final String failedBlockIndex;
  @JsonKey(name: "mode")
  final String mode;
  @JsonKey(name: "reason")
  final ChainflipStatusReason? reason;
}

@JsonSerializable(createToJson: false)
@MillisDateTimeConverter()
class ChainflipStatusChunkInfo {
  const ChainflipStatusChunkInfo({
    required this.inputAmountNative,
    required this.scheduledAt,
    required this.scheduledBlockIndex,
    required this.retryCount,
    this.intermediateAmountNative,
    this.outputAmountNative,
    this.executedAt,
    this.executedBlockIndex,
  });

  factory ChainflipStatusChunkInfo.fromJson(Map<String, dynamic> json) =>
      _$ChainflipStatusChunkInfoFromJson(json);

  @JsonKey(name: "inputAmountNative")
  final BigInt inputAmountNative;
  @JsonKey(name: "intermediateAmountNative")
  final BigInt? intermediateAmountNative;
  @JsonKey(name: "outputAmountNative")
  final BigInt? outputAmountNative;
  @JsonKey(name: "scheduledAt")
  final DateTime scheduledAt;
  @JsonKey(name: "scheduledBlockIndex")
  final String scheduledBlockIndex;
  @JsonKey(name: "executedAt")
  final DateTime? executedAt;
  @JsonKey(name: "executedBlockIndex")
  final String? executedBlockIndex;
  @JsonKey(name: "retryCount")
  final int retryCount;
}

@JsonSerializable(createToJson: false)
class ChainflipStatusDca {
  const ChainflipStatusDca({
    required this.executedChunks,
    required this.remainingChunks,
    this.lastExecutedChunk,
    this.currentChunk,
  });

  factory ChainflipStatusDca.fromJson(Map<String, dynamic> json) =>
      _$ChainflipStatusDcaFromJson(json);

  @JsonKey(name: "lastExecutedChunk")
  final ChainflipStatusChunkInfo? lastExecutedChunk;
  @JsonKey(name: "currentChunk")
  final ChainflipStatusChunkInfo? currentChunk;
  @JsonKey(name: "executedChunks")
  final int executedChunks;
  @JsonKey(name: "remainingChunks")
  final int remainingChunks;
}

@JsonSerializable(createToJson: false)
class ChainflipStatusAffiliateBroker {
  const ChainflipStatusAffiliateBroker({required this.account, required this.commissionBps});

  factory ChainflipStatusAffiliateBroker.fromJson(Map<String, dynamic> json) =>
      _$ChainflipStatusAffiliateBrokerFromJson(json);

  @JsonKey(name: "account")
  final String account;
  @JsonKey(name: "commissionBps")
  final int commissionBps;
}

@JsonSerializable(createToJson: false)
class ChainflipStatusFillOrKillParams {
  const ChainflipStatusFillOrKillParams({
    required this.retryDurationBlocks,
    required this.refundAddress,
    required this.minimumPrice,
  });

  factory ChainflipStatusFillOrKillParams.fromJson(Map<String, dynamic> json) =>
      _$ChainflipStatusFillOrKillParamsFromJson(json);

  @JsonKey(name: "retryDurationBlocks")
  final int retryDurationBlocks;
  @JsonKey(name: "refundAddress")
  final String refundAddress;

  // U256 fixed-point encoded price string, not a decimal number.
  @JsonKey(name: "minimumPrice")
  final String minimumPrice;
}

@JsonSerializable(createToJson: false)
class ChainflipStatusDcaParams {
  const ChainflipStatusDcaParams({required this.numberOfChunks, required this.chunkIntervalBlocks});

  factory ChainflipStatusDcaParams.fromJson(Map<String, dynamic> json) =>
      _$ChainflipStatusDcaParamsFromJson(json);

  @JsonKey(name: "numberOfChunks")
  final int numberOfChunks;
  @JsonKey(name: "chunkIntervalBlocks")
  final int chunkIntervalBlocks;
}

@JsonSerializable(createToJson: false)
class ChainflipStatusCcmParams {
  const ChainflipStatusCcmParams({
    required this.gasBudget,
    required this.message,
    this.cfParameters,
  });

  factory ChainflipStatusCcmParams.fromJson(Map<String, dynamic> json) =>
      _$ChainflipStatusCcmParamsFromJson(json);

  @JsonKey(name: "gasBudget")
  final String gasBudget;
  @JsonKey(name: "message")
  final String message;
  @JsonKey(name: "cfParameters")
  final String? cfParameters;
}

@JsonSerializable(createToJson: false)
@MillisDateTimeConverter()
class ChainflipStatusBoost {
  const ChainflipStatusBoost({
    required this.maximumBoostFeeBps,
    this.effectiveBoostFeeBps,
    this.boostedAt,
    this.boostedBlockIndex,
    this.skippedAt,
    this.skippedBlockIndex,
  });

  factory ChainflipStatusBoost.fromJson(Map<String, dynamic> json) =>
      _$ChainflipStatusBoostFromJson(json);

  @JsonKey(name: "maximumBoostFeeBps")
  final int maximumBoostFeeBps;
  @JsonKey(name: "effectiveBoostFeeBps")
  final int? effectiveBoostFeeBps;
  @JsonKey(name: "boostedAt")
  final DateTime? boostedAt;
  @JsonKey(name: "boostedBlockIndex")
  final String? boostedBlockIndex;
  @JsonKey(name: "skippedAt")
  final DateTime? skippedAt;
  @JsonKey(name: "skippedBlockIndex")
  final String? skippedBlockIndex;
}

@JsonSerializable(createToJson: false)
@MillisDateTimeConverter()
class ChainflipStatusDeposit {
  const ChainflipStatusDeposit({
    required this.amountNative,
    this.transactionReference,
    this.transactionConfirmations,
    this.witnessedAt,
    this.witnessedBlockIndex,
    this.failure,
    this.failedAt,
    this.failedBlockIndex,
  });

  factory ChainflipStatusDeposit.fromJson(Map<String, dynamic> json) =>
      _$ChainflipStatusDepositFromJson(json);

  @JsonKey(name: "amountNative")
  final BigInt amountNative;
  @JsonKey(name: "transactionReference")
  final String? transactionReference;
  @JsonKey(name: "transactionConfirmations")
  final int? transactionConfirmations;
  @JsonKey(name: "witnessedAt")
  final DateTime? witnessedAt;
  @JsonKey(name: "witnessedBlockIndex")
  final String? witnessedBlockIndex;
  @JsonKey(name: "failure")
  final ChainflipStatusFailure? failure;
  @JsonKey(name: "failedAt")
  final DateTime? failedAt;
  @JsonKey(name: "failedBlockIndex")
  final String? failedBlockIndex;
}

@JsonSerializable(createToJson: false)
@MillisDateTimeConverter()
class ChainflipStatusEgress {
  const ChainflipStatusEgress({
    required this.amountNative,
    this.scheduledAt,
    this.scheduledBlockIndex,
    this.transactionReference,
    this.witnessedAt,
    this.witnessedBlockIndex,
    this.failure,
    this.failedAt,
    this.failedBlockIndex,
  });

  factory ChainflipStatusEgress.fromJson(Map<String, dynamic> json) =>
      _$ChainflipStatusEgressFromJson(json);

  @JsonKey(name: "amountNative")
  final BigInt amountNative;
  @JsonKey(name: "scheduledAt")
  final DateTime? scheduledAt;
  @JsonKey(name: "scheduledBlockIndex")
  final String? scheduledBlockIndex;
  @JsonKey(name: "transactionReference")
  final String? transactionReference;
  @JsonKey(name: "witnessedAt")
  final DateTime? witnessedAt;
  @JsonKey(name: "witnessedBlockIndex")
  final String? witnessedBlockIndex;
  @JsonKey(name: "failure")
  final ChainflipStatusFailure? failure;
  @JsonKey(name: "failedAt")
  final DateTime? failedAt;
  @JsonKey(name: "failedBlockIndex")
  final String? failedBlockIndex;
}

@JsonSerializable(createToJson: false)
class ChainflipStatusSwap {
  const ChainflipStatusSwap({
    required this.originalInputAmountNative,
    required this.remainingInputAmountNative,
    required this.swappedInputAmountNative,
    required this.swappedIntermediateAmountNative,
    required this.swappedOutputAmountNative,
    this.regular,
    this.dca,
  });

  factory ChainflipStatusSwap.fromJson(Map<String, dynamic> json) =>
      _$ChainflipStatusSwapFromJson(json);

  @JsonKey(name: "originalInputAmountNative")
  final BigInt originalInputAmountNative;
  @JsonKey(name: "remainingInputAmountNative")
  final BigInt remainingInputAmountNative;
  @JsonKey(name: "swappedInputAmountNative")
  final BigInt swappedInputAmountNative;
  @JsonKey(name: "swappedIntermediateAmountNative")
  final BigInt swappedIntermediateAmountNative;
  @JsonKey(name: "swappedOutputAmountNative")
  final BigInt swappedOutputAmountNative;
  @JsonKey(name: "regular")
  final ChainflipStatusChunkInfo? regular;
  @JsonKey(name: "dca")
  final ChainflipStatusDca? dca;
}

@JsonSerializable(createToJson: false)
@MillisDateTimeConverter()
class ChainflipStatusDepositChannel {
  const ChainflipStatusDepositChannel({
    required this.id,
    required this.createdAt,
    required this.brokerCommissionBps,
    required this.depositAddress,
    required this.sourceChainExpiryBlock,
    required this.estimatedExpiryTime,
    required this.isExpired,
    required this.openedThroughBackend,
    this.expectedDepositAmountNative,
    this.affiliateBrokers,
    this.fillOrKillParams,
    this.dcaParams,
  });

  factory ChainflipStatusDepositChannel.fromJson(Map<String, dynamic> json) =>
      _$ChainflipStatusDepositChannelFromJson(json);

  @JsonKey(name: "id")
  final String id;
  @JsonKey(name: "createdAt")
  final DateTime createdAt;
  @JsonKey(name: "brokerCommissionBps")
  final int brokerCommissionBps;
  @JsonKey(name: "depositAddress")
  final String depositAddress;
  @JsonKey(name: "sourceChainExpiryBlock")
  final BigInt sourceChainExpiryBlock;
  @JsonKey(name: "estimatedExpiryTime")
  final DateTime estimatedExpiryTime;
  @JsonKey(name: "expectedDepositAmountNative")
  final BigInt? expectedDepositAmountNative;
  @JsonKey(name: "isExpired")
  final bool isExpired;
  @JsonKey(name: "openedThroughBackend")
  final bool openedThroughBackend;
  @JsonKey(name: "affiliateBrokers")
  final List<ChainflipStatusAffiliateBroker>? affiliateBrokers;
  @JsonKey(name: "fillOrKillParams")
  final ChainflipStatusFillOrKillParams? fillOrKillParams;
  @JsonKey(name: "dcaParams")
  final ChainflipStatusDcaParams? dcaParams;
}

@JsonSerializable(createToJson: false)
@ChainflipCurrencyConverter()
@ChainflipTradeStateConverter()
@MillisDateTimeConverter()
class ChainflipStatusData {
  const ChainflipStatusData({
    required this.state,
    required this.sourceAsset,
    required this.destinationAsset,
    required this.destinationAddress,
    this.swapId,
    this.depositChannel,
    this.ccmParams,
    this.boost,
    this.estimatedDurationSeconds,
    this.sourceChainRequiredBlockConfirmations,
    this.fees,
    this.deposit,
    this.swap,
    this.swapEgress,
    this.refundEgress,
    this.lastStateChainUpdateAt,
  });

  factory ChainflipStatusData.fromJson(Map<String, dynamic> json) =>
      _$ChainflipStatusDataFromJson(json);

  @JsonKey(name: "state")
  final TradeState state;
  @JsonKey(name: "swapId")
  final String? swapId;
  @JsonKey(name: "sourceAsset")
  final CryptoCurrency sourceAsset;
  @JsonKey(name: "destinationAsset")
  final CryptoCurrency destinationAsset;
  @JsonKey(name: "destinationAddress")
  final String destinationAddress;
  @JsonKey(name: "depositChannel")
  final ChainflipStatusDepositChannel? depositChannel;
  @JsonKey(name: "ccmParams")
  final ChainflipStatusCcmParams? ccmParams;
  @JsonKey(name: "boost")
  final ChainflipStatusBoost? boost;
  @JsonKey(name: "estimatedDurationSeconds")
  final double? estimatedDurationSeconds;
  @JsonKey(name: "sourceChainRequiredBlockConfirmations")
  final int? sourceChainRequiredBlockConfirmations;
  @JsonKey(name: "fees")
  final List<ChainflipFeeData>? fees;
  @JsonKey(name: "deposit")
  final ChainflipStatusDeposit? deposit;
  @JsonKey(name: "swap")
  final ChainflipStatusSwap? swap;
  @JsonKey(name: "swapEgress")
  final ChainflipStatusEgress? swapEgress;
  @JsonKey(name: "refundEgress")
  final ChainflipStatusEgress? refundEgress;
  @JsonKey(name: "lastStateChainUpdateAt")
  final DateTime? lastStateChainUpdateAt;
}

@JsonSerializable(createToJson: false)
class ChainflipStatusResponse {
  const ChainflipStatusResponse({required this.status, this.id});

  factory ChainflipStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$ChainflipStatusResponseFromJson(json);

  @JsonKey(name: "id")
  final int? id;
  @JsonKey(name: "status")
  final ChainflipStatusData status;
}