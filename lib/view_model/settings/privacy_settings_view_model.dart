import 'package:cake_wallet/entities/auto_generate_subaddress_status.dart';
import 'package:cake_wallet/entities/exchange_api_mode.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';

part 'privacy_settings_view_model.g.dart';

class PrivacySettingsViewModel = PrivacySettingsViewModelBase with _$PrivacySettingsViewModel;

abstract class PrivacySettingsViewModelBase with Store {
  PrivacySettingsViewModelBase(this._settingsStore, this._wallet);

  final SettingsStore _settingsStore;
  final WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> _wallet;

  @computed
  ExchangeApiMode get exchangeStatus => _settingsStore.exchangeStatus;

  @computed
  bool get isAutoGenerateSubaddressesEnabled =>
      _settingsStore.autoGenerateSubaddressStatus != AutoGenerateSubaddressStatus.disabled;

  @action
  void setAutoGenerateSubaddresses(bool value) {
    _wallet.isEnabledAutoGenerateSubaddress = value;
    if (value) {
      _settingsStore.autoGenerateSubaddressStatus = AutoGenerateSubaddressStatus.enabled;
    } else {
      _settingsStore.autoGenerateSubaddressStatus = AutoGenerateSubaddressStatus.disabled;
    }
  }

  bool get isAutoGenerateSubaddressesVisible => _wallet.type == WalletType.monero;

  @computed
  bool get shouldSaveRecipientAddress => _settingsStore.shouldSaveRecipientAddress;

  @computed
  FiatApiMode get fiatApiMode => _settingsStore.fiatApiMode;

  @computed
  bool get isAppSecure => _settingsStore.isAppSecure;

  @computed
  bool get disableBuy => _settingsStore.disableBuy;

  @computed
  bool get disableSell => _settingsStore.disableSell;

  @computed
  bool get useEtherscan => _settingsStore.useEtherscan;

  bool get canUseEtherscan => _wallet.type == WalletType.ethereum;

  @action
  void setShouldSaveRecipientAddress(bool value) =>
      _settingsStore.shouldSaveRecipientAddress = value;

  @action
  void setExchangeApiMode(ExchangeApiMode value) => _settingsStore.exchangeStatus = value;

  @action
  void setFiatMode(FiatApiMode fiatApiMode) => _settingsStore.fiatApiMode = fiatApiMode;

  @action
  void setIsAppSecure(bool value) => _settingsStore.isAppSecure = value;

  @action
  void setDisableBuy(bool value) => _settingsStore.disableBuy = value;

  @action
  void setDisableSell(bool value) => _settingsStore.disableSell = value;

  @action
  void setUseEtherscan(bool value) {
    _settingsStore.useEtherscan = value;
    ethereum!.updateEtherscanUsageState(_wallet, value);
  }
}
