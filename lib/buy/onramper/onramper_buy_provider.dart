import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OnRamperBuyProvider {
  OnRamperBuyProvider({required SettingsStore settingsStore, required WalletBase wallet})
      : this._settingsStore = settingsStore,
        this._wallet = wallet;

  final SettingsStore _settingsStore;
  final WalletBase _wallet;

  static const _baseUrl = 'buy.onramper.com';

  String get _apiKey => secrets.onramperApiKey;

  String get _normalizeCryptoCurrency {
    switch (_wallet.currency) {
      case CryptoCurrency.ltc:
        return "LTC_LITECOIN";
      case CryptoCurrency.xmr:
        return "XMR_MONERO";
      default:
        return _wallet.currency.title;
    }
  }

  String getColorStr(Color color) {
    return color.value.toRadixString(16).replaceAll(RegExp(r'^ff'), "");
  }

  Uri requestUrl(BuildContext context) {
    String primaryColor,
        secondaryColor,
        primaryTextColor,
        secondaryTextColor,
        containerColor,
        cardColor;

    primaryColor = getColorStr(Theme.of(context).primaryColor);
    secondaryColor = getColorStr(Theme.of(context).colorScheme.background);
    primaryTextColor = getColorStr(Theme.of(context).extension<CakeTextTheme>()!.titleColor);
    secondaryTextColor =
        getColorStr(Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor);
    containerColor = getColorStr(Theme.of(context).colorScheme.background);
    cardColor = getColorStr(Theme.of(context).cardColor);

    if (_settingsStore.currentTheme.title == S.current.high_contrast_theme) {
      cardColor = getColorStr(Colors.white);
    }

    final networkName = _wallet.currency.fullName?.toUpperCase().replaceAll(" ", "");

    return Uri.https(_baseUrl, '', <String, dynamic>{
      'apiKey': _apiKey,
      'defaultCrypto': _normalizeCryptoCurrency,
      'networkWallets': '${networkName}:${_wallet.walletAddresses.address}',
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

  Future<void> launchProvider(BuildContext context) async {
    final uri = requestUrl(context);
    if (DeviceInfo.instance.isMobile) {
      Navigator.of(context).pushNamed(Routes.webViewPage, arguments: [S.of(context).buy, uri]);
    } else {
      await launchUrl(uri);
    }
  }
}
