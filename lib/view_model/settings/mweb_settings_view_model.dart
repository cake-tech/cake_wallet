import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:mobx/mobx.dart';

part 'mweb_settings_view_model.g.dart';

class MwebSettingsViewModel = MwebSettingsViewModelBase with _$MwebSettingsViewModel;

abstract class MwebSettingsViewModelBase with Store {
  MwebSettingsViewModelBase(this._settingsStore, this._wallet);

  final SettingsStore _settingsStore;
  final WalletBase _wallet;

  @computed
  bool get mwebCardDisplay => _settingsStore.mwebCardDisplay;

  @computed
  bool get mwebAlwaysScan => _settingsStore.mwebAlwaysScan;

  @action
  void setMwebCardDisplay(bool value) {
    _settingsStore.mwebCardDisplay = value;
  }

  @action
  void setMwebAlwaysScan(bool value) {
    _settingsStore.mwebAlwaysScan = value;
    bitcoin!.setMwebEnabled(_wallet, value);
  }
}
