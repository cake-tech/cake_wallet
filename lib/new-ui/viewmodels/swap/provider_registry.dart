import "dart:convert";

import "package:cake_wallet/entities/exchange_api_mode.dart";
import "package:cake_wallet/entities/preferences_key.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/chainflip/chainflip_exchange_provider.dart";
import "package:cake_wallet/exchange/provider/changenow/changenow_exchange_provider.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/provider/exolix/exolix_exchange_provider.dart";
import "package:cake_wallet/exchange/provider/flashnet/flashnet_exchange_provider.dart";
import "package:cake_wallet/exchange/provider/jupiter/jupiter_exchange_provider.dart";
import "package:cake_wallet/exchange/provider/letsexchange/letsexchange_exchange_provider.dart";
import "package:cake_wallet/exchange/provider/near_intents/near_Intents_exchange_provider.dart";
import "package:cake_wallet/exchange/provider/stealthex/stealth_ex_exchange_provider.dart";
import "package:cake_wallet/exchange/provider/swapsxyz/swapsxyz_exchange_provider.dart";
import "package:cake_wallet/exchange/provider/swaptrade/swaptrade_exchange_provider.dart";
import "package:cake_wallet/exchange/provider/trocador/trocador_exchange_provider.dart";
import "package:cake_wallet/exchange/provider/xoswap/xoswap_exchange_provider.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:shared_preferences/shared_preferences.dart";

class ExchangeProviderRegistry {
  ExchangeProviderRegistry(
      {required SharedPreferences sharedPreferences, required SettingsStore settingsStore})
      : _sharedPreferences = sharedPreferences,
        _settingsStore = settingsStore;

  final SettingsStore _settingsStore;
  final SharedPreferences _sharedPreferences;

  late final Map<ExchangeProviderDescription, ExchangeProvider> _providers = {
    ExchangeProviderDescription.changeNow: ChangeNowExchangeProvider(settingsStore: _settingsStore),
    ExchangeProviderDescription.chainflip: ChainflipExchangeProvider(),
    ExchangeProviderDescription.exolix: ExolixExchangeProvider(),
    ExchangeProviderDescription.swapTrade: SwapTradeExchangeProvider(),
    ExchangeProviderDescription.letsExchange: LetsExchangeExchangeProvider(),
    ExchangeProviderDescription.stealthEx: StealthExExchangeProvider(),
    ExchangeProviderDescription.xoSwap: XOSwapExchangeProvider(),
    ExchangeProviderDescription.swapsXyz: SwapsXyzExchangeProvider(settingsStore: _settingsStore),
    ExchangeProviderDescription.jupiter: JupiterExchangeProvider(),
    ExchangeProviderDescription.nearIntents: NearIntentsExchangeProvider(),
    ExchangeProviderDescription.trocador: TrocadorExchangeProvider(
      useTorOnly: _settingsStore.exchangeStatus == ExchangeApiMode.torOnly,
      providerStates: _settingsStore.trocadorProviderStates,
    ),
    ExchangeProviderDescription.flashnet: FlashnetExchangeProvider(),
  };

  ExchangeProvider getProvider(ExchangeProviderDescription description) => _providers[description]!;

  Future<void> updateProviders(List<ExchangeProviderDescription> newProviders) async {
      final providerSettings = json.decode(_sharedPreferences.getString(PreferencesKey.exchangeProvidersSelection) ?? "{}")
      as Map<String, dynamic>;

      for (final provider in allProviders) {
        providerSettings[provider.title] = newProviders.contains(provider);
      }

      await _sharedPreferences.setString(
        PreferencesKey.exchangeProvidersSelection,
        json.encode(providerSettings),
      );
    }

    List<ExchangeProviderDescription> get enabledProviders {
      final providerSettings = json.decode(_sharedPreferences.getString(PreferencesKey.exchangeProvidersSelection) ?? "{}")
      as Map<String, dynamic>;

      return _providers.keys.where((item)=>providerSettings[item.title] != false).toList();
    }


  List<ExchangeProviderDescription> get allProviders => _providers.keys.toList();
}
