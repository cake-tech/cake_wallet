import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/screens/dashboard/wallet_menu_item.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';

// FIXME: terrible design

class WalletMenu {
  WalletMenu(this.context, this.reconnect, this.hasRescan) : items = [] {
    items.addAll([
    WalletMenuItem(
      title: S.current.connection_sync,
      image: Image.asset('assets/images/nodes_menu.png',
          height: 16, width: 16),
      handler: () => Navigator.of(context).pushNamed(Routes.connectionSync),
    ),
    WalletMenuItem(
      title: S.current.wallets,
      image: Image.asset('assets/images/wallet_menu.png',
          height: 16, width: 16),
      handler: () => Navigator.of(context).pushNamed(Routes.walletList),
    ),
    WalletMenuItem(
      title: S.current.security_and_backup,
      image:
          Image.asset('assets/images/key_menu.png', height: 16, width: 16),
      handler: () {
      Navigator.of(context).pushNamed(Routes.securityBackupPage);
	  }),
    WalletMenuItem(
      title: S.current.privacy,
      image:
          Image.asset('assets/images/eye_menu.png', height: 16, width: 16),
      handler: () {
      Navigator.of(context).pushNamed(Routes.privacyPage);
	  }),
    WalletMenuItem(
      title: S.current.address_book_menu,
      image: Image.asset('assets/images/open_book_menu.png',
      height: 16, width: 16),
      handler: () => Navigator.of(context).pushNamed(Routes.addressBook),
    ),
    WalletMenuItem(
      title: S.current.display_settings,
      image: Image.asset('assets/images/eye_menu.png',
      height: 16, width: 16),
      handler: () => Navigator.of(context).pushNamed(Routes.displaySettingsPage),
    ),
    WalletMenuItem(
      title: S.current.other_settings,
      image: Image.asset('assets/images/settings_menu.png',
      height: 16, width: 16),
      handler: () => Navigator.of(context).pushNamed(Routes.otherSettingsPage),
    ),
    WalletMenuItem(
      title: S.current.settings_support,
      image: Image.asset('assets/images/question_mark.png',
      height: 16, width: 16, color: Palette.darkBlue),
      handler: () => Navigator.of(context).pushNamed(Routes.support),
    ),
    ]);
  }

  final List<WalletMenuItem> items;
  final BuildContext context;
  final Future<void> Function() reconnect;
  final bool hasRescan;

  void action(int index) {
    final item = items[index];
    item.handler();
  }
}
