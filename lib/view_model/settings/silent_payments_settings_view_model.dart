import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:mobx/mobx.dart';

part 'silent_payments_settings_view_model.g.dart';

class SilentPaymentsSettingsViewModel = SilentPaymentsSettingsViewModelBase
    with _$SilentPaymentsSettingsViewModel;

abstract class SilentPaymentsSettingsViewModelBase with Store {
  SilentPaymentsSettingsViewModelBase(this._settingsStore, this._wallet);

  final SettingsStore _settingsStore;
  final WalletBase _wallet;

  @computed
  bool get silentPaymentsCardDisplay => _settingsStore.silentPaymentsCardDisplay;

  @computed
  bool get silentPaymentsAlwaysScan => _settingsStore.silentPaymentsAlwaysScan;

  @action
  void setSilentPaymentsCardDisplay(bool value) {
    _settingsStore.silentPaymentsCardDisplay = value;
  }

  @action
  void setSilentPaymentsAlwaysScan(bool value) {
    _settingsStore.silentPaymentsAlwaysScan = value;
    if (value) bitcoin!.setScanningActive(_wallet, true);
  }

  @action
  void registerSilentPaymentsKey(bool value) {
    _settingsStore.silentPaymentsKeyRegistered = value;
    bitcoin!.registerSilentPaymentsKey(_wallet, true);
  }
}
