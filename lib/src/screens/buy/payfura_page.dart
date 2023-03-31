import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

class PayFuraPage extends BasePage {
  PayFuraPage({required this.settingsStore, required this.wallet});

  final SettingsStore settingsStore;
  final WalletBase wallet;

  @override
  String get title => S.current.buy;

  @override
  Widget body(BuildContext context) {
    return PayFuraPageBody(
        settingsStore: settingsStore,
        wallet: wallet);
  }
}

class PayFuraPageBody extends StatefulWidget {
  PayFuraPageBody(
      {required this.settingsStore,
        required this.wallet});

  static const baseUrl = 'exchange.payfura.com';
  final SettingsStore settingsStore;
  final WalletBase wallet;

  Uri get uri => Uri.https(baseUrl, '', <String, dynamic>{
    'apiKey': secrets.payfuraApiKey,
    'to': wallet.currency.title,
    'from': settingsStore.fiatCurrency.title,
    'walletAddress': '${wallet.currency.title}:${wallet.walletAddresses.address}',
    'mode': 'buy'
  });

  @override
  PayFuraPageBodyState createState() => PayFuraPageBodyState();
}

class PayFuraPageBodyState extends State<PayFuraPageBody> {
  PayFuraPageBodyState();

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
