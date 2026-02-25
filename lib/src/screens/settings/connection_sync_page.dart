import 'dart:io';

import 'package:cake_wallet/entities/exchange_api_mode.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_selector.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_toggle.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/modal_header.dart';
import 'package:cake_wallet/new-ui/widgets/modal_page_wrapper.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/settings/connection_sync_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class ConnectionSyncPage extends BasePage {
  ConnectionSyncPage(this._connectionSyncViewModel);

  @override
  bool get hideAppBar => true;

  final ConnectionSyncViewModel _connectionSyncViewModel;

  @override
  Widget body(BuildContext context) {
    return ModalPageWrapper(
      topBar: ModalTopBar(
          title: "",
          leadingIcon: Icon(Icons.arrow_back_ios_new),
          onLeadingPressed: () => Navigator.of(context).pop()),
      header: ModalHeader(
          iconPath: "assets/new-ui/settings_row_icons/connections.svg",
          message: S.of(context).connections_desc,
          title: S.of(context).connection_sync),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Observer(
              builder: (context) =>
                  NewListSections(
                      sections: {
                        "": [
                          if (FeatureFlag.isInAppTorEnabled)
                            ListItemToggle(
                                keyValue: "enable_builtin_tor",
                                label: S.current.enable_builtin_tor,
                                value: _connectionSyncViewModel.builtinTor,
                                onChanged: (val) {
                                  _connectionSyncViewModel.setBuiltinTor(val, context);
                                }),
                          ListItemToggle(
                              keyValue: "disable_automatic_exchange_status_updates",
                              label: S.current.disable_automatic_exchange_status_updates,
                              value: _connectionSyncViewModel.disableAutomaticExchangeStatusUpdates,
                              onChanged: (val) {
                                _connectionSyncViewModel.setDisableAutomaticExchangeStatusUpdates(val);
                              }),
                          if (_connectionSyncViewModel.canUseBlinkProtection)
                            ListItemToggle(
                                keyValue: "can_use_blink_protection",
                                label: S.current.use_blink_protection,
                                value: _connectionSyncViewModel.useBlinkProtection,
                                onChanged: (val) {
                                  _connectionSyncViewModel.setUseBlinkProtection(val);
                                }),
                          if (_connectionSyncViewModel.canUseEtherscan)
                            ListItemToggle(
                                keyValue: "can_use_etherscan",
                                label: S.current.etherscan_history,
                                value: _connectionSyncViewModel.useEtherscan,
                                onChanged: (val) {
                                  _connectionSyncViewModel.setUseEtherscan(val);
                                }),
                          if (_connectionSyncViewModel.canUsePolygonScan)
                            ListItemToggle(
                                keyValue: "can_use_polygonscan",
                                label: S.current.polygonscan_history,
                                value: _connectionSyncViewModel.usePolygonScan,
                                onChanged: (val) {
                                  _connectionSyncViewModel.setUsePolygonScan(val);
                                }),
                          if (_connectionSyncViewModel.canUseBaseScan)
                            ListItemToggle(
                                keyValue: "can_use_basescan",
                                label: S.current.basescan_history,
                                value: _connectionSyncViewModel.canUseBaseScan,
                                onChanged: (val) {
                                  _connectionSyncViewModel.setUseBaseScan(val);
                                }),
                          if (_connectionSyncViewModel.canUseArbiScan)
                            ListItemToggle(
                                keyValue: "can_use_arbiscan",
                                label: S.current.arbiscan_history,
                                value: _connectionSyncViewModel.useArbiScan,
                                onChanged: (val) {
                                  _connectionSyncViewModel.setUsePolygonScan(val);
                                }),
                          if (_connectionSyncViewModel.canUseBscScan)
                            ListItemToggle(
                                keyValue: "can_use_bscscan",
                                label: S.current.bscscan_history,
                                value: _connectionSyncViewModel.useBscScan,
                                onChanged: (val) {
                                  _connectionSyncViewModel.setUseBscScan(val);
                                }),
                          if (_connectionSyncViewModel.canUseTronGrid)
                            ListItemToggle(
                                keyValue: "can_use_trongrid",
                                label: S.current.trongrid_history,
                                value: _connectionSyncViewModel.useTronGrid,
                                onChanged: (val) {
                                  _connectionSyncViewModel.setUsePolygonScan(val);
                                }),
                          if (_connectionSyncViewModel.canUseMempoolFeeAPI)
                            ListItemToggle(
                                keyValue: "enable_mempool_api",
                                label: S.current.enable_mempool_api,
                                value: _connectionSyncViewModel.useMempoolFeeAPI,
                                onChanged: (bool isEnabled) async {
                                  if (!isEnabled) {
                                    final bool confirmation = await showPopUp<bool>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertWithTwoActions(
                                              alertTitle: S.of(context).warning,
                                              alertContent: S.of(context).disable_fee_api_warning,
                                              rightButtonText: S.of(context).confirm,
                                              leftButtonText: S.of(context).cancel,
                                              actionRightButton: () => Navigator.of(context).pop(true),
                                              actionLeftButton: () => Navigator.of(context).pop(false));
                                        }) ??
                                        false;
                                    if (confirmation) {
                                      _connectionSyncViewModel.setUseMempoolFeeAPI(isEnabled);
                                    }
                                    return;
                                  }

                                  _connectionSyncViewModel.setUseMempoolFeeAPI(isEnabled);
                                }),
                          if (Platform.isAndroid && FeatureFlag.isBackgroundSyncEnabled)
                            ListItemRegularRow(
                                keyValue: "background_sync",
                                label: S.current.background_sync,
                                onTap: () => Navigator.of(context).pushNamed(Routes.backgroundSync)
                            ),
                          if (_connectionSyncViewModel.hasPowNodes)
                            ListItemRegularRow(
                                keyValue: "manage_pow_nodes",
                                label: S.current.manage_pow_nodes,
                                onTap: () => Navigator.of(context).pushNamed(Routes.managePowNodes),
                            ),
                          ListItemSelector(
                              keyValue: "fiat_api",
                              label: S.current.fiat_api,
                              options: [_connectionSyncViewModel.fiatApiMode.title],
                              onTap: () async {
                                final items = FiatApiMode.all;

                                final selectedAtIndex =
                                items.indexOf(_connectionSyncViewModel.fiatApiMode);

                                await showPopUp<void>(
                                  context: context,
                                  builder: (_) => Picker(
                                    items: items,
                                    selectedAtIndex: selectedAtIndex,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    onItemSelected: (FiatApiMode fiatApiMode) {
                                      _connectionSyncViewModel.setFiatMode(fiatApiMode);
                                    },
                                    isSeparated: false,
                                  ),
                                );
                              }),
                          ListItemSelector(
                              keyValue: "swap",
                              label: S.current.swap,
                              options: [_connectionSyncViewModel.exchangeStatus.title],
                              onTap: () async {
                                final items = ExchangeApiMode.all;

                                final selectedAtIndex =
                                items.indexOf(_connectionSyncViewModel.exchangeStatus);

                                await showPopUp<void>(
                                  context: context,
                                  builder: (_) => Picker(
                                    items: items,
                                    selectedAtIndex: selectedAtIndex,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    onItemSelected: (ExchangeApiMode mode) {
                                      _connectionSyncViewModel.setExchangeApiMode(mode);
                                    },
                                    isSeparated: false,
                                  ),
                                );
                              }),
                          ListItemRegularRow(
                              keyValue: "domain_lookups",
                              label: S.current.domain_looks_up,
                              onTap: () => Navigator.of(context).pushNamed(Routes.domainLookupsPage)
                          ),
                        ],
                        "1": [
                          if (_connectionSyncViewModel.isWalletConnectCompatible)
                            ListItemRegularRow(
                                keyValue: "wallet_connect",
                                iconPath: 'assets/images/walletconnect_logo.png',
                                label: S.current.walletConnect,
                                onTap: () => Navigator.of(context).pushNamed(Routes.walletConnectConnectionsListing)
                            ),
                        ],
                      }
                  )
          ),
        ],
      ),
    );
  }
}
