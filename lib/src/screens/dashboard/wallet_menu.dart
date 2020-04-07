import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';

class WalletMenu {
  WalletMenu(this.context, this.walletStore) {
    switch (walletStore.walletType) {
      case WalletType.monero:
        items = [
          S.current.reconnect,
          S.current.rescan,
          S.current.wallets,
          S.current.show_seed,
          S.current.show_keys,
          S.current.accounts,
          S.current.address_book_menu
        ];
        break;
      case WalletType.bitcoin:
        items = [
          S.current.reconnect,
          S.current.rescan,
          S.current.wallets,
          S.current.show_seed,
          S.current.show_keys,
          S.current.address_book_menu
        ];
        break;
      case WalletType.none:
        items = [];
        break;
    }
  }

  final BuildContext context;
  final WalletStore walletStore;
  List<String> items;

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
        walletStore.walletType == WalletType.monero
        ? Navigator.of(context).pushNamed(Routes.accountList)
        : Navigator.of(context).pushNamed(Routes.addressBook);
        break;
      case 6:
        Navigator.of(context).pushNamed(Routes.addressBook);
        break;
      default:
        break;
    }
  }

  Future<void> _presentReconnectAlert(BuildContext context) async {
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
