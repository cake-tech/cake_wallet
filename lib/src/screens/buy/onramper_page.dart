import 'dart:io';
import 'package:cake_wallet/buy/onramper/onramper_buy_provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

class OnRamperPage extends BasePage {
  OnRamperPage(this._onRamperBuyProvider);

  final OnRamperBuyProvider _onRamperBuyProvider;

  @override
  String get title => S.current.buy;

  @override
  Widget body(BuildContext context) {
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    return OnRamperPageBody(
      onRamperBuyProvider: _onRamperBuyProvider,
      darkMode: darkMode,
      backgroundColor: darkMode ? backgroundDarkColor : backgroundLightColor,
    );
  }
}

class OnRamperPageBody extends StatefulWidget {
  OnRamperPageBody({
    required this.onRamperBuyProvider,
    required this.darkMode,
    required this.backgroundColor,
  });

  final OnRamperBuyProvider onRamperBuyProvider;
  final Color backgroundColor;
  final bool darkMode;

  Uri get uri => onRamperBuyProvider.requestUrl(darkMode);

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
