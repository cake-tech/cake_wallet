
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MeldProvider extends BuyProvider {
  MeldProvider({
    required SettingsStore settingsStore,
    required WalletBase wallet,
    bool isTestEnvironment = false,
  })  : baseSellUrl = isTestEnvironment ? _baseSellTestUrl : _baseSellProductUrl,
        baseBuyUrl = isTestEnvironment ? _baseBuyTestUrl : _baseBuyProductUrl,
        this._settingsStore = settingsStore,
        super(wallet: wallet, isTestEnvironment: isTestEnvironment);

  final SettingsStore _settingsStore;

  static const _baseSellTestUrl = 'api-sb.meld.io';
  static const _baseSellProductUrl = 'api.meld.io';
  static const _baseBuyTestUrl = 'api-sb.meld.io';
  static const _baseBuyProductUrl = 'api.meld.io';
  // static const _cIdBaseUrl = 'exchange-helper.cakewallet.com';

  final String baseBuyUrl;
  final String baseSellUrl;

  @override
  String get providerDescription => 'Meld provider description here';

  @override
  String get title => 'Meld';

  @override
  String get lightIcon => 'assets/images/meld_light.svg';

  @override
  String get darkIcon => 'assets/images/moonpay_dark.png';

  static String themeToMoonPayTheme(ThemeBase theme) {
    switch (theme.type) {
      case ThemeType.bright:
      case ThemeType.light:
        return 'light';
      case ThemeType.dark:
        return 'dark';
    }
  }

  static String get _apiKey => secrets.moonPayApiKey;

  String get currencyCode => walletTypeToCryptoCurrency(wallet.type).title.toLowerCase();


  static String get _exchangeHelperApiKey => secrets.exchangeHelperApiKey;

  Future<Uri> requestSellUrl({
    required CryptoCurrency currency,
    required String refundWalletAddress,
    required SettingsStore settingsStore,
  }) async {
    throw UnimplementedError();
  }

  // BUY:
  static const _currenciesSuffix = '/v3/currencies';
  static const _quoteSuffix = '/buy_quote';
  static const _transactionsSuffix = '/v1/transactions';
  static const _ipAddressSuffix = '/v4/ip_address';

  Future<Uri> requestBuyUrl({
    required CryptoCurrency currency,
    required SettingsStore settingsStore,
    required String walletAddress,
    String? amount,
  }) async {
    final params = {
      'theme': themeToMoonPayTheme(settingsStore.currentTheme),
      'language': settingsStore.languageCode,
      'colorCode': settingsStore.currentTheme.type == ThemeType.dark
          ? '#${Palette.blueCraiola.value.toRadixString(16).substring(2, 8)}'
          : '#${Palette.moderateSlateBlue.value.toRadixString(16).substring(2, 8)}',
      'defaultCurrencyCode': _normalizeCurrency(currency),
      'baseCurrencyCode': _normalizeCurrency(currency),
      'baseCurrencyAmount': amount ?? '0',
      'currencyCode': currencyCode,
      'walletAddress': walletAddress,
      'lockAmount': 'true',
      'showAllCurrencies': 'false',
      'showWalletAddressForm': 'false',
      'enabledPaymentMethods':
          'credit_debit_card,apple_pay,google_pay,samsung_pay,sepa_bank_transfer,gbp_bank_transfer,gbp_open_banking_payment',
    };

    if (_apiKey.isNotEmpty) {
      params['apiKey'] = _apiKey;
    }

    final originalUri = Uri.https(
      baseBuyUrl,
      '',
      params,
    );

    if (isTestEnvironment) {
      return originalUri;
    }

    return originalUri;
    // final signature = await getMoonpaySignature('?${originalUri.query}');
    // final query = Map<String, dynamic>.from(originalUri.queryParameters);
    // query['signature'] = signature;
    // final signedUri = originalUri.replace(queryParameters: query);
    // return signedUri;
  }

  @override
  Future<void> launchProvider(BuildContext context, bool? isBuyAction) async {
    late final Uri uri;
    if (isBuyAction ?? true) {
      uri = await requestBuyUrl(
        currency: wallet.currency,
        walletAddress: wallet.walletAddresses.address,
        settingsStore: _settingsStore,
      );
    } else {
      uri = await requestSellUrl(
        currency: wallet.currency,
        refundWalletAddress: wallet.walletAddresses.address,
        settingsStore: _settingsStore,
      );
    }

    if (await canLaunchUrl(uri)) {
      if (DeviceInfo.instance.isMobile) {
        Navigator.of(context).pushNamed(Routes.webViewPage, arguments: ['Meld', uri]);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      throw Exception('Could not launch URL');
    }
  }

  String _normalizeCurrency(CryptoCurrency currency) {
    if (currency == CryptoCurrency.maticpoly) {
      return "MATIC_POLYGON";
    }

    return currency.toString().toLowerCase();
  }
}
