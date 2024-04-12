import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/buy/buy_provider.dart';
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
  })  : baseSellUrl = isTestEnvironment ? _baseTestUrl : _baseProductUrl,
        baseBuyUrl = isTestEnvironment ? _baseTestUrl : _baseProductUrl,
        this._settingsStore = settingsStore,
        super(wallet: wallet, isTestEnvironment: isTestEnvironment);

  final SettingsStore _settingsStore;

  static const _baseTestUrl = 'sb.fluidmoney.xyz';
  static const _baseProductUrl = 'fluidmoney.xyz';

  final String baseBuyUrl;
  final String baseSellUrl;

  @override
  String get providerDescription =>
      'Buy crypto with many payment providers like Stripe and PayPal. Available in most countries. Spreads and feed vary.';

  @override
  String get providerSellDescription =>
      'Sell crypto with many payment providers like Stripe and PayPal. Available in most countries. Spreads and feed vary.';

  @override
  String get title => 'Meld';

  @override
  String get lightIcon => 'assets/images/meld_dark.png';

  @override
  String get darkIcon => lightIcon;

  String get currencyCode => walletTypeToCryptoCurrency(wallet.type).title.toLowerCase();

  static String convertTheme(ThemeBase theme) {
    switch (theme.type) {
      case ThemeType.bright:
      case ThemeType.light:
        return 'lightMode';
      case ThemeType.dark:
        return 'darkMode';
    }
  }

  Future<Uri> requestSellUrl({
    required CryptoCurrency currency,
    required String walletAddress,
    required SettingsStore settingsStore,
    String? amount,
  }) async {
    final params = {
      "transactionType": "SELL",
      "publicKey": secrets.meldApiKey,
      "theme": convertTheme(settingsStore.currentTheme),
      "sourceCurrencyCode": currencyCode.toUpperCase(),
      "destinationCurrencyCode": settingsStore.fiatCurrency.raw,
      "sourceAmount": amount ?? '100',
      "walletAddress": walletAddress,
    };

    final uri = Uri.https(baseSellUrl, '', params);
    return uri;
  }

  Future<Uri> requestBuyUrl({
    required CryptoCurrency currency,
    required SettingsStore settingsStore,
    required String walletAddress,
    String? amount,
  }) async {
    final params = {
      "transactionType": "BUY",
      "publicKey": secrets.meldApiKey,
      "theme": convertTheme(settingsStore.currentTheme),
      "destinationCurrencyCode": currencyCode.toUpperCase(),
      "sourceCurrencyCode": settingsStore.fiatCurrency.raw,
      "sourceAmount": amount ?? '100',
      "walletAddress": walletAddress,
    };

    final uri = Uri.https(baseBuyUrl, '', params);
    return uri;
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
        walletAddress: wallet.walletAddresses.address,
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
}