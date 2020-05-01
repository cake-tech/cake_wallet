import 'package:flutter/material.dart';
import 'package:cake_wallet/routes.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';

class WalletMenu {
  WalletMenu(this.context);

  final List<String> items = [
    S.current.reconnect,
    S.current.wallets,
    S.current.nodes,
    S.current.show_seed,
    S.current.show_keys,
    S.current.address_book_menu,
    S.current.settings_title
  ];

  final List<Image> images = [
    Image.asset('assets/images/reconnect.png'),
    Image.asset('assets/images/wallet.png'),
    Image.asset('assets/images/nodes.png'),
    Image.asset('assets/images/eye.png'),
    Image.asset('assets/images/key.png'),
    Image.asset('assets/images/open_book.png'),
    Image.asset('assets/images/settings.png'),
  ];

  final BuildContext context;

  void action(int index) {
    switch (index) {
      case 0:
        _presentReconnectAlert(context);
        break;
      case 1:
        Navigator.of(context).pushNamed(Routes.walletList);
        break;
      case 2:
        // FIXME: apply Nodes
        break;
      case 3:
        Navigator.of(context).pushNamed(Routes.auth,
            arguments: (bool isAuthenticatedSuccessfully, AuthPageState auth) =>
                isAuthenticatedSuccessfully
                    ? Navigator.of(auth.context).popAndPushNamed(Routes.seed)
                    : null);

        break;
      case 4:
        Navigator.of(context).pushNamed(Routes.auth,
            arguments: (bool isAuthenticatedSuccessfully, AuthPageState auth) =>
                isAuthenticatedSuccessfully
                    ? Navigator.of(auth.context)
                        .popAndPushNamed(Routes.showKeys)
                    : null);
        break;
      case 5:
        Navigator.of(context).pushNamed(Routes.addressBook);
        break;
      case 6:
        Navigator.of(context).pushNamed(Routes.settings);
        break;
      default:
        break;
    }
  }

  Future<void> _presentReconnectAlert(BuildContext context) async {
    final walletStore = Provider.of<WalletStore>(context);

    await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              S.of(context).reconnection,
              textAlign: TextAlign.center,
            ),
            content: Text(S.of(context).reconnect_alert_text),
            actions: <Widget>[
              FlatButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(S.of(context).cancel)),
              FlatButton(
                  onPressed: () {
                    walletStore.reconnect();
                    Navigator.of(context).pop();
                  },
                  child: Text(S.of(context).ok))
            ],
          );
        });
  }
}
