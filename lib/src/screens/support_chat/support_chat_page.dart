import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/support_chat/widgets/chatwoot_widget.dart';
import 'package:cake_wallet/view_model/support_view_model.dart';
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
          if (snapshot.hasData)
            return ChatwootWidget(
              secureStorage,
              supportUrl: supportViewModel.fetchUrl(authToken: snapshot.data!),
              appVersion: supportViewModel.appVersion,
              fiatApiMode: supportViewModel.fiatApiMode,
              walletType: supportViewModel.walletType,
              walletSyncState: supportViewModel.walletSyncState,
              builtInTorState: supportViewModel.builtInTorState,
            );
          return Container();
        },
      );

  Future<String> getCookie() async =>
      await secureStorage.read(key: COOKIE_KEY) ?? "";
}
