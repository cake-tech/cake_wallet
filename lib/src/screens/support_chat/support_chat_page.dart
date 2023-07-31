import 'package:flutter/material.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'chatwoot_widget.dart';

class SupportChatPage extends BasePage {
  SupportChatPage({required this.secureStorage});

  final FlutterSecureStorage secureStorage;
  final chatwootBaseUrl = "https://support.cakewallet.com";
  final chatwootInboxIdentifier = "kyUCS2fX2xnPSRrtTixPyJWu";

  @override
  String get title => S.current.settings_support;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.regular;

  @override
  Widget body(BuildContext context) => FutureBuilder<String>(
        future: getCookie(), // a previously-obtained Future<String> or null
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          print(snapshot.data);
          if (snapshot.hasData)
            return ChatwootWidget(
              secureStorage,
              baseUrl: chatwootBaseUrl,
              websiteToken: chatwootInboxIdentifier,
              authToken: snapshot.data!,
            );
          return Container();
        },
      );

  Future<String> getCookie() async {
    return await secureStorage.read(key: COOKIE_KEY) ?? "";
  }
}
