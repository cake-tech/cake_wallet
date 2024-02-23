import 'package:cake_wallet/entities/priority_for_wallet_type.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_picker_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_version_cell.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/view_model/settings/other_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class OtherSettingsPage extends BasePage {
  OtherSettingsPage(this._otherSettingsViewModel);

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
              if(_otherSettingsViewModel.isEnabledBuyAction)
              SettingsPickerCell(
                title: S.current.default_buy_provider,
                items: _otherSettingsViewModel.availableBuyProvidersTypes,
                displayItem: _otherSettingsViewModel.getBuyProviderType,
                selectedItem: _otherSettingsViewModel.buyProviderType,
                onItemSelected: _otherSettingsViewModel.onBuyProviderTypeSelected
              ),
              if(_otherSettingsViewModel.isEnabledSellAction)
              SettingsPickerCell(
                title: S.current.default_sell_provider,
                items: _otherSettingsViewModel.availableSellProvidersTypes,
                displayItem: _otherSettingsViewModel.getSellProviderType,
                selectedItem: _otherSettingsViewModel.sellProviderType,
                onItemSelected: _otherSettingsViewModel.onSellProviderTypeSelected,
              ),
              SettingsCellWithArrow(
                title: S.current.settings_terms_and_conditions,
                handler: (BuildContext context) =>
                    Navigator.of(context).pushNamed(Routes.readDisclaimer),
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
