import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/monero/monero.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/provider_registry.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/utils/exchange_provider_logger.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/print_verbose.dart";

class TradeCreator {
  const TradeCreator({
    required AppStore appStore,
    required ExchangeProviderRegistry registry,
  }) : _appStore = appStore,
       _registry = registry;

  final ExchangeProviderRegistry _registry;
  final AppStore _appStore;

  Future<Trade?> createTrade(List<ProviderRate> rates, TradeRequest req) async {
    for (final rate in rates) {
      final provider = _registry.getProvider(rate.provider);

      try {
        final trade = await provider.createTrade(request: req);
        ExchangeProviderLogger.logSuccess(
          provider: provider.description,
          function: "createTrade",
          requestData: {"req": req},
        );
        return trade;
      } catch (e, st) {
        ExchangeProviderLogger.logError(
          provider: provider.description,
          error: e,
          stackTrace: st,
          function: "createTrade",
          requestData: {"req": req},
        );
        printV("failed to create trade at ${provider.description.title}: $e");
      }
    }

    return null;
  }

  Future<void> persistTrade(Trade trade) => trade
      .copyWith(walletId: _appStore.wallet!.id, accountIndex: _accountIndexFor(trade))
      .save();

  int _accountIndexFor(Trade trade) => switch (_appStore.wallet!.type) {
    _ when trade.depositCurrency == CryptoCurrency.btcln => 0,
    .monero => monero!.getCurrentAccount(_appStore.wallet!).id,
    .bitcoin => _appStore.wallet!.walletInfo.currentAccountIndex,
    _ => 0,
  };
}
