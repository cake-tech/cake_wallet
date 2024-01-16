import 'dart:convert';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:crypto/crypto.dart';
import 'package:cake_wallet/buy/buy_exception.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:cake_wallet/buy/buy_amount.dart';
import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/buy_provider_description.dart';
import 'package:cake_wallet/buy/order.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cw_core/crypto_currency.dart';
import 'package:url_launcher/url_launcher.dart';

class MoonPaySellProvider extends BuyProvider {
  MoonPaySellProvider({
    required SettingsStore settingsStore,
    required WalletBase wallet,
    bool isTestEnvironment = false,
  })  : baseUrl = isTestEnvironment ? _baseTestUrl : _baseProductUrl,
        this._settingsStore = settingsStore,
        super(wallet: wallet, isTestEnvironment: isTestEnvironment);

  final SettingsStore _settingsStore;

  static const _baseTestUrl = 'sell-sandbox.moonpay.com';
  static const _baseProductUrl = 'sell.moonpay.com';

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
  final String baseUrl;

  Future<Uri> requestMoonPayUrl({
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

    final originalUri = Uri.https(
      baseUrl,
      '',
      <String, dynamic>{
        'apiKey': _apiKey,
        'defaultBaseCurrencyCode': currency.toString().toLowerCase(),
        'refundWalletAddress': refundWalletAddress,
      }..addAll(customParams),
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

  @override
  Future<void> launchProvider(BuildContext context, bool? isBuyAction) async {
    try {
      final uri = await requestMoonPayUrl(
        currency: wallet.currency,
        refundWalletAddress: wallet.walletAddresses.address,
        settingsStore: _settingsStore,
      );

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
}

class MoonPayBuyProvider extends BuyProvider {
  MoonPayBuyProvider({required WalletBase wallet, bool isTestEnvironment = false})
      : baseUrl = isTestEnvironment ? _baseTestUrl : _baseProductUrl,
        super(wallet: wallet, isTestEnvironment: isTestEnvironment);

  static const _baseTestUrl = 'https://buy-staging.moonpay.com';
  static const _baseProductUrl = 'https://buy.moonpay.com';
  static const _apiUrl = 'https://api.moonpay.com';
  static const _currenciesSuffix = '/v3/currencies';
  static const _quoteSuffix = '/buy_quote';
  static const _transactionsSuffix = '/v1/transactions';
  static const _ipAddressSuffix = '/v4/ip_address';
  static const _apiKey = secrets.moonPayApiKey;
  static const _secretKey = secrets.moonPaySecretKey;

  @override
  String get title => 'MoonPay';

  @override
  String get providerDescription =>
      'MoonPay offers a fast and simple way to buy and sell cryptocurrencies';

  @override
  String get lightIcon => 'assets/images/moonpay_light.png';

  @override
  String get darkIcon => 'assets/images/moonpay_dark.png';

  String get currencyCode => walletTypeToCryptoCurrency(wallet.type).title.toLowerCase();

  String get trackUrl => baseUrl + '/transaction_receipt?transactionId=';

  String baseUrl;

  Future<String> requestUrl(String amount, String sourceCurrency) async {
    final enabledPaymentMethods = 'credit_debit_card%2Capple_pay%2Cgoogle_pay%2Csamsung_pay'
        '%2Csepa_bank_transfer%2Cgbp_bank_transfer%2Cgbp_open_banking_payment';

    final suffix = '?apiKey=' +
        _apiKey +
        '&currencyCode=' +
        currencyCode +
        '&enabledPaymentMethods=' +
        enabledPaymentMethods +
        '&walletAddress=' +
        wallet.walletAddresses.address +
        '&baseCurrencyCode=' +
        sourceCurrency.toLowerCase() +
        '&baseCurrencyAmount=' +
        amount +
        '&lockAmount=true' +
        '&showAllCurrencies=false' +
        '&showWalletAddressForm=false';

    final originalUrl = baseUrl + suffix;

    final messageBytes = utf8.encode(suffix);
    final key = utf8.encode(_secretKey);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(messageBytes);
    final signature = base64.encode(digest.bytes);
    final urlWithSignature = originalUrl + '&signature=${Uri.encodeComponent(signature)}';

    return isTestEnvironment ? originalUrl : urlWithSignature;
  }

  Future<BuyAmount> calculateAmount(String amount, String sourceCurrency) async {
    final url = _apiUrl +
        _currenciesSuffix +
        '/$currencyCode' +
        _quoteSuffix +
        '/?apiKey=' +
        _apiKey +
        '&baseCurrencyAmount=' +
        amount +
        '&baseCurrencyCode=' +
        sourceCurrency.toLowerCase();
    final uri = Uri.parse(url);
    final response = await get(uri);

    if (response.statusCode != 200) {
      throw BuyException(title: providerDescription, content: 'Quote is not found!');
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final sourceAmount = responseJSON['totalAmount'] as double;
    final destAmount = responseJSON['quoteCurrencyAmount'] as double;
    final minSourceAmount = responseJSON['baseCurrency']['minAmount'] as int;

    return BuyAmount(
        sourceAmount: sourceAmount, destAmount: destAmount, minAmount: minSourceAmount);
  }

  Future<Order> findOrderById(String id) async {
    final url = _apiUrl + _transactionsSuffix + '/$id' + '?apiKey=' + _apiKey;
    final uri = Uri.parse(url);
    final response = await get(uri);

    if (response.statusCode != 200) {
      throw BuyException(title: providerDescription, content: 'Transaction $id is not found!');
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final status = responseJSON['status'] as String;
    final state = TradeState.deserialize(raw: status);
    final createdAtRaw = responseJSON['createdAt'] as String;
    final createdAt = DateTime.parse(createdAtRaw).toLocal();
    final amount = responseJSON['quoteCurrencyAmount'] as double;

    return Order(
        id: id,
        provider: BuyProviderDescription.moonPay,
        transferId: id,
        state: state,
        createdAt: createdAt,
        amount: amount.toString(),
        receiveAddress: wallet.walletAddresses.address,
        walletId: wallet.id);
  }

  static Future<bool> onEnabled() async {
    final url = _apiUrl + _ipAddressSuffix + '?apiKey=' + _apiKey;
    var isBuyEnable = false;
    final uri = Uri.parse(url);
    final response = await get(uri);

    try {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      isBuyEnable = responseJSON['isBuyAllowed'] as bool;
    } catch (e) {
      isBuyEnable = false;
      print(e.toString());
    }

    return isBuyEnable;
  }

  @override
  Future<void> launchProvider(BuildContext context, bool? isBuyAction) =>
      throw UnimplementedError();
}
