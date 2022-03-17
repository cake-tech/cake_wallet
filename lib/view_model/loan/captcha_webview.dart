import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CaptchaWebview extends StatefulWidget {
  const CaptchaWebview({Key key});

  @override
  _CaptchaWebviewState createState() => _CaptchaWebviewState();
}

class _CaptchaWebviewState extends State<CaptchaWebview> {
  WebViewController _controller;

  @override
  Widget build(BuildContext context) {
    return WebView(
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (controller) {
          _controller = controller;
          _loadHtmlFromAssets();
        },
        javascriptChannels: Set.from([
          JavascriptChannel(
              name: 'Captcha',
              onMessageReceived: (JavascriptMessage message) {
                print(message.message);
              })
        ].toList()));
  }

  Future<void> _loadHtmlFromAssets() async {
    final fileText =
        await rootBundle.loadString('assets/webpages/captcha.html');
    await _controller.loadUrl(Uri.dataFromString(fileText,
            mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
        .toString());
  }
}
