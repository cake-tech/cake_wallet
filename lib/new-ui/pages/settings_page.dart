import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/router.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/src/widgets/section_divider.dart';
import 'package:cake_wallet/view_model/settings/regular_list_item.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class SettingsListItem {
  final String iconPath;
  final String title;
  final String route;
  final Object? routeArgs;

  const SettingsListItem(this.iconPath, this.title, this.route, {this.routeArgs = null});
}

class SettingsSectionData {
  final String title;
  final String titleIconPath;
  final List<SettingsListItem> items;

  const SettingsSectionData(this.title, this.titleIconPath, this.items);

  static SettingsSectionData walletSettings =
      SettingsSectionData("Wallet Settings", "assets/new-ui/wallet_settings.svg", [
    SettingsListItem("assets/new-ui/settings_row_icons/nodes.svg", "Nodes", Routes.manageNodes),
    // SettingsListItem("assets/new-ui/settings_row_icons/privacy.svg", "Privacy features", ""),
    SettingsListItem("assets/new-ui/settings_row_icons/seed.svg", "Seed & keys", Routes.seed,
        routeArgs: true),
    SettingsListItem("assets/new-ui/settings_row_icons/other.svg", "Other", Routes.otherSettingsPage),
  ]);

  static SettingsSectionData appSettings =
      SettingsSectionData("App Settings", "assets/new-ui/app_settings.svg", [
    SettingsListItem("assets/new-ui/settings_row_icons/connections.svg", "Connections", Routes.connectionSync),
    // SettingsListItem("assets/new-ui/settings_row_icons/defaults.svg", "Defaults", ""),
    SettingsListItem("assets/new-ui/settings_row_icons/display.svg", "Display", Routes.displaySettingsPage),
    SettingsListItem("assets/new-ui/settings_row_icons/security.svg", "Privacy & Security", Routes.privacyPage),
    SettingsListItem("assets/new-ui/settings_row_icons/backup.svg", "Backup", Routes.backup),
  ]);

  static SettingsSectionData otherSettings = SettingsSectionData("", "", [
    SettingsListItem("assets/new-ui/settings_row_icons/support.svg", S.current.settings_support, Routes.support),
    // SettingsListItem("assets/new-ui/settings_row_icons/info.svg", "About", ""),
  ]);

  static List<SettingsSectionData> all = [walletSettings, appSettings, otherSettings];
}

class NewSettingsPage extends StatefulWidget {
  const NewSettingsPage({super.key});

  @override
  State<NewSettingsPage> createState() => _NewSettingsPageState();
}

class _NewSettingsPageState extends State<NewSettingsPage> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      left: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Theme(
          data: Theme.of(context).copyWith(
            pageTransitionsTheme: PageTransitionsTheme(
              builders: {
                // requested by ui - iphone-style back anim on every platform
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
                TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;

              final navigator = _navigatorKey.currentState;
              if (navigator != null && navigator.canPop()) {
                navigator.pop();
              } else {
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: Navigator(
                key: _navigatorKey,
                observers: [HeroController()],
                onGenerateRoute: (settings) {
                  printV(settings.name);

                  if (settings.name == "/")
                    return handleRouteWithPlatformAwareness((context) => SettingsMainPage(),
                        fullscreenDialog: false);
                  else
                    return createRoute(settings);
                }),
          ),
        ),
      ),
    );
  }
}

class SettingsMainPage extends StatelessWidget {
  const SettingsMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    Map<String, List<ListItem>> sections = Map.fromEntries(SettingsSectionData.all.map((section) =>
        MapEntry(
            section.title,
            section.items
                .map((item) => ListItemRegularRow(
                    keyValue: item.title, label: item.title, iconPath: item.iconPath, onTap: (){
              if (item.route.isNotEmpty) {
                Navigator.of(context).pushNamed(item.route, arguments: item.routeArgs);
              }

            }))
                .toList())));

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      controller: ModalScrollController.of(context),
      child: Column(children: [
        ModalTopBar(
          title: "Settings",
          leadingIcon: Icon(Icons.close),
          onLeadingPressed: Navigator.of(context, rootNavigator: true).pop,
          onTrailingPressed: () {},
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
          child: NewListSections(
            sections: sections,
          ),
        ),
      ]),
    );
  }
}