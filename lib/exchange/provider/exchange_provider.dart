import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/limits.dart";
import "package:cake_wallet/exchange/rate_request.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/pending_transaction.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/wallet_base.dart";

abstract class ExchangeProvider {
  ExchangeProvider({ProxyWrapper? proxyWrapper}) : proxyWrapper = proxyWrapper ?? ProxyWrapper();

  final ProxyWrapper proxyWrapper;

  ExchangeProviderDescription get description;

  String get title => description.title;

  bool get supportsFixedRate;

  bool get supportsOnionAddress => false;

  @override
  String toString() => title;

  Future<ExchangeLimits> fetchLimits(
      {required CryptoCurrency from, required CryptoCurrency to, required bool isFixedRateMode,});

  Future<Trade> createTrade(
      {required TradeRequest request,});

  Future<Trade> updateTrade(Trade trade);

  Future<ProviderRate> fetchRate(RateRequest request);
}

abstract class LimitsCacheExchangeProvider extends ExchangeProvider {
  LimitsCacheExchangeProvider({super.proxyWrapper});

  static const _limitsLifetime = Duration(minutes: 10);

  final Map<(CryptoCurrency, CryptoCurrency, bool), (ExchangeLimits, DateTime)> _limitsCache = {};

  @override
  Future<ExchangeLimits> fetchLimits({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode,
  });

  Future<ExchangeLimits> getLimits({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode,
  }) async {
    if (_limitsCache[(from, to, isFixedRateMode)] case (final limits, final fetchedAt)
        when DateTime.now().difference(fetchedAt) < _limitsLifetime) {
      return limits;
    }

    final limits = await fetchLimits(from: from, to: to, isFixedRateMode: isFixedRateMode);
    _limitsCache[(from, to, isFixedRateMode)] = (limits, DateTime.now());
    return limits;
  }
}

abstract interface class TransactionCreationExchangeProvider {
  Future<PendingTransaction?> createTransaction(WalletBase wallet, Trade trade);
}

abstract interface class TransactionRegistrationExchangeProvider {
  bool get supportsExternalSend;

  Future<Trade> registerTransaction(Trade trade, String txHash);
}