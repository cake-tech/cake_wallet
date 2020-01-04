import 'package:flutter/material.dart';
import 'package:cake_wallet/routes.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:cake_wallet/generated/i18n.dart';

class WalletMenu {
  final List<String> items = [
    S.current.reconnect,
    S.current.rescan,
    S.current.wallets,
    S.current.show_seed,
    S.current.show_keys,
    S.current.accounts,
    S.current.address_book_menu
  ];
  final BuildContext context;

  WalletMenu(this.context);

  void action(int index) {
    switch (index) {
      case 0:
        _presentReconnectAlert(context);
        break;
      case 1:
        Navigator.of(context).pushNamed(Routes.rescan);
        break;
      case 2:
        Navigator.of(context).pushNamed(Routes.walletList);

        break;
      case 3:
        Navigator.of(context).pushNamed(Routes.auth,
            arguments: (isAuthenticatedSuccessfully, auth) =>
                isAuthenticatedSuccessfully
                    ? Navigator.of(auth.context).popAndPushNamed(Routes.seed)
                    : null);

        break;
      case 4:
        Navigator.of(context).pushNamed(Routes.auth,
            arguments: (isAuthenticatedSuccessfully, auth) =>
                isAuthenticatedSuccessfully
                    ? Navigator.of(auth.context)
                        .popAndPushNamed(Routes.showKeys)
                    : null);
        break;
      case 5:
        Navigator.of(context).pushNamed(Routes.accountList);
        break;
      case 6:
        Navigator.of(context).pushNamed(Routes.addressBook);
        break;
      default:
        break;
    }
  }

  Future _presentReconnectAlert(BuildContext context) async {
    final walletStore = Provider.of<WalletStore>(context);

    await showDialog(
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
