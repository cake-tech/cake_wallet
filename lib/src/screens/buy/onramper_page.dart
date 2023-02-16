import 'dart:io';
import 'package:cake_wallet/buy/onramper/onramper_buy_provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return WebView(
        initialUrl: widget.uri.toString(),
        backgroundColor: widget.backgroundColor,
        javascriptMode: JavascriptMode.unrestricted);
  }
}
