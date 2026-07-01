import 'dart:io';

import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_selector.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_toggle.dart';
import 'package:cake_wallet/entities/pin_code_required_duration.dart';
import 'package:cake_wallet/new-ui/widgets/modal_header.dart';
import 'package:cake_wallet/new-ui/widgets/modal_page_wrapper.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/pin_code/pin_code_widget.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/settings/security_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class SecurityBackupPage extends BasePage {
  SecurityBackupPage(this._securitySettingsViewModel, this._authService,
      [this._isHardwareWallet = false]);

  final AuthService _authService;

  @override
  bool get hideAppBar => true;

  @override
  String get title => S.current.security_and_backup;

  final SecuritySettingsViewModel _securitySettingsViewModel;

  final bool _isHardwareWallet;

  @override
  Widget body(BuildContext context) {
    return ModalPageWrapper(
      topBar: ModalTopBar(
          title: "",
          leadingIcon: Icon(Icons.arrow_back_ios_new),
          onLeadingPressed: () => Navigator.of(context).pop()),
      header: ModalHeader(
          iconPath: "assets/new-ui/settings_row_icons/security.svg",
          message: S.of(context).privacy_and_security_desc,
          title: S.of(context).security),
      content: Column(
        spacing: 16,
        mainAxisSize: MainAxisSize.min,
        children: [
          Observer(
            builder: (_) => NewListSections(sections: {
              "": [
                if (DeviceInfo.instance.isMobile || Platform.isMacOS || Platform.isLinux)
                  ListItemToggle(
                      keyValue: "security_backup_page_allow_biometrics_button_key",
                      label: S.current.settings_allow_biometrical_authentication,
                      value: _securitySettingsViewModel.allowBiometricalAuthentication,
                      onChanged: (bool value) {
                        if (value) {
                          _authService.authenticateAction(
                            context,
                            onAuthSuccess: (isAuthenticatedSuccessfully) async {
                              if (isAuthenticatedSuccessfully) {
                                if (await _securitySettingsViewModel.biometricAuthenticated()) {
                                  _securitySettingsViewModel.setAllowBiometricalAuthentication(
                                      isAuthenticatedSuccessfully);
                                }
                              } else {
                                _securitySettingsViewModel.setAllowBiometricalAuthentication(
                                    isAuthenticatedSuccessfully);
                              }
                            },
                            conditionToDetermineIfToUse2FA: _securitySettingsViewModel
                                .shouldRequireTOTP2FAForAllSecurityAndBackupSettings,
                          );
                        } else {
                          _securitySettingsViewModel.setAllowBiometricalAuthentication(value);
                        }
                      }),
                if (DeviceInfo.instance.isMobile)
                ListItemToggle(
                    keyValue: "display_settings_prevent_screen_capture",
                    label: S.of(context).prevent_screenshots,
                    value: _securitySettingsViewModel.isAppSecure,
                    onChanged: (val) {
                      _securitySettingsViewModel.setIsAppSecure(val);
                    }),
                if (FeatureFlag.duressPinEnabled)
                  ListItemToggle(
                      keyValue: "security_backup_page_duress_pin_button_key",
                      label: "Duress PIN",
                      value: _securitySettingsViewModel.enableDuressPin,
                      onChanged: (bool value) {
                        _authService
                            .authenticateAction(context, route: Routes.securityBackupDuressPin,
                                onAuthSuccess: (isAuthenticatedSuccessfully) async {
                          if (isAuthenticatedSuccessfully) {
                            if (!value) {
                              _securitySettingsViewModel.setEnableDuressPin(value);
                              _securitySettingsViewModel.clearDuressPin();
                              return;
                            }
                            final res = await _showDuressPinDescription(context);
                            if (res) {
                              final confirmation = await _showDuressPinConfirmation(context);

                              if (confirmation) {
                                Navigator.of(context).pushNamed(
                                  Routes.setupDuressPin,
                                  arguments:
                                      (PinCodeState<PinCodeWidget> pinCtx, String _) async {
                                    pinCtx.close();
                                    _securitySettingsViewModel.setEnableDuressPin(true);
                                  },
                                );
                              }
                            }
                          }
                        },
                                conditionToDetermineIfToUse2FA: _securitySettingsViewModel
                                    .shouldRequireTOTP2FAForAllSecurityAndBackupSettings);
                      }),
                ListItemSelector(
                    keyValue: "security_backup_page_require_pin_after_button_key",
                    label: S.current.require_pin_after,
                    options: [_securitySettingsViewModel.pinCodeRequiredDuration.toString()],
                    onTap: () async {
                      final items = PinCodeRequiredDuration.values;

                      final selectedAtIndex =
                          items.indexOf(_securitySettingsViewModel.pinCodeRequiredDuration);

                      await showPopUp<void>(
                        context: context,
                        builder: (_) => Picker(
                          items: items,
                          selectedAtIndex: selectedAtIndex,
                          mainAxisAlignment: MainAxisAlignment.start,
                          onItemSelected: (PinCodeRequiredDuration item) {
                            _securitySettingsViewModel.setPinCodeRequiredDuration(item);
                          },
                          isSeparated: false,
                        ),
                      );
                    }),
                // if (!_isHardwareWallet)
                //   ListItemRegularRow(
                //       keyValue: "security_backup_page_show_keys_button_key",
                //       label: S.current.show_keys,
                //       onTap: () {
                //         _authService.authenticateAction(
                //           context,
                //           route: Routes.showKeys,
                //           conditionToDetermineIfToUse2FA: _securitySettingsViewModel
                //               .shouldRequireTOTP2FAForAllSecurityAndBackupSettings,
                //         );
                //       }),
                ListItemRegularRow(
                    keyValue: "security_backup_page_change_pin_button_key",
                    label: S.current.settings_change_pin,
                    onTap: () {
                      _authService.authenticateAction(
                        context,
                        route: Routes.setupPin,
                        arguments: (PinCodeState<PinCodeWidget> setupPinContext, String _) {
                          setupPinContext.close();
                        },
                        conditionToDetermineIfToUse2FA: _securitySettingsViewModel
                            .shouldRequireTOTP2FAForAllSecurityAndBackupSettings,
                      );
                    }),
                ListItemRegularRow(
                    keyValue: "security_backup_page_totp_2fa_button_key",
                    label: _securitySettingsViewModel.useTotp2FA
                        ? S.current.modify_2fa
                        : S.current.setup_2fa,
                    onTap: () {
                      _authService.authenticateAction(
                        context,
                        route: _securitySettingsViewModel.useTotp2FA
                            ? Routes.modify2FAPage
                            : Routes.setup2faInfoPage,
                        conditionToDetermineIfToUse2FA: _securitySettingsViewModel
                            .shouldRequireTOTP2FAForAllSecurityAndBackupSettings,
                      );
                    })
              ]
            }),
          ),
        ],
      ),
    );
  }
}

Future<bool> _showDuressPinDescription(BuildContext context) async {
  final ok = await showPopUp<bool>(
      context: context,
      builder: (BuildContext context) => AlertWithOneAction(
          alertTitle: S.of(context).alert_notice,
          alertContent: S.current.duress_pin_description,
          buttonText: S.of(context).ok,
          buttonAction: () => Navigator.of(context).pop(true)));
  return ok ?? false;
}

Future<bool> _showDuressPinConfirmation(BuildContext context) async {
  final ok = await showPopUp<bool>(
      context: context,
      builder: (BuildContext context) => AlertWithTwoActions(
          alertTitle: S.of(context).confirm,
          alertContent: S.current.did_you_back_up_seeds,
          leftButtonText: S.current.no,
          rightButtonText: S.current.yes,
          actionLeftButton: () => Navigator.of(context).pop(false),
          actionRightButton: () => Navigator.of(context).pop(true)));
  return ok ?? false;
}
