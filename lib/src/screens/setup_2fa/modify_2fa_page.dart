import 'package:cake_wallet/entities/cake_2fa_preset_options.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_choices_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/settings/choices_list_item.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/view_model/set_up_2fa_viewmodel.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../routes.dart';

class Modify2FAPage extends BasePage {
  Modify2FAPage({required this.setup2FAViewModel});

  final Setup2FAViewModel setup2FAViewModel;

  @override
  String get title => S.current.modify_2fa;

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      child: _2FAControlsWidget(setup2FAViewModel: setup2FAViewModel),
    );
  }
}

class _2FAControlsWidget extends StatelessWidget {
  const _2FAControlsWidget({required this.setup2FAViewModel});

  final Setup2FAViewModel setup2FAViewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsCellWithArrow(
          title: S.current.disable_cake_2fa,
          handler: (_) async {
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
                    Navigator.pushNamedAndRemoveUntil(context, Routes.dashboard, (route) => false);
                  },
                );
              },
            );
          },
        ),
        StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
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
            );
          },
        ),
        Observer(
          builder: (context) {
            return SettingsSwitcherCell(
              title: S.current.require_for_assessing_wallet,
              value: setup2FAViewModel.shouldRequireTOTP2FAForAccessingWallet,
              onValueChange: (context, value) async =>
                  setup2FAViewModel.switchShouldRequireTOTP2FAForAccessingWallet(value),
            );
          },
        ),
        StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
        Observer(
          builder: (context) {
            return SettingsSwitcherCell(
              title: S.current.require_for_sends_to_non_contacts,
              value: setup2FAViewModel.shouldRequireTOTP2FAForSendsToNonContact,
              onValueChange: (context, value) async =>
                  setup2FAViewModel.switchShouldRequireTOTP2FAForSendsToNonContact(value),
            );
          },
        ),
        StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
        Observer(
          builder: (context) {
            return SettingsSwitcherCell(
              title: S.current.require_for_sends_to_contacts,
              value: setup2FAViewModel.shouldRequireTOTP2FAForSendsToContact,
              onValueChange: (context, value) async =>
                  setup2FAViewModel.switchShouldRequireTOTP2FAForSendsToContact(value),
            );
          },
        ),
        StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
        Observer(
          builder: (context) {
            return SettingsSwitcherCell(
              title: S.current.require_for_sends_to_internal_wallets,
              value: setup2FAViewModel.shouldRequireTOTP2FAForSendsToInternalWallets,
              onValueChange: (context, value) async =>
                  setup2FAViewModel.switchShouldRequireTOTP2FAForSendsToInternalWallets(value),
            );
          },
        ),
        StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
        Observer(
          builder: (context) {
            return SettingsSwitcherCell(
              title: S.current.require_for_exchanges_to_internal_wallets,
              value: setup2FAViewModel.shouldRequireTOTP2FAForExchangesToInternalWallets,
              onValueChange: (context, value) async =>
                  setup2FAViewModel.switchShouldRequireTOTP2FAForExchangesToInternalWallets(value),
            );
          },
        ),
        StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
        Observer(
          builder: (context) {
            return SettingsSwitcherCell(
              title: S.current.require_for_exchanges_to_external_wallets,
              value: setup2FAViewModel.shouldRequireTOTP2FAForExchangesToExternalWallets,
              onValueChange: (context, value) async =>
                  setup2FAViewModel.switchShouldRequireTOTP2FAForExchangesToExternalWallets(value),
            );
          },
        ),
        StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
        Observer(
          builder: (context) {
            return SettingsSwitcherCell(
              title: S.current.require_for_adding_contacts,
              value: setup2FAViewModel.shouldRequireTOTP2FAForAddingContacts,
              onValueChange: (context, value) async =>
                  setup2FAViewModel.switchShouldRequireTOTP2FAForAddingContacts(value),
            );
          },
        ),
        StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
        Observer(
          builder: (context) {
            return SettingsSwitcherCell(
              title: S.current.require_for_creating_new_wallets,
              value: setup2FAViewModel.shouldRequireTOTP2FAForCreatingNewWallets,
              onValueChange: (context, value) async =>
                  setup2FAViewModel.switchShouldRequireTOTP2FAForCreatingNewWallet(value),
            );
          },
        ),
        StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
        Observer(
          builder: (context) {
            return SettingsSwitcherCell(
              title: S.current.require_for_all_security_and_backup_settings,
              value: setup2FAViewModel.shouldRequireTOTP2FAForAllSecurityAndBackupSettings,
              onValueChange: (context, value) async => setup2FAViewModel
                  .switchShouldRequireTOTP2FAForAllSecurityAndBackupSettings(value),
            );
          },
        ),
        StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
      ],
    );
  }
}
