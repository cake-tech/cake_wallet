import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_selector.dart';
import 'package:cake_wallet/entities/priority_for_wallet_type.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/modal_page_wrapper.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/dev/moneroc_cache_debug.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/settings/other_settings_view_model.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/db/sqlite.dart';
import 'package:flutter/material.dart';

class OtherSettingsPage extends BasePage {
  OtherSettingsPage(this._otherSettingsViewModel) {
    if (_otherSettingsViewModel.sendViewModel.isElectrumWallet) {
      bitcoin!.updateFeeRates(_otherSettingsViewModel.sendViewModel.wallet);
    }
  }

  @override
  bool get hideAppBar => true;

  final OtherSettingsViewModel _otherSettingsViewModel;


  @override
  Widget body(BuildContext context) {
    return ModalPageWrapper(
      topBar: ModalTopBar(
        title: S.current.other,
        leadingIcon: Icon(Icons.arrow_back_ios_new),
        onLeadingPressed: () => Navigator.of(context).pop(),
      ),
      // header: ModalHeader(
      //     iconPath: "assets/new-ui/settings_row_icons/other.svg",
      //     message: "Other settings",
      //     title: S.of(context).other_settings),
      content: NewListSections(
        sections: {
        "": [
          if (_otherSettingsViewModel.displayTransactionPriority)
            _otherSettingsViewModel.walletType == WalletType.bitcoin
                ? ListItemSelector(
                    keyValue: "fee_priority",
                    label: S.current.settings_fee_priority,
                    options: [_otherSettingsViewModel.transactionPriority.title],
                onTap: () async {

                  final items = priorityForWalletType(_otherSettingsViewModel.walletType);

                  var selectedAtIndex = items.indexOf(_otherSettingsViewModel.transactionPriority);
                  double sliderValue = _otherSettingsViewModel.customBitcoinFeeRate ?? 0.0;

                  await showPopUp<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return Picker(
                            items: items,
                            displayItem: (TransactionPriority item) => _otherSettingsViewModel.getDisplayBitcoinPriority(item, sliderValue.round()),
                            selectedAtIndex: selectedAtIndex,
                            customItemIndex: _otherSettingsViewModel.customPriorityItemIndex,
                            maxValue: _otherSettingsViewModel.maxCustomFeeRate?.toDouble(),
                            headerEnabled: false,
                            closeOnItemSelected: false,
                            mainAxisAlignment: MainAxisAlignment.center,
                            sliderValue: sliderValue,
                            onSliderChanged: (double newValue) =>
                                setState(() => sliderValue = newValue),
                            onItemSelected: (TransactionPriority priority) {
                              setState(() => selectedAtIndex = items.indexOf(priority));
                              _otherSettingsViewModel.onDisplayBitcoinPrioritySelected.call(priority, sliderValue);
                            },
                          );
                        },
                      );
                    },
                  );
                  _otherSettingsViewModel.onDisplayBitcoinPrioritySelected.call(items[selectedAtIndex], sliderValue);
                }
                  )
                : ListItemSelector(
                    keyValue: "fee_priority",
                    label: S.current.settings_fee_priority,
                    options: [_otherSettingsViewModel.transactionPriority.title],
              onTap: () async {
                final selectedAtIndex = priorityForWalletType(_otherSettingsViewModel.walletType).indexOf(_otherSettingsViewModel.transactionPriority,);

                await showPopUp<void>(
                  context: context,
                  builder: (_) => Picker(
                    items: priorityForWalletType(_otherSettingsViewModel.walletType),
                    displayItem: _otherSettingsViewModel.getDisplayPriority,
                    selectedAtIndex: selectedAtIndex,
                    mainAxisAlignment: MainAxisAlignment.start,
                    onItemSelected: (TransactionPriority item) => _otherSettingsViewModel.onDisplayBitcoinPrioritySelected.call(item, 0),
                    isSeparated: false,
                  ),
                );
              },
            ),
          if(_otherSettingsViewModel.changeRepresentativeEnabled)
          ListItemRegularRow(
              keyValue: "change_rep",
              label: S.current.change_rep,
              onTap: () => Navigator.of(context).pushNamed(Routes.changeRep)
          ),
          if (_otherSettingsViewModel.changeHardwareWalletTypeEnabled)
          ListItemRegularRow(
              keyValue: "hardware_wallet_manufacturer",
              label: "Hardware wallet manufacturer",
              onTap: () => Navigator.of(context)
                  .pushNamed(Routes.restoreWalletFromHardwareWallet, arguments: {
                "showUnavailable": false,
                "availableHardwareWalletTypes": [
                  HardwareWalletType.cupcake,
                  HardwareWalletType.coldcard,
                  HardwareWalletType.seedsigner,
                ],
                "onSelect": (BuildContext context, HardwareWalletType hwType) async {
                  await _otherSettingsViewModel.onHardwareWalletTypeChanged(hwType);
                  Navigator.pop(context);
                },
              }),
          ),
          ListItemRegularRow(
              keyValue: "security_backup_page_sign_and_verify",
              label: S.current.sign_verify_title,
              onTap: () {
                Navigator.of(context).pushNamed(Routes.signPage);
              }),
        ],
          if(FeatureFlag.hasDevOptions)
          "dev": [
            if (FeatureFlag.hasDevOptions &&
                _otherSettingsViewModel.walletType == WalletType.monero)
            ListItemRegularRow(
              keyValue: "[dev] monero background sync",
              label: "[dev] monero background sync",
              onTap: () => Navigator.of(context).pushNamed(Routes.devMoneroBackgroundSync)
            ),
            if (FeatureFlag.hasDevOptions &&
                [WalletType.monero, WalletType.wownero, WalletType.zano]
                    .contains(_otherSettingsViewModel.walletType))
              ListItemRegularRow(
                  keyValue: "[dev] xmr call profiler",
                  label: "[dev] xmr call profiler",
                  onTap: () => Navigator.of(context).pushNamed(Routes.devMoneroCallProfiler)
              ),
            if (FeatureFlag.hasDevOptions &&
                [WalletType.monero].contains(_otherSettingsViewModel.walletType))
              ListItemRegularRow(
                  keyValue: '[dev] xmr wallet cache debug',
                  label: '[dev] xmr wallet cache debug',
                  onTap: () => Navigator.of(context).pushNamed(Routes.devMoneroWalletCacheDebug)
              ),
            ListItemRegularRow(
                keyValue: '[dev] shared preferences',
                label: '[dev] shared preferences',
                onTap: () => Navigator.of(context).pushNamed(Routes.devSharedPreferences)
            ),
            ListItemRegularRow(
                keyValue: '[dev] secure storage preferences',
                label: '[dev] secure storage preferences',
                onTap: () => Navigator.of(context).pushNamed(Routes.devSecurePreferences)
            ),
            ListItemRegularRow(
                keyValue: '[dev] background sync logs',
                label: '[dev] background sync logs',
                onTap: () => Navigator.of(context).pushNamed(Routes.devBackgroundSyncLogs)
            ),
            ListItemRegularRow(
                keyValue: '[dev] socket health logs',
                label: '[dev] socket health logs',
                onTap: () => Navigator.of(context).pushNamed(Routes.devSocketHealthLogs)
            ),
            ListItemRegularRow(
                keyValue: '[dev] network requests logs',
                label: '[dev] network requests logs',
                onTap: () => Navigator.of(context).pushNamed(Routes.devNetworkRequests)
            ),
            ListItemRegularRow(
                keyValue: '[dev] exchange provider logs',
                label: '[dev] exchange provider logs',
                onTap: () => Navigator.of(context).pushNamed(Routes.devExchangeProviderLogs)
            ),
            ListItemRegularRow(
                keyValue: '[dev] *QR tools',
                label: '[dev] *QR tools',
                onTap: () => Navigator.of(context).pushNamed(Routes.devExchangeProviderLogs)
            ),
            ListItemRegularRow(
                keyValue: '[dev] browse sqlite db',
                label: '[dev] browse sqlite db',
                onTap: () async {
                  final data = await dumpDb();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) =>
                        JsonExplorerPage(data: data, title: 'sqlite db')),
                  );
                }
            ),
          ]
      }
      ),
    );
  }
}
