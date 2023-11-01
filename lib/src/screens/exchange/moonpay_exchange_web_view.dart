import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:permission_handler/permission_handler.dart';

class MoonpayExchangeWebView extends BasePage {
  @override
  String get title => "Swap";

  @override
  Widget body(BuildContext context) {
    return InAppWebView(
      initialOptions: InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(transparentBackground: true),
      ),
      initialFile: "assets/index.html",
      onLoadStop: (controller, uri) {
        final String functionBody = """
        const moonPay = window.MoonPayWebSdk.init;

const moonPaySdk = moonPay({
  flow: 'swapsCustomerSetup',
  environment: 'production',
  variant: 'newTab',
  params: {
    apiKey: '${secrets.moonPayApiKey}',
    theme: 'dark',
    amountCurrencyCode: 'usd',
    amount: '100',
  },
  debug: $kDebugMode
});

moonPaySdk.show();
""";
        controller.callAsyncJavaScript(functionBody: functionBody);
      },
      androidOnPermissionRequest: (_, __, List<String> resources) async {
        bool permissionGranted = await Permission.camera.status == PermissionStatus.granted;
        if (!permissionGranted) {
          final permissionStatus = await Permission.camera.request();
          permissionGranted = await permissionStatus.isGranted;
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
