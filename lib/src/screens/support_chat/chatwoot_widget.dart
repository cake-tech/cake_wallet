import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const COOKIE_KEY = 'chatwootCookie';

class ChatwootWidget extends StatefulWidget {
  ChatwootWidget(this.secureStorage,
      {required this.baseUrl,
      required this.websiteToken,
      this.locale = "en",
      this.authToken = ""});

  final FlutterSecureStorage secureStorage;
  final String baseUrl;
  final String websiteToken;
  final String locale;
  final String authToken;

  @override
  ChatwootWidgetState createState() => ChatwootWidgetState();
}

class ChatwootWidgetState extends State<ChatwootWidget> {
  final GlobalKey _webViewkey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    var chatwootUrl =
        "${widget.baseUrl}/widget?website_token=${widget.websiteToken}&locale=${widget.locale}";

    if (widget.authToken.isNotEmpty)
      chatwootUrl += "&cw_conversation=${widget.authToken}";

    return InAppWebView(
      key: _webViewkey,
      initialOptions: InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(transparentBackground: true),
      ),
      initialUrlRequest: URLRequest(url: Uri.tryParse(chatwootUrl)),
      onWebViewCreated: (InAppWebViewController controller) {
        controller.addWebMessageListener(
          WebMessageListener(
            jsObjectName: 'ReactNativeWebView',
            onPostMessage: (String? message, Uri? sourceOrigin, bool isMainFrame,
                JavaScriptReplyProxy replyProxy) {
              final shortenedMessage = message?.substring(16);
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
  }

  bool isJsonString(String str) {
    try {
      jsonDecode(str);
    } catch (e) {
      return false;
    }
    return true;
  }

  Future<void> storeCookie(String value) async =>
      await widget.secureStorage.write(key: COOKIE_KEY, value: value);
}
