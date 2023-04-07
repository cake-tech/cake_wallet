import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

class OnRamperPage extends BasePage {
  OnRamperPage({required this.settingsStore, required this.wallet});

  final SettingsStore settingsStore;
  final WalletBase wallet;
  ThemeBase get currentTheme => getIt.get<SettingsStore>().currentTheme;

  @override
  String get title => S.current.buy;

  @override
  Widget body(BuildContext context) {
    String? primaryColor,
        secondaryColor,
        primaryTextColor,
        secondaryTextColor,
        containerColor,
        cardColor;

    switch (currentTheme.type) {
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
        cardColor = 'e5f7ff';
        break;
      case ThemeType.dark:
        primaryColor = '456effff';
        secondaryColor = '1b2747ff';
        primaryTextColor = secondaryTextColor = 'ffffff';
        containerColor = '19233C';
        cardColor = '232f4fff';
        break;
    }

    secondaryColor ??= 'ffffff';
    primaryTextColor ??= '141519';
    secondaryTextColor ??= '6b6f80';
    containerColor ??= 'ffffff';

    return OnRamperPageBody(
        settingsStore: settingsStore,
        wallet: wallet,
        supportSell: false,
        supportSwap: false,
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
        primaryTextColor: primaryTextColor,
        secondaryTextColor: secondaryTextColor,
        containerColor: containerColor,
        cardColor: cardColor);
  }
}

class OnRamperPageBody extends StatefulWidget {
  OnRamperPageBody({
    required this.settingsStore,
    required this.wallet,
    required this.supportSell,
    required this.supportSwap,
    required this.primaryColor,
    required this.secondaryColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.containerColor,
    required this.cardColor,
  });

  static const baseUrl = 'buy.onramper.com';
  final SettingsStore settingsStore;
  final WalletBase wallet;
  final bool supportSell;
  final bool supportSwap;
  final String primaryColor,
      secondaryColor,
      primaryTextColor,
      secondaryTextColor,
      containerColor,
      cardColor;

  Uri get uri => Uri.https(baseUrl, '', <String, dynamic>{
        'apiKey': secrets.onramperApiKey,
        'defaultCrypto': wallet.currency.title,
        'defaultFiat': settingsStore.fiatCurrency.title,
        'wallets': '${wallet.currency.title}:${wallet.walletAddresses.address}',
        'supportSell': supportSell.toString(),
        'supportSwap': supportSwap.toString(),
        'primaryColor': primaryColor,
        'secondaryColor': secondaryColor,
        'primaryTextColor': primaryTextColor,
        'secondaryTextColor': secondaryTextColor,
        'containerColor': containerColor,
        'cardColor': cardColor
      });

  @override
  OnRamperPageBodyState createState() => OnRamperPageBodyState();
}

class OnRamperPageBodyState extends State<OnRamperPageBody> {
  OnRamperPageBodyState();

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialOptions: InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(transparentBackground: true),
      ),
      initialUrlRequest: URLRequest(url: widget.uri),
      androidOnPermissionRequest: (_, __, resources) async {
        bool permissionGranted = await Permission.camera.status == PermissionStatus.granted;
        if (!permissionGranted) {
          permissionGranted = await Permission.camera.request().isGranted;
        }

        return PermissionRequestResponse(
          resources: resources,
          action: permissionGranted
              ? PermissionRequestResponseAction.GRANT
              : PermissionRequestResponseAction.DENY,
        );
      },
    );
  }
}
