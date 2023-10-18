import 'dart:convert';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:crypto/crypto.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/widgets.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cw_core/crypto_currency.dart';
import 'package:url_launcher/url_launcher.dart';

class MoonPayExchangeProvider {
  MoonPayExchangeProvider(
      {required SettingsStore settingsStore, required WalletBase wallet, this.isTest = true})
      : this._settingsStore = settingsStore,
        this._wallet = wallet,
        baseUrl = isTest ? _baseTestUrl : _baseProductUrl;

  final SettingsStore _settingsStore;
  final WalletBase _wallet;

  static const _baseTestUrl = 'buy-staging.moonpay.com';
  static const _baseProductUrl = 'buy.moonpay.com';
  static const _apiUrl = 'https://api.moonpay.com';
  static const _currenciesSuffix = '/v3/currencies';
  static const _quoteSuffix = '/buy_quote';
  static const _transactionsSuffix = '/v1/transactions';
  static const _ipAddressSuffix = '/v4/ip_address';
  static const _apiKey = secrets.moonPayApiKey;
  static const _secretKey = secrets.moonPaySecretKey;

  static String themeToMoonPayTheme(ThemeBase theme) {
    switch (theme.type) {
      case ThemeType.bright:
        return 'light';
      case ThemeType.light:
        return 'light';
      case ThemeType.dark:
        return 'dark';
    }
  }

  final bool isTest;
  final String baseUrl;

  Future<Uri> requestUrl(
      {required CryptoCurrency currency, required String refundWalletAddress}) async {
    final customParams = {
      'theme': themeToMoonPayTheme(_settingsStore.currentTheme),
      'language': _settingsStore.languageCode,
      'colorCode': _settingsStore.currentTheme.type == ThemeType.dark
          ? '#${Palette.blueCraiola.value.toRadixString(16).substring(2, 8)}'
          : '#${Palette.moderateSlateBlue.value.toRadixString(16).substring(2, 8)}',
    };

    final originalUri = Uri.https(
        baseUrl,
        '',
        <String, dynamic>{
          // 'apiKey': _apiKey,
          'defaultBaseCurrencyCode': currency.toString().toLowerCase(),
          // 'refundWalletAddress': refundWalletAddress
        }..addAll(customParams));
    final messageBytes = utf8.encode('?${originalUri.query}');
    final key = utf8.encode(_secretKey);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(messageBytes);
    final signature = base64.encode(digest.bytes);

    if (isTest) {
      return originalUri;
    }

    final query = Map<String, dynamic>.from(originalUri.queryParameters);
    query['signature'] = signature;
    final signedUri = originalUri.replace(queryParameters: query);
    return signedUri;
  }

  // void _initialPairBasedOnWallet() {
  //   switch (wallet.type) {
  //     case WalletType.monero:
  //       depositCurrency = CryptoCurrency.xmr;
  //       receiveCurrency = CryptoCurrency.btc;
  //       break;
  //     case WalletType.bitcoin:
  //       depositCurrency = CryptoCurrency.btc;
  //       receiveCurrency = CryptoCurrency.xmr;
  //       break;
  //     case WalletType.litecoin:
  //       depositCurrency = CryptoCurrency.ltc;
  //       receiveCurrency = CryptoCurrency.xmr;
  //       break;
  //     case WalletType.bitcoinCash:
  //       depositCurrency = CryptoCurrency.bch;
  //       receiveCurrency = CryptoCurrency.xmr;
  //       break;
  //     case WalletType.haven:
  //       depositCurrency = CryptoCurrency.xhv;
  //       receiveCurrency = CryptoCurrency.btc;
  //       break;
  //     case WalletType.ethereum:
  //       depositCurrency = CryptoCurrency.eth;
  //       receiveCurrency = CryptoCurrency.xmr;
  //       break;
  //     case WalletType.nano:
  //       depositCurrency = CryptoCurrency.nano;
  //       receiveCurrency = CryptoCurrency.xmr;
  //       break;
  //     default:
  //       break;
  //   }
  // }

  Future<void> launchProvider(BuildContext context) async {
    //     primaryColor = getColorStr(Theme.of(context).primaryColor);
    // secondaryColor = getColorStr(Theme.of(context).colorScheme.background);
    // primaryTextColor = getColorStr(Theme.of(context).extension<CakeTextTheme>()!.titleColor);
    // secondaryTextColor =
    //     getColorStr(Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor);
    // containerColor = getColorStr(Theme.of(context).colorScheme.background);
    // cardColor = getColorStr(Theme.of(context).cardColor);

    final uri = await requestUrl(currency: CryptoCurrency.xmr, refundWalletAddress: "");
    if (DeviceInfo.instance.isMobile) {
      Navigator.of(context).pushNamed(Routes.webViewPage, arguments: [S.of(context).exchange, uri]);
    } else {
      await launchUrl(uri);
    }
  }
}
