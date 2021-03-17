import 'dart:async';
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
  WebViewController webViewController;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return WebView(
      initialUrl: widget.url,
      javascriptMode: JavascriptMode.unrestricted,
      onWebViewCreated: (WebViewController controller) {
        setState(() => webViewController = controller);
      },
      javascriptChannels: <JavascriptChannel>{
        JavascriptChannel(
          name: 'Echo',
          onMessageReceived: (JavascriptMessage message) {
            webViewController.evaluateJavascript("console.log('test callback');");
          },
        ),
      },
      /*onPageFinished: (url) {
        webViewController.evaluateJavascript("alert('Test alert');");
      },*/
    );
  }
}