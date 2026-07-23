import "package:cake_wallet/entities/exchange_api_mode.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/chainflip_exchange_provider.dart";
import "package:cake_wallet/exchange/provider/changenow_exchange_provider.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/provider/exolix_exchange_provider.dart";
import "package:cake_wallet/exchange/provider/jupiter_exchange_provider.dart";
import "package:cake_wallet/exchange/provider/letsexchange_exchange_provider.dart";
import "package:cake_wallet/exchange/provider/near_Intents_exchange_provider.dart";
import "package:cake_wallet/exchange/provider/stealth_ex_exchange_provider.dart";
import "package:cake_wallet/exchange/provider/swapsxyz_exchange_provider.dart";
import "package:cake_wallet/exchange/provider/swaptrade_exchange_provider.dart";
import "package:cake_wallet/exchange/provider/trocador_exchange_provider.dart";
import "package:cake_wallet/exchange/provider/xoswap_exchange_provider.dart";
import "package:cake_wallet/store/settings_store.dart";

class ExchangeProviderRegistry {
  ExchangeProviderRegistry({required SettingsStore settingsStore}) : _settingsStore = settingsStore;

  final SettingsStore _settingsStore;

  late final Map<ExchangeProviderDescription, ExchangeProvider> _providers = {
    ExchangeProviderDescription.changeNow: ChangeNowExchangeProvider(settingsStore: _settingsStore),
    ExchangeProviderDescription.chainflip: ChainflipExchangeProvider(),
    ExchangeProviderDescription.exolix: ExolixExchangeProvider(),
    ExchangeProviderDescription.swapTrade: SwapTradeExchangeProvider(),
    ExchangeProviderDescription.letsExchange: LetsExchangeExchangeProvider(),
    ExchangeProviderDescription.stealthEx: StealthExExchangeProvider(),
    ExchangeProviderDescription.xoSwap: XOSwapExchangeProvider(),
    ExchangeProviderDescription.swapsXyz: SwapsXyzExchangeProvider(),
    ExchangeProviderDescription.jupiter: JupiterExchangeProvider(),
    ExchangeProviderDescription.nearIntents: NearIntentsExchangeProvider(),
    ExchangeProviderDescription.trocador: TrocadorExchangeProvider(
      useTorOnly: _settingsStore.exchangeStatus == ExchangeApiMode.torOnly,
      providerStates: _settingsStore.trocadorProviderStates,
    ),
  };

  ExchangeProvider getProvider(ExchangeProviderDescription description) => _providers[description]!;

  List<ExchangeProviderDescription> get allProviders => _providers.keys.toList();
}
