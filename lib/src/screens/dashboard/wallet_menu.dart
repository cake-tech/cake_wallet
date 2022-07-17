import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/screens/dashboard/wallet_menu_item.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/wallet_type_utils.dart';

// FIXME: terrible design

class WalletMenu {
  WalletMenu(this.context, this.reconnect, this.hasRescan) : items = [] {
    items.addAll([
      WalletMenuItem(
          title: S.current.reconnect,
          image: Image.asset('assets/images/reconnect_menu.png',
              height: 16, width: 16),
	  handler: () => _presentReconnectAlert(context)),
      if (hasRescan)
        WalletMenuItem(
            title: S.current.rescan,
            image: Image.asset('assets/images/filter_icon.png',
                height: 16, width: 16, color: Palette.darkBlue),
	    handler: () => Navigator.of(context).pushNamed(Routes.rescan)),
      WalletMenuItem(
          title: S.current.wallets,
          image: Image.asset('assets/images/wallet_menu.png',
              height: 16, width: 16),
	  handler: () => Navigator.of(context).pushNamed(Routes.walletList)),
      WalletMenuItem(
          title: S.current.nodes,
          image: Image.asset('assets/images/nodes_menu.png',
              height: 16, width: 16),
	  handler: () => Navigator.of(context).pushNamed(Routes.nodeList)),
      WalletMenuItem(
          title: S.current.show_keys,
          image:
              Image.asset('assets/images/key_menu.png', height: 16, width: 16),
	  handler: () {
	  Navigator.of(context).pushNamed(Routes.auth,
            arguments: (bool isAuthenticatedSuccessfully, AuthPageState auth) {
            if (isAuthenticatedSuccessfully) {
             auth.close();
		Navigator.of(auth.context).pushNamed(Routes.showKeys);
            }
          });
	}),
      WalletMenuItem(
          title: S.current.address_book_menu,
          image: Image.asset('assets/images/open_book_menu.png',
              height: 16, width: 16),
	  handler: () => Navigator.of(context).pushNamed(Routes.addressBook)),
      WalletMenuItem(
          title: S.current.settings_title,
          image: Image.asset('assets/images/settings_menu.png',
              height: 16, width: 16),
	  handler: () => Navigator.of(context).pushNamed(Routes.settings)),
      WalletMenuItem(
          title: S.current.settings_support,
          image: Image.asset('assets/images/question_mark.png',
              height: 16, width: 16, color: Palette.darkBlue),
	  handler: () => Navigator.of(context).pushNamed(Routes.support)),
    ]);
  }

  final List<WalletMenuItem> items;
  final BuildContext context;
  final Future<void> Function() reconnect;
  final bool hasRescan;

  void action(int index) {
    final item = items[index];
    item?.handler();
  }

  Future<void> _presentReconnectAlert(BuildContext context) async {
    await showPopUp<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertWithTwoActions(
              alertTitle: S.of(context).reconnection,
              alertContent: S.of(context).reconnect_alert_text,
              rightButtonText: S.of(context).ok,
              leftButtonText: S.of(context).cancel,
              actionRightButton: () async {
                Navigator.of(context).pop();
                await reconnect?.call();
              },
              actionLeftButton: () => Navigator.of(context).pop());
        });
  }
}
