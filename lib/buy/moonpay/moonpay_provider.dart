import 'dart:convert';

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/buy/buy_amount.dart';
import 'package:cake_wallet/buy/buy_exception.dart';
import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/buy_provider_description.dart';
import 'package:cake_wallet/buy/order.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:crypto/crypto.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';

class MoonPayProvider extends BuyProvider {
  MoonPayProvider({
    required SettingsStore settingsStore,
    required WalletBase wallet,
    bool isTestEnvironment = false,
  })  : baseSellUrl = isTestEnvironment ? _baseSellTestUrl : _baseSellProductUrl,
        baseBuyUrl = isTestEnvironment ? _baseBuyTestUrl : _baseBuyProductUrl,
        this._settingsStore = settingsStore,
        super(wallet: wallet, isTestEnvironment: isTestEnvironment);

  final SettingsStore _settingsStore;

  static const _baseSellTestUrl = 'sell-sandbox.moonpay.com';
  static const _baseSellProductUrl = 'sell.moonpay.com';
  static const _baseBuyTestUrl = 'buy-staging.moonpay.com';
  static const _baseBuyProductUrl = 'buy.moonpay.com';
  static const _cIdBaseUrl = 'exchange-helper.cakewallet.com';

  @override
  String get providerDescription =>
      'MoonPay offers a fast and simple way to buy and sell cryptocurrencies';

  @override
  String get title => 'MoonPay';

  @override
  String get lightIcon => 'assets/images/moonpay_light.png';

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

  static String get _secretKey => secrets.moonPaySecretKey;
  final String baseBuyUrl;
  final String baseSellUrl;

  String get currencyCode => walletTypeToCryptoCurrency(wallet.type).title.toLowerCase();

  String get trackUrl => baseBuyUrl + '/transaction_receipt?transactionId=';

  static String get _exchangeHelperApiKey => secrets.exchangeHelperApiKey;

  Future<String> getMoonpaySignature(String query) async {
    final uri = Uri.https(_cIdBaseUrl, "/api/moonpay");

    final response = await post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _exchangeHelperApiKey,
      },
      body: json.encode({'query': query}),
    );

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as Map<String, dynamic>)['signature'] as String;
    } else {
      throw Exception(
          'Provider currently unavailable. Status: ${response.statusCode} ${response.body}');
    }
  }

  Future<Uri> requestSellMoonPayUrl({
    required CryptoCurrency currency,
    required String refundWalletAddress,
    required SettingsStore settingsStore,
  }) async {
    final customParams = {
      'theme': themeToMoonPayTheme(settingsStore.currentTheme),
      'language': settingsStore.languageCode,
      'colorCode': settingsStore.currentTheme.type == ThemeType.dark
          ? '#${Palette.blueCraiola.value.toRadixString(16).substring(2, 8)}'
          : '#${Palette.moderateSlateBlue.value.toRadixString(16).substring(2, 8)}',
    };

    var params = <String, dynamic>{
        'defaultBaseCurrencyCode': _normalizeCurrency(currency),
        'refundWalletAddress': refundWalletAddress,
      }..addAll(customParams);

    if (_apiKey.isNotEmpty) {
      params['apiKey'] = _apiKey;
    }

    final originalUri = Uri.https(
      baseSellUrl,
      '',
      params,
    );

    final messageBytes = utf8.encode('?${originalUri.query}');
    final key = utf8.encode(_secretKey);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(messageBytes);
    final signature = base64.encode(digest.bytes);

    if (isTestEnvironment) {
      return originalUri;
    }

    final query = Map<String, dynamic>.from(originalUri.queryParameters);
    query['signature'] = signature;
    final signedUri = originalUri.replace(queryParameters: query);
    return signedUri;
  }

  Future<Uri> requestBuyMoonPayUrl({
    required CryptoCurrency currency,
    required String refundWalletAddress,
    required SettingsStore settingsStore,
  }) async {
    final customParams = {
      'theme': themeToMoonPayTheme(settingsStore.currentTheme),
      'language': settingsStore.languageCode,
      'colorCode': settingsStore.currentTheme.type == ThemeType.dark
          ? '#${Palette.blueCraiola.value.toRadixString(16).substring(2, 8)}'
          : '#${Palette.moderateSlateBlue.value.toRadixString(16).substring(2, 8)}',
    };

    var params = <String, dynamic>{
        'defaultBaseCurrencyCode': _normalizeCurrency(currency),
        'refundWalletAddress': refundWalletAddress,
      }..addAll(customParams);

    if (_apiKey.isNotEmpty) {
      params['apiKey'] = _apiKey;
    }

    final originalUri = Uri.https(
      baseBuyUrl,
      '',
      params,
    );

    final signature = await getMoonpaySignature('?${originalUri.query}');

    if (isTestEnvironment) {
      return originalUri;
    }

    final query = Map<String, dynamic>.from(originalUri.queryParameters);
    query['signature'] = signature;
    final signedUri = originalUri.replace(queryParameters: query);
    return signedUri;
  }

  @override
  Future<void> launchProvider(BuildContext context, bool? isBuyAction) async {
    try {
      late final Uri uri;
      if (isBuyAction ?? true) {
        uri = await requestBuyMoonPayUrl(
          currency: wallet.currency,
          refundWalletAddress: wallet.walletAddresses.address,
          settingsStore: _settingsStore,
        );
      } else {
        uri = await requestSellMoonPayUrl(
          currency: wallet.currency,
          refundWalletAddress: wallet.walletAddresses.address,
          settingsStore: _settingsStore,
        );
      }

      if (await canLaunchUrl(uri)) {
        if (DeviceInfo.instance.isMobile) {
          Navigator.of(context).pushNamed(Routes.webViewPage, arguments: ['MoonPay', uri]);
        } else {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertWithOneAction(
            alertTitle: 'MoonPay',
            alertContent: 'The MoonPay service is currently unavailable: $e',
            buttonText: S.of(context).ok,
            buttonAction: () => Navigator.of(context).pop(),
          );
        },
      );
    }
  }

  String _normalizeCurrency(CryptoCurrency currency) {
    if (currency == CryptoCurrency.maticpoly) {
      return "MATIC_POLYGON";
    }

    return currency.toString().toLowerCase();
  }

}
