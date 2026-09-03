import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/modal_navigator.dart';
import 'package:cake_wallet/new-ui/pages/coin_control_page.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

bool _alwaysVisible(DashboardViewModel _) => true;

bool _hasLightning(DashboardViewModel vm) => vm.hasLightning;

bool _hasSilentPayments(DashboardViewModel vm) => vm.hasSilentPayments;

bool _hasMweb(DashboardViewModel vm) => vm.hasMweb;

bool _hasWalletConnect(DashboardViewModel vm) => vm.hasWalletConnect;

bool _hasAccounts(DashboardViewModel vm) => vm.balanceViewModel.hasAccounts;

bool _requiresKeyImageSync(DashboardViewModel vm) =>
    vm.wallet.type == WalletType.monero &&
    [HardwareWalletType.cupcake, HardwareWalletType.trezor].contains(vm.wallet.hardwareWalletType);

class SettingsListItem {
  const SettingsListItem(
    this.iconPath,
    this.title,
    this.route, {
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
  final Object? routeArgs;
  final Object? Function(DashboardViewModel)? routeArgsBuilder;
  final bool requireAuth;
  final bool Function(DashboardViewModel) use2fa;
  final bool Function(DashboardViewModel) condition;
}

class SettingsSectionData {
  const SettingsSectionData(this.title, this.titleIconPath, this.items);

  final String title;
  final String titleIconPath;
  final List<SettingsListItem> items;
}

/// The network-specific settings that may appear for an active wallet.
///
/// Availability that can change at runtime (hardware wallet, platform, wallet
/// implementation, and feature support) is intentionally handled by each
/// item's [SettingsListItem.condition], not by this enum.
enum WalletSettingsItemType {
  accounts,
  nodes,
  coinControl,
  lightningUsername,
  silentPayments,
  mweb,
  walletConnect,
  resyncDevice,
}

extension on WalletSettingsItemType {
  bool get isCoreSetting => switch (this) {
        WalletSettingsItemType.accounts ||
        WalletSettingsItemType.nodes ||
        WalletSettingsItemType.coinControl =>
          true,
        WalletSettingsItemType.lightningUsername ||
        WalletSettingsItemType.silentPayments ||
        WalletSettingsItemType.mweb ||
        WalletSettingsItemType.walletConnect ||
        WalletSettingsItemType.resyncDevice =>
          false,
      };
}

/// Resolves the nested wallet settings for every [WalletType].
///
/// This switch deliberately has no wildcard/default branch. Adding a wallet
/// type therefore requires an explicit decision about its settings here.
class WalletSettingsResolver {
  const WalletSettingsResolver();

  List<WalletSettingsItemType> settingsFor(WalletType walletType) => switch (walletType) {
        WalletType.monero => const [
            WalletSettingsItemType.accounts,
            WalletSettingsItemType.nodes,
            WalletSettingsItemType.coinControl,
            WalletSettingsItemType.resyncDevice,
          ],
        WalletType.bitcoin => const [
            WalletSettingsItemType.accounts,
            WalletSettingsItemType.nodes,
            WalletSettingsItemType.coinControl,
            WalletSettingsItemType.lightningUsername,
            WalletSettingsItemType.silentPayments,
          ],
        WalletType.litecoin => const [
            WalletSettingsItemType.accounts,
            WalletSettingsItemType.nodes,
            WalletSettingsItemType.coinControl,
            WalletSettingsItemType.mweb,
          ],
        WalletType.ethereum => const [
            WalletSettingsItemType.accounts,
            WalletSettingsItemType.nodes,
            WalletSettingsItemType.walletConnect,
          ],
        WalletType.bitcoinCash => const [
            WalletSettingsItemType.accounts,
            WalletSettingsItemType.nodes,
            WalletSettingsItemType.coinControl,
          ],
        WalletType.nano => const [
            WalletSettingsItemType.accounts,
            WalletSettingsItemType.nodes,
          ],
        WalletType.banano => const [
            WalletSettingsItemType.accounts,
            WalletSettingsItemType.nodes,
          ],
        WalletType.haven => const [
            WalletSettingsItemType.accounts,
            WalletSettingsItemType.nodes,
          ],
        WalletType.polygon => const [
            WalletSettingsItemType.accounts,
            WalletSettingsItemType.nodes,
            WalletSettingsItemType.walletConnect,
          ],
        WalletType.solana => const [
            WalletSettingsItemType.accounts,
            WalletSettingsItemType.nodes,
            WalletSettingsItemType.walletConnect,
          ],
        WalletType.tron => const [
            WalletSettingsItemType.accounts,
            WalletSettingsItemType.nodes,
          ],
        WalletType.wownero => const [
            WalletSettingsItemType.accounts,
            WalletSettingsItemType.nodes,
            WalletSettingsItemType.coinControl,
          ],
        WalletType.zano => const [
            WalletSettingsItemType.accounts,
            WalletSettingsItemType.nodes,
          ],
        WalletType.decred => const [
            WalletSettingsItemType.accounts,
            WalletSettingsItemType.nodes,
            WalletSettingsItemType.coinControl,
          ],
        WalletType.dogecoin => const [
            WalletSettingsItemType.accounts,
            WalletSettingsItemType.nodes,
            WalletSettingsItemType.coinControl,
          ],
        WalletType.base => const [
            WalletSettingsItemType.accounts,
            WalletSettingsItemType.nodes,
            WalletSettingsItemType.walletConnect,
          ],
        WalletType.arbitrum => const [
            WalletSettingsItemType.accounts,
            WalletSettingsItemType.nodes,
            WalletSettingsItemType.walletConnect,
          ],
        WalletType.zcash => const [
            WalletSettingsItemType.accounts,
            WalletSettingsItemType.nodes,
          ],
        WalletType.bsc => const [
            WalletSettingsItemType.accounts,
            WalletSettingsItemType.nodes,
            WalletSettingsItemType.walletConnect,
          ],
        WalletType.none => const [
            WalletSettingsItemType.accounts,
            WalletSettingsItemType.nodes,
          ],
      };

  String titleFor(WalletType walletType, S strings) =>
      '${walletTypeToString(walletType)} ${strings.settings_title}'.trim();

  String iconPathFor(WalletType walletType) => walletType == WalletType.none
      ? 'assets/new-ui/wallet-setting.svg'
      : getCryptoCurrencyIconForWalletListItem(walletType);

  List<List<SettingsListItem>> resolveSections(S strings, DashboardViewModel viewModel) {
    final supportedTypes = settingsFor(viewModel.wallet.type);
    final visibleEntries = supportedTypes
        .map(
          (type) => (
            type: type,
            item: _buildItem(type, strings, viewModel.wallet.type),
          ),
        )
        .where((entry) => entry.item.condition(viewModel))
        .toList();

    final coreItems = visibleEntries
        .where((entry) => entry.type.isCoreSetting)
        .map((entry) => entry.item)
        .toList();
    final featureItems = visibleEntries
        .where((entry) => !entry.type.isCoreSetting)
        .map((entry) => entry.item)
        .toList();

    return [
      if (coreItems.isNotEmpty) coreItems,
      if (featureItems.isNotEmpty) featureItems,
    ];
  }

  SettingsListItem _buildItem(
    WalletSettingsItemType type,
    S strings,
    WalletType walletType,
  ) =>
      switch (type) {
        WalletSettingsItemType.accounts => SettingsListItem(
            'assets/new-ui/settings_row_icons/accounts.svg',
            walletType == WalletType.bitcoin ? strings.accounts_onchain : strings.accounts,
            Routes.accountCustomizer,
            condition: _hasAccounts,
            routeArgsBuilder: (vm) => vm,
          ),
        WalletSettingsItemType.nodes => SettingsListItem(
            'assets/new-ui/settings_row_icons/nodes.svg',
            strings.nodes,
            Routes.manageNodes,
          ),
        WalletSettingsItemType.coinControl => SettingsListItem(
            'assets/new-ui/settings_row_icons/coin-control.svg',
            strings.coin_control_settings,
            Routes.unspentCoinsList,
            routeArgs: const CoinControlPageArgs(canEdit: false),
          ),
        WalletSettingsItemType.lightningUsername => SettingsListItem(
            'assets/new-ui/settings_row_icons/lightning_username.svg',
            'Lightning ${strings.username}',
            Routes.lightningUsernamePage,
            condition: _hasLightning,
          ),
        WalletSettingsItemType.silentPayments => SettingsListItem(
            'assets/new-ui/settings_row_icons/silent-payments.svg',
            strings.silent_payments,
            Routes.silentPaymentsSettings,
            condition: _hasSilentPayments,
          ),
        WalletSettingsItemType.mweb => SettingsListItem(
            'assets/new-ui/settings_row_icons/mweb.svg',
            strings.litecoin_mweb,
            Routes.mwebSettings,
            condition: _hasMweb,
          ),
        WalletSettingsItemType.walletConnect => SettingsListItem(
            'assets/new-ui/settings_row_icons/wc.svg',
            strings.walletConnect,
            Routes.walletConnectConnectionsListing,
            condition: _hasWalletConnect,
          ),
        WalletSettingsItemType.resyncDevice => SettingsListItem(
            'assets/new-ui/settings_row_icons/sync-balance.svg',
            strings.resync_device,
            Routes.syncKeyImagesDevices,
            routeArgs: const {'export-outputs': 'export-outputs'},
            condition: _requiresKeyImageSync,
          ),
      };
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

  SettingsSectionData appSettings(S strings) => SettingsSectionData(
        strings.app_settings,
        'assets/new-ui/cake-setting.svg',
        [
          SettingsListItem(
            'assets/new-ui/settings_row_icons/connections.svg',
            strings.connections,
            Routes.connectionSync,
          ),
          SettingsListItem(
            'assets/new-ui/settings_row_icons/display.svg',
            strings.display,
            Routes.displaySettingsPage,
          ),
          SettingsListItem(
            'assets/new-ui/settings_row_icons/security.svg',
            strings.security,
            Routes.securityBackupPage,
          ),
          SettingsListItem(
            'assets/new-ui/settings_row_icons/backup.svg',
            strings.backup,
            Routes.backup,
            requireAuth: true,
            use2fa: (vm) => vm.settingsStore.shouldRequireTOTP2FAForAllSecurityAndBackupSettings,
          ),
        ],
      );

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
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final wallet = dashboardViewModel.wallet;
    final walletSettingsTitle = _walletSettingsResolver.titleFor(wallet.type, strings);
    final appSettings = _sectionsResolver.appSettings(strings);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          ModalTopBar(
            title: strings.settings_title,
            leadingIcon: const Icon(Icons.close),
            leadingSemanticLabel: strings.close,
            onLeadingPressed: Navigator.of(context, rootNavigator: true).pop,
          ),
          Expanded(
            child: ListView(
              controller: ModalScrollController.of(context),
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
              children: [
                _SettingsSectionHeader(
                  iconPath: 'assets/new-ui/wallet-setting.svg',
                  title: wallet.name,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                NewListSections(
                  sections: {
                    'wallet_type_settings': [
                      ListItemRegularRow(
                        keyValue: 'wallet_type_settings',
                        label: walletSettingsTitle,
                        iconPath: _walletSettingsResolver.iconPathFor(wallet.type),
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
                  },
                ),
                const SizedBox(height: 24),
                NewListSections(
                  sections: {
                    'wallet_general': _buildRows(context, _sectionsResolver.walletGeneral(strings)),
                  },
                ),
                const SizedBox(height: 24),
                Divider(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                const SizedBox(height: 24),
                _SettingsSectionHeader(
                  iconPath: appSettings.titleIconPath,
                  title: appSettings.title,
                ),
                const SizedBox(height: 16),
                NewListSections(
                  sections: {'app_settings': _buildRows(context, appSettings.items)},
                ),
                const SizedBox(height: 24),
                NewListSections(
                  sections: {
                    'support_and_about':
                        _buildRows(context, _sectionsResolver.supportAndAbout(strings)),
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
    final sections = _resolver.resolveSections(strings, dashboardViewModel);

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
