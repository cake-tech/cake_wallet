import 'package:cake_wallet/entities/derivation_type_setting.dart';
import 'package:cake_wallet/entities/seed_type.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:mobx/mobx.dart';

part 'seed_settings_view_model.g.dart';

class SeedSettingsViewModel = SeedSettingsViewModelBase with _$SeedSettingsViewModel;

abstract class SeedSettingsViewModelBase with Store {
  SeedSettingsViewModelBase(this._appStore);

  @computed
  SeedType get moneroSeedType => _appStore.settingsStore.moneroSeedType;

  @action
  void setMoneroSeedType(SeedType seedType) => _appStore.settingsStore.moneroSeedType = seedType;

  @computed
  DerivationTypeSetting get bitcoinDerivationType => _appStore.settingsStore.bitcoinDerivationType;

  @action
  void setBitcoinDerivationType(DerivationTypeSetting derivationType) =>
      _appStore.settingsStore.bitcoinDerivationType = derivationType;

  final AppStore _appStore;
}
