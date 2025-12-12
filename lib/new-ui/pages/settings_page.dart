import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/router.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/section_divider.dart';
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

class NewSettingsPage extends StatelessWidget {
  const NewSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      left: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Navigator(
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
    );
  }
}

class SettingsMainPage extends StatelessWidget {
  const SettingsMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      controller: ModalScrollController.of(context),
      child: Column(
        children: [
          ModalTopBar(
            title: S.of(context).settings,
            leadingIcon: Icon(Icons.close),
            onLeadingPressed: Navigator.of(context, rootNavigator: true).pop,
            onTrailingPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              spacing: 24.0,
              children: SettingsSectionData.all
                  .map((item) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: SettingsSection(data: item),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.data});

  final SettingsSectionData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (data.titleIconPath.isNotEmpty)
              SvgPicture.asset(
                data.titleIconPath,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onSurfaceVariant, BlendMode.srcIn),
              ),
            SizedBox(width: 6),
            if (data.title.isNotEmpty)
              Text(
                data.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              )
          ],
        ),
        if (data.titleIconPath.isNotEmpty && data.title.isNotEmpty) SizedBox(height: 20),
        ...data.items.map((item) => SettingsRow(
              item: item,
              roundedTop: item == data.items.first,
              roundedBottom: item == data.items.last,
            ))
      ],
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow(
      {super.key, required this.item, required this.roundedTop, required this.roundedBottom});

  final SettingsListItem item;
  final bool roundedTop;
  final bool roundedBottom;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 50,
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(roundedTop ? 10 : 0),
                  bottom: Radius.circular(roundedBottom ? 10 : 0)),
            child: InkWell(
              onTap: () {
                if (item.route.isNotEmpty) {
                  Navigator.of(context).pushNamed(item.route, arguments: item.routeArgs);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: SvgPicture.asset(item.iconPath),
                        ),
                        Text(item.title)
                      ],
                    ),
                    SvgPicture.asset(
                      "assets/new-ui/arrow_right.svg",
                      colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.onSurfaceVariant, BlendMode.srcIn),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
        if (!roundedBottom)
          Container(
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.0),
              child: HorizontalSectionDivider(),
            ),
          )
      ],
    );
  }
}
