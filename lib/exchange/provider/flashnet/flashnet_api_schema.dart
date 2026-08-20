// spec reference: https://orchestration.flashnet.xyz/openapi.json
//
// covers /v1/orchestration/limits, /estimate, /quote, /submit and /status. every amount the API sends or
// takes is a decimal string in the asset's smallest unit (or in USD cents where the field says
// so), so they stay String here instead of being parsed into something lossy.
//
// asset codes stay String rather than becoming an enum: the supported list is long, churns with
// every listing, and the spec only pins it on requests anyway. the codes are case sensitive
// though, so build them with FlashnetExchangeProvider._normalizeCurrency instead of by hand

import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/exchange/utils/json_converters.dart";
import "package:json_annotation/json_annotation.dart";

part "flashnet_api_schema.g.dart";



/// chains the orchestrator routes between. shows up in responses too, so it needs an unknown
/// fallback for chains added server side after this was generated
enum FlashnetChain {
  @JsonValue("arbitrum")
  arbitrum,
  @JsonValue("avalanche")
  avalanche,
  @JsonValue("base")
  base,
  @JsonValue("bitcoin")
  bitcoin,
  @JsonValue("bsc")
  bsc,
  @JsonValue("ethereum")
  ethereum,
  @JsonValue("hedera")
  hedera,
  @JsonValue("hypercore")
  hypercore,
  @JsonValue("hyperevm")
  hyperevm,
  @JsonValue("lightning")
  lightning,
  @JsonValue("litecoin")
  litecoin,
  @JsonValue("monad")
  monad,
  @JsonValue("monero")
  monero,
  @JsonValue("optimism")
  optimism,
  @JsonValue("plasma")
  plasma,
  @JsonValue("polygon")
  polygon,
  @JsonValue("robinhood")
  robinhood,
  @JsonValue("sei")
  sei,
  @JsonValue("solana")
  solana,
  @JsonValue("spark")
  spark,
  @JsonValue("tempo")
  tempo,
  @JsonValue("ton")
  ton,
  @JsonValue("tron")
  tron,
  @JsonValue("xrp")
  xrp,
  @JsonValue("zcash")
  zcash,
  unknown,
}

/// which leg of the quote the amount pins. exact_out requires whole cents on stablecoin
/// destinations
enum FlashnetAmountMode {
  @JsonValue("exact_in")
  exactIn,
  @JsonValue("exact_out")
  exactOut,
  unknown,
}

/// fixed is opt in and only works on routes where the partner has an active fixed delivery
/// buffer. the quote response only ever echoes fixed back, never variable
enum FlashnetDeliveryMode {
  @JsonValue("variable")
  variable,
  @JsonValue("fixed")
  fixed,
  unknown,
}

/// what happens when the locked price moves before delivery
enum FlashnetPriceLockMode {
  @JsonValue("strict_requote")
  strictRequote,
  @JsonValue("approval_required")
  approvalRequired,
  unknown,
}

enum FlashnetOperationType {
  @JsonValue("order")
  order,
  unknown,
}

enum FlashnetRouteDirection {
  @JsonValue("buy")
  buy,
  @JsonValue("sell")
  sell,
  unknown,
}

/// which side of the route a limit constraint binds. route means it applies to the pair as a
/// whole rather than to one asset
enum FlashnetLimitLeg {
  @JsonValue("source")
  source,
  @JsonValue("destination")
  destination,
  @JsonValue("route")
  route,
  unknown,
}

/// the amount modes a constraint applies to
enum FlashnetConstraintAmountMode {
  @JsonValue("all")
  all,
  @JsonValue("exact_in")
  exactIn,
  @JsonValue("exact_out")
  exactOut,
  unknown,
}

/// where a limit came from, which decides how much to trust it - provider_quote limits only
/// materialise once a quote is priced
enum FlashnetLimitSource {
  @JsonValue("runtime_order_bounds")
  runtimeOrderBounds,
  @JsonValue("flashnet_static_limit")
  flashnetStaticLimit,
  @JsonValue("bitcoin_l1_delivery")
  bitcoinL1Delivery,
  @JsonValue("provider_quote")
  providerQuote,
  @JsonValue("fiat_amount")
  fiatAmount,
  unknown,
}



@JsonSerializable(createToJson: false)
class FlashnetErrorDetail {
  const FlashnetErrorDetail({required this.code, required this.message});

  factory FlashnetErrorDetail.fromJson(Map<String, dynamic> json) =>
      _$FlashnetErrorDetailFromJson(json);

  @JsonKey(name: "code")
  final String code;
  @JsonKey(name: "message")
  final String message;
}

/// every non-2xx on these four endpoints has this shape. `rate_limited` is worth special casing:
/// back off on the Retry-After header when present, otherwise on X-RateLimit-Reset, which is an
/// absolute epoch in milliseconds rather than a delta
@JsonSerializable(createToJson: false)
class FlashnetErrorResponse {
  const FlashnetErrorResponse({required this.error});

  factory FlashnetErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$FlashnetErrorResponseFromJson(json);

  @JsonKey(name: "error")
  final FlashnetErrorDetail error;
}



@JsonSerializable(createToJson: false)
class FlashnetAssetDetails {
  const FlashnetAssetDetails({
    required this.chain,
    required this.asset,
    required this.assetDisplayName,
    required this.assetDisplaySymbol,
    required this.decimals,
    required this.chainDisplayName,
    this.contractAddress,
    this.chainId,
    this.chainIcon,
  });

  factory FlashnetAssetDetails.fromJson(Map<String, dynamic> json) =>
      _$FlashnetAssetDetailsFromJson(json);

  @JsonKey(name: "chain", unknownEnumValue: FlashnetChain.unknown)
  final FlashnetChain chain;
  @JsonKey(name: "asset")
  final String asset;
  @JsonKey(name: "assetDisplayName")
  final String assetDisplayName;
  @JsonKey(name: "assetDisplaySymbol")
  final String assetDisplaySymbol;
  @JsonKey(name: "decimals")
  final int decimals;
  @JsonKey(name: "chainDisplayName")
  final String chainDisplayName;

  /// null for native assets
  @JsonKey(name: "contractAddress")
  final String? contractAddress;
  @JsonKey(name: "chainId")
  final String? chainId;
  @JsonKey(name: "chainIcon")
  final String? chainIcon;
}



/// query for GET /v1/orchestration/limits. leave every field off to get the whole route table -
/// this endpoint needs no auth but is rate limited per IP
@JsonSerializable(createFactory: false)
class FlashnetLimitsRequest {
  const FlashnetLimitsRequest({
    this.sourceChain,
    this.sourceAsset,
    this.destinationChain,
    this.destinationAsset,
  });

  @JsonKey(name: "sourceChain", includeIfNull: false)
  final FlashnetChain? sourceChain;
  /// case sensitive flashnet asset code, e.g. "BTC", "USDC.e", "cbBTC"
  @JsonKey(name: "sourceAsset", includeIfNull: false)
  final String? sourceAsset;
  @JsonKey(name: "destinationChain", includeIfNull: false)
  final FlashnetChain? destinationChain;
  @JsonKey(name: "destinationAsset", includeIfNull: false)
  final String? destinationAsset;

  Map<String, dynamic> toJson() => _$FlashnetLimitsRequestToJson(this);
}

/// the amount a quote request should carry for one amount mode, and the bounds on it. the
/// smallest unit bounds are null on routes only bounded in USD, in which case price the USD cent
/// bounds yourself
@JsonSerializable(createToJson: false)
class FlashnetLimitRequestAmount {
  const FlashnetLimitRequestAmount({
    required this.leg,
    required this.chain,
    required this.asset,
    required this.minUsdCents,
    required this.maxUsdCents,
    this.minAmountSmallest,
    this.maxAmountSmallest,
  });

  factory FlashnetLimitRequestAmount.fromJson(Map<String, dynamic> json) =>
      _$FlashnetLimitRequestAmountFromJson(json);

  @JsonKey(name: "leg", unknownEnumValue: FlashnetLimitLeg.unknown)
  final FlashnetLimitLeg leg;
  @JsonKey(name: "chain", unknownEnumValue: FlashnetChain.unknown)
  final FlashnetChain chain;
  @JsonKey(name: "asset")
  final String asset;

  @JsonKey(name: "minUsdCents")
  final String minUsdCents;
  @JsonKey(name: "maxUsdCents")
  final String maxUsdCents;

  @JsonKey(name: "minAmountSmallest")
  final String? minAmountSmallest;
  @JsonKey(name: "maxAmountSmallest")
  final String? maxAmountSmallest;
}

/// per amount mode support. requestAmount is null when supported is false, and constraints holds
/// the ids of the [FlashnetLimitConstraint]s that apply
@JsonSerializable(createToJson: false)
class FlashnetLimitMode {
  const FlashnetLimitMode({
    required this.supported,
    required this.constraints,
    this.requestAmount,
  });

  factory FlashnetLimitMode.fromJson(Map<String, dynamic> json) =>
      _$FlashnetLimitModeFromJson(json);

  @JsonKey(name: "supported")
  final bool supported;
  @JsonKey(name: "constraints")
  final List<String> constraints;

  @JsonKey(name: "requestAmount")
  final FlashnetLimitRequestAmount? requestAmount;
}

/// one entry of the flat constraint list, referenced by id from the per mode constraint lists
@JsonSerializable(createToJson: false)
class FlashnetLimitConstraint {
  const FlashnetLimitConstraint({
    required this.id,
    required this.amountMode,
    required this.leg,
    required this.source,
    required this.description,
    this.chain,
    this.asset,
    this.minAmountSmallest,
    this.maxAmountSmallest,
    this.minUsdCents,
    this.maxUsdCents,
  });

  factory FlashnetLimitConstraint.fromJson(Map<String, dynamic> json) =>
      _$FlashnetLimitConstraintFromJson(json);

  @JsonKey(name: "id")
  final String id;
  @JsonKey(name: "amountMode", unknownEnumValue: FlashnetConstraintAmountMode.unknown)
  final FlashnetConstraintAmountMode amountMode;
  @JsonKey(name: "leg", unknownEnumValue: FlashnetLimitLeg.unknown)
  final FlashnetLimitLeg leg;
  @JsonKey(name: "source", unknownEnumValue: FlashnetLimitSource.unknown)
  final FlashnetLimitSource source;
  @JsonKey(name: "description")
  final String description;

  /// null on route wide constraints
  @JsonKey(name: "chain", unknownEnumValue: FlashnetChain.unknown)
  final FlashnetChain? chain;
  @JsonKey(name: "asset")
  final String? asset;

  @JsonKey(name: "minAmountSmallest")
  final String? minAmountSmallest;
  @JsonKey(name: "maxAmountSmallest")
  final String? maxAmountSmallest;
  @JsonKey(name: "minUsdCents")
  final String? minUsdCents;
  @JsonKey(name: "maxUsdCents")
  final String? maxUsdCents;
}

/// USD notional bounds that apply to the route regardless of amount mode
@JsonSerializable(createToJson: false)
class FlashnetOrderNotionalUsdLimit {
  const FlashnetOrderNotionalUsdLimit({
    required this.minCents,
    required this.maxCents,
    required this.source,
  });

  factory FlashnetOrderNotionalUsdLimit.fromJson(Map<String, dynamic> json) =>
      _$FlashnetOrderNotionalUsdLimitFromJson(json);

  @JsonKey(name: "minCents")
  final String minCents;
  @JsonKey(name: "maxCents")
  final String maxCents;
  @JsonKey(name: "source", unknownEnumValue: FlashnetLimitSource.unknown)
  final FlashnetLimitSource source;
}

/// bounds for quoting by a USD figure instead of an asset amount. null on routes that do not
/// take a fiat amount at all
@JsonSerializable(createToJson: false)
class FlashnetFiatUsdLimit {
  const FlashnetFiatUsdLimit({
    required this.supported,
    required this.min,
    required this.max,
    required this.surfaces,
  });

  factory FlashnetFiatUsdLimit.fromJson(Map<String, dynamic> json) =>
      _$FlashnetFiatUsdLimitFromJson(json);

  @JsonKey(name: "supported")
  final bool supported;
  @JsonKey(name: "min")
  final String min;
  @JsonKey(name: "max")
  final String max;

  @JsonKey(name: "surfaces")
  final List<String> surfaces;
}

/// warns that the real bounds on this route are only known once a provider prices it, so the
/// static limits here can still be tightened at quote time
@JsonSerializable(createToJson: false)
class FlashnetDynamicProviderLimits {
  const FlashnetDynamicProviderLimits({
    required this.possible,
    required this.components,
    this.description,
  });

  factory FlashnetDynamicProviderLimits.fromJson(Map<String, dynamic> json) =>
      _$FlashnetDynamicProviderLimitsFromJson(json);

  @JsonKey(name: "possible")
  final bool possible;
  @JsonKey(name: "components")
  final List<String> components;
  @JsonKey(name: "description")
  final String? description;
}

@JsonSerializable(createToJson: false)
class FlashnetLimitRouteLimits {
  const FlashnetLimitRouteLimits({
    required this.orderNotionalUsd,
    required this.exactIn,
    required this.exactOut,
    required this.dynamicProviderLimits,
    required this.constraints,
    this.fiatUsd,
  });

  factory FlashnetLimitRouteLimits.fromJson(Map<String, dynamic> json) =>
      _$FlashnetLimitRouteLimitsFromJson(json);

  @JsonKey(name: "orderNotionalUsd")
  final FlashnetOrderNotionalUsdLimit orderNotionalUsd;
  @JsonKey(name: "exactIn")
  final FlashnetLimitMode exactIn;
  @JsonKey(name: "exactOut")
  final FlashnetLimitMode exactOut;
  @JsonKey(name: "dynamicProviderLimits")
  final FlashnetDynamicProviderLimits dynamicProviderLimits;
  @JsonKey(name: "constraints")
  final List<FlashnetLimitConstraint> constraints;

  @JsonKey(name: "fiatUsd")
  final FlashnetFiatUsdLimit? fiatUsd;
}

/// one supported pair plus its limits. the spec models this as RoutePair allOf the direction and
/// limits, flattened here into one class
@JsonSerializable(createToJson: false)
class FlashnetLimitRoute {
  const FlashnetLimitRoute({
    required this.sourceChain,
    required this.sourceAsset,
    required this.destinationChain,
    required this.destinationAsset,
    required this.exactOutEligible,
    required this.fixedEligible,
    required this.source,
    required this.destination,
    required this.direction,
    required this.limits,
  });

  factory FlashnetLimitRoute.fromJson(Map<String, dynamic> json) =>
      _$FlashnetLimitRouteFromJson(json);

  @JsonKey(name: "sourceChain", unknownEnumValue: FlashnetChain.unknown)
  final FlashnetChain sourceChain;
  /// case sensitive flashnet asset code, e.g. "BTC", "USDC.e", "cbBTC"
  @JsonKey(name: "sourceAsset")
  final String sourceAsset;
  @JsonKey(name: "destinationChain", unknownEnumValue: FlashnetChain.unknown)
  final FlashnetChain destinationChain;
  @JsonKey(name: "destinationAsset")
  final String destinationAsset;

  @JsonKey(name: "exactOutEligible")
  final bool exactOutEligible;
  @JsonKey(name: "fixedEligible")
  final bool fixedEligible;

  @JsonKey(name: "source")
  final FlashnetAssetDetails source;
  @JsonKey(name: "destination")
  final FlashnetAssetDetails destination;

  @JsonKey(name: "direction", unknownEnumValue: FlashnetRouteDirection.unknown)
  final FlashnetRouteDirection direction;
  @JsonKey(name: "limits")
  final FlashnetLimitRouteLimits limits;
}

@JsonSerializable(createToJson: false)
class FlashnetLimitsResponse {
  const FlashnetLimitsResponse({required this.generatedAt, required this.routes});

  factory FlashnetLimitsResponse.fromJson(Map<String, dynamic> json) =>
      _$FlashnetLimitsResponseFromJson(json);

  @JsonKey(name: "generatedAt")
  final DateTime generatedAt;

  /// empty when nothing matches the filter, which is how an unsupported pair reads
  @JsonKey(name: "routes")
  final List<FlashnetLimitRoute> routes;
}



/// one cost the destination chain imposes on delivery, on top of the flashnet fee - creating a
/// solana associated token account is the one seen in the wild. undocumented in the spec, so the
/// fields past type stay nullable and type and assumption stay String rather than becoming enums
/// on the strength of two observed values ("solana_associated_token_account", and
/// "assumed_missing" / "observed_exists")
@JsonSerializable(createToJson: false)
class FlashnetNetworkCost {
  const FlashnetNetworkCost({
    required this.type,
    this.amount,
    this.asset,
    this.nativeAmount,
    this.nativeAsset,
    this.assumption,
  });

  factory FlashnetNetworkCost.fromJson(Map<String, dynamic> json) =>
      _$FlashnetNetworkCostFromJson(json);

  @JsonKey(name: "type")
  final String type;

  /// what it costs denominated in the fee asset, which is what actually comes off the delivery
  @JsonKey(name: "amount")
  final String? amount;
  @JsonKey(name: "asset")
  final String? asset;

  /// and the same cost in the destination chain's native coin
  @JsonKey(name: "nativeAmount")
  final String? nativeAmount;
  @JsonKey(name: "nativeAsset")
  final String? nativeAsset;

  /// whether the cost was measured or guessed. it reads assumed_missing until the estimate is
  /// given a recipientAddress to check against, then flips to observed_exists and drops to zero
  /// where the account is already there
  @JsonKey(name: "assumption")
  final String? assumption;
}

/// query for GET /v1/orchestration/estimate. the cheap unauthenticated preview of a quote: same
/// pricing, no deposit address, nothing created, so nothing to expire. rate limited per IP for
/// unauthenticated callers only.
///
/// pass recipientAddress whenever it is known. without it the orchestrator has to assume the
/// destination account does not exist yet and prices the network cost of creating it into the
/// estimate, which understates the rate on a destination the user already holds
@JsonSerializable(createFactory: false)
class FlashnetEstimateRequest {
  const FlashnetEstimateRequest({
    required this.sourceChain,
    required this.sourceAsset,
    required this.destinationChain,
    required this.destinationAsset,
    required this.amount,
    this.amountMode,
    this.deliveryMode,
    this.recipientAddress,
    this.slippageBps,
  });

  @JsonKey(name: "sourceChain")
  final FlashnetChain sourceChain;

  /// case sensitive flashnet asset code, e.g. "BTC", "USDC.e", "cbBTC"
  @JsonKey(name: "sourceAsset")
  final String sourceAsset;
  @JsonKey(name: "destinationChain")
  final FlashnetChain destinationChain;
  @JsonKey(name: "destinationAsset")
  final String destinationAsset;

  /// smallest units, digits only. the destination amount under amountMode exact_out
  @JsonKey(name: "amount")
  final String amount;

  @JsonKey(name: "amountMode", includeIfNull: false)
  final FlashnetAmountMode? amountMode;
  @JsonKey(name: "deliveryMode", includeIfNull: false)
  final FlashnetDeliveryMode? deliveryMode;

  @JsonKey(name: "recipientAddress", includeIfNull: false)
  final String? recipientAddress;

  /// 0 to 1000 (10%)
  @JsonKey(name: "slippageBps", includeIfNull: false)
  final int? slippageBps;

  Map<String, dynamic> toJson() => _$FlashnetEstimateRequestToJson(this);
}

/// response of GET /v1/orchestration/estimate. the same priced shape a quote answers with, minus
/// everything to do with actually placing the order, plus the resolved source and destination
/// asset details.
///
/// the networkCost fields are absent from the spec but real in the responses, and they are not
/// part of totalFeeAmount's sibling fees - read them before treating estimatedOut as final
@JsonSerializable(createToJson: false)
class FlashnetEstimateResponse {
  const FlashnetEstimateResponse({
    required this.estimatedOut,
    required this.feeAmount,
    required this.feeBps,
    required this.feeAsset,
    required this.route,
    required this.source,
    required this.destination,
    this.amountMode,
    this.targetAmountOut,
    this.requiredAmountIn,
    this.maxAcceptedAmountIn,
    this.inputBufferBps,
    this.deliveryMode,
    this.roundingFeeAmount,
    this.totalFeeAmount,
    this.appFeeAmount,
    this.appFeePlatformCutAmount,
    this.appFees,
    this.feeAssetDetails,
    this.feeAmountUsd,
    this.totalFeeAmountUsd,
    this.networkCostAmount,
    this.networkCostAsset,
    this.networkCostRequired,
    this.networkCosts,
  });

  factory FlashnetEstimateResponse.fromJson(Map<String, dynamic> json) =>
      _$FlashnetEstimateResponseFromJson(json);

  /// destination asset smallest units. equals targetAmountOut on an exact_out estimate
  @JsonKey(name: "estimatedOut")
  final String estimatedOut;

  @JsonKey(name: "feeAmount")
  final String feeAmount;
  @JsonKey(name: "feeBps")
  final int feeBps;
  @JsonKey(name: "feeAsset")
  final String feeAsset;

  /// the legs the swap would route over. entries are bare asset codes on some routes and
  /// chain:asset on others, so this is for display, not for parsing
  @JsonKey(name: "route")
  final List<String> route;

  @JsonKey(name: "source")
  final FlashnetAssetDetails source;
  @JsonKey(name: "destination")
  final FlashnetAssetDetails destination;

  /// only echoed back on an exact_out estimate, along with the four fields below
  @JsonKey(name: "amountMode", unknownEnumValue: FlashnetAmountMode.unknown)
  final FlashnetAmountMode? amountMode;

  @JsonKey(name: "targetAmountOut")
  final String? targetAmountOut;
  @JsonKey(name: "requiredAmountIn")
  final String? requiredAmountIn;
  @JsonKey(name: "maxAcceptedAmountIn")
  final String? maxAcceptedAmountIn;
  @JsonKey(name: "inputBufferBps")
  final int? inputBufferBps;

  /// only ever fixed - a variable estimate leaves this off
  @JsonKey(name: "deliveryMode", unknownEnumValue: FlashnetDeliveryMode.unknown)
  final FlashnetDeliveryMode? deliveryMode;

  @JsonKey(name: "roundingFeeAmount")
  final String? roundingFeeAmount;
  @JsonKey(name: "totalFeeAmount")
  final String? totalFeeAmount;
  @JsonKey(name: "appFeeAmount")
  final String? appFeeAmount;
  @JsonKey(name: "appFeePlatformCutAmount")
  final String? appFeePlatformCutAmount;

  /// only comes back for callers whose key carries app fees
  @JsonKey(name: "appFees")
  final List<FlashnetAppFeeQuote>? appFees;

  @JsonKey(name: "feeAssetDetails")
  final FlashnetAssetDetails? feeAssetDetails;
  @JsonKey(name: "feeAmountUsd")
  final String? feeAmountUsd;
  @JsonKey(name: "totalFeeAmountUsd")
  final String? totalFeeAmountUsd;

  /// the networkCosts total, in the fee asset. absent entirely on routes that impose none
  @JsonKey(name: "networkCostAmount")
  final String? networkCostAmount;
  @JsonKey(name: "networkCostAsset")
  final String? networkCostAsset;
  @JsonKey(name: "networkCostRequired")
  final bool? networkCostRequired;
  @JsonKey(name: "networkCosts")
  final List<FlashnetNetworkCost>? networkCosts;
}



/// inline app fee, in bps of the swap. requires a full server key (`fn_`) - requests from a
/// public client key (`fnp_`) carrying this are rejected
@JsonSerializable(createFactory: false)
class FlashnetAppFeeRequest {
  const FlashnetAppFeeRequest({required this.recipient, required this.fee});

  @JsonKey(name: "recipient")
  final String recipient;

  /// 1 to 9999 bps
  @JsonKey(name: "fee")
  final int fee;

  Map<String, dynamic> toJson() => _$FlashnetAppFeeRequestToJson(this);
}

/// affiliateIds entry: either a bare registered affiliate id, which uses the profile's stored
/// feeBps, or an id plus a feeBps override that applies to this quote only
class FlashnetAffiliateIdEntry {
  const FlashnetAffiliateIdEntry.id(this.affiliateId) : feeBps = null;

  const FlashnetAffiliateIdEntry.withFeeBps({required this.affiliateId, required this.feeBps});

  final String affiliateId;

  /// 1 to 9999 bps. overriding needs a full server key (`fn_`); public client keys may only send
  /// the bare id form
  final int? feeBps;
}

class FlashnetAffiliateIdEntryConverter
    implements JsonConverter<FlashnetAffiliateIdEntry, Object> {
  const FlashnetAffiliateIdEntryConverter();

  @override
  FlashnetAffiliateIdEntry fromJson(Object json) {
    if (json is Map) {
      return FlashnetAffiliateIdEntry.withFeeBps(
        affiliateId: json["affiliateId"] as String,
        feeBps: json["feeBps"] as int,
      );
    }
    return FlashnetAffiliateIdEntry.id(json as String);
  }

  @override
  Object toJson(FlashnetAffiliateIdEntry value) => value.feeBps == null
      ? value.affiliateId
      : {"affiliateId": value.affiliateId, "feeBps": value.feeBps};
}

/// body for POST /v1/orchestration/quote. needs a bearer key and a unique X-Idempotency-Key
/// header - replaying the same key returns the same quote rather than pricing a new one
@JsonSerializable(createFactory: false)
class FlashnetQuoteRequest {
  const FlashnetQuoteRequest({
    required this.sourceChain,
    required this.sourceAsset,
    required this.destinationChain,
    required this.destinationAsset,
    required this.amount,
    required this.recipientAddress,
    this.amountMode,
    this.deliveryMode,
    this.refundChain,
    this.refundAddress,
    this.slippageBps,
    this.appFees,
    this.affiliateId,
    this.affiliateIds,
  });

  @JsonKey(name: "sourceChain")
  final FlashnetChain sourceChain;
  /// case sensitive flashnet asset code, e.g. "BTC", "USDC.e", "cbBTC"
  @JsonKey(name: "sourceAsset")
  final String sourceAsset;
  @JsonKey(name: "destinationChain")
  final FlashnetChain destinationChain;
  @JsonKey(name: "destinationAsset")
  final String destinationAsset;

  /// smallest units, digits only. with amountMode exact_out this is the destination amount and
  /// stablecoin destinations must land on whole cents
  @JsonKey(name: "amount")
  final String amount;

  /// for solana SPL payouts this is the token account owner, not the token account or ATA. for
  /// lightning, exact_in takes a 0 amount BOLT11 or a lightning address, exact_out also takes an
  /// exact whole sat BOLT11. BOLT12 is not supported yet
  @JsonKey(name: "recipientAddress")
  final String recipientAddress;

  @JsonKey(name: "amountMode", includeIfNull: false)
  final FlashnetAmountMode? amountMode;

  /// omit for the normal variable output quote
  @JsonKey(name: "deliveryMode", includeIfNull: false)
  final FlashnetDeliveryMode? deliveryMode;

  @JsonKey(name: "refundChain", includeIfNull: false)
  final FlashnetChain? refundChain;

  /// required for deposits from BNB, native TON, Tron, XRP, Litecoin and Zcash, and must be
  /// valid on the source chain. for lightning sources this may be a 0 amount BOLT11, a BOLT12 or
  /// a lightning address
  @JsonKey(name: "refundAddress", includeIfNull: false)
  final String? refundAddress;

  /// 0 to 1000 (10%). the AMM backed BTC/USDB route rejects anything under an operator floor,
  /// 10 bps by default; bridge and relay routes take anything in range
  @JsonKey(name: "slippageBps", includeIfNull: false)
  final int? slippageBps;

  /// 1 to 16 entries. mutually exclusive with affiliateIds
  @JsonKey(name: "appFees", includeIfNull: false)
  final List<FlashnetAppFeeRequest>? appFees;

  @JsonKey(name: "affiliateId", includeIfNull: false)
  final String? affiliateId;

  /// 1 to 16 entries, for ledger accrued fees. mutually exclusive with appFees
  @JsonKey(name: "affiliateIds", includeIfNull: false)
  @FlashnetAffiliateIdEntryConverter()
  final List<FlashnetAffiliateIdEntry>? affiliateIds;

  Map<String, dynamic> toJson() => _$FlashnetQuoteRequestToJson(this);
}

/// how one app fee resolved against the quote
@JsonSerializable(createToJson: false)
class FlashnetAppFeeQuote {
  const FlashnetAppFeeQuote({
    required this.recipient,
    required this.feeBps,
    required this.amount,
    required this.platformCutAmount,
    required this.recipientAmount,
    this.affiliateId,
  });

  factory FlashnetAppFeeQuote.fromJson(Map<String, dynamic> json) =>
      _$FlashnetAppFeeQuoteFromJson(json);

  @JsonKey(name: "recipient")
  final String recipient;
  @JsonKey(name: "feeBps")
  final int feeBps;

  @JsonKey(name: "amount")
  final String amount;
  @JsonKey(name: "platformCutAmount")
  final String platformCutAmount;
  @JsonKey(name: "recipientAmount")
  final String recipientAmount;

  /// only set for affiliate sourced fees
  @JsonKey(name: "affiliateId")
  final String? affiliateId;
}

/// response of POST /v1/orchestration/quote. send the deposit to depositAddress, then hand the
/// quoteId and the resulting tx to /submit before expiresAt
@JsonSerializable(createToJson: false)
class FlashnetQuoteResponse {
  const FlashnetQuoteResponse({
    required this.quoteId,
    required this.depositAddress,
    required this.amountIn,
    required this.estimatedOut,
    required this.feeAmount,
    required this.totalFeeAmount,
    required this.feeAsset,
    required this.feeBps,
    required this.route,
    required this.expiresAt,
    this.depositMemo,
    this.lightningReceiveRequestId,
    this.amountMode,
    this.targetAmountOut,
    this.requiredAmountIn,
    this.maxAcceptedAmountIn,
    this.inputBufferBps,
    this.deliveryMode,
    this.priceLockMode,
    this.lockedMinAmountOut,
    this.roundingFeeAmount,
    this.sweepFeeAmount,
    this.appFeeAmount,
    this.appFeePlatformCutAmount,
    this.appFees,
    this.feeAssetDetails,
    this.feeAmountUsd,
    this.totalFeeAmountUsd,
    this.readToken,
  });

  factory FlashnetQuoteResponse.fromJson(Map<String, dynamic> json) =>
      _$FlashnetQuoteResponseFromJson(json);

  @JsonKey(name: "quoteId")
  final String quoteId;
  @JsonKey(name: "depositAddress")
  final String depositAddress;

  /// memo or tag that has to ride along with the deposit. only set on provider routes that need
  /// one, and dropping it means the deposit is not credited
  @JsonKey(name: "depositMemo")
  final String? depositMemo;

  /// set for lightning sourced quotes, echoed back on submit
  @JsonKey(name: "lightningReceiveRequestId")
  final String? lightningReceiveRequestId;

  @JsonKey(name: "amountIn")
  final String amountIn;
  @JsonKey(name: "estimatedOut")
  final String estimatedOut;

  @JsonKey(name: "amountMode", unknownEnumValue: FlashnetAmountMode.unknown)
  final FlashnetAmountMode? amountMode;

  /// the exact_out fields: what the recipient gets, what has to be deposited to get it, and the
  /// ceiling the orchestrator will still accept
  @JsonKey(name: "targetAmountOut")
  final String? targetAmountOut;
  @JsonKey(name: "requiredAmountIn")
  final String? requiredAmountIn;
  @JsonKey(name: "maxAcceptedAmountIn")
  final String? maxAcceptedAmountIn;
  @JsonKey(name: "inputBufferBps")
  final int? inputBufferBps;

  /// only ever fixed - a variable quote leaves this off
  @JsonKey(name: "deliveryMode", unknownEnumValue: FlashnetDeliveryMode.unknown)
  final FlashnetDeliveryMode? deliveryMode;

  @JsonKey(name: "priceLockMode", unknownEnumValue: FlashnetPriceLockMode.unknown)
  final FlashnetPriceLockMode? priceLockMode;
  @JsonKey(name: "lockedMinAmountOut")
  final String? lockedMinAmountOut;

  @JsonKey(name: "feeAmount")
  final String feeAmount;
  @JsonKey(name: "totalFeeAmount")
  final String totalFeeAmount;
  @JsonKey(name: "feeBps")
  final int feeBps;
  @JsonKey(name: "feeAsset")
  final String feeAsset;

  @JsonKey(name: "roundingFeeAmount")
  final String? roundingFeeAmount;
  @JsonKey(name: "sweepFeeAmount")
  final String? sweepFeeAmount;
  @JsonKey(name: "appFeeAmount")
  final String? appFeeAmount;
  @JsonKey(name: "appFeePlatformCutAmount")
  final String? appFeePlatformCutAmount;
  @JsonKey(name: "appFees")
  final List<FlashnetAppFeeQuote>? appFees;

  @JsonKey(name: "feeAssetDetails")
  final FlashnetAssetDetails? feeAssetDetails;
  @JsonKey(name: "feeAmountUsd")
  final String? feeAmountUsd;
  @JsonKey(name: "totalFeeAmountUsd")
  final String? totalFeeAmountUsd;

  /// the legs the swap is routed over
  @JsonKey(name: "route")
  final List<String> route;
  @JsonKey(name: "expiresAt")
  final DateTime expiresAt;

  /// only returned to public client keys (`fnp_`). bound to this quoteId, and needed on status
  /// reads for the order this quote produces
  @JsonKey(name: "readToken")
  final String? readToken;
}



/// body for POST /v1/orchestration/submit. which of the tx reference fields are required depends
/// on the quote's source chain and deposit address type: on chain sources use txHash (plus
/// bitcoinTxid and bitcoinVout for bitcoin), spark sources use sparkTxHash, lightning sources use
/// lightningReceiveRequestId. needs a bearer key and an X-Idempotency-Key header - replaying the
/// same key returns the existing order instead of creating a second one
@JsonSerializable(createFactory: false)
class FlashnetSubmitRequest {
  const FlashnetSubmitRequest({
    required this.quoteId,
    this.txHash,
    this.sourceAddress,
    this.sparkTxHash,
    this.sourceSparkAddress,
    this.bitcoinTxid,
    this.bitcoinVout,
    this.lightningReceiveRequestId,
  });

  @JsonKey(name: "quoteId")
  final String quoteId;

  /// hedera takes either the native transaction id (0.0.x-seconds-nanos, any separator) or the
  /// EVM hash of an EthereumTransaction, but native transfers must go in by native id
  @JsonKey(name: "txHash", includeIfNull: false)
  final String? txHash;

  /// optional, but when the source chain can derive the sender itself a mismatch pauses the
  /// order for operator review
  @JsonKey(name: "sourceAddress", includeIfNull: false)
  final String? sourceAddress;

  @JsonKey(name: "sparkTxHash", includeIfNull: false)
  final String? sparkTxHash;
  @JsonKey(name: "sourceSparkAddress", includeIfNull: false)
  final String? sourceSparkAddress;

  @JsonKey(name: "bitcoinTxid", includeIfNull: false)
  final String? bitcoinTxid;
  @JsonKey(name: "bitcoinVout", includeIfNull: false)
  final int? bitcoinVout;

  @JsonKey(name: "lightningReceiveRequestId", includeIfNull: false)
  final String? lightningReceiveRequestId;

  Map<String, dynamic> toJson() => _$FlashnetSubmitRequestToJson(this);
}

@JsonSerializable(createToJson: false)
@TradeStateConverter()
class FlashnetSubmitResponse {
  const FlashnetSubmitResponse({required this.orderId, required this.status});

  factory FlashnetSubmitResponse.fromJson(Map<String, dynamic> json) =>
      _$FlashnetSubmitResponseFromJson(json);

  @JsonKey(name: "orderId")
  final String orderId;

  /// partner visible status. the spec leaves it open ended, so unrecognised values survive as a
  /// raw TradeState rather than being dropped
  @JsonKey(name: "status")
  final TradeState status;
}



/// query for GET /v1/orchestration/status. look the order up by id, by the quoteId it came from,
/// or by txHash plus the sourceChain it landed on. readToken is required for public client keys
/// (`fnp_`), which must also look up by id - it can go in the X-Read-Token header instead
@JsonSerializable(createFactory: false)
class FlashnetStatusRequest {
  const FlashnetStatusRequest({this.id, this.quoteId, this.txHash, this.sourceChain, this.readToken});

  @JsonKey(name: "id", includeIfNull: false)
  final String? id;
  @JsonKey(name: "quoteId", includeIfNull: false)
  final String? quoteId;
  @JsonKey(name: "txHash", includeIfNull: false)
  final String? txHash;
  @JsonKey(name: "sourceChain", includeIfNull: false)
  final FlashnetChain? sourceChain;

  @JsonKey(name: "readToken", includeIfNull: false)
  final String? readToken;

  Map<String, dynamic> toJson() => _$FlashnetStatusRequestToJson(this);
}

/// a milestone the order has already passed - the API only emits stages once completed
@JsonSerializable(createToJson: false)
class FlashnetOperationStage {
  const FlashnetOperationStage({
    required this.name,
    required this.status,
    required this.completedAt,
  });

  factory FlashnetOperationStage.fromJson(Map<String, dynamic> json) =>
      _$FlashnetOperationStageFromJson(json);

  @JsonKey(name: "name")
  final String name;

  /// always "completed"
  @JsonKey(name: "status")
  final String status;
  @JsonKey(name: "completedAt")
  final DateTime completedAt;
}

/// the order itself. the spec leaves swap, feePlan, priceLock and friends as untyped objects, so
/// they stay raw maps here
@JsonSerializable(createToJson: false)
@TradeStateConverter()
class FlashnetOperationRecord {
  const FlashnetOperationRecord({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.quoteId,
    this.sourceChain,
    this.sourceAsset,
    this.sourceAddress,
    this.sourceTxHash,
    this.sourceTxVout,
    this.sourceTxKey,
    this.sweepTxHash,
    this.destinationChain,
    this.destinationAsset,
    this.destinationAddress,
    this.destinationTxHash,
    this.depositAddress,
    this.recipientAddress,
    this.supersededByOperationId,
    this.recoveredFromOperationId,
    this.amountIn,
    this.amountOut,
    this.amountInUsd,
    this.amountOutUsd,
    this.amountFiatUsd,
    this.amountFiatCurrency,
    this.spotUsdPerBtc,
    this.feeBps,
    this.feeAmount,
    this.feeAsset,
    this.feeAssetDetails,
    this.feeAmountUsd,
    this.totalFeeBps,
    this.totalFeeAmount,
    this.totalFeeAmountUsd,
    this.roundingFeeAmount,
    this.slippageBps,
    this.flashnetRequestId,
    this.sparkTxHash,
    this.refundAsset,
    this.refundAmount,
    this.refundTxHash,
    this.errorCode,
    this.errorMessage,
    this.swap,
    this.ingressSwap,
    this.egressSwap,
    this.feePlan,
    this.feePayouts,
    this.priceLock,
    this.reprice,
    this.paymentIntent,
    this.zeroconfOffer,
    this.completedAt,
  });

  factory FlashnetOperationRecord.fromJson(Map<String, dynamic> json) =>
      _$FlashnetOperationRecordFromJson(json);

  @JsonKey(name: "id")
  final String id;
  @JsonKey(name: "type", unknownEnumValue: FlashnetOperationType.unknown)
  final FlashnetOperationType type;

  /// partner visible status. orders paused internally are reported as processing. the spec
  /// leaves it open ended, so unrecognised values survive as a raw TradeState
  @JsonKey(name: "status")
  final TradeState status;

  @JsonKey(name: "quoteId")
  final String? quoteId;

  @JsonKey(name: "sourceChain", unknownEnumValue: FlashnetChain.unknown)
  final FlashnetChain? sourceChain;
  @JsonKey(name: "sourceAsset")
  final String? sourceAsset;
  @JsonKey(name: "sourceAddress")
  final String? sourceAddress;
  @JsonKey(name: "sourceTxHash")
  final String? sourceTxHash;
  @JsonKey(name: "sourceTxVout")
  final int? sourceTxVout;
  @JsonKey(name: "sourceTxKey")
  final String? sourceTxKey;
  @JsonKey(name: "sweepTxHash")
  final String? sweepTxHash;

  @JsonKey(name: "destinationChain", unknownEnumValue: FlashnetChain.unknown)
  final FlashnetChain? destinationChain;
  @JsonKey(name: "destinationAsset")
  final String? destinationAsset;
  @JsonKey(name: "destinationAddress")
  final String? destinationAddress;
  @JsonKey(name: "destinationTxHash")
  final String? destinationTxHash;

  @JsonKey(name: "depositAddress")
  final String? depositAddress;
  @JsonKey(name: "recipientAddress")
  final String? recipientAddress;

  /// set when a later order recovered this one's deposit, e.g. an RBF replaced BTC deposit -
  /// follow it to the successor for the delivered result
  @JsonKey(name: "supersededByOperationId")
  final String? supersededByOperationId;

  /// the other side of that link, pointing back at the superseded order
  @JsonKey(name: "recoveredFromOperationId")
  final String? recoveredFromOperationId;

  @JsonKey(name: "amountIn")
  final String? amountIn;

  /// destination asset smallest units, null until the order completes. for bitcoin:BTC this is
  /// the on chain recipient amount after the Spark coop exit fee, and for lightning:BTC it is
  /// what was actually sent
  @JsonKey(name: "amountOut")
  final String? amountOut;

  /// decimal USD, only on completed orders where it is derivable
  @JsonKey(name: "amountInUsd")
  final String? amountInUsd;
  @JsonKey(name: "amountOutUsd")
  final String? amountOutUsd;

  /// only set when the order was created from a USD figure rather than an asset amount
  @JsonKey(name: "amountFiatUsd")
  final String? amountFiatUsd;

  /// always "USD" today
  @JsonKey(name: "amountFiatCurrency")
  final String? amountFiatCurrency;

  /// the BTC/USD spot used to turn amountFiatUsd into sats at order creation
  @JsonKey(name: "spotUsdPerBtc")
  final String? spotUsdPerBtc;

  @JsonKey(name: "feeBps")
  final int? feeBps;
  @JsonKey(name: "feeAmount")
  final String? feeAmount;
  @JsonKey(name: "feeAsset")
  final String? feeAsset;
  @JsonKey(name: "feeAssetDetails")
  final FlashnetAssetDetails? feeAssetDetails;
  @JsonKey(name: "feeAmountUsd")
  final String? feeAmountUsd;
  @JsonKey(name: "totalFeeBps")
  final int? totalFeeBps;
  @JsonKey(name: "totalFeeAmount")
  final String? totalFeeAmount;
  @JsonKey(name: "totalFeeAmountUsd")
  final String? totalFeeAmountUsd;
  @JsonKey(name: "roundingFeeAmount")
  final String? roundingFeeAmount;
  @JsonKey(name: "slippageBps")
  final int? slippageBps;

  @JsonKey(name: "flashnetRequestId")
  final String? flashnetRequestId;
  @JsonKey(name: "sparkTxHash")
  final String? sparkTxHash;

  @JsonKey(name: "refundAsset")
  final String? refundAsset;
  @JsonKey(name: "refundAmount")
  final String? refundAmount;
  @JsonKey(name: "refundTxHash")
  final String? refundTxHash;

  /// partner safe, so these are fine to show
  @JsonKey(name: "errorCode")
  final String? errorCode;
  @JsonKey(name: "errorMessage")
  final String? errorMessage;

  @JsonKey(name: "swap")
  final Map<String, dynamic>? swap;
  @JsonKey(name: "ingressSwap")
  final Map<String, dynamic>? ingressSwap;
  @JsonKey(name: "egressSwap")
  final Map<String, dynamic>? egressSwap;
  @JsonKey(name: "feePlan")
  final Map<String, dynamic>? feePlan;
  @JsonKey(name: "feePayouts")
  final Map<String, dynamic>? feePayouts;
  @JsonKey(name: "priceLock")
  final Map<String, dynamic>? priceLock;
  @JsonKey(name: "reprice")
  final Map<String, dynamic>? reprice;
  @JsonKey(name: "paymentIntent")
  final Map<String, dynamic>? paymentIntent;

  /// 0-conf outcome on bitcoin deposits. a live offer carries the full fields; with a valid read
  /// token a denied order carries a `{status: "denied", deniedAt}` stub, and without one the
  /// field is simply absent for denied orders. discriminate on status
  @JsonKey(name: "zeroconfOffer")
  final Map<String, dynamic>? zeroconfOffer;

  @JsonKey(name: "createdAt")
  final DateTime createdAt;
  @JsonKey(name: "updatedAt")
  final DateTime updatedAt;
  @JsonKey(name: "completedAt")
  final DateTime? completedAt;
}

@JsonSerializable(createToJson: false)
class FlashnetStatusResponse {
  const FlashnetStatusResponse({required this.order, required this.stages});

  factory FlashnetStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$FlashnetStatusResponseFromJson(json);

  @JsonKey(name: "order")
  final FlashnetOperationRecord order;
  @JsonKey(name: "stages")
  final List<FlashnetOperationStage> stages;
}
