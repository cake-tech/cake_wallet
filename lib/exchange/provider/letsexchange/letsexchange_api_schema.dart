// spec reference: https://api-doc.letsexchange.io/api-reference/openapi.json

import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/exchange/utils/json_converters.dart";
import "package:json_annotation/json_annotation.dart";

part "letsexchange_api_schema.g.dart";

class SafeBoolConverter implements JsonConverter<bool, Object> {
  const SafeBoolConverter();

  @override
  bool fromJson(Object json) {
    // letsexchange api docs say isFloat is a boolean
    // the example response says isFloat: "true"
    // a curl test showed isFloat: 1
    // i ain't settling this
    if (json is bool) {
      return json;
    }
    if (json is int) {
      return json == 1;
    }
    if (json is String) {
      return json.toLowerCase() == "true";
    }
    return json != 0;
  }

  @override
  Object toJson(bool value) => value;
}

@JsonSerializable()
class LetsExchangeInfoRequest {
  const LetsExchangeInfoRequest({
    required this.from,
    required this.to,
    required this.amount,
    required this.affiliateId,
    this.networkFrom,
    this.networkTo,
    this.float,
    this.promocode,
    this.partnerUserIp,
  });

  @JsonKey(name: "from")
  final String from;
  @JsonKey(name: "to")
  final String to;
  @JsonKey(name: "network_from", includeIfNull: false)
  final String? networkFrom;
  @JsonKey(name: "network_to", includeIfNull: false)
  final String? networkTo;
  @JsonKey(name: "amount")
  final String amount;
  @JsonKey(name: "affiliate_id")
  final String affiliateId;
  @JsonKey(name: "float", includeIfNull: false)
  final bool? float;
  @JsonKey(name: "promocode", includeIfNull: false)
  final String? promocode;
  @JsonKey(name: "partner_user_ip", includeIfNull: false)
  final String? partnerUserIp;

  Map<String, dynamic> toJson() => _$LetsExchangeInfoRequestToJson(this);
}

@JsonSerializable(createToJson: false)
class LetsExchangeInfoResponse {
  const LetsExchangeInfoResponse({
    required this.minAmount,
    required this.maxAmount,
    required this.amount,
    this.fee,
    this.rate,
    this.profit,
    this.withdrawalFee,
    this.rateId,
    this.rateIdExpiredAt,
  });

  factory LetsExchangeInfoResponse.fromJson(Map<String, dynamic> json) =>
      _$LetsExchangeInfoResponseFromJson(json);

  @JsonKey(name: "min_amount")
  final String minAmount;
  @JsonKey(name: "max_amount")
  final String maxAmount;
  @JsonKey(name: "amount")
  final String amount;
  @JsonKey(name: "fee")
  final String? fee;
  @JsonKey(name: "rate")
  final String? rate;
  @JsonKey(name: "profit")
  final String? profit;
  @JsonKey(name: "withdrawal_fee")
  final String? withdrawalFee;
  @JsonKey(name: "rate_id")
  final String? rateId;
  @JsonKey(name: "rate_id_expired_at")
  final String? rateIdExpiredAt;
}

@JsonSerializable(createToJson: false)
class LetsExchangeAmlSignal {
  const LetsExchangeAmlSignal({
    required this.signal,
    required this.signalId,
    required this.signalPercent,
    required this.level,
  });

  factory LetsExchangeAmlSignal.fromJson(Map<String, dynamic> json) =>
      _$LetsExchangeAmlSignalFromJson(json);

  @JsonKey(name: "signal")
  final String signal;
  @JsonKey(name: "signalId")
  final int signalId;
  @JsonKey(name: "signalPercent")
  final double signalPercent;
  @JsonKey(name: "level")
  final int level;
}

@JsonSerializable()
class LetsExchangeCreateTransactionRequest {
  const LetsExchangeCreateTransactionRequest({
    required this.coinFrom,
    required this.coinTo,
    required this.withdrawal,
    required this.withdrawalExtraId,
    required this.affiliateId,
    required this.float,
    this.networkFrom,
    this.networkTo,
    this.depositAmount,
    this.withdrawalAmount,
    this.returnAddress,
    this.returnExtraId,
    this.rateId,
    this.promocode,
    this.email,
    this.partnerUserIp,
  });

  @JsonKey(name: "coin_from")
  final String coinFrom;
  @JsonKey(name: "coin_to")
  final String coinTo;
  @JsonKey(name: "network_from", includeIfNull: false)
  final String? networkFrom;
  @JsonKey(name: "network_to", includeIfNull: false)
  final String? networkTo;
  @JsonKey(name: "deposit_amount", includeIfNull: false)
  final String? depositAmount;
  @JsonKey(name: "withdrawal_amount", includeIfNull: false)
  final String? withdrawalAmount;
  @JsonKey(name: "withdrawal")
  final String withdrawal;
  @JsonKey(name: "withdrawal_extra_id")
  final String withdrawalExtraId;
  @JsonKey(name: "return", includeIfNull: false)
  final String? returnAddress;
  @JsonKey(name: "return_extra_id", includeIfNull: false)
  final String? returnExtraId;
  @JsonKey(name: "rate_id", includeIfNull: false)
  final String? rateId;
  @JsonKey(name: "affiliate_id")
  final String affiliateId;

  // true = floating rate, false = fixed.
  @JsonKey(name: "float")
  final bool float;
  @JsonKey(name: "promocode", includeIfNull: false)
  final String? promocode;
  @JsonKey(name: "email", includeIfNull: false)
  final String? email;
  @JsonKey(name: "partner_user_ip", includeIfNull: false)
  final String? partnerUserIp;

  Map<String, dynamic> toJson() => _$LetsExchangeCreateTransactionRequestToJson(this);
}

@JsonSerializable(createToJson: false)
@TradeStateConverter()
class LetsExchangeTransactionResponse {
  const LetsExchangeTransactionResponse({
    this.transactionId,
    this.status,
    this.coinFrom,
    this.coinTo,
    this.depositAmount,
    this.withdrawalAmount,
    this.deposit,
    this.withdrawal,
    this.coinFromName,
    this.coinFromNetwork,
    this.coinToName,
    this.coinToNetwork,
    this.realDepositAmount,
    this.realWithdrawalAmount,
    this.depositExtraId,
    this.withdrawalExtraId,
    this.rate,
    this.fee,
    this.hashIn,
    this.hashOut,
    this.returnAddress,
    this.returnHash,
    this.returnAmount,
    this.returnExtraId,
    this.isFloat,
    this.coinFromExplorerUrl,
    this.coinToExplorerUrl,
    this.needConfirmations,
    this.confirmations,
    this.executionTime,
    this.profit,
    this.amlErrorSignals,
    this.createdAt,
    this.expiredAt,
  });

  factory LetsExchangeTransactionResponse.fromJson(Map<String, dynamic> json) =>
      _$LetsExchangeTransactionResponseFromJson(json);

  @JsonKey(name: "transaction_id")
  final String? transactionId;
  @JsonKey(name: "status")
  final TradeState? status;
  @JsonKey(name: "coin_from")
  final String? coinFrom;
  @JsonKey(name: "coin_from_name")
  final String? coinFromName;
  @JsonKey(name: "coin_from_network")
  final String? coinFromNetwork;
  @JsonKey(name: "coin_to")
  final String? coinTo;
  @JsonKey(name: "coin_to_name")
  final String? coinToName;
  @JsonKey(name: "coin_to_network")
  final String? coinToNetwork;
  @JsonKey(name: "deposit_amount")
  final String? depositAmount;
  @JsonKey(name: "withdrawal_amount")
  final String? withdrawalAmount;
  @JsonKey(name: "real_deposit_amount")
  final String? realDepositAmount;
  @JsonKey(name: "real_withdrawal_amount")
  final String? realWithdrawalAmount;
  @JsonKey(name: "deposit")
  final String? deposit;
  @JsonKey(name: "deposit_extra_id")
  final String? depositExtraId;
  @JsonKey(name: "withdrawal")
  final String? withdrawal;
  @JsonKey(name: "withdrawal_extra_id")
  final String? withdrawalExtraId;
  @JsonKey(name: "rate")
  final String? rate;
  @JsonKey(name: "fee")
  final String? fee;
  @JsonKey(name: "hash_in")
  final String? hashIn;
  @JsonKey(name: "hash_out")
  final String? hashOut;
  @JsonKey(name: "return")
  final String? returnAddress;
  @JsonKey(name: "return_hash")
  final String? returnHash;
  @JsonKey(name: "return_amount")
  final String? returnAmount;
  @JsonKey(name: "return_extra_id")
  final String? returnExtraId;
  @JsonKey(name: "is_float")
  @SafeBoolConverter()
  final bool? isFloat;
  @JsonKey(name: "coin_from_explorer_url")
  final String? coinFromExplorerUrl;
  @JsonKey(name: "coin_to_explorer_url")
  final String? coinToExplorerUrl;
  @JsonKey(name: "need_confirmations")
  final int? needConfirmations;
  @JsonKey(name: "confirmations")
  final int? confirmations;
  @JsonKey(name: "execution_time")
  final double? executionTime;
  @JsonKey(name: "profit")
  final double? profit;
  @JsonKey(name: "aml_error_signals")
  final List<LetsExchangeAmlSignal>? amlErrorSignals;
  @JsonKey(name: "created_at")
  final DateTime? createdAt;
  @JsonKey(name: "expired_at")
  @SecondsDateTimeConverter()
  final DateTime? expiredAt;
}
