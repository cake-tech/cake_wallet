import 'dart:async';
import 'dart:io';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/view_model/yat_view_model.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum YatMode {create, connect}

class YatWebViewPage extends BasePage {
  YatWebViewPage({this.yatViewModel, this.mode});

  final YatMode mode;
  final YatViewModel yatViewModel;

  @override
  String get title => 'Yat';

  @override
  Color get backgroundDarkColor => Colors.white;

  @override
  Color get titleColor => Palette.darkBlueCraiola;

  @override
  Widget body(BuildContext context) => YatWebViewPageBody(yatViewModel, mode);
}

class YatWebViewPageBody extends StatefulWidget{
  YatWebViewPageBody(this.yatViewModel, this.mode);

  final YatMode mode;
  final YatViewModel yatViewModel;

  @override
  YatWebViewPageBodyState createState() =>
      YatWebViewPageBodyState(yatViewModel, mode);
}

class YatWebViewPageBodyState extends State<YatWebViewPageBody> {
  YatWebViewPageBodyState(this.yatViewModel, this.mode) {
    switch (mode) {
      case YatMode.create:
        url = _baseUrl + _createSuffix;
        break;
      case YatMode.connect:
        url = _baseUrl + _signInSuffix;
        break;
      default:
        url = _baseUrl + _createSuffix;
    }
  }

  static const _baseUrl = 'https://yat.fyi';
  static const _signInSuffix = '/sign-in';
  static const _createSuffix = '/create';

  final YatMode mode;
  final YatViewModel yatViewModel;

  String url;
  WebViewController _webViewController;
  GlobalKey _webViewkey;
  Timer _timer;

  @override
  void initState() {
    super.initState();
    _webViewkey = GlobalKey();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
    _fetchYatInfo();
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return WebView(
        key: _webViewkey,
        initialUrl: url,
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController controller) =>
            setState(() => _webViewController = controller));
  }

  void _fetchYatInfo() {
    final keyword = 'dashboard';
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {

      try {
        if (_webViewController == null) {
          return;
        }

        final url = await _webViewController.currentUrl();
        print('URL = $url');
        if (url.contains(keyword)) {
          timer.cancel();
          await yatViewModel.fetchCartInfo();
        }
      } catch (e) {
        print(e);
      }
    });
  }
}