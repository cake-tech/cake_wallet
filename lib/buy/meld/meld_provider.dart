import 'dart:convert';

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

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

  final String baseBuyUrl;
  final String baseSellUrl;

  @override
  String get providerDescription => 'Meld provider description here';

  @override
  String get title => 'Meld';

  @override
  String get lightIcon => 'assets/images/meld_light.svg';

  @override
  String get darkIcon => 'assets/images/meld_light.svg';

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
  static const _buyWidgetSuffix = "/crypto/session/widget";

  Future<Uri> requestBuyUrl({
    required CryptoCurrency currency,
    required SettingsStore settingsStore,
    required String walletAddress,
    String? amount,
  }) async {
    try {
      final headers = {
        'Meld-Version': '2023-12-19',
        'Content-Type': 'application/json',
        'Authorization': 'BASIC ${secrets.meldApiKey}',
      };
      final body = {
        "sessionData": {
          "walletAddress": walletAddress,
          "countryCode": _normalizeCountryCode(settingsStore.fiatCurrency.countryCode),
          "sourceCurrencyCode": settingsStore.fiatCurrency.raw,
          "sourceAmount": amount ?? '60',
          "destinationCurrencyCode": currencyCode.toUpperCase(),
          "serviceProvider": "STRIPE"
        },
        "sessionType": "BUY",
        "externalCustomerId": "testcustomer",
      };
      final response = await http.post(
        Uri.https(baseBuyUrl, _buyWidgetSuffix),
        headers: headers,
        body: json.encode(body),
      );
      return Uri.parse(json.decode(response.body)["widgetUrl"] as String);
    } catch (e) {
      print(e);
      rethrow;
    }
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

  // normalize country codes to ISO-3166:
  String _normalizeCountryCode(String countryCode) {
    countryCode = countryCode.toLowerCase();
    switch (countryCode) {
      case "usa":
      default:
        return "US";
    }
  }
}
