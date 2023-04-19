import 'package:cake_wallet/buy/onramper/onramper_buy_provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

class OnRamperPage extends BasePage {
  OnRamperPage(this._onRamperBuyProvider);

  final OnRamperBuyProvider _onRamperBuyProvider;

  @override
  String get title => S.current.buy;

  @override
  Widget body(BuildContext context) {
    return OnRamperPageBody(_onRamperBuyProvider);
  }
}

class OnRamperPageBody extends StatefulWidget {
  OnRamperPageBody(this.onRamperBuyProvider);

  final OnRamperBuyProvider onRamperBuyProvider;

  Uri get uri => onRamperBuyProvider.requestUrl();

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
