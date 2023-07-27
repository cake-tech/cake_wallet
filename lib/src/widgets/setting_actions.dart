import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:flutter/material.dart';

class SettingActions {
  final String Function(BuildContext) name;
  final String image;
  final void Function(BuildContext) onTap;

  SettingActions._({
    required this.name,
    required this.image,
    required this.onTap,
  });

  static List<SettingActions> all = [
    connectionSettingAction,
    walletSettingAction,
    addressBookSettingAction,
    securityBackupSettingAction,
    privacySettingAction,
    displaySettingAction,
    otherSettingAction,
    supportSettingAction,
  ];

  static List<SettingActions> desktopSettings = [
    connectionSettingAction,
    walletSettingAction,
    addressBookSettingAction,
    securityBackupSettingAction,
    privacySettingAction,
    displaySettingAction,
    otherSettingAction,
    supportSettingAction,
  ];

  static SettingActions connectionSettingAction = SettingActions._(
    name: (context) => S.of(context).connection_sync,
    image: 'assets/images/nodes_menu.png',
    onTap: (BuildContext context) {
      Navigator.pop(context);
      Navigator.of(context).pushNamed(Routes.connectionSync);
    },
  );

  static SettingActions walletSettingAction = SettingActions._(
    name: (context) => S.of(context).wallets,
    image: 'assets/images/wallet_menu.png',
    onTap: (BuildContext context) {
      Navigator.pop(context);
      Navigator.of(context).pushNamed(Routes.walletList);
    },
  );

  static SettingActions addressBookSettingAction = SettingActions._(
    name: (context) => S.of(context).address_book_menu,
    image: 'assets/images/open_book_menu.png',
    onTap: (BuildContext context) {
      Navigator.pop(context);
      Navigator.of(context).pushNamed(Routes.addressBook);
    },
  );

  static SettingActions securityBackupSettingAction = SettingActions._(
    name: (context) => S.of(context).security_and_backup,
    image: 'assets/images/key_menu.png',
    onTap: (BuildContext context) {
      Navigator.pop(context);
      Navigator.of(context).pushNamed(Routes.securityBackupPage);
    },
  );

  static SettingActions privacySettingAction = SettingActions._(
    name: (context) => S.of(context).privacy,
    image: 'assets/images/privacy_menu.png',
    onTap: (BuildContext context) {
      Navigator.pop(context);
      Navigator.of(context).pushNamed(Routes.privacyPage);
    },
  );

  static SettingActions displaySettingAction = SettingActions._(
    name: (context) => S.of(context).display_settings,
    image: 'assets/images/eye_menu.png',
    onTap: (BuildContext context) {
      Navigator.pop(context);
      Navigator.of(context).pushNamed(Routes.displaySettingsPage);
    },
  );

  static SettingActions otherSettingAction = SettingActions._(
    name: (context) => S.of(context).other_settings,
    image: 'assets/images/settings_menu.png',
    onTap: (BuildContext context) {
      Navigator.pop(context);
      Navigator.of(context).pushNamed(Routes.otherSettingsPage);
    },
  );

  static SettingActions supportSettingAction = SettingActions._(
    name: (context) => S.of(context).settings_support,
    image: 'assets/images/question_mark.png',
    onTap: (BuildContext context) {
      Navigator.pop(context);
      Navigator.of(context).pushNamed(Routes.support);
    },
  );
}
