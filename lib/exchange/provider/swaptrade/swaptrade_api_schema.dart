// spec reference: https://github.com/Swaptrade/swaptrade.github.io/blob/main/openapi.yaml

import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/exchange/utils/provider_api.dart";
import "package:json_annotation/json_annotation.dart";

part "swaptrade_api_schema.g.dart";

// numbers are inconsistently typed - get-coins returns price as "565.95000000" for most coins
// but as 1 for USDT, and min/max as either int or double. note that an unsupported pair answers
// with success and a price of "NaN", which double.parse happily returns as NaN
class SwapTradeAmountConverter implements JsonConverter<double, Object> {
  const SwapTradeAmountConverter();

  @override
  double fromJson(Object json) {
    if (json is num) {
      return json.toDouble();
    }
    if (json is String) {
      return double.parse(json);
    }
    throw ArgumentError("unexpected SwapTrade amount: $json");
  }

  @override
  Object toJson(double value) => value;
}

// the networks of a coin arrive as one comma separated string of chains, e.g. "ETH,TRX,BSC"
class SwapTradeNetworkListConverter implements JsonConverter<List<String>, String?> {
  const SwapTradeNetworkListConverter();

  @override
  List<String> fromJson(String? json) => (json ?? "")
      .split(",")
      .map((network) => network.trim())
      .where((network) => network.isNotEmpty)
      .toList();

  @override
  String? toJson(List<String> value) => value.isEmpty ? null : value.join(",");
}

class SwapTradeStatusConverter implements JsonConverter<TradeState, String> {
  const SwapTradeStatusConverter();

  @override
  TradeState fromJson(String json) => switch (json) {
    "1" => TradeState.waitingPayment,
    "2" => TradeState.confirming,
    "3" || "13" => TradeState.processing,
    "4" || "5" => TradeState.exchanging,
    "6" || "7" => TradeState.sending,
    "8" => TradeState.completed,
    "9" => TradeState.expired,
    "10" => TradeState.underpaid,
    "11" => TradeState.pending,
    "12" => TradeState.refunded,
    _ => TradeState.deserialize(raw: json),
  };

  @override
  String toJson(TradeState state) => state.serialize();
}

@JsonSerializable(createToJson: false)
class SwapTradeError {
  const SwapTradeError({this.msg});

  factory SwapTradeError.fromJson(Map<String, dynamic> json) => _$SwapTradeErrorFromJson(json);

  @JsonKey(name: "msg")
  final String? msg;
}


@JsonSerializable(createToJson: false)
@SwapTradeAmountConverter()
class SwapTradeCoin {
  const SwapTradeCoin({
    required this.id,
    required this.name,
    this.network = const [],
    this.price,
    this.min,
    this.max,
    this.minIncoming,
    this.maxIncoming,
    this.minOutgoing,
    this.maxOutgoing,
    this.minOutgoingUsd,
    this.maxOutgoingUsd,
    this.fee,
    this.networkFee,
    this.memo,
    this.enabled,
    this.amountScale,
    this.erc,
  });

  factory SwapTradeCoin.fromJson(Map<String, dynamic> json) => _$SwapTradeCoinFromJson(json);

  @JsonKey(name: "id")
  final String id;
  @JsonKey(name: "name")
  final String name;

  @JsonKey(name: "network")
  @SwapTradeNetworkListConverter()
  final List<String> network;

  @JsonKey(name: "price")
  final double? price;
  @JsonKey(name: "min")
  final double? min;
  @JsonKey(name: "max")
  final double? max;
  @JsonKey(name: "min_incoming")
  final double? minIncoming;
  @JsonKey(name: "max_incoming")
  final double? maxIncoming;
  @JsonKey(name: "min_outgoing")
  final double? minOutgoing;
  @JsonKey(name: "max_outgoing")
  final double? maxOutgoing;
  @JsonKey(name: "min_outgoing_USD")
  final double? minOutgoingUsd;
  @JsonKey(name: "max_outgoing_USD")
  final double? maxOutgoingUsd;
  @JsonKey(name: "fee")
  final double? fee;
  @JsonKey(name: "network_fee")
  final double? networkFee;

  @JsonKey(name: "memo")
  final bool? memo;
  @JsonKey(name: "enabled")
  final bool? enabled;

  @JsonKey(name: "amount_scale")
  final int? amountScale;

  // seems undocumented, but we use it anyway?
  @JsonKey(name: "erc")
  final int? erc;
}

class SwapTradeCoinsRequest extends ApiRequest<SwapTradeCoinsResponse> {
  const SwapTradeCoinsRequest();

  @override
  String path() => "/api/swap/get-coins";

  @override
  Map<String, dynamic> toJson() => const {};

  @override
  SwapTradeCoinsResponse decode(Object json) =>
      SwapTradeCoinsResponse.fromJson(json as Map<String, dynamic>);
}

@JsonSerializable(createToJson: false)
class SwapTradeCoinsResponse {
  const SwapTradeCoinsResponse({required this.success, this.status, this.msg, this.data, this.errors});

  factory SwapTradeCoinsResponse.fromJson(Map<String, dynamic> json) =>
      _$SwapTradeCoinsResponseFromJson(json);

  @JsonKey(name: "success")
  final bool success;
  @JsonKey(name: "status")
  final int? status;
  @JsonKey(name: "msg")
  final String? msg;
  @JsonKey(name: "data")
  final List<SwapTradeCoin>? data;
  @JsonKey(name: "errors")
  final List<SwapTradeError>? errors;
}


@JsonSerializable()
class SwapTradeGetRateRequest {
  const SwapTradeGetRateRequest({
    required this.coinSend,
    required this.coinReceive,
    this.amount,
    this.ref,
  });

  @JsonKey(name: "coin_send")
  final String coinSend;
  @JsonKey(name: "coin_receive")
  final String coinReceive;

  // not in the spec, but we use it ig?
  @JsonKey(name: "amount", includeIfNull: false)
  final String? amount;

  @JsonKey(name: "ref", defaultValue: "cake")
  final String? ref;

  Map<String, dynamic> toJson() => _$SwapTradeGetRateRequestToJson(this);
}

@JsonSerializable()
class SwapTradeGetPriceRequest extends ApiRequest<SwapTradeRateResponse> {
  SwapTradeGetPriceRequest({required this.coinSend, required this.coinSendNetwork, required this.coinReceive, required this.coinReceiveNetwork, required this.amountSend, required this.markup})
    : super.post();


  @JsonKey(name: "coin_send")
  final String coinSend;
  @JsonKey(name: "coin_send_network")
  final String coinSendNetwork;
  @JsonKey(name: "coin_receive")
  final String coinReceive;
  @JsonKey(name: "coin_receive_network")
  final String coinReceiveNetwork;
  @JsonKey(name: "amount_send")
  final String amountSend;
  @JsonKey(name: "markup")
  final double markup;

  @override
  String path() => "/api/swap/get-price";

  @override
  Map<String, dynamic> toJson() => _$SwapTradeGetPriceRequestToJson(this);

  @override
  SwapTradeRateResponse decode(Object json) =>
      SwapTradeRateResponse.fromJson(json as Map<String, dynamic>);
}

@JsonSerializable(createToJson: false)
@SwapTradeAmountConverter()
class SwapTradeRate {
  const SwapTradeRate({required this.price, this.symbol});

  factory SwapTradeRate.fromJson(Map<String, dynamic> json) => _$SwapTradeRateFromJson(json);

  @JsonKey(name: "data")
  final double price;

  @JsonKey(name: "symbol")
  final String? symbol;
}

@JsonSerializable(createToJson: false)
class SwapTradeRateResponse {
  const SwapTradeRateResponse({required this.success, this.status, this.msg, this.data, this.errors});

  factory SwapTradeRateResponse.fromJson(Map<String, dynamic> json) =>
      _$SwapTradeRateResponseFromJson(json);

  @JsonKey(name: "success")
  final bool success;
  @JsonKey(name: "status")
  final int? status;
  @JsonKey(name: "msg")
  final String? msg;
  @JsonKey(name: "data")
  final SwapTradeRate? data;
  @JsonKey(name: "errors")
  final List<SwapTradeError>? errors;
}


@JsonSerializable()
class SwapTradeCreateOrderRequest extends ApiRequest<SwapTradeCreateOrderResponse> {
  const SwapTradeCreateOrderRequest({
    required this.coinSend,
    required this.coinSendNetwork,
    required this.coinReceive,
    required this.coinReceiveNetwork,
    required this.amountSend,
    required this.recipient,
    this.refundAddress,
    this.ref,
    this.markup,
  }) : super.post();

  @JsonKey(name: "coin_send")
  final String coinSend;
  @JsonKey(name: "coin_send_network")
  final String coinSendNetwork;
  @JsonKey(name: "coin_receive")
  final String coinReceive;
  @JsonKey(name: "coin_receive_network")
  final String coinReceiveNetwork;

  @JsonKey(name: "amount_send")
  final String amountSend;
  @JsonKey(name: "recipient")
  final String recipient;

  // not in the spec, the provider sends it
  @JsonKey(name: "refund_address", includeIfNull: false)
  final String? refundAddress;
  @JsonKey(name: "ref", includeIfNull: false)
  final String? ref;
  @JsonKey(name: "markup", includeIfNull: false)
  final double? markup;

  @override
  String path() => "/api/swap/create-order";

  @override
  Map<String, dynamic> toJson() => _$SwapTradeCreateOrderRequestToJson(this);

  @override
  SwapTradeCreateOrderResponse decode(Object json) =>
      SwapTradeCreateOrderResponse.fromJson(json as Map<String, dynamic>);
}

@JsonSerializable(createToJson: false)
@SwapTradeAmountConverter()
class SwapTradeCreatedOrder {
  const SwapTradeCreatedOrder({
    required this.orderId,
    required this.serverAddress,
    this.amountReceive,
  });

  factory SwapTradeCreatedOrder.fromJson(Map<String, dynamic> json) =>
      _$SwapTradeCreatedOrderFromJson(json);

  @JsonKey(name: "order_id")
  final String orderId;
  @JsonKey(name: "server_address")
  final String serverAddress;
  @JsonKey(name: "amount_receive")
  final double? amountReceive;
}

@JsonSerializable(createToJson: false)
class SwapTradeCreateOrderResponse {
  const SwapTradeCreateOrderResponse({
    required this.success,
    this.status,
    this.msg,
    this.data,
    this.errors,
  });

  factory SwapTradeCreateOrderResponse.fromJson(Map<String, dynamic> json) =>
      _$SwapTradeCreateOrderResponseFromJson(json);

  @JsonKey(name: "success")
  final bool success;
  @JsonKey(name: "status")
  final int? status;
  @JsonKey(name: "msg")
  final String? msg;
  @JsonKey(name: "data")
  final SwapTradeCreatedOrder? data;
  @JsonKey(name: "errors")
  final List<SwapTradeError>? errors;
}


@JsonSerializable()
class SwapTradeOrderRequest extends ApiRequest<SwapTradeOrderResponse> {
  const SwapTradeOrderRequest({required this.orderId}) : super.post();

  @JsonKey(name: "order_id")
  final String orderId;

  @override
  String path() => "/api/swap/order";

  @override
  Map<String, dynamic> toJson() => _$SwapTradeOrderRequestToJson(this);

  @override
  SwapTradeOrderResponse decode(Object json) =>
      SwapTradeOrderResponse.fromJson(json as Map<String, dynamic>);
}

@JsonSerializable(createToJson: false)
@SwapTradeAmountConverter()
@SwapTradeStatusConverter()
class SwapTradeOrder {
  const SwapTradeOrder({
    required this.orderId,
    required this.coinSend,
    required this.coinReceive,
    required this.status,
    required this.serverAddress,
    required this.recipient,
    this.amountSend,
    this.amountReceive,
    this.memo,
    this.createdAt,
    this.refundAddress,
    this.outgoingTx,
  });

  factory SwapTradeOrder.fromJson(Map<String, dynamic> json) => _$SwapTradeOrderFromJson(json);

  @JsonKey(name: "order_id")
  final String orderId;
  @JsonKey(name: "coin_send")
  final String coinSend;
  @JsonKey(name: "coin_receive")
  final String coinReceive;
  @JsonKey(name: "status")
  final TradeState status;

  @JsonKey(name: "server_address")
  final String serverAddress;

  @JsonKey(name: "recipient")
  final String recipient;
  @JsonKey(name: "amount_send")
  final double? amountSend;
  @JsonKey(name: "amount_receive")
  final double? amountReceive;

  @JsonKey(name: "memo")
  final String? memo;
  @JsonKey(name: "created_at")
  final DateTime? createdAt;

  @JsonKey(name: "refund_address")
  final String? refundAddress;
  @JsonKey(name: "outgoing_tx")
  final String? outgoingTx;
}

@JsonSerializable(createToJson: false)
class SwapTradeOrderResponse {
  const SwapTradeOrderResponse({required this.success, this.status, this.msg, this.data, this.errors});

  factory SwapTradeOrderResponse.fromJson(Map<String, dynamic> json) =>
      _$SwapTradeOrderResponseFromJson(json);

  @JsonKey(name: "success")
  final bool success;
  @JsonKey(name: "status")
  final int? status;
  @JsonKey(name: "msg")
  final String? msg;
  @JsonKey(name: "data")
  final SwapTradeOrder? data;
  @JsonKey(name: "errors")
  final List<SwapTradeError>? errors;
}
