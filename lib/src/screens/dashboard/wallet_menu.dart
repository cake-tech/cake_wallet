import 'package:flutter/material.dart';
import 'package:cake_wallet/routes.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';

// FIXME: terrible design

class WalletMenu {
  WalletMenu(this.context, this.reconnect);

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
    Image.asset('assets/images/reconnect_menu.png', height: 16, width: 16),
    Image.asset('assets/images/wallet_menu.png', height: 16, width: 16),
    Image.asset('assets/images/nodes_menu.png', height: 16, width: 16),
    Image.asset('assets/images/eye_menu.png', height: 16, width: 16),
    Image.asset('assets/images/key_menu.png', height: 16, width: 16),
    Image.asset('assets/images/open_book_menu.png', height: 16, width: 16),
    Image.asset('assets/images/settings_menu.png', height: 16, width: 16),
  ];

  final BuildContext context;
  final Future<void> Function() reconnect;

  void action(int index) {
    switch (index) {
      case 0:
        _presentReconnectAlert(context);
        break;
      case 1:
        Navigator.of(context).pushNamed(Routes.walletList);
        break;
      case 2:
        Navigator.of(context).pushNamed(Routes.nodeList);
        break;
      case 3:
        Navigator.of(context).pushNamed(Routes.auth,
            arguments: (bool isAuthenticatedSuccessfully, AuthPageState auth) =>
                isAuthenticatedSuccessfully
                    ? Navigator.of(auth.context).popAndPushNamed(Routes.seed, arguments: false)
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
    await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertWithTwoActions(
              alertTitle: S.of(context).reconnection,
              alertContent: S.of(context).reconnect_alert_text,
              rightButtonText: S.of(context).ok,
              leftButtonText: S.of(context).cancel,
              actionRightButton: () async {
                await reconnect?.call();
                Navigator.of(context).pop();
              },
              actionLeftButton: () => Navigator.of(context).pop());
        });
  }
}
