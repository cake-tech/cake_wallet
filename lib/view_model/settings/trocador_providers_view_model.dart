import 'package:cake_wallet/store/settings_store.dart';
import 'package:mobx/mobx.dart';

part 'trocador_providers_view_model.g.dart';

class TrocadorProvidersViewModel = TrocadorProvidersViewModelBase with _$TrocadorProvidersViewModel;

abstract class TrocadorProvidersViewModelBase with Store {
  TrocadorProvidersViewModelBase(this._settingsStore);

  final SettingsStore _settingsStore;

  @computed
  Map<String, bool> get providerStates => _settingsStore.trocadorProviderStates;

  @action
  void toggleProviderState(String providerName) {
    final currentState = providerStates[providerName] ?? false;
    _settingsStore.saveTrocadorProviderState(providerName, !currentState);
  }
}