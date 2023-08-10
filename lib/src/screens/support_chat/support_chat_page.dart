import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/support_chat/widgets/chatwoot_widget.dart';
import 'package:cake_wallet/view_model/support_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class SupportChatPage extends BasePage {
  SupportChatPage(this.supportViewModel, {required this.secureStorage});

  final SupportViewModel supportViewModel;
  final FlutterSecureStorage secureStorage;

  @override
  String get title => S.current.settings_support;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.regular;

  @override
  Widget body(BuildContext context) => FutureBuilder<String>(
        future: getCookie(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          print(snapshot.data);
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
