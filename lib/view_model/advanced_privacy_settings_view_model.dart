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

  @computed
  ExchangeApiMode get exchangeStatus => _settingsStore.exchangeStatus;

  @computed
  FiatApiMode get fiatApiMode => _settingsStore.fiatApiMode;

  @observable
  bool _addCustomNode = false;

  final WalletType type;

  final SettingsStore _settingsStore;

  bool get hasSeedPhraseLengthOption {
    // convert to switch case so that it give a syntax error when adding a new wallet type
    // thus we don't forget about it
    switch (type) {
      case WalletType.ethereum:
      case WalletType.bitcoinCash:
      case WalletType.polygon:
      case WalletType.solana:
        return true;
      case WalletType.monero:
      case WalletType.none:
      case WalletType.bitcoin:
      case WalletType.litecoin:
      case WalletType.haven:
      case WalletType.nano:
      case WalletType.banano:
        return false;
    }
  }

  bool get hasSeedTypeOption => type == WalletType.monero;

  @computed
  bool get addCustomNode => _addCustomNode;

  @computed
  SeedPhraseLength get seedPhraseLength => _settingsStore.seedPhraseLength;

  @computed
  bool get isPolySeed => _settingsStore.moneroSeedType == SeedType.polyseed;

  @action
  void setFiatApiMode(FiatApiMode fiatApiMode) => _settingsStore.fiatApiMode = fiatApiMode;

  @action
  void setExchangeApiMode(ExchangeApiMode value) => _settingsStore.exchangeStatus = value;

  @action
  void toggleAddCustomNode() => _addCustomNode = !_addCustomNode;

  @action
  void setSeedPhraseLength(SeedPhraseLength length) => _settingsStore.seedPhraseLength = length;
}
