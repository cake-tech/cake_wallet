import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/silent_payments_scanning_view_model.dart';
import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';

part 'silent_payments_settings_view_model.g.dart';

class SilentPaymentsSettingsViewModel = SilentPaymentsSettingsViewModelBase
    with _$SilentPaymentsSettingsViewModel;

abstract class SilentPaymentsSettingsViewModelBase with Store {
  SilentPaymentsSettingsViewModelBase(
    this._settingsStore,
    this._scanningViewModel,
  );

  final SettingsStore _settingsStore;

  final SilentPaymentsScanningViewModel _scanningViewModel;

  @computed
  bool get silentPaymentsCardDisplay => _settingsStore.silentPaymentsCardDisplay;

  @computed
  bool get silentPaymentsAlwaysScan => _scanningViewModel.silentPaymentsAlwaysScan;

  @action
  void setSilentPaymentsCardDisplay(bool value) {
    _settingsStore.silentPaymentsCardDisplay = value;
  }

  @action
  Future<void> setSilentPaymentsAlwaysScan(bool value, BuildContext context) async {
    await _scanningViewModel.setSilentPaymentsAlwaysScan(value);

    if (value) _scanningViewModel.toggleSilentPaymentsScanning(context);
  }
}
