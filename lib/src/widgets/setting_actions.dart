import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/ur/animated_ur_page.dart';
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
    exportOutputsAction,
    connectionSettingAction,
    walletSettingAction,
    addressBookSettingAction,
    silentPaymentsSettingAction,
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
    silentPaymentsSettingAction,
    securityBackupSettingAction,
    privacySettingAction,
    displaySettingAction,
    otherSettingAction,
    supportSettingAction,
  ];

  static SettingActions silentPaymentsSettingAction = SettingActions._(
    name: (context) => S.of(context).silent_payments_settings,
    image: 'assets/images/bitcoin_menu.png',
    onTap: (BuildContext context) {
      Navigator.pop(context);
      Navigator.of(context).pushNamed(Routes.silentPaymentsSettings);
    },
  );

  static SettingActions exportOutputsAction = SettingActions._(
    name: (context) => "Export outputs",
    image: 'assets/images/monero_menu.png',
    onTap: (BuildContext context) {
      Navigator.pop(context);
      Navigator.of(context).push(MaterialPageRoute(builder:(context) {
        return getIt.get<AnimatedURPage>(param1: 'export-outputs');
      },));
    },
  );

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
