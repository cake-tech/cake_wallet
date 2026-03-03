import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/modal_navigator.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import "package:cw_core/wallet_type.dart";

bool _trueFunc(DashboardViewModel _) => true;

bool _falseFunc(DashboardViewModel _) => false;

bool _isBtc(DashboardViewModel vm) => vm.wallet.type == WalletType.bitcoin;

bool _hasMweb(DashboardViewModel vm) => vm.hasMweb;

bool _isCupcake(DashboardViewModel vm) => vm.wallet.hardwareWalletType == HardwareWalletType.cupcake;

class SettingsListItem {
  final String iconPath;
  final String title;
  final String route;
  final Object? routeArgs;
  final bool requireAuth;
  final bool Function(DashboardViewModel) use2fa;
  final bool Function(DashboardViewModel) condition;

  const SettingsListItem(this.iconPath, this.title, this.route, {this.routeArgs = null, this.requireAuth = false, this.use2fa = _falseFunc, this.condition = _trueFunc});
}

class SettingsSectionData {
  final String title;
  final String titleIconPath;
  final List<SettingsListItem> items;

  const SettingsSectionData(this.title, this.titleIconPath, this.items);

  static SettingsSectionData walletSettings =
      SettingsSectionData(S.current.wallet_settings, "assets/new-ui/wallet_settings.svg", [
    SettingsListItem("assets/new-ui/settings_row_icons/nodes.svg", S.current.nodes, Routes.manageNodes),
    SettingsListItem("assets/new-ui/settings_row_icons/privacy.svg", S.current.privacy, Routes.privacyPage),
    SettingsListItem("assets/new-ui/settings_row_icons/seed.svg", S.current.seed_and_keys, Routes.showKeys,
        routeArgs: true, requireAuth: true, use2fa: (vm)=>vm.settingsStore.shouldRequireTOTP2FAForAllSecurityAndBackupSettings),
    SettingsListItem("assets/new-ui/settings_row_icons/lightning_username.svg",
        "Lightning ${S.current.username}", Routes.lightningUsernamePage, condition: _isBtc),
    SettingsListItem("assets/new-ui/settings_row_icons/silent-payments.svg", S.current.silent_payments_settings, Routes.silentPaymentsSettings, condition: _isBtc),
    SettingsListItem("assets/new-ui/settings_row_icons/mweb.svg", S.current.litecoin_mweb_settings, Routes.mwebSettings, condition: _hasMweb),
    SettingsListItem("assets/new-ui/settings_row_icons/cupcake.svg", S.current.export_outputs, Routes.urqrAnimatedPage, routeArgs: {'export-outputs': 'export-outputs'}, condition: _isCupcake),
    SettingsListItem("assets/new-ui/settings_row_icons/other.svg", S.current.other, Routes.otherSettingsPage),
  ]);

  static SettingsSectionData appSettings =
      SettingsSectionData(S.current.app_settings, "assets/new-ui/app_settings.svg", [
    SettingsListItem("assets/new-ui/settings_row_icons/connections.svg", S.current.connections, Routes.connectionSync),
    // SettingsListItem("assets/new-ui/settings_row_icons/defaults.svg", "Defaults", ""),
    SettingsListItem("assets/new-ui/settings_row_icons/display.svg", S.current.display, Routes.displaySettingsPage),
    SettingsListItem("assets/new-ui/settings_row_icons/security.svg", S.current.security, Routes.securityBackupPage),
    SettingsListItem("assets/new-ui/settings_row_icons/backup.svg", S.current.backup, Routes.backup, requireAuth: true, use2fa: (vm)=>vm.settingsStore.shouldRequireTOTP2FAForAllSecurityAndBackupSettings),
  ]);

  static SettingsSectionData otherSettings = SettingsSectionData("", "", [
    SettingsListItem("assets/new-ui/settings_row_icons/support.svg", S.current.settings_support, Routes.support),
    SettingsListItem("assets/new-ui/settings_row_icons/info.svg", S.current.about, Routes.aboutPage),
  ]);

  static List<SettingsSectionData> all = [walletSettings, appSettings, otherSettings];
}

class NewSettingsPage extends StatelessWidget {
  const NewSettingsPage({super.key, required this.dashboardViewModel, required this.authService});

  final DashboardViewModel dashboardViewModel;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return ModalNavigator(
        parentContext: context,
        rootPage: SettingsMainPage(
          dashboardViewModel: dashboardViewModel,
          authService: authService,
        ));
  }
}

class SettingsMainPage extends StatelessWidget {
  const SettingsMainPage({super.key, required this.dashboardViewModel, required this.authService});

  final DashboardViewModel dashboardViewModel;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    Map<String, List<ListItem>> sections =
        Map.fromEntries(SettingsSectionData.all.map((section) => MapEntry(
            section.title,
            section.items
                .map((item) => item.condition(dashboardViewModel)
                    ? ListItemRegularRow(
                        keyValue: item.title,
                        label: item.title,
                        iconPath: item.iconPath,
                        onTap: () {
                          if (item.route.isNotEmpty) {
                            if(item.requireAuth) {
                              authService.authenticateAction(context,
                                  conditionToDetermineIfToUse2FA: item.use2fa(dashboardViewModel),
                                  route: item.route);
                            } else {
                              Navigator.of(context).pushNamed(item.route, arguments: item.routeArgs);
                            }
                          }
                        })
                    : null)
                .whereType<ListItem>()
                .toList())));

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(children: [
        ModalTopBar(
          title: "Settings",
          leadingIcon: Icon(Icons.close),
          onLeadingPressed: Navigator.of(context, rootNavigator: true).pop,
          onTrailingPressed: () {},
        ),
        Expanded(
          child: ListView(
            controller: ModalScrollController.of(context),
            children: [Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
              child: NewListSections(
                sections: sections,
              ),
            ),]
          ),
        ),
      ]),
    );
  }
}