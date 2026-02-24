import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/screens/support_chat/widgets/chatwoot_widget.dart';
import 'package:cake_wallet/view_model/support_view_model.dart';
import 'package:flutter/material.dart';

class SupportChatPage extends StatelessWidget {
  SupportChatPage(this.supportViewModel, {required this.secureStorage});

  final SupportViewModel supportViewModel;
  final SecureStorage secureStorage;


  @override
  Widget build(BuildContext context) => Container(
    color: Theme.of(context).colorScheme.surface,
    child: SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
                ModalTopBar(
                    title: S.current.settings_support,
                    leadingIcon: Icon(Icons.arrow_back_ios_new),
                    onLeadingPressed: Navigator.of(context).pop),
                FutureBuilder<String>(
                  future: getCookie(),
                  builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                    if (snapshot.hasData)
                      return Expanded(
                        child: ChatwootWidget(
                          secureStorage,
                          supportUrl: supportViewModel.fetchUrl(authToken: snapshot.data!),
                          appVersion: supportViewModel.appVersion,
                          fiatApiMode: supportViewModel.fiatApiMode,
                          walletType: supportViewModel.walletType,
                          walletSyncState: supportViewModel.walletSyncState,
                          builtInTorState: supportViewModel.builtInTorState,
                        ),
                      );
                    return Container();
                  },
                ),
          ],
        ),
      ),
    ),
  );

  Future<String> getCookie() async =>
      await secureStorage.read(key: COOKIE_KEY) ?? "";
}
