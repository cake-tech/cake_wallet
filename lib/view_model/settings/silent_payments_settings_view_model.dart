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
  bool get silentPaymentsAlwaysScan => bitcoin!.getIsAlwaysScanningSP(_wallet);

  @computed
  String get scanServer => _settingsStore.silentPaymentsScanServer;

  bool isValidScanServer(String value) =>
      value.trim().isEmpty || bitcoin!.isValidSilentPaymentsScanServer(value);

  // Blank restores Cake's default server. Applies from the next scan round.
  @action
  void setScanServer(String value) {
    _settingsStore.silentPaymentsScanServer = value.trim();
  }

  @action
  void setSilentPaymentsCardDisplay(bool value) {
    _settingsStore.silentPaymentsCardDisplay = value;
  }

  @action
  void setSilentPaymentsAlwaysScan(bool value) {
    bitcoin!.setIsAlwaysScanningSP(_wallet, value);
    bitcoin!.setScanningActive(_wallet, value);
  }

  // Continues scanning from wherever the wallet last left off.
  @action
  Future<void> resumeScanning() async {
    await bitcoin!.rescan(
      _wallet,
      height: _wallet.walletInfo.restoreHeight,
      historicalMode: false,
      ignoreExistingCoverage: false,
    );
  }
}
