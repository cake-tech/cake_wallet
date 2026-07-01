import 'dart:convert';

import 'package:cake_wallet/core/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

const COOKIE_KEY = 'chatwootCookie';

class ChatwootWidget extends StatefulWidget {
  const ChatwootWidget(
    this.secureStorage, {
    required this.supportUrl,
    required this.appVersion,
    required this.fiatApiMode,
    required this.walletType,
    required this.walletSyncState,
    required this.builtInTorState,
  });

  final SecureStorage secureStorage;
  final String supportUrl;
  final String appVersion;
  final String fiatApiMode;
  final String walletType;
  final String walletSyncState;
  final String builtInTorState;

  @override
  ChatwootWidgetState createState() => ChatwootWidgetState();
}

class ChatwootWidgetState extends State<ChatwootWidget> {
  final GlobalKey _webViewKey = GlobalKey();

  @override
  Widget build(BuildContext context) => InAppWebView(
        key: _webViewKey,
        initialSettings: InAppWebViewSettings(transparentBackground: true),
        initialUrlRequest: URLRequest(url: WebUri(widget.supportUrl)),
        onWebViewCreated: (InAppWebViewController controller) {
          controller.addWebMessageListener(
            WebMessageListener(
              jsObjectName: 'ReactNativeWebView',
              onPostMessage: (WebMessage? message, WebUri? sourceOrigin,
                  bool isMainFrame, PlatformJavaScriptReplyProxy replyProxy) {
                final shortenedMessage = message?.data.toString().substring(16);
                if (shortenedMessage != null &&
                    _isJsonString(shortenedMessage)) {
                  final parsedMessage = jsonDecode(shortenedMessage);
                  final eventType = parsedMessage["event"];
                  if (eventType == 'loaded') {
                    final authToken = parsedMessage["config"]["authToken"];
                    _storeCookie(authToken as String);
                    _setCustomAttributes(controller, {
                      "app_version": widget.appVersion,
                      "fiat_api_mode": widget.fiatApiMode,
                      "wallet_type": widget.walletType,
                      "wallet_sync_state": widget.walletSyncState,
                      "built_in_tor": widget.builtInTorState,
                    });
                  }
                }
              },
            ),
          );
        },
      );

  bool _isJsonString(String str) {
    try {
      jsonDecode(str);
    } catch (e) {
      return false;
    }
    return true;
  }

  /// Add additional contact attributes to the chatwoot chat.
  /// IMPORTANT: You have to add the attribute key in the chatwoot settings
  ///            under: settings/custom-attributes
  Future<void> _setCustomAttributes(
    InAppWebViewController controller,
    Map<String, dynamic> customAttributes,
  ) {
    final attributeObject = {
      "event": "set-custom-attributes",
      "customAttributes": customAttributes,
    };
    return controller.postWebMessage(
      message: WebMessage(
        data: "chatwoot-widget:${jsonEncode(attributeObject)}",
      ),
    );
  }

  Future<void> _storeCookie(String value) =>
      widget.secureStorage.write(key: COOKIE_KEY, value: value);
}
