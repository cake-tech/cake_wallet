import 'package:chatwoot_sdk/chatwoot_sdk.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';

class SupportChatPage extends BasePage {
  final chatwootBaseUrl = "https://support.cakewallet.com";
  final chatwootInboxIdentifier = "kyUCS2fX2xnPSRrtTixPyJWu";

  @override
  String get title => S.current.settings_support;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.regular;

  @override
  Widget body(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        gradient: LinearGradient(colors: [
          Theme.of(context).primaryTextTheme.titleMedium!.color!,
          Theme.of(context).primaryTextTheme.titleMedium!.decorationColor!,
        ], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: ChatwootWidget(
        baseUrl: chatwootBaseUrl,
        websiteToken: chatwootInboxIdentifier,
      ),
    );
  }
}
