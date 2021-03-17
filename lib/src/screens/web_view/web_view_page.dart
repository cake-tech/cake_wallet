import 'dart:io';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/store/dashboard/orders_store.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPage extends BasePage {
  WebViewPage({@required this.ordersStore, @required this.url});

  final OrdersStore ordersStore;
  final String url;

  @override
  String get title => S.current.buy;

  @override
  Widget body(BuildContext context) =>
      WebViewPageBody(ordersStore: ordersStore,url: url);
}

class WebViewPageBody extends StatefulWidget {
  WebViewPageBody({this.ordersStore, this.url});

  final OrdersStore ordersStore;
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
    widget.ordersStore.orderId = '';

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
            widget.ordersStore.orderId = orderId;
          }

          return NavigationDecision.navigate;
        });
  }
}
