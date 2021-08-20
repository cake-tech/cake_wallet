import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/view_model/yat_view_model.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum YatMode {create, connect}

class YatWebViewPage extends BasePage {
  YatWebViewPage({this.yatViewModel, this.mode}) {
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

  static const _baseUrl = 'https://y.at';
  static const _signInSuffix = '/sign-in';
  static const _createSuffix = '/create';

  final YatMode mode;
  final YatViewModel yatViewModel;

  String url;

  @override
  String get title => 'Yat';

  @override
  Color get backgroundDarkColor => Colors.white;

  @override
  Color get titleColor => Palette.darkBlueCraiola;

  @override
  Widget body(BuildContext context) => WebView(
      initialUrl: url,
      javascriptMode: JavascriptMode.unrestricted);
}