import 'dart:convert';

import 'package:cake_wallet/core/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

const COOKIE_KEY = 'chatwootCookie';

class ChatwootWidget extends StatefulWidget {
  ChatwootWidget(this.secureStorage, {required this.supportUrl});

  final SecureStorage secureStorage;
  final String supportUrl;

  @override
  ChatwootWidgetState createState() => ChatwootWidgetState();
}

class ChatwootWidgetState extends State<ChatwootWidget> {
  final GlobalKey _webViewkey = GlobalKey();

  @override
  Widget build(BuildContext context) => InAppWebView(
        key: _webViewkey,
    initialSettings: InAppWebViewSettings(
      transparentBackground: true,
    ),
        initialUrlRequest: URLRequest(url: WebUri(widget.supportUrl)),
        onWebViewCreated: (InAppWebViewController controller) {
          controller.addWebMessageListener(
            WebMessageListener(
              jsObjectName: 'ReactNativeWebView',
              onPostMessage: (WebMessage? message, WebUri? sourceOrigin, bool isMainFrame,
                  PlatformJavaScriptReplyProxy replyProxy) {
                final shortenedMessage = message?.data.toString().substring(16);
                if (shortenedMessage != null && isJsonString(shortenedMessage)) {
                  final parsedMessage = jsonDecode(shortenedMessage);
                  final eventType = parsedMessage["event"];
                  if (eventType == 'loaded') {
                    final authToken = parsedMessage["config"]["authToken"];
                    print(authToken);
                    storeCookie(authToken as String);
                  }
                }
              },
            ),
          );
        },
      );

  bool isJsonString(String str) {
    try {
      jsonDecode(str);
    } catch (e) {
      return false;
    }
    return true;
  }

  Future<void> storeCookie(String value) async {
    await widget.secureStorage.write(key: COOKIE_KEY, value: value);
  }
}
