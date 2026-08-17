import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";

class FlashnetExchangeProvider extends ExchangeProvider
    implements TransactionRegistrationExchangeProvider {
  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  Future<Trade> createTrade({required TradeRequest request}) {
    // TODO: implement createTrade
    throw UnimplementedError();
  }

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.flashnet;

  @override
  Future<ExchangeLimits> fetchLimits({required CryptoCurrency from, required CryptoCurrency to, required bool isFixedRateMode}) {
    // TODO: implement fetchLimits
    throw UnimplementedError();
  }

  @override
  Future<ProviderRate> fetchRate({required Money from, required CryptoCurrency to, required bool isFixedRate}) {
    // TODO: implement fetchRate
    throw UnimplementedError();
  }

  @override
  Future<Trade> findTradeById({required String id}) {
    // TODO: implement findTradeById
    throw UnimplementedError();
  }

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  Future<void> registerTransaction(String txHash) {
    // TODO: implement registerTransaction
    throw UnimplementedError();
  }

  @override
  bool get supportsFixedRate => true;

  @override
  String get title => description.title;


}
