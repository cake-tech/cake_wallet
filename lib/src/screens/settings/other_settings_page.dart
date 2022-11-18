import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_picker_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_version_cell.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/view_model/settings/settings_view_model.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class OtherSettingsPage extends BasePage {
  OtherSettingsPage(this._settingsViewModel);

  @override
  String get title => S.current.other_settings;

  final SettingsViewModel _settingsViewModel;

  @override
  Widget body(BuildContext context) {
    return Observer(builder: (_) {
      return Container(
        padding: EdgeInsets.only(top: 10),
        child: Column(children: [
          SettingsPickerCell(
            title: S.current.settings_fee_priority,
            items: priorityForWalletType(_settingsViewModel.walletType),
            displayItem: _settingsViewModel.getDisplayPriority,
            selectedItem: _settingsViewModel.transactionPriority,
            onItemSelected: _settingsViewModel.onDisplayPrioritySelected,
          ),
          SettingsCellWithArrow(
            title: S.current.settings_terms_and_conditions,
            handler: (BuildContext context) => Navigator.of(context).pushNamed(Routes.readDisclaimer),
          ),
          StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
          Spacer(),
          SettingsVersionCell(title: S.of(context).version(_settingsViewModel.currentVersion))
        ]),
      );
    });
  }
}
