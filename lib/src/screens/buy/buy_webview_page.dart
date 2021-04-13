import 'dart:async';
import 'dart:io';
import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/moonpay/moonpay_buy_provider.dart';
import 'package:cake_wallet/buy/wyre/wyre_buy_provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/store/dashboard/orders_store.dart';
import 'package:cake_wallet/view_model/buy/buy_view_model.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BuyWebViewPage extends BasePage {
  BuyWebViewPage(this.buyViewModel,
      {@required this.ordersStore, @required this.url});

  final OrdersStore ordersStore;
  final String url;
  final BuyViewModel buyViewModel;

  @override
  String get title => S.current.buy;

  @override
  Color get backgroundDarkColor => Colors.white;

  @override
  Color get titleColor => Palette.darkBlueCraiola;

  @override
  Widget body(BuildContext context) =>
      BuyWebViewPageBody(buyViewModel, ordersStore: ordersStore, url: url);
}

class BuyWebViewPageBody extends StatefulWidget {
  BuyWebViewPageBody(this.buyViewModel, {this.ordersStore, this.url});

  final OrdersStore ordersStore;
  final String url;
  final BuyViewModel buyViewModel;

  @override
  BuyWebViewPageBodyState createState() => BuyWebViewPageBodyState();
}

class BuyWebViewPageBodyState extends State<BuyWebViewPageBody> {
  String orderId;
  WebViewController _webViewController;
  GlobalKey _webViewkey;
  Timer _timer;
  bool _isSaving;
  BuyProvider _provider;

  @override
  void initState() {
    super.initState();
    _webViewkey = GlobalKey();
    _isSaving = false;
    widget.ordersStore.orderId = '';
    _provider = widget.buyViewModel.selectedProvider;

    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();

    if (_provider is WyreBuyProvider) {
      _timer?.cancel();
      _timer = Timer.periodic(Duration(seconds: 1), (timer) async {

        try {
          if (_webViewController == null || _isSaving) {
            return;
          }

          final url = await _webViewController.currentUrl();

          if (url.contains('completed')) {
            final urlParts = url.split('/');
            orderId = urlParts.last;
            widget.ordersStore.orderId = orderId;

            if (orderId.isNotEmpty) {
              _isSaving = true;
              await widget.buyViewModel.saveOrder(orderId);
              timer.cancel();
            }
          }
        } catch (e) {
          _isSaving = false;
          print(e);
        }
      });
    }

    if (_provider is MoonPayBuyProvider) {
      // FIXME: fetch orderId
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebView(
        key: _webViewkey,
        initialUrl: widget.url,
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController controller) =>
            setState(() => _webViewController = controller));
  }
}
