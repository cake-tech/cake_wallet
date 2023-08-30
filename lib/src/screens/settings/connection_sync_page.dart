import 'package:another_flushbar/flushbar.dart';
import 'package:cake_wallet/core/wallet_connect/chain_service.dart';
import 'package:cake_wallet/core/wallet_connect/evm_chain_service.dart';
import 'package:cake_wallet/core/wallet_connect/wallet_connect_key_service.dart';
import 'package:cake_wallet/core/wallet_connect/wc_bottom_sheet_service.dart';
import 'package:cake_wallet/core/wallet_connect/web3wallet_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_picker_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/wallet_connect_button.dart';
import 'package:cake_wallet/src/screens/wallet_connect/wc_connections_listing_view.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/settings/sync_mode.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

class ConnectionSyncPage extends BasePage {
  ConnectionSyncPage(this.dashboardViewModel);

  @override
  String get title => S.current.connection_sync;

  final DashboardViewModel dashboardViewModel;

  @override
  Widget body(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SettingsCellWithArrow(
            title: S.current.reconnect,
            handler: (context) => _presentReconnectAlert(context),
          ),
          const StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
          if (dashboardViewModel.hasRescan) ...[
            SettingsCellWithArrow(
              title: S.current.rescan,
              handler: (context) => Navigator.of(context).pushNamed(Routes.rescan),
            ),
            const StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
            if (DeviceInfo.instance.isMobile) ...[
              Observer(builder: (context) {
                return SettingsPickerCell<SyncMode>(
                  title: S.current.background_sync_mode,
                  items: SyncMode.all,
                  displayItem: (SyncMode syncMode) => syncMode.name,
                  selectedItem: dashboardViewModel.syncMode,
                  onItemSelected: dashboardViewModel.setSyncMode,
                );
              }),
              const StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
              Observer(builder: (context) {
                return SettingsSwitcherCell(
                  title: S.current.sync_all_wallets,
                  value: dashboardViewModel.syncAll,
                  onValueChange: (_, bool value) => dashboardViewModel.setSyncAll(value),
                );
              }),
              const StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
            ],
          ],
          SettingsCellWithArrow(
            title: S.current.manage_nodes,
            handler: (context) => Navigator.of(context).pushNamed(Routes.manageNodes),
          ),
          const StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
          if (dashboardViewModel.wallet.type == WalletType.ethereum) ...[
            WalletConnectTile(
              onTap: () async {
                await initializeWeb3Wallet();
                // await initializeWalletConnectDependencies();
                // print('Dependencies registration done');
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return WalletConnectConnectionsView();
                    },
                  ),
                );
              },
            ),
            const StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
          ]
        ],
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

  Future<void> initializeWeb3Wallet() async {
    //TODO(David): Switch Singleton to Factory when appropriate

    // if (dashboardViewModel.initializedWalletConnectDependencies) return;
    final appStore = getIt.get<AppStore>();

    getIt.registerSingleton<WalletConnectKeyService>(KeyServiceImpl(appStore.wallet!));

    final Web3WalletService web3WalletService = Web3WalletServiceImpl();
    web3WalletService.create();
    getIt.registerSingleton<Web3WalletService>(web3WalletService);

    for (final cId in EVMChainId.values) {
      GetIt.I.registerSingleton<ChainService>(
        EvmChainServiceImpl(reference: cId, appStore: appStore),
        instanceName: cId.chain(),
      );
    }

    await web3WalletService.init();

    dashboardViewModel.isWalletConnectDependenciesIntialized(isWCDependenciesInitialized: true);
  
  }
}
