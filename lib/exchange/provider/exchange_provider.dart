import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/limits.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";

abstract class ExchangeProvider {
  ExchangeProvider();

  String get title;

  ExchangeProviderDescription get description;

  bool get isAvailable;

  bool get isEnabled;

  bool get supportsFixedRate;

  bool get supportsOnionAddress => false;

  bool get supportsMemoOrDestinationTag => true;

  @override
  String toString() => title;

  Future<ExchangeLimits> fetchLimits(
      {required CryptoCurrency from, required CryptoCurrency to, required bool isFixedRateMode,});

  Future<Trade> createTrade(
      {required TradeRequest request,});

  Future<Trade> findTradeById({required String id});

  Future<ProviderRate> fetchRate({required Money from, required CryptoCurrency to, required bool isFixedRate});

  Future<bool> checkIsAvailable();
}
