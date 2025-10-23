import 'package:cake_wallet/entities/seed_type.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/seed_settings_store.dart';
import 'package:mobx/mobx.dart';

part 'seed_settings_view_model.g.dart';

class SeedSettingsViewModel = SeedSettingsViewModelBase with _$SeedSettingsViewModel;

abstract class SeedSettingsViewModelBase with Store {
  SeedSettingsViewModelBase(this._appStore, this._seedSettingsStore);

  @computed
  MoneroSeedType get moneroSeedType => _appStore.settingsStore.moneroSeedType;

  @action
  void setMoneroSeedType(MoneroSeedType seedType) => _appStore.settingsStore.moneroSeedType = seedType;

  @computed
  BitcoinSeedType get bitcoinSeedType => _appStore.settingsStore.bitcoinSeedType;

  @action
  void setBitcoinSeedType(BitcoinSeedType derivationType) =>
      _appStore.settingsStore.bitcoinSeedType = derivationType;

  @computed
  NanoSeedType get nanoSeedType => _appStore.settingsStore.nanoSeedType;

  @action
  void setNanoSeedType(NanoSeedType derivationType) =>
      _appStore.settingsStore.nanoSeedType = derivationType;

  @computed
  ZanoSeedType get zanoSeedType => _appStore.settingsStore.zanoSeedType;

  @action
  void setZanoSeedType(ZanoSeedType derivationType) =>
      _appStore.settingsStore.zanoSeedType = derivationType;

  @computed
  String? get passphrase => this._seedSettingsStore.passphrase;

  @action
  void setPassphrase(String? passphrase) => this._seedSettingsStore.passphrase = passphrase;

  final AppStore _appStore;
  final SeedSettingsStore _seedSettingsStore;
}
