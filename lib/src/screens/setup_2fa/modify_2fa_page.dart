import 'package:cake_wallet/entities/cake_2fa_preset_options.dart';
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_toggle.dart";
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_choices_cell.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/settings/choices_list_item.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/view_model/set_up_2fa_viewmodel.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../../routes.dart';

class Modify2FAPage extends BasePage {
  Modify2FAPage({required this.setup2FAViewModel});

  final Setup2FAViewModel setup2FAViewModel;

  @override
  String get title => S.current.modify_2fa;

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      controller: ModalScrollController.of(context),
      child: _2FAControlsWidget(setup2FAViewModel: setup2FAViewModel),
    );
  }
}

class _2FAControlsWidget extends StatelessWidget {
  const _2FAControlsWidget({required this.setup2FAViewModel});

  final Setup2FAViewModel setup2FAViewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        spacing: 18.0,
        children: [
          Container(
            decoration: ShapeDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(18))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Observer(
                  builder: (context) {
                    return SettingsChoicesCell(
                      ChoicesListItem<Cake2FAPresetsOptions>(
                        title: S.current.cake_2fa_preset,
                        onItemSelected: setup2FAViewModel.selectCakePreset,
                        selectedItem: setup2FAViewModel.selectedCake2FAPreset,
                        items: [
                          Cake2FAPresetsOptions.narrow,
                          Cake2FAPresetsOptions.normal,
                          Cake2FAPresetsOptions.aggressive,
                        ],
                      ),
                      useGenericColor: false,
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  child: Text("Require Cake 2FA For", style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.left,),
                ),
                Observer(
                    builder: (_) => NewListSections(sections: {
                        "2": [
                          ListItemToggle(
                              keyValue: "require_for_accessing_wallet",
                              label: S.current.require_for_assessing_wallet,
                              value: setup2FAViewModel.shouldRequireTOTP2FAForAccessingWallet,
                              onChanged: (val) async =>
                                setup2FAViewModel.switchShouldRequireTOTP2FAForAccessingWallet(val)
                              ),
                          ListItemToggle(
                              keyValue: "require_for_sends_to_non_contacts",
                              label: S.current.require_for_sends_to_non_contacts,
                              value: setup2FAViewModel.shouldRequireTOTP2FAForSendsToNonContact,
                              onChanged: (val) async =>
                                setup2FAViewModel.switchShouldRequireTOTP2FAForSendsToNonContact(val)
                              ),
                          ListItemToggle(
                              keyValue: "require_for_sends_to_contacts",
                              label: S.current.require_for_sends_to_contacts,
                              value: setup2FAViewModel.shouldRequireTOTP2FAForSendsToContact,
                              onChanged: (val) async =>
                                  setup2FAViewModel.switchShouldRequireTOTP2FAForSendsToContact(val)
                          ),
                          ListItemToggle(
                              keyValue: "require_for_sends_to_internal_wallets",
                              label: S.current.require_for_sends_to_internal_wallets,
                              value: setup2FAViewModel.shouldRequireTOTP2FAForSendsToInternalWallets,
                              onChanged: (val) async =>
                                  setup2FAViewModel.switchShouldRequireTOTP2FAForSendsToInternalWallets(val)
                          ),
                          ListItemToggle(
                              keyValue: "require_for_exchanges_to_internal_wallets",
                              label: S.current.require_for_exchanges_to_internal_wallets,
                              value: setup2FAViewModel.shouldRequireTOTP2FAForExchangesToInternalWallets,
                              onChanged: (val) async =>
                                  setup2FAViewModel.switchShouldRequireTOTP2FAForExchangesToInternalWallets(val)
                          ),
                          ListItemToggle(
                              keyValue: "require_for_exchanges_to_external_wallets",
                              label: S.current.require_for_exchanges_to_external_wallets,
                              value: setup2FAViewModel.shouldRequireTOTP2FAForExchangesToExternalWallets,
                              onChanged: (val) async => setup2FAViewModel
                                  .switchShouldRequireTOTP2FAForExchangesToExternalWallets(val)
                          ),
                          ListItemToggle(
                              keyValue: "require_for_adding_contacts",
                              label: S.current.require_for_adding_contacts,
                              value: setup2FAViewModel.shouldRequireTOTP2FAForAddingContacts,
                              onChanged: (val) async =>
                                  setup2FAViewModel.switchShouldRequireTOTP2FAForAddingContacts(val)
                          ),
                          ListItemToggle(
                              keyValue: "require_for_creating_new_wallets",
                              label: S.current.require_for_creating_new_wallets,
                              value: setup2FAViewModel.shouldRequireTOTP2FAForCreatingNewWallets,
                              onChanged: (val) async =>
                                  setup2FAViewModel.switchShouldRequireTOTP2FAForCreatingNewWallet(val)
                          ),
                          ListItemToggle(
                              keyValue: "require_for_all_security_and_backup_settings",
                              label: S.current.require_for_all_security_and_backup_settings,
                              value: setup2FAViewModel.shouldRequireTOTP2FAForAllSecurityAndBackupSettings,
                              onChanged: (val) async => setup2FAViewModel
                                  .switchShouldRequireTOTP2FAForAllSecurityAndBackupSettings(val)
                          ),
                        ]
                        })),
              ],
            ),
          ),
          Observer(
              builder: (_) => NewListSections(sections: {
                "1": [
                  ListItemRegularRow(
                      showArrow: false,
                      foregroundColor: Theme.of(context).colorScheme.error,
                      keyValue: "disable_cake_2fa",
                      label: S.current.disable_cake_2fa,
                      onTap: () async {
                        await showPopUp<void>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertWithTwoActions(
                              alertTitle: S.current.disable_cake_2fa,
                              alertContent: S.current.question_to_disable_2fa,
                              leftButtonText: S.current.cancel,
                              rightButtonText: S.current.disable,
                              actionLeftButton: () => Navigator.of(context).pop(),
                              actionRightButton: () {
                                setup2FAViewModel.setUseTOTP2FA(false);
                                Navigator.pushNamedAndRemoveUntil(
                                    context, Routes.dashboard, (route) => false);
                              },
                            );
                          },
                        );
                      }),
                ]
              })
          )
        ],
      ),

    );
  }
}
