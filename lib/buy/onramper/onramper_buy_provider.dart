import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cw_core/wallet_base.dart';

class OnRamperBuyProvider {
  OnRamperBuyProvider({required SettingsStore settingsStore, required WalletBase wallet})
      : this._settingsStore = settingsStore,
        this._wallet = wallet;

  final SettingsStore _settingsStore;
  final WalletBase _wallet;

  static const _baseUrl = 'buy.onramper.com';

  static String get _apiKey => secrets.onramperApiKey;

  Uri requestUrl() {
    String primaryColor,
        secondaryColor,
        primaryTextColor,
        secondaryTextColor,
        containerColor,
        cardColor;

    switch (_settingsStore.currentTheme.type) {
      case ThemeType.bright:
        primaryColor = '815dfbff';
        secondaryColor = 'ffffff';
        primaryTextColor = '141519';
        secondaryTextColor = '6b6f80';
        containerColor = 'ffffff';
        cardColor = 'f2f0faff';
        break;
      case ThemeType.light:
        primaryColor = '2194ffff';
        secondaryColor = 'ffffff';
        primaryTextColor = '141519';
        secondaryTextColor = '6b6f80';
        containerColor = 'ffffff';
        cardColor = 'e5f7ff';
        break;
      case ThemeType.dark:
        primaryColor = '456effff';
        secondaryColor = '1b2747ff';
        primaryTextColor = 'ffffff';
        secondaryTextColor = 'ffffff';
        containerColor = '19233C';
        cardColor = '232f4fff';
        break;
    }


    return Uri.https(_baseUrl, '', <String, dynamic>{
      'apiKey': _apiKey,
      'defaultCrypto': _wallet.currency.title,
      'defaultFiat': _settingsStore.fiatCurrency.title,
      'wallets': '${_wallet.currency.title}:${_wallet.walletAddresses.address}',
      'supportSell': "false",
      'supportSwap': "false",
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'primaryTextColor': primaryTextColor,
      'secondaryTextColor': secondaryTextColor,
      'containerColor': containerColor,
      'cardColor': cardColor
    });
  }
}
