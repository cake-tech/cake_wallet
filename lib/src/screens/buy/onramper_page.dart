import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

class OnRamperPage extends BasePage {
  OnRamperPage({required this.settingsStore, required this.wallet});

  final SettingsStore settingsStore;
  final WalletBase wallet;

  @override
  String get title => S.current.buy;

  @override
  Widget body(BuildContext context) {
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    return OnRamperPageBody(
        settingsStore: settingsStore,
        wallet: wallet,
        darkMode: darkMode,
        backgroundColor: darkMode ? backgroundDarkColor : backgroundLightColor,
        supportSell: false,
        supportSwap: false);
  }
}

class OnRamperPageBody extends StatefulWidget {
  OnRamperPageBody(
      {required this.settingsStore,
      required this.wallet,
      required this.darkMode,
      required this.supportSell,
      required this.supportSwap,
      required this.backgroundColor});

  static const baseUrl = 'exchange.payfura.com';
  final SettingsStore settingsStore;
  final WalletBase wallet;
  final Color backgroundColor;
  final bool darkMode;
  final bool supportSell;
  final bool supportSwap;

  Uri get uri => Uri.https(baseUrl, '', <String, dynamic>{
        'apiKey': secrets.payfuraApiKey,
        'to': wallet.currency.title,
        'from': settingsStore.fiatCurrency.title,
        'walletAddress': '${wallet.currency.title}:${wallet.walletAddresses.address}',
        'mode': 'buy'
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
