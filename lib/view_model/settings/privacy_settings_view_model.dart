import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/entities/auto_generate_subaddress_status.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'privacy_settings_view_model.g.dart';

class PrivacySettingsViewModel = PrivacySettingsViewModelBase with _$PrivacySettingsViewModel;

abstract class PrivacySettingsViewModelBase with Store {
  PrivacySettingsViewModelBase(this._settingsStore, this._wallet);

  final SettingsStore _settingsStore;
  final WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> _wallet;

  @computed
  bool get isBitcoin => _wallet.type == WalletType.bitcoin;

  @computed
  bool get isLitecoin => _wallet.type == WalletType.litecoin;

  @computed
  bool get isAutoGenerateSubaddressesEnabled =>
      _settingsStore.autoGenerateSubaddressStatus != AutoGenerateSubaddressStatus.disabled;

  @action
  void setAutoGenerateSubaddresses(bool value) {
    _wallet.isEnabledAutoGenerateSubaddress = value;
    _settingsStore.autoGenerateSubaddressStatus =
        value ? AutoGenerateSubaddressStatus.enabled : AutoGenerateSubaddressStatus.disabled;
  }

  bool get isAutoGenerateSubaddressesVisible => [
        WalletType.monero,
        WalletType.wownero,
        WalletType.bitcoin,
        WalletType.litecoin,
        WalletType.bitcoinCash,
        WalletType.dogecoin,
        WalletType.decred
      ].contains(_wallet.type);

  @computed
  bool get shouldSaveRecipientAddress => _settingsStore.shouldSaveRecipientAddress;

  @computed
  bool get isAppSecure => _settingsStore.isAppSecure;

  @computed
  bool get disableTradeOption => _settingsStore.disableTradeOption;

  @computed
  bool get disableAutomaticExchangeStatusUpdates =>
      _settingsStore.disableAutomaticExchangeStatusUpdates;

  @computed
  bool get disableBulletin => _settingsStore.disableBulletin;

  @computed
  bool get lookupTwitter => _settingsStore.lookupsTwitter;

  @computed
  bool get lookupsZanoAlias => _settingsStore.lookupsZanoAlias;

  @computed
  bool get looksUpMastodon => _settingsStore.lookupsMastodon;

  @computed
  bool get looksUpYatService => _settingsStore.lookupsYatService;

  @computed
  bool get looksUpUnstoppableDomains => _settingsStore.lookupsUnstoppableDomains;

  @computed
  bool get looksUpOpenAlias => _settingsStore.lookupsOpenAlias;

  @computed
  bool get looksUpENS => _settingsStore.lookupsENS;

  @computed
  bool get looksUpWellKnown => _settingsStore.lookupsWellKnown;

  @computed
  bool get usePayjoin => _settingsStore.usePayjoin;

  @computed
  bool get canUsePayjoin => _wallet.type == WalletType.bitcoin && DeviceInfo.instance.isMobile;

  @action
  void setShouldSaveRecipientAddress(bool value) =>
      _settingsStore.shouldSaveRecipientAddress = value;

  @action
  void setIsAppSecure(bool value) => _settingsStore.isAppSecure = value;

  @action
  void setDisableTradeOption(bool value) => _settingsStore.disableTradeOption = value;

  @action
  void setDisableAutomaticExchangeStatusUpdates(bool value) =>
      _settingsStore.disableAutomaticExchangeStatusUpdates = value;

  @action
  void setDisableBulletin(bool value) => _settingsStore.disableBulletin = value;

  @action
  void setUseMempoolFeeAPI(bool value) => _settingsStore.useMempoolFeeAPI = value;

  @action
  void setUseBlinkProtection(bool value) => _settingsStore.useBlinkProtection = value;

  @action
  void setUsePayjoin(bool value) {
    _settingsStore.usePayjoin = value;
    bitcoin!.updatePayjoinState(_wallet, value);
  }
}
