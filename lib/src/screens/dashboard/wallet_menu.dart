import 'package:cake_wallet/src/screens/dashboard/wallet_menu_item.dart';
import 'package:cake_wallet/src/widgets/setting_actions.dart';
import 'package:flutter/material.dart';

// FIXME: terrible design

class WalletMenu {
  WalletMenu._();

  static List<WalletMenuItem> items = [
    WalletMenuItem(
      title: SettingActions.connectionSettingAction.name,
      image: SettingActions.connectionSettingAction.image,
      handler: (BuildContext context) => SettingActions.connectionSettingAction.onTap(context),
    ),
    WalletMenuItem(
      title: SettingActions.walletSettingAction.name,
      image: SettingActions.walletSettingAction.image,
      handler: (BuildContext context) => SettingActions.walletSettingAction.onTap(context),
    ),
    WalletMenuItem(
      title: SettingActions.addressBookSettingAction.name,
      image: SettingActions.addressBookSettingAction.image,
      handler: (BuildContext context) => SettingActions.addressBookSettingAction.onTap(context),
    ),
    WalletMenuItem(
      title: SettingActions.securityBackupSettingAction.name,
      image: SettingActions.securityBackupSettingAction.image,
      handler: (BuildContext context) => SettingActions.securityBackupSettingAction.onTap(context),
    ),
    WalletMenuItem(
      title: SettingActions.privacySettingAction.name,
      image: SettingActions.privacySettingAction.image,
      handler: (BuildContext context) => SettingActions.privacySettingAction.onTap(context),
    ),
    WalletMenuItem(
      title: SettingActions.displaySettingAction.name,
      image: SettingActions.displaySettingAction.image,
      handler: (BuildContext context) => SettingActions.displaySettingAction.onTap(context),
    ),
    WalletMenuItem(
      title: SettingActions.otherSettingAction.name,
      image: SettingActions.otherSettingAction.image,
      handler: (BuildContext context) => SettingActions.otherSettingAction.onTap(context),
    ),
    WalletMenuItem(
      title: SettingActions.supportSettingAction.name,
      image: SettingActions.supportSettingAction.image,
      handler: (BuildContext context) => SettingActions.supportSettingAction.onTap(context),
    ),
  ];

  static void action(int index, BuildContext context) {
    final item = items[index];
    item.handler(context);
  }
}
