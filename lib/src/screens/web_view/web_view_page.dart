import 'dart:io';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPage extends BasePage {
  WebViewPage({@required this.url});

  final String url;

  @override
  String get title => S.current.buy;

  @override
  Widget body(BuildContext context) => WebViewPageBody(url: url);
}

class WebViewPageBody extends StatefulWidget {
  WebViewPageBody({this.url});

  final String url;

  @override
  WebViewPageBodyState createState() => WebViewPageBodyState();
}

class WebViewPageBodyState extends State<WebViewPageBody> {
  String orderId;
  WebViewController _webViewController;
  GlobalKey _webViewkey;

  @override
  void initState() {
    super.initState();
    _webViewkey = GlobalKey();

    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return WebView(
        key: _webViewkey,
        initialUrl: widget.url,
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController controller) =>
            setState(() => _webViewController = controller),
        navigationDelegate: (req) async {
          final currentUrl = await _webViewController?.currentUrl() ?? '';

          if (currentUrl.contains('processing') ||
              currentUrl.contains('completed')) {
            final urlParts = currentUrl.split('/');
            orderId = urlParts.last;
            print(orderId);
          }

          return NavigationDecision.navigate;
        });
  }
}
