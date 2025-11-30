import 'package:cake_wallet/entities/exchange_api_mode.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/entities/seed_phrase_length.dart';
import 'package:cake_wallet/entities/seed_type.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'advanced_privacy_settings_view_model.g.dart';

class AdvancedPrivacySettingsViewModel = AdvancedPrivacySettingsViewModelBase
    with _$AdvancedPrivacySettingsViewModel;

abstract class AdvancedPrivacySettingsViewModelBase with Store {
  AdvancedPrivacySettingsViewModelBase(this.type, this._settingsStore) : _addCustomNode = false;

  static const hasPassphraseOptionWalletTypes = [
    WalletType.bitcoin,
    WalletType.litecoin,
    WalletType.bitcoinCash,
    WalletType.ethereum,
    WalletType.polygon,
    WalletType.base,
    WalletType.arbitrum,
    WalletType.tron,
    WalletType.solana,
    WalletType.monero,
    WalletType.wownero,
    WalletType.zano,
    WalletType.dogecoin,
  ];

  @computed
  ExchangeApiMode get exchangeStatus => _settingsStore.exchangeStatus;

  @computed
  FiatApiMode get fiatApiMode => _settingsStore.fiatApiMode;

  @computed
  bool get disableBulletin => _settingsStore.disableBulletin;

  @observable
  bool _addCustomNode = false;

  final WalletType type;

  final SettingsStore _settingsStore;

  bool get _isGroupCreation => type == WalletType.none;

  @computed
  bool get hasSeedPhraseLengthOption {

    if (_isGroupCreation) return false; // group flow = BIP-39 only

    // convert to switch case so that it give a syntax error when adding a new wallet type
    // thus we don't forget about it
    switch (type) {
      case WalletType.ethereum:
      case WalletType.bitcoinCash:
      case WalletType.dogecoin:
      case WalletType.polygon:
      case WalletType.base:
      case WalletType.arbitrum:
      case WalletType.solana:
      case WalletType.tron:
        return true;

      case WalletType.bitcoin:
      case WalletType.litecoin:
        return _settingsStore.bitcoinSeedType == BitcoinSeedType.bip39;

      case WalletType.nano:
      case WalletType.banano:
        return _settingsStore.nanoSeedType == NanoSeedType.bip39;

      case WalletType.monero:
      case WalletType.wownero:
      case WalletType.none:
      case WalletType.haven:
      case WalletType.zano:
      case WalletType.decred:
        return false;
    }
  }

  bool get isMoneroSeedTypeOptionsEnabled => !_isGroupCreation && [
        WalletType.monero,
        WalletType.wownero,
      ].contains(type);

  bool get isBitcoinSeedTypeOptionsEnabled => !_isGroupCreation && [
        WalletType.bitcoin,
        WalletType.litecoin,
      ].contains(type);

  bool get isNanoSeedTypeOptionsEnabled => !_isGroupCreation && [WalletType.nano].contains(type);

  bool get hasPassphraseOption => _isGroupCreation || hasPassphraseOptionWalletTypes.contains(type);

  @computed
  bool get addCustomNode => _addCustomNode;

  @computed
  SeedPhraseLength get seedPhraseLength => _settingsStore.seedPhraseLength;

  @computed
  bool get isPolySeed =>
      _isGroupCreation
          ? false
          : _settingsStore.moneroSeedType == MoneroSeedType.polyseed;

  @action
  void setFiatApiMode(FiatApiMode fiatApiMode) => _settingsStore.fiatApiMode = fiatApiMode;

  @action
  void setExchangeApiMode(ExchangeApiMode value) => _settingsStore.exchangeStatus = value;

  @action
  void setDisableBulletin(bool value) => _settingsStore.disableBulletin = value;

  @action
  void toggleAddCustomNode() => _addCustomNode = !_addCustomNode;

  @action
  void setSeedPhraseLength(SeedPhraseLength length) => _settingsStore.seedPhraseLength = length;
}
