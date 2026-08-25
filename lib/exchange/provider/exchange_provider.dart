import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/limits.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/pending_transaction.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/wallet_base.dart";

abstract class ExchangeProvider {
  ExchangeProvider({ProxyWrapper? proxyWrapper}) : proxyWrapper = proxyWrapper ?? ProxyWrapper();

  final ProxyWrapper proxyWrapper;

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

  Future<Trade> updateTrade(Trade trade);

  Future<ProviderRate> fetchRate({required Money from, required CryptoCurrency to, required bool isFixedRate});

  Future<bool> checkIsAvailable();
}


abstract interface class TransactionCreationExchangeProvider {
  Future<PendingTransaction> createTransaction(WalletBase wallet, Trade trade);
}

abstract interface class TransactionCommitExchangeProvider {
  Future<void> commitTransaction(PendingTransaction tx);
}

abstract interface class TransactionRegistrationExchangeProvider {
  Future<Trade> registerTransaction(Trade trade, String txHash);
}