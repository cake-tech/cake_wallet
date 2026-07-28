// spec reference: https://dev.thorchain.org
// thornode: https://gitlab.com/thorchain/thornode/-/raw/develop/openapi/openapi.yaml
// midgard: https://gitlab.com/thorchain/midgard/-/raw/develop/openapi/openapi.yaml

import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/exchange/utils/json_converters.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:json_annotation/json_annotation.dart";

part "thorchain_api_schema.g.dart";

class ThorChainCurrencyConverter implements JsonConverter<CryptoCurrency, String> {
  const ThorChainCurrencyConverter();

  @override
  String toJson(CryptoCurrency currency) => "${currency.tag ?? currency.title}.${currency.title}";

  @override
  CryptoCurrency fromJson(String json) {
    final parts = json.split(".");
    if (parts.length != 2) {
      throw ArgumentError("bad currency input, should be chain.symbol");
    }
    final chain = parts.first;
    // drop the contract address suffix
    final symbol = parts.last.split("-").first;
    if (chain == symbol) {
      return CryptoCurrency.fromString(symbol);
    }
    final chainCurrency = CryptoCurrency.safeParseCurrencyFromString(chain);
    final currency = CryptoCurrency.safeParseCurrencyFromString(
      symbol,
      walletCurrency: chainCurrency,
    );
    if (currency == null) {
      throw ArgumentError("unknown asset: $json");
    }
    return currency;
  }
}

// thorchain internally uses integers of 1e8 (no matter how many decimals the chain supports)
class ThorChainAmount {
  const ThorChainAmount(this.baseUnits);

  factory ThorChainAmount.fromString(String value) => ThorChainAmount(BigInt.parse(value));

  factory ThorChainAmount.fromDouble(double value) =>
      ThorChainAmount(BigInt.from(value * _oneUnit));

  factory ThorChainAmount.fromMoney(Money value) => ThorChainAmount.fromDouble(value.toDouble());

  static const _oneUnit = 1e8;
  static final _oneUnitAsBigInt = BigInt.from(_oneUnit);

  final BigInt baseUnits;

  double toDouble() => baseUnits / _oneUnitAsBigInt;

  @override
  String toString() => baseUnits.toString();
}

class ThorChainAmountConverter implements JsonConverter<ThorChainAmount, String> {
  const ThorChainAmountConverter();

  @override
  ThorChainAmount fromJson(String json) => ThorChainAmount.fromString(json);

  @override
  String toJson(ThorChainAmount amount) => amount.toString();
}

@JsonSerializable()
@ThorChainCurrencyConverter()
@ThorChainAmountConverter()
class ThorChainQuoteSwapRequest {
  const ThorChainQuoteSwapRequest({
    required this.fromAsset,
    required this.toAsset,
    required this.amount,
    this.destination,
    this.refundAddress,
    this.affiliate,
    this.affiliateBps,
  });

  @JsonKey(name: "from_asset")
  final CryptoCurrency fromAsset;
  @JsonKey(name: "to_asset")
  final CryptoCurrency toAsset;
  @JsonKey(name: "amount")
  final ThorChainAmount amount;
  @JsonKey(name: "destination", includeIfNull: false)
  final String? destination;
  @JsonKey(name: "refund_address", includeIfNull: false)
  final String? refundAddress;
  @JsonKey(name: "affiliate", includeIfNull: false)
  final String? affiliate;
  @JsonKey(name: "affiliate_bps", includeIfNull: false)
  final String? affiliateBps;

  Map<String, dynamic> toJson() => _$ThorChainQuoteSwapRequestToJson(this);
}

@JsonSerializable(createToJson: false)
@ThorChainCurrencyConverter()
@ThorChainAmountConverter()
class ThorChainQuoteFees {
  const ThorChainQuoteFees({
    required this.asset,
    required this.liquidity,
    required this.total,
    required this.slippageBps,
    required this.totalBps,
    this.affiliate,
    this.outbound,
  });

  factory ThorChainQuoteFees.fromJson(Map<String, dynamic> json) =>
      _$ThorChainQuoteFeesFromJson(json);

  @JsonKey(name: "asset")
  final CryptoCurrency asset;
  @JsonKey(name: "liquidity")
  final ThorChainAmount liquidity;
  @JsonKey(name: "total")
  final ThorChainAmount total;
  @JsonKey(name: "affiliate")
  final ThorChainAmount? affiliate;
  @JsonKey(name: "outbound")
  final ThorChainAmount? outbound;
  @JsonKey(name: "slippage_bps")
  final int slippageBps;
  @JsonKey(name: "total_bps")
  final int totalBps;
}

@JsonSerializable(createToJson: false)
@ThorChainAmountConverter()
class ThorChainQuoteSwapResponse {
  const ThorChainQuoteSwapResponse({
    required this.expectedAmountOut,
    required this.outboundDelayBlocks,
    required this.outboundDelaySeconds,
    required this.fees,
    required this.warning,
    required this.notes,
    required this.expiry,
    this.memo,
    this.inboundAddress,
    this.inboundConfirmationBlocks,
    this.inboundConfirmationSeconds,
    this.router,
    this.dustThreshold,
    this.recommendedMinAmountIn,
    this.recommendedGasRate,
    this.gasRateUnits,
    this.maxStreamingQuantity,
    this.streamingSwapBlocks,
    this.streamingSwapSeconds,
    this.totalSwapSeconds,
  });

  factory ThorChainQuoteSwapResponse.fromJson(Map<String, dynamic> json) =>
      _$ThorChainQuoteSwapResponseFromJson(json);

  @JsonKey(name: "expected_amount_out")
  final ThorChainAmount expectedAmountOut;
  @JsonKey(name: "memo")
  final String? memo;
  @JsonKey(name: "inbound_address")
  final String? inboundAddress;
  @JsonKey(name: "inbound_confirmation_blocks")
  final int? inboundConfirmationBlocks;
  @JsonKey(name: "inbound_confirmation_seconds")
  final int? inboundConfirmationSeconds;
  @JsonKey(name: "outbound_delay_blocks")
  final int outboundDelayBlocks;
  @JsonKey(name: "outbound_delay_seconds")
  final int outboundDelaySeconds;
  @JsonKey(name: "fees")
  final ThorChainQuoteFees fees;
  @JsonKey(name: "router")
  final String? router;
  @JsonKey(name: "dust_threshold")
  final ThorChainAmount? dustThreshold;
  @JsonKey(name: "recommended_min_amount_in")
  final ThorChainAmount? recommendedMinAmountIn;
  @JsonKey(name: "recommended_gas_rate")
  final String? recommendedGasRate;
  @JsonKey(name: "gas_rate_units")
  final String? gasRateUnits;
  @JsonKey(name: "warning")
  final String warning;
  @JsonKey(name: "notes")
  final String notes;
  @JsonKey(name: "expiry")
  @SecondsDateTimeConverter()
  final DateTime expiry;
  @JsonKey(name: "max_streaming_quantity")
  final int? maxStreamingQuantity;
  @JsonKey(name: "streaming_swap_blocks")
  final int? streamingSwapBlocks;
  @JsonKey(name: "streaming_swap_seconds")
  final int? streamingSwapSeconds;

  @JsonKey(name: "total_swap_seconds")
  final int? totalSwapSeconds;
}



@JsonSerializable(createToJson: false)
@ThorChainCurrencyConverter()
@ThorChainAmountConverter()
class ThorChainCoin {
  const ThorChainCoin({required this.asset, required this.amount, this.decimals});

  factory ThorChainCoin.fromJson(Map<String, dynamic> json) => _$ThorChainCoinFromJson(json);

  @JsonKey(name: "asset")
  final CryptoCurrency asset;

  @JsonKey(name: "amount")
  final ThorChainAmount amount;
  @JsonKey(name: "decimals")
  final int? decimals;
}

@JsonSerializable(createToJson: false)
class ThorChainTx {
  const ThorChainTx({
    required this.coins,
    required this.gas,
    this.id,
    this.chain,
    this.fromAddress,
    this.toAddress,
    this.memo,
  });

  factory ThorChainTx.fromJson(Map<String, dynamic> json) => _$ThorChainTxFromJson(json);

  @JsonKey(name: "id")
  final String? id;
  @JsonKey(name: "chain")
  final String? chain;
  @JsonKey(name: "from_address")
  final String? fromAddress;
  @JsonKey(name: "to_address")
  final String? toAddress;
  @JsonKey(name: "coins")
  final List<ThorChainCoin> coins;
  @JsonKey(name: "gas")
  final List<ThorChainCoin> gas;

  @JsonKey(name: "memo")
  final String? memo;
}

@JsonSerializable(createToJson: false)
class ThorChainPlannedOutTx {
  const ThorChainPlannedOutTx({
    required this.chain,
    required this.toAddress,
    required this.coin,
    required this.refund,
  });

  factory ThorChainPlannedOutTx.fromJson(Map<String, dynamic> json) =>
      _$ThorChainPlannedOutTxFromJson(json);

  @JsonKey(name: "chain")
  final String chain;
  @JsonKey(name: "to_address")
  final String toAddress;
  @JsonKey(name: "coin")
  final ThorChainCoin coin;

  @JsonKey(name: "refund")
  final bool refund;
}

@JsonSerializable(createToJson: false)
class ThorChainInboundObservedStage {
  const ThorChainInboundObservedStage({
    required this.finalCount,
    required this.completed,
    this.started,
    this.preConfirmationCount,
  });

  factory ThorChainInboundObservedStage.fromJson(Map<String, dynamic> json) =>
      _$ThorChainInboundObservedStageFromJson(json);

  @JsonKey(name: "started")
  final bool? started;
  @JsonKey(name: "pre_confirmation_count")
  final int? preConfirmationCount;
  @JsonKey(name: "final_count")
  final int finalCount;
  @JsonKey(name: "completed")
  final bool completed;
}

@JsonSerializable(createToJson: false)
class ThorChainInboundConfirmationCountedStage {
  const ThorChainInboundConfirmationCountedStage({
    required this.completed,
    this.countingStartHeight,
    this.chain,
    this.externalObservedHeight,
    this.externalConfirmationDelayHeight,
    this.remainingConfirmationSeconds,
  });

  factory ThorChainInboundConfirmationCountedStage.fromJson(Map<String, dynamic> json) =>
      _$ThorChainInboundConfirmationCountedStageFromJson(json);

  @JsonKey(name: "counting_start_height")
  final int? countingStartHeight;
  @JsonKey(name: "chain")
  final String? chain;
  @JsonKey(name: "external_observed_height")
  final int? externalObservedHeight;
  @JsonKey(name: "external_confirmation_delay_height")
  final int? externalConfirmationDelayHeight;
  @JsonKey(name: "remaining_confirmation_seconds")
  final int? remainingConfirmationSeconds;
  @JsonKey(name: "completed")
  final bool completed;
}

@JsonSerializable(createToJson: false)
class ThorChainInboundFinalisedStage {
  const ThorChainInboundFinalisedStage({required this.completed});

  factory ThorChainInboundFinalisedStage.fromJson(Map<String, dynamic> json) =>
      _$ThorChainInboundFinalisedStageFromJson(json);

  @JsonKey(name: "completed")
  final bool completed;
}

@JsonSerializable(createToJson: false)
class ThorChainStreamingStatus {
  const ThorChainStreamingStatus({
    required this.interval,
    required this.quantity,
    required this.count,
  });

  factory ThorChainStreamingStatus.fromJson(Map<String, dynamic> json) =>
      _$ThorChainStreamingStatusFromJson(json);

  @JsonKey(name: "interval")
  final int interval;
  @JsonKey(name: "quantity")
  final int quantity;
  @JsonKey(name: "count")
  final int count;
}

@JsonSerializable(createToJson: false)
class ThorChainSwapStatus {
  const ThorChainSwapStatus({required this.pending, this.streaming});

  factory ThorChainSwapStatus.fromJson(Map<String, dynamic> json) =>
      _$ThorChainSwapStatusFromJson(json);

  @JsonKey(name: "pending")
  final bool pending;
  @JsonKey(name: "streaming")
  final ThorChainStreamingStatus? streaming;
}

@JsonSerializable(createToJson: false)
class ThorChainSwapFinalisedStage {
  const ThorChainSwapFinalisedStage({required this.completed});

  factory ThorChainSwapFinalisedStage.fromJson(Map<String, dynamic> json) =>
      _$ThorChainSwapFinalisedStageFromJson(json);

  @JsonKey(name: "completed")
  final bool completed;
}

@JsonSerializable(createToJson: false)
class ThorChainOutboundDelayStage {
  const ThorChainOutboundDelayStage({
    required this.completed,
    this.remainingDelayBlocks,
    this.remainingDelaySeconds,
  });

  factory ThorChainOutboundDelayStage.fromJson(Map<String, dynamic> json) =>
      _$ThorChainOutboundDelayStageFromJson(json);

  @JsonKey(name: "remaining_delay_blocks")
  final int? remainingDelayBlocks;
  @JsonKey(name: "remaining_delay_seconds")
  final int? remainingDelaySeconds;
  @JsonKey(name: "completed")
  final bool completed;
}

@JsonSerializable(createToJson: false)
class ThorChainOutboundSignedStage {
  const ThorChainOutboundSignedStage({
    required this.completed,
    this.scheduledOutboundHeight,
    this.blocksSinceScheduled,
  });

  factory ThorChainOutboundSignedStage.fromJson(Map<String, dynamic> json) =>
      _$ThorChainOutboundSignedStageFromJson(json);

  @JsonKey(name: "scheduled_outbound_height")
  final int? scheduledOutboundHeight;
  @JsonKey(name: "blocks_since_scheduled")
  final int? blocksSinceScheduled;

  @JsonKey(name: "completed")
  final bool completed;
}

@JsonSerializable(createToJson: false)
class ThorChainTxStages {
  const ThorChainTxStages({
    required this.inboundObserved,
    this.inboundConfirmationCounted,
    this.inboundFinalised,
    this.swapStatus,
    this.swapFinalised,
    this.outboundDelay,
    this.outboundSigned,
  });

  factory ThorChainTxStages.fromJson(Map<String, dynamic> json) =>
      _$ThorChainTxStagesFromJson(json);

  @JsonKey(name: "inbound_observed")
  final ThorChainInboundObservedStage inboundObserved;
  @JsonKey(name: "inbound_confirmation_counted")
  final ThorChainInboundConfirmationCountedStage? inboundConfirmationCounted;
  @JsonKey(name: "inbound_finalised")
  final ThorChainInboundFinalisedStage? inboundFinalised;
  @JsonKey(name: "swap_status")
  final ThorChainSwapStatus? swapStatus;
  @JsonKey(name: "swap_finalised")
  final ThorChainSwapFinalisedStage? swapFinalised;
  @JsonKey(name: "outbound_delay")
  final ThorChainOutboundDelayStage? outboundDelay;
  @JsonKey(name: "outbound_signed")
  final ThorChainOutboundSignedStage? outboundSigned;

  TradeState get state {
    if (inboundObserved.completed) {
      return TradeState.confirmation;
    }
    if (inboundConfirmationCounted?.completed ?? false) {
      return TradeState.confirmed;
    }
    if (inboundFinalised?.completed ?? false) {
      return TradeState.processing;
    }
    if (swapFinalised?.completed ?? false) {
      return TradeState.traded;
    }
    if (outboundSigned?.completed ?? false) {
      return TradeState.success;
    }

    return TradeState.notFound;
  }
}

@JsonSerializable(createToJson: false)
class ThorChainTxStatusResponse {
  const ThorChainTxStatusResponse({
    required this.stages,
    this.tx,
    this.plannedOutTxs,
    this.outTxs,
  });

  factory ThorChainTxStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$ThorChainTxStatusResponseFromJson(json);

  @JsonKey(name: "tx")
  final ThorChainTx? tx;
  @JsonKey(name: "planned_out_txs")
  final List<ThorChainPlannedOutTx>? plannedOutTxs;
  @JsonKey(name: "out_txs")
  final List<ThorChainTx>? outTxs;
  @JsonKey(name: "stages")
  final ThorChainTxStages stages;
}


@JsonSerializable(createToJson: false)
class ThorNameEntry {
  const ThorNameEntry({required this.chain, required this.address});

  factory ThorNameEntry.fromJson(Map<String, dynamic> json) => _$ThorNameEntryFromJson(json);

  @JsonKey(name: "chain")
  final String chain;
  @JsonKey(name: "address")
  final String address;
}

@JsonSerializable(createToJson: false)
class ThorNameDetails {
  const ThorNameDetails({required this.owner, required this.expire, required this.entries});

  factory ThorNameDetails.fromJson(Map<String, dynamic> json) => _$ThorNameDetailsFromJson(json);

  @JsonKey(name: "owner")
  final String owner;

  @JsonKey(name: "expire")
  final String expire;

  @JsonKey(name: "entries")
  final List<ThorNameEntry> entries;
}
