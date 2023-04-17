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
    return Observer(builder: (_) {
      return Container(
        padding: EdgeInsets.only(top: 10),
        child: Column(children: [
          SettingsPickerCell(
            title: S.current.settings_fee_priority,
            items: priorityForWalletType(_otherSettingsViewModel.walletType),
            displayItem: _otherSettingsViewModel.getDisplayPriority,
            selectedItem: _otherSettingsViewModel.transactionPriority,
            onItemSelected: _otherSettingsViewModel.onDisplayPrioritySelected,
          ),
          SettingsCellWithArrow(
            title: S.current.settings_terms_and_conditions,
            handler: (BuildContext context) => Navigator.of(context).pushNamed(Routes.readDisclaimer),
          ),
          StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
          Spacer(),
          SettingsVersionCell(title: S.of(context).version(_otherSettingsViewModel.currentVersion))
        ]),
      );
    });
  }
}
