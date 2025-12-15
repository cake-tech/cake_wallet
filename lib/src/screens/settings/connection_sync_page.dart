import 'dart:io';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/wallet_connect_button.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_monero/monero_wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class ConnectionSyncPage extends BasePage {
  ConnectionSyncPage(this.dashboardViewModel);

  @override
  String get title => S.current.connection_sync;

  final DashboardViewModel dashboardViewModel;

  @override
  Widget body(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 10),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SettingsCellWithArrow(
              title: S.current.reconnect,
              handler: (context) => _presentReconnectAlert(context),
            ),
            if (dashboardViewModel.hasRescan) ...[
              SettingsCellWithArrow(
                title: dashboardViewModel.hasSilentPayments
                    ? S.current.silent_payments_scanning
                    : S.current.rescan,
                handler: (context) => Navigator.of(context).pushNamed(Routes.rescan),
              ),
            ],
            SettingsCellWithArrow(
              title: S.current.manage_nodes,
              handler: (context) => Navigator.of(context).pushNamed(Routes.manageNodes),
            ),
            if (Platform.isAndroid && FeatureFlag.isBackgroundSyncEnabled) ...[
              SettingsCellWithArrow(
                title: S.current.background_sync,
                handler: (context) => Navigator.of(context).pushNamed(Routes.backgroundSync),
              ),
            ],
            Observer(
              builder: (context) {
                if (!dashboardViewModel.hasPowNodes) return const SizedBox();

                return Column(
                  children: [
                    SettingsCellWithArrow(
                      title: S.current.manage_pow_nodes,
                      handler: (context) => Navigator.of(context).pushNamed(Routes.managePowNodes),
                    ),
                  ],
                );
              },
            ),
            if (isWalletConnectCompatibleChain(dashboardViewModel.wallet.type) &&
                !dashboardViewModel.wallet.isHardwareWallet) ...[
              // ToDo: Remove this line once WalletConnect is implemented
              WalletConnectTile(
                onTap: () =>
                    Navigator.of(context).pushNamed(Routes.walletConnectConnectionsListing),
              ),
            ],
            if (FeatureFlag.isInAppTorEnabled)
              Observer(builder: (context) {
                return SettingsSwitcherCell(
                  leading: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'Alpha',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: S.current.enable_builtin_tor,
                  value: dashboardViewModel.builtinTor,
                  onValueChange: (_, bool value) =>
                      dashboardViewModel.setBuiltinTor(value, context),
                );
              }),
            if (dashboardViewModel.wallet.type == WalletType.monero)
              Observer(builder: (context) {
                return SettingsSwitcherCell(
                  leading: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'Alpha',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: "Enable LWS for this wallet",
                  value: (dashboardViewModel.wallet as MoneroWallet).isLWSEnabled,
                  onValueChange: (_, bool value) =>
                      (dashboardViewModel.wallet as MoneroWallet).setLWSEnabled(value),
                );
              }),
          ],
        ),
      ),
    );
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
              await dashboardViewModel.reconnect();
            },
            actionLeftButton: () => Navigator.of(context).pop());
      },
    );
  }
}
