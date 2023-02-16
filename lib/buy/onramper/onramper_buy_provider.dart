import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/wallet_base.dart';

class OnRamperBuyProvider {
  OnRamperBuyProvider({required SettingsStore settingsStore, required WalletBase wallet})
      : this._settingsStore = settingsStore,
        this._wallet = wallet;

  final SettingsStore _settingsStore;
  final WalletBase _wallet;

  static const _baseUrl = 'widget.onramper.com';

  static String get _apiKey => secrets.onramperApiKey;

  Uri requestUrl(bool darkMode) {
    return Uri.https(_baseUrl, '', <String, dynamic>{
      'apiKey': _apiKey,
      'defaultCrypto': _wallet.currency.title,
      'defaultFiat': _settingsStore.fiatCurrency.title,
      'wallets': '${_wallet.currency.title}:${_wallet.walletAddresses.address}',
      'darkMode': darkMode.toString(),
      'supportSell': "false",
      'supportSwap': "false"
    });
  }
}
