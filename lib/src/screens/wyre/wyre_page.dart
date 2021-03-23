import 'dart:io';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/store/dashboard/orders_store.dart';
import 'package:cake_wallet/view_model/wyre_view_model.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WyrePage extends BasePage {
  WyrePage(this.wyreViewModel, {@required this.ordersStore, @required this.url});

  final OrdersStore ordersStore;
  final String url;
  final WyreViewModel wyreViewModel;

  @override
  String get title => S.current.buy;

  @override
  Color get backgroundDarkColor => Colors.white;

  @override
  Color get titleColor => Palette.darkBlueCraiola;

  @override
  Widget body(BuildContext context) =>
      WyrePageBody(wyreViewModel, ordersStore: ordersStore,url: url);
}

class WyrePageBody extends StatefulWidget {
  WyrePageBody(this.wyreViewModel, {this.ordersStore, this.url});

  final OrdersStore ordersStore;
  final String url;
  final WyreViewModel wyreViewModel;

  @override
  WyrePageBodyState createState() => WyrePageBodyState();
}

class WyrePageBodyState extends State<WyrePageBody> {
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

            if (orderId.isNotEmpty) {
              await widget.wyreViewModel.saveOrder(orderId);
            }
          }

          return NavigationDecision.navigate;
        });
  }
}
