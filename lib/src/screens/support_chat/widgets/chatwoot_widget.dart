import 'dart:convert';

import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/src/screens/support_chat/support_chat_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

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

  String get _allowedHost => Uri.parse(widget.supportUrl).host;

  Future<NavigationActionPolicy> _policyFor(Uri? url, {required bool isMainFrame}) async {
    final decision = decideSupportChatNavigation(
      request: url,
      isMainFrame: isMainFrame,
      allowedHost: _allowedHost,
    );
    if (decision == SupportChatNavigation.openOutside && url != null) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    if (decision == SupportChatNavigation.allow) {
      return NavigationActionPolicy.ALLOW;
    }
    return NavigationActionPolicy.CANCEL;
  }

  @override
  Widget build(BuildContext context) => InAppWebView(
        key: _webViewKey,
        initialSettings: InAppWebViewSettings(
          transparentBackground: true,
          useShouldOverrideUrlLoading: true,
          supportMultipleWindows: true,
        ),
        initialUrlRequest: URLRequest(url: WebUri(widget.supportUrl)),
        shouldOverrideUrlLoading: (controller, navigationAction) {
          return _policyFor(
            navigationAction.request.url,
            isMainFrame: navigationAction.isForMainFrame,
          );
        },
        onCreateWindow: (controller, createWindowAction) async {
          final url = createWindowAction.request.url;
          final decision = decideSupportChatPopup(
            request: url,
            allowedHost: _allowedHost,
          );
          if (decision == SupportChatNavigation.openOutside && url != null) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
          return false;
        },
        onWebViewCreated: (InAppWebViewController controller) {
          controller.addWebMessageListener(
            WebMessageListener(
              jsObjectName: 'ReactNativeWebView',
              onPostMessage: (WebMessage? message, WebUri? sourceOrigin, bool isMainFrame,
                  PlatformJavaScriptReplyProxy replyProxy) {
                final shortenedMessage = message?.data.toString().substring(16);
                if (shortenedMessage != null && _isJsonString(shortenedMessage)) {
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
