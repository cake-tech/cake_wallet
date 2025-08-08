import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/entities/priority_for_wallet_type.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/setting_priority_picker_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_picker_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_version_cell.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/view_model/settings/other_settings_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class OtherSettingsPage extends BasePage {
  OtherSettingsPage(this._otherSettingsViewModel) {
    if (_otherSettingsViewModel.sendViewModel.isElectrumWallet) {
      bitcoin!.updateFeeRates(_otherSettingsViewModel.sendViewModel.wallet);
    }
  }

  @override
  String get title => S.current.other_settings;

  final OtherSettingsViewModel _otherSettingsViewModel;

  @override
  Widget body(BuildContext context) {
    return Observer(
      builder: (_) {
        return Container(
          padding: EdgeInsets.only(top: 10),
          child: Column(
            children: [
              if (_otherSettingsViewModel.displayTransactionPriority)
                _otherSettingsViewModel.walletType == WalletType.bitcoin ?
                  SettingsPriorityPickerCell(
                        title: S.current.settings_fee_priority,
                        items: priorityForWalletType(_otherSettingsViewModel.walletType),
                        displayItem: _otherSettingsViewModel.getDisplayBitcoinPriority,
                        selectedItem: _otherSettingsViewModel.transactionPriority,
                        customItemIndex: _otherSettingsViewModel.customPriorityItemIndex,
                        onItemSelected: _otherSettingsViewModel.onDisplayBitcoinPrioritySelected,
                        customValue: _otherSettingsViewModel.customBitcoinFeeRate,
                        maxValue: _otherSettingsViewModel.maxCustomFeeRate?.toDouble(),
                  ) :
                  SettingsPickerCell(
                        title: S.current.settings_fee_priority,
                        items: priorityForWalletType(_otherSettingsViewModel.walletType),
                        displayItem: _otherSettingsViewModel.getDisplayPriority,
                        selectedItem: _otherSettingsViewModel.transactionPriority,
                        onItemSelected: _otherSettingsViewModel.onDisplayPrioritySelected,
                      ),
              if (_otherSettingsViewModel.changeRepresentativeEnabled)
                SettingsCellWithArrow(
                  title: S.current.change_rep,
                  handler: (BuildContext context) =>
                      Navigator.of(context).pushNamed(Routes.changeRep),
                ),
              SettingsCellWithArrow(
                title: S.current.settings_terms_and_conditions,
                handler: (BuildContext context) =>
                    Navigator.of(context).pushNamed(Routes.readDisclaimer),
              ),
              if (FeatureFlag.hasDevOptions && _otherSettingsViewModel.walletType == WalletType.monero) 
                SettingsCellWithArrow(
                  title: '[dev] monero background sync',
                  handler: (BuildContext context) =>
                      Navigator.of(context).pushNamed(Routes.devMoneroBackgroundSync),
                ),
              if (FeatureFlag.hasDevOptions && [WalletType.monero, WalletType.wownero, WalletType.zano].contains(_otherSettingsViewModel.walletType))
                SettingsCellWithArrow(
                  title: '[dev] xmr call profiler',
                  handler: (BuildContext context) =>
                      Navigator.of(context).pushNamed(Routes.devMoneroCallProfiler),
                ),
              if (FeatureFlag.hasDevOptions && [WalletType.monero].contains(_otherSettingsViewModel.walletType))
                SettingsCellWithArrow(
                  title: '[dev] xmr wallet cache debug',
                  handler: (BuildContext context) =>
                      Navigator.of(context).pushNamed(Routes.devMoneroWalletCacheDebug),
                ),
              if (FeatureFlag.hasDevOptions)
                SettingsCellWithArrow(
                  title: '[dev] shared preferences',
                  handler: (BuildContext context) =>
                      Navigator.of(context).pushNamed(Routes.devSharedPreferences),
                ),
              if (FeatureFlag.hasDevOptions)
                SettingsCellWithArrow(
                  title: '[dev] secure storage preferences',
                  handler: (BuildContext context) =>
                      Navigator.of(context).pushNamed(Routes.devSecurePreferences),
                ),
              if (FeatureFlag.hasDevOptions)
                SettingsCellWithArrow(
                  title: '[dev] background sync logs',
                  handler: (BuildContext context) =>
                      Navigator.of(context).pushNamed(Routes.devBackgroundSyncLogs),
                ),
              if (FeatureFlag.hasDevOptions)
                SettingsCellWithArrow(
                  title: '[dev] socket health logs',
                  handler: (BuildContext context) =>
                      Navigator.of(context).pushNamed(Routes.devSocketHealthLogs),
                ),
              if (FeatureFlag.hasDevOptions)
                SettingsCellWithArrow(
                  title: '[dev] network requests logs',
                  handler: (BuildContext context) =>
                      Navigator.of(context).pushNamed(Routes.devNetworkRequests),
                ),
              Spacer(),
              SettingsVersionCell(
                  title: S.of(context).version(_otherSettingsViewModel.currentVersion)),
            ],
          ),
        );
      },
    );
  }
}
