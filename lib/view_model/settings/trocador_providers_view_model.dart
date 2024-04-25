import 'package:cake_wallet/exchange/provider/trocador_exchange_provider.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:mobx/mobx.dart';

part 'trocador_providers_view_model.g.dart';

class TrocadorProvidersViewModel = TrocadorProvidersViewModelBase with _$TrocadorProvidersViewModel;

abstract class TrocadorProvidersViewModelBase with Store {
  TrocadorProvidersViewModelBase(this._settingsStore) {
    fetchTrocadorPartners();
  }

  final SettingsStore _settingsStore;

  @observable
  ObservableFuture<Map<String, bool>>? fetchProvidersFuture;

  @computed
  bool get isLoading => fetchProvidersFuture?.status == FutureStatus.pending;

  @action
  Future<void> fetchTrocadorPartners() async {
    fetchProvidersFuture =
        ObservableFuture(TrocadorExchangeProvider().fetchProviders().then((providers) {
      var providerNames = providers.map((e) => e.name).toList();
      return _settingsStore
          .updateAllTrocadorProviderStates(providerNames)
          .then((_) => _settingsStore.trocadorProviderStates);
    }));
  }

  @computed
  Map<String, bool> get providerStates => _settingsStore.trocadorProviderStates;

  @action
  void toggleProviderState(String providerName) {
    final currentState = providerStates[providerName] ?? false;
    _settingsStore.setTrocadorProviderState(providerName, !currentState);
  }
}
