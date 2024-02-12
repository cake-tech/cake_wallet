import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/entities/provider_types.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:collection/collection.dart';

enum OnRamperPartner {
  guardarian,
  paybis,
}

class OnRamperBuyProvider extends BuyProvider {
  OnRamperBuyProvider({this.settingsStore,this.partner,
      required WalletBase wallet, bool isTestEnvironment = false})
      : super(wallet: wallet, isTestEnvironment: isTestEnvironment);

  static const _baseUrl = 'buy.onramper.com';

  static OnRamperPartner? fromRaw(int? raw) =>
      OnRamperPartner.values.firstWhereOrNull((e) => e.index == raw);

  final SettingsStore? settingsStore;

  OnRamperPartner? partner;

  @override
  ProviderType get providerType => ProviderType.onramper;

  @override
  String get title => providerType.title;

  @override
  String get providerDescription => S.current.onramper_option_description;

  @override
  String get lightIcon => 'assets/images/onramper_light.png';

  @override
  String get darkIcon => 'assets/images/onramper_dark.png';

  String get trackUrl {
    switch (partner) {
      case OnRamperPartner.guardarian:
        return "https://payments.guardarian.com/checkout?tid=";
      case OnRamperPartner.paybis:
        return "https://widget.paybis.com/?requestId=";
      default:
        return '';
    }
  }

  String get _apiKey => secrets.onramperApiKey;

  String get _normalizeCryptoCurrency {
    switch (wallet.currency) {
      case CryptoCurrency.ltc:
        return "LTC_LITECOIN";
      case CryptoCurrency.xmr:
        return "XMR_MONERO";
      case CryptoCurrency.bch:
        return "BCH_BITCOINCASH";
      case CryptoCurrency.nano:
        return "XNO_NANO";
      default:
        return wallet.currency.title;
    }
  }

  String getColorStr(Color color) {
    return color.value.toRadixString(16).replaceAll(RegExp(r'^ff'), "");
  }

  Uri requestOnramperUrl(BuildContext context, bool? isBuyAction) {
    String primaryColor,
        secondaryColor,
        primaryTextColor,
        secondaryTextColor,
        containerColor,
        cardColor;

    primaryColor = getColorStr(Theme.of(context).primaryColor);
    secondaryColor = getColorStr(Theme.of(context).colorScheme.background);
    primaryTextColor =
        getColorStr(Theme.of(context).extension<CakeTextTheme>()!.titleColor);
    secondaryTextColor = getColorStr(
        Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor);
    containerColor = getColorStr(Theme.of(context).colorScheme.background);
    cardColor = getColorStr(Theme.of(context).cardColor);

    if (settingsStore != null) {
      if (settingsStore!.currentTheme.title == S.current.high_contrast_theme) {
        cardColor = getColorStr(Colors.white);
      }
    }

    final networkName =
        wallet.currency.fullName?.toUpperCase().replaceAll(" ", "");

    return Uri.https(_baseUrl, '', <String, dynamic>{
      'apiKey': _apiKey,
      'defaultCrypto': _normalizeCryptoCurrency,
      'sell_defaultCrypto': _normalizeCryptoCurrency,
      'networkWallets': '${networkName}:${wallet.walletAddresses.address}',
      'supportSwap': "false",
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'primaryTextColor': primaryTextColor,
      'secondaryTextColor': secondaryTextColor,
      'containerColor': containerColor,
      'cardColor': cardColor,
      'mode': isBuyAction == true ? 'buy' : 'sell',
    });
  }

  Future<void> launchProvider(BuildContext context, bool? isBuyAction) async {
    final uri = requestOnramperUrl(context, isBuyAction);
    if (DeviceInfo.instance.isMobile) {
      Navigator.of(context)
          .pushNamed(Routes.webViewPage, arguments:[uri, providerType]);
    } else {
      await launchUrl(uri);
    }
  }
}
