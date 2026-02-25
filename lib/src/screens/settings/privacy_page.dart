import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_toggle.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/modal_header.dart';
import 'package:cake_wallet/new-ui/widgets/modal_page_wrapper.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/view_model/settings/privacy_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class PrivacyPage extends BasePage {
  PrivacyPage(this._privacySettingsViewModel);

  @override
  bool get hideAppBar => true;

  final PrivacySettingsViewModel _privacySettingsViewModel;

  @override
  Widget body(BuildContext context) {
    return ModalPageWrapper(
      topBar: ModalTopBar(
        title: "",
        leadingIcon: Icon(Icons.arrow_back_ios_new),
        onLeadingPressed: () => Navigator.of(context).pop(),
      ),
      header: ModalHeader(
          iconPath: "assets/new-ui/settings_row_icons/privacy.svg",
          message: S.of(context).privacy_desc,
          title: S.of(context).privacy),
      content: SingleChildScrollView(
        child: Container(
          child: Observer(builder: (_) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NewListSections(
                  sections: {
                    "1": [
                      if (_privacySettingsViewModel.isAutoGenerateSubaddressesVisible)
                        ListItemToggle(
                            keyValue: "auto_generate_subaddresses",
                            label: S.current.auto_generate_subaddresses,
                            value: _privacySettingsViewModel.isAutoGenerateSubaddressesEnabled,
                            onChanged: (val) {
                              _privacySettingsViewModel.setAutoGenerateSubaddresses(val);
                            }),
                      ListItemToggle(
                          keyValue: "save_recipient_address",
                          label: S.current.settings_save_recipient_address,
                          value: _privacySettingsViewModel.shouldSaveRecipientAddress,
                          onChanged: (val) {
                            _privacySettingsViewModel.setShouldSaveRecipientAddress(val);
                          }),
                    ],
                    "": [
                    if (_privacySettingsViewModel.isBitcoin)
                      ListItemRegularRow(
                          iconPath: "assets/new-ui/settings_row_icons/silent-payments.svg",
                          keyValue: "silent_payments",
                          label: S.current.silent_payments,
                          onTap: () =>
                              Navigator.of(context).pushNamed(Routes.silentPaymentsSettings)),
                    if (_privacySettingsViewModel.canUsePayjoin)
                      ListItemToggle(
                          keyValue: "use_payjoin",
                          label: S.current.use_payjoin,
                          value: _privacySettingsViewModel.usePayjoin,
                          onChanged: (val) {
                            _privacySettingsViewModel.setUsePayjoin(val);
                          }),
                  ],
                }
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
