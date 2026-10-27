import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";

sealed class RateRequest {
  const RateRequest();

  CryptoCurrency get depositCurrency;

  CryptoCurrency get payoutCurrency;

  Money get amount;

  bool isSameQuery(RateRequest other) =>
      (this is FixedRateRequest) == (other is FixedRateRequest) &&
      depositCurrency == other.depositCurrency &&
      payoutCurrency == other.payoutCurrency;

  @override
  bool operator ==(Object other) =>
      other is RateRequest && isSameQuery(other) && amount == other.amount;

  @override
  int get hashCode => Object.hash(this is FixedRateRequest, depositCurrency, payoutCurrency, amount);

  Map<String, dynamic> toJson() => {
    "depositCurrency": depositCurrency.serialized,
    "payoutCurrency": payoutCurrency.serialized,
    "amount": amount.serialized,
    "isFixedRate": this is FixedRateRequest,
  };
}

final class FloatingRateRequest extends RateRequest {
  const FloatingRateRequest({required this.depositAmount, required this.payoutCurrency});

  final Money depositAmount;

  @override
  final CryptoCurrency payoutCurrency;

  @override
  CryptoCurrency get depositCurrency => depositAmount.currency as CryptoCurrency;

  @override
  Money get amount => depositAmount;
}

final class FixedRateRequest extends RateRequest {
  const FixedRateRequest({required this.depositCurrency, required this.payoutAmount});

  @override
  final CryptoCurrency depositCurrency;

  final Money payoutAmount;

  @override
  CryptoCurrency get payoutCurrency => payoutAmount.currency as CryptoCurrency;

  @override
  Money get amount => payoutAmount;
}
