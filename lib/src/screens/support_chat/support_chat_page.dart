import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/support_chat/widgets/chatwoot_widget.dart';
import 'package:cake_wallet/view_model/support_view_model.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:flutter/material.dart';


class SupportChatPage extends BasePage {
  SupportChatPage(this.supportViewModel, {required this.secureStorage});

  final SupportViewModel supportViewModel;
  final SecureStorage secureStorage;

  @override
  String get title => S.current.settings_support;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.regular;

  @override
  Widget body(BuildContext context) => FutureBuilder<String>(
        future: getCookie(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          printV(snapshot.data);
          if (snapshot.hasData)
            return ChatwootWidget(
              secureStorage,
              supportUrl: supportViewModel.fetchUrl(authToken: snapshot.data!)
            );
          return Container();
        },
      );

  Future<String> getCookie() async {
    return await secureStorage.read(key: COOKIE_KEY) ?? "";
  }
}
