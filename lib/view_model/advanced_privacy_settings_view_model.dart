import 'package:cake_wallet/entities/exchange_api_mode.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/entities/seed_phrase_length.dart';
import 'package:cake_wallet/entities/seed_type.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'advanced_privacy_settings_view_model.g.dart';

class AdvancedPrivacySettingsViewModel = AdvancedPrivacySettingsViewModelBase
    with _$AdvancedPrivacySettingsViewModel;

abstract class AdvancedPrivacySettingsViewModelBase with Store {
  AdvancedPrivacySettingsViewModelBase(this.types, this._settingsStore) : _addCustomNode = false;

  final List<WalletType> types;

  final SettingsStore _settingsStore;

  bool get isMultiType => types.length > 1;

  WalletType? get singleType => types.length == 1 ? types.first : null;

  @computed
  ExchangeApiMode get exchangeStatus => _settingsStore.exchangeStatus;

  @computed
  FiatApiMode get fiatApiMode => _settingsStore.fiatApiMode;

  @computed
  bool get disableBulletin => _settingsStore.disableBulletin;

  @computed
  bool get useBlinkProtection => _settingsStore.useBlinkProtection;

  bool get canUseBlinkProtection {
    final type = singleType;
    if (type == null || !isEVMCompatibleChain(type)) return false;

    // Get the chainId from the wallet type
    final chainId = evm!.getChainIdByWalletType(type);

    return canSupportBlinkProtection(chainId);
  }

  @observable
  bool _addCustomNode = false;

  @computed
  bool get hasSeedPhraseLengthOption {
    final type = singleType;

    // Omnichain wallet is always BIP39-based, so seed phrase length option is always available.
    if (type == null) return true;

    switch (type) {
      case WalletType.ethereum:
      case WalletType.bitcoinCash:
      case WalletType.dogecoin:
      case WalletType.polygon:
      case WalletType.base:
      case WalletType.arbitrum:
      case WalletType.bsc:
      case WalletType.solana:
      case WalletType.tron:
      case WalletType.zcash:
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

 // Seed type options are only available for single-network wallet creation/restoration.
  bool get isMoneroSeedTypeOptionsEnabled =>
      !isMultiType && [WalletType.monero, WalletType.wownero].contains(singleType);

  bool get isBitcoinSeedTypeOptionsEnabled =>
      !isMultiType && [WalletType.bitcoin, WalletType.litecoin].contains(singleType);

  bool get isNanoSeedTypeOptionsEnabled => !isMultiType && singleType == WalletType.nano;

  bool get hasPassphraseOption {
    // Omnichain wallet is always BIP39-based, so passphrase option is always available.
    if (isMultiType) return true;

    return [
      WalletType.bitcoin,
      WalletType.litecoin,
      WalletType.bitcoinCash,
      WalletType.ethereum,
      WalletType.polygon,
      WalletType.base,
      WalletType.arbitrum,
      WalletType.bsc,
      WalletType.tron,
      WalletType.solana,
      WalletType.monero,
      WalletType.wownero,
      WalletType.zano,
      WalletType.dogecoin,
      WalletType.zcash,
    ].contains(singleType);
  }

  // Custom node option is only available for single-network wallet creation/restoration.
  bool get hasCustomNodeOption => !isMultiType;

  bool get supportsTestnetToggle =>
      !isMultiType && (singleType == WalletType.bitcoin || singleType == WalletType.decred);

  bool get supportsZcashNetworkOption => !isMultiType && singleType == WalletType.zcash;

  @computed
  bool get addCustomNode => _addCustomNode;

  @computed
  SeedPhraseLength get seedPhraseLength => _settingsStore.seedPhraseLength;

  @computed
  bool get isPolySeed => _settingsStore.moneroSeedType == MoneroSeedType.polyseed;

  @action
  void setFiatApiMode(FiatApiMode fiatApiMode) => _settingsStore.fiatApiMode = fiatApiMode;

  @action
  void setExchangeApiMode(ExchangeApiMode value) => _settingsStore.exchangeStatus = value;

  @action
  void setDisableBulletin(bool value) => _settingsStore.disableBulletin = value;

  @action
  void setUseBlinkProtection(bool value) => _settingsStore.useBlinkProtection = value;

  @action
  void toggleAddCustomNode() => _addCustomNode = !_addCustomNode;

  @action
  void setSeedPhraseLength(SeedPhraseLength length) => _settingsStore.seedPhraseLength = length;
}
