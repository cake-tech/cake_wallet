import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/modal_navigator.dart";
import "package:cake_wallet/new-ui/pages/coin_control_page.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

bool _alwaysVisible(DashboardViewModel _) => true;

bool _hasLightning(DashboardViewModel vm) => vm.hasLightning;

bool _hasSilentPayments(DashboardViewModel vm) => vm.hasSilentPayments;

bool _hasMweb(DashboardViewModel vm) => vm.hasMweb;

bool _hasWalletConnect(DashboardViewModel vm) => vm.hasWalletConnect;

bool _hasAccounts(DashboardViewModel vm) => vm.balanceViewModel.hasAccounts;

bool _hasCoinControl(DashboardViewModel vm) => vm.wallet.hasCoinControl;

bool _requiresKeyImageSync(DashboardViewModel vm) =>
    vm.wallet.type == WalletType.monero &&
    [HardwareWalletType.cupcake, HardwareWalletType.trezor].contains(vm.wallet.hardwareWalletType);

class SettingsListItem {
  const SettingsListItem(
    this.iconPath,
    this.title,
    this.route, {
    this.isCore = false,
    this.requireAuth = false,
    this.use2fa = _neverUse2fa,
    this.condition = _alwaysVisible,
    this.routeArgs,
    this.routeArgsBuilder,
  });

  static bool _neverUse2fa(DashboardViewModel _) => false;

  final String iconPath;
  final String title;
  final String route;
  final bool isCore;
  final Object? routeArgs;
  final Object? Function(DashboardViewModel)? routeArgsBuilder;
  final bool requireAuth;
  final bool Function(DashboardViewModel) use2fa;
  final bool Function(DashboardViewModel) condition;
}

class SettingsSectionData {
  const SettingsSectionData(
    this.title,
    this.titleIconPath,
    this.groups, {
    this.titleColor,
    this.headerSpacing = 16,
  });

  final String title;
  final String titleIconPath;
  final Map<String, List<ListItem>> groups;
  final Color? titleColor;
  final double headerSpacing;
}

class WalletSettingsResolver {
  const WalletSettingsResolver();

  String titleFor(WalletType walletType, S strings) =>
      '${walletTypeToString(walletType)} ${strings.settings_title}'.trim();

  String iconPathFor(WalletType walletType) =>
      "assets/new-ui/network_icons/${walletType.name.toLowerCase()}.svg";

  List<List<SettingsListItem>> resolveSections(DashboardViewModel viewModel) {
    final visibleItems = <SettingsListItem>[
      SettingsListItem(
        "assets/new-ui/settings_row_icons/accounts.svg",
        viewModel.wallet.type == WalletType.bitcoin ? S.current.accounts_onchain : S.current.accounts,
        Routes.accountCustomizer,
        isCore: true,
        condition: _hasAccounts,
        routeArgsBuilder: (vm) => vm,
      ),
      SettingsListItem(
        "assets/new-ui/settings_row_icons/nodes.svg",
        S.current.nodes,
        Routes.manageNodes,
        isCore: true,
      ),
      SettingsListItem(
        "assets/new-ui/settings_row_icons/coin-control.svg",
        S.current.coin_control_settings,
        Routes.unspentCoinsList,
        isCore: true,
        condition: _hasCoinControl,
        routeArgs: const CoinControlPageArgs(canEdit: false),
      ),
      SettingsListItem(
        "assets/new-ui/settings_row_icons/lightning_username.svg",
        "Lightning ${S.current.username}",
        Routes.lightningUsernamePage,
        condition: _hasLightning,
      ),
      SettingsListItem(
        "assets/new-ui/settings_row_icons/silent-payments.svg",
        S.current.silent_payments,
        Routes.silentPaymentsSettings,
        condition: _hasSilentPayments,
      ),
      SettingsListItem(
        "assets/new-ui/settings_row_icons/mweb.svg",
        S.current.litecoin_mweb,
        Routes.mwebSettings,
        condition: _hasMweb,
      ),
      SettingsListItem(
        "assets/new-ui/settings_row_icons/wc.svg",
        S.current.walletConnect,
        Routes.walletConnectConnectionsListing,
        condition: _hasWalletConnect,
      ),
      SettingsListItem(
        "assets/new-ui/settings_row_icons/sync-balance.svg",
        S.current.resync_device,
        Routes.syncKeyImagesDevices,
        routeArgs: const {"export-outputs": "export-outputs"},
        condition: _requiresKeyImageSync,
      ),
    ].where((item) => item.condition(viewModel)).toList();

    final coreItems = visibleItems.where((item) => item.isCore).toList();
    final featureItems = visibleItems.where((item) => !item.isCore).toList();

    return [
      if (coreItems.isNotEmpty) coreItems,
      if (featureItems.isNotEmpty) featureItems,
    ];
  }
}

class SettingsPageSectionsResolver {
  const SettingsPageSectionsResolver();

  List<SettingsListItem> walletGeneral(S strings) => [
        SettingsListItem(
          'assets/new-ui/settings_row_icons/privacy.svg',
          strings.privacy,
          Routes.privacyPage,
        ),
        SettingsListItem(
          'assets/new-ui/settings_row_icons/seed.svg',
          strings.seed_and_keys,
          Routes.showKeys,
          routeArgs: true,
          requireAuth: true,
          use2fa: (vm) => vm.settingsStore.shouldRequireTOTP2FAForAllSecurityAndBackupSettings,
        ),
        SettingsListItem(
          'assets/new-ui/settings_row_icons/other.svg',
          strings.other,
          Routes.otherSettingsPage,
        ),
      ];

  List<SettingsListItem> appSettings() => [
        SettingsListItem(
          "assets/new-ui/settings_row_icons/connections.svg",
          S.current.connections,
          Routes.connectionSync,
        ),
        SettingsListItem(
          "assets/new-ui/settings_row_icons/display.svg",
          S.current.display,
          Routes.displaySettingsPage,
        ),
        SettingsListItem(
          "assets/new-ui/settings_row_icons/security.svg",
          S.current.security,
          Routes.securityBackupPage,
        ),
        SettingsListItem(
          "assets/new-ui/settings_row_icons/backup.svg",
          S.current.backup,
          Routes.backup,
          requireAuth: true,
          use2fa: (vm) => vm.settingsStore.shouldRequireTOTP2FAForAllSecurityAndBackupSettings,
        ),
      ];

  List<SettingsListItem> supportAndAbout(S strings) => [
        SettingsListItem(
          'assets/new-ui/settings_row_icons/support.svg',
          strings.settings_support,
          Routes.support,
        ),
        SettingsListItem(
          'assets/new-ui/settings_row_icons/info.svg',
          strings.about,
          Routes.aboutPage,
        ),
      ];
}

class NewSettingsPage extends StatelessWidget {
  const NewSettingsPage({
    super.key,
    required this.dashboardViewModel,
    required this.authService,
  });

  final DashboardViewModel dashboardViewModel;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return ModalNavigator(
      parentContext: context,
      rootPage: SettingsMainPage(
        dashboardViewModel: dashboardViewModel,
        authService: authService,
      ),
    );
  }
}

class SettingsMainPage extends StatelessWidget {
  const SettingsMainPage({
    super.key,
    required this.dashboardViewModel,
    required this.authService,
  });

  static const _walletSettingsResolver = WalletSettingsResolver();
  static const _sectionsResolver = SettingsPageSectionsResolver();

  final DashboardViewModel dashboardViewModel;
  final AuthService authService;

  @override
  Widget build(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            ModalTopBar(
              title: S.of(context).settings_title,
              leadingIcon: const Icon(Icons.close),
              leadingSemanticLabel: S.of(context).close,
              onLeadingPressed: Navigator.of(context, rootNavigator: true).pop,
            ),
            Expanded(
              child: ListView(
                controller: ModalScrollController.of(context),
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
                children: [
                  for (final (index, section) in _sections(context).indexed) ...[
                    if (index > 0) ...[
                      const SizedBox(height: 24),
                      Divider(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                      const SizedBox(height: 24),
                    ],
                    _SettingsSectionHeader(
                      iconPath: section.titleIconPath,
                      title: section.title,
                      foregroundColor: section.titleColor,
                    ),
                    SizedBox(height: section.headerSpacing),
                    for (final (groupIndex, group) in section.groups.entries.indexed) ...[
                      if (groupIndex > 0) const SizedBox(height: 24),
                      NewListSections(sections: {group.key: group.value}),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  List<SettingsSectionData> _sections(BuildContext context) => [
        SettingsSectionData(
          dashboardViewModel.wallet.name,
          "assets/new-ui/wallet-setting.svg",
          {
            "wallet_type_settings": [
              ListItemRegularRow(
                keyValue: "wallet_type_settings",
                label: _walletSettingsResolver.titleFor(
                  dashboardViewModel.wallet.type,
                  S.of(context),
                ),
                iconPath: _walletSettingsResolver.iconPathFor(dashboardViewModel.wallet.type),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => WalletSettingsPage(
                      dashboardViewModel: dashboardViewModel,
                      authService: authService,
                    ),
                  ),
                ),
              ),
            ],
            "wallet_general": _buildRows(context, _sectionsResolver.walletGeneral(S.of(context))),
          },
          titleColor: Theme.of(context).colorScheme.primary,
          headerSpacing: 20,
        ),
        SettingsSectionData(
          S.of(context).app_settings,
          "assets/new-ui/cake-setting.svg",
          {
            "app_settings": _buildRows(context, _sectionsResolver.appSettings()),
            "support_and_about":
                _buildRows(context, _sectionsResolver.supportAndAbout(S.of(context))),
          },
        ),
      ];

  List<ListItem> _buildRows(BuildContext context, List<SettingsListItem> items) => items
      .where((item) => item.condition(dashboardViewModel))
      .map((item) => _buildRow(context, item))
      .toList();

  ListItemRegularRow _buildRow(BuildContext context, SettingsListItem item) => ListItemRegularRow(
        keyValue: item.route,
        label: item.title,
        iconPath: item.iconPath,
        onTap: () => _openItem(context, item),
      );

  Future<void> _openItem(BuildContext context, SettingsListItem item) async {
    final arguments = item.routeArgsBuilder?.call(dashboardViewModel) ?? item.routeArgs;
    if (item.requireAuth) {
      await authService.authenticateAction(
        context,
        conditionToDetermineIfToUse2FA: item.use2fa(dashboardViewModel),
        route: item.route,
        arguments: arguments,
      );
      return;
    }

    await Navigator.of(context).pushNamed(item.route, arguments: arguments);
  }
}

class WalletSettingsPage extends StatelessWidget {
  const WalletSettingsPage({
    super.key,
    required this.dashboardViewModel,
    required this.authService,
  });

  static const _resolver = WalletSettingsResolver();

  final DashboardViewModel dashboardViewModel;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final sections = _resolver.resolveSections(dashboardViewModel);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          ModalTopBar(
            title: _resolver.titleFor(dashboardViewModel.wallet.type, strings),
            titleLeadingWidget: CakeImageWidget(
              imageUrl: _resolver.iconPathFor(dashboardViewModel.wallet.type),
              width: 24,
              height: 24,
            ),
            leadingIcon: const Icon(Icons.arrow_back_ios_new),
            leadingSemanticLabel: strings.seed_alert_back,
            onLeadingPressed: Navigator.of(context).pop,
          ),
          Expanded(
            child: ListView(
              controller: ModalScrollController.of(context),
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
              children: [
                for (var index = 0; index < sections.length; index++) ...[
                  if (index > 0) const SizedBox(height: 24),
                  NewListSections(
                    sections: {
                      'wallet_settings_$index': sections[index]
                          .map(
                            (item) => ListItemRegularRow(
                              keyValue: item.route,
                              label: item.title,
                              iconPath: item.iconPath,
                              onTap: () => _openItem(context, item),
                            ),
                          )
                          .toList(),
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openItem(BuildContext context, SettingsListItem item) async {
    final arguments = item.routeArgsBuilder?.call(dashboardViewModel) ?? item.routeArgs;
    if (item.requireAuth) {
      await authService.authenticateAction(
        context,
        conditionToDetermineIfToUse2FA: item.use2fa(dashboardViewModel),
        route: item.route,
        arguments: arguments,
      );
      return;
    }

    await Navigator.of(context).pushNamed(item.route, arguments: arguments);
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  const _SettingsSectionHeader({
    required this.iconPath,
    required this.title,
    this.foregroundColor,
  });

  final String iconPath;
  final String title;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final color = foregroundColor ?? Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          CakeImageWidget(
            imageUrl: iconPath,
            height: 20,
            width: 20,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
