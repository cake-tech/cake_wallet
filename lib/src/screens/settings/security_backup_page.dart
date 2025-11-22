import 'dart:io';

import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/entities/pin_code_required_duration.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/pin_code/pin_code_widget.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_picker_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/store/settings_store.dart';
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
  String get title => S.current.security_and_backup;

  final SecuritySettingsViewModel _securitySettingsViewModel;

  final bool _isHardwareWallet;

  @override
  Widget body(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (DeviceInfo.instance.isMobile || Platform.isMacOS || Platform.isLinux)
            Observer(builder: (_) {
              return SettingsSwitcherCell(
                  key: ValueKey('security_backup_page_allow_biometrics_button_key'),
                  title: S.current.settings_allow_biometrical_authentication,
                  value: _securitySettingsViewModel.allowBiometricalAuthentication,
                  onValueChange: (BuildContext context, bool value) {
                    if (value) {
                      _authService.authenticateAction(
                        context,
                        onAuthSuccess: (isAuthenticatedSuccessfully) async {
                          if (isAuthenticatedSuccessfully) {
                            if (await _securitySettingsViewModel.biometricAuthenticated()) {
                              _securitySettingsViewModel
                                  .setAllowBiometricalAuthentication(isAuthenticatedSuccessfully);
                            }
                          } else {
                            _securitySettingsViewModel
                                .setAllowBiometricalAuthentication(isAuthenticatedSuccessfully);
                          }
                        },
                        conditionToDetermineIfToUse2FA: _securitySettingsViewModel
                            .shouldRequireTOTP2FAForAllSecurityAndBackupSettings,
                      );
                    } else {
                      _securitySettingsViewModel.setAllowBiometricalAuthentication(value);
                    }
                  });
            }),
          if (FeatureFlag.duressPinEnabled)
            Observer(builder: (_) {
              return SettingsSwitcherCell(
                  key: ValueKey('security_backup_page_duress_pin_button_key'),
                  title: 'Duress PIN',
                  value: _securitySettingsViewModel.enableDuressPin,
                  onValueChange: (BuildContext context, bool value) {
                    _authService.authenticateAction(context, route: Routes.securityBackupDuressPin,
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
                              arguments: (PinCodeState<PinCodeWidget> pinCtx, String _) async {
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
                  });
            }),
          Observer(builder: (_) {
            return SettingsPickerCell<PinCodeRequiredDuration>(
              key: ValueKey('security_backup_page_require_pin_after_button_key'),
              title: S.current.require_pin_after,
              items: PinCodeRequiredDuration.values,
              selectedItem: _securitySettingsViewModel.pinCodeRequiredDuration,
              onItemSelected: (PinCodeRequiredDuration code) {
                _securitySettingsViewModel.setPinCodeRequiredDuration(code);
              },
            );
          }),
          if (!_isHardwareWallet)
            SettingsCellWithArrow(
              key: ValueKey('security_backup_page_show_keys_button_key'),
              title: S.current.show_keys,
              handler: (_) => _authService.authenticateAction(
                context,
                route: Routes.showKeys,
                conditionToDetermineIfToUse2FA:
                    _securitySettingsViewModel.shouldRequireTOTP2FAForAllSecurityAndBackupSettings,
              ),
            ),
          if (!SettingsStoreBase.walletPasswordDirectInput)
            SettingsCellWithArrow(
              key: ValueKey('security_backup_page_create_backup_button_key'),
              title: S.current.create_backup,
              handler: (_) => _authService.authenticateAction(
                context,
                route: Routes.backup,
                conditionToDetermineIfToUse2FA:
                    _securitySettingsViewModel.shouldRequireTOTP2FAForAllSecurityAndBackupSettings,
              ),
            ),
          SettingsCellWithArrow(
            key: ValueKey('security_backup_page_change_pin_button_key'),
            title: S.current.settings_change_pin,
            handler: (_) => _authService.authenticateAction(
              context,
              route: Routes.setupPin,
              arguments: (PinCodeState<PinCodeWidget> setupPinContext, String _) {
                setupPinContext.close();
              },
              conditionToDetermineIfToUse2FA:
                  _securitySettingsViewModel.shouldRequireTOTP2FAForAllSecurityAndBackupSettings,
            ),
          ),
          SettingsCellWithArrow(
              key: ValueKey('security_backup_page_sign_and_verify'),
              title: S.current.sign_verify_title,
              handler: (_) => Navigator.of(context).pushNamed(Routes.signPage)
              //_securitySettingsViewModel.pinCodeRequiredDuration,
              ),
          Observer(
            builder: (context) {
              return SettingsCellWithArrow(
                key: ValueKey('security_backup_page_totp_2fa_button_key'),
                title: _securitySettingsViewModel.useTotp2FA
                    ? S.current.modify_2fa
                    : S.current.setup_2fa,
                handler: (_) => _authService.authenticateAction(
                  context,
                  route: _securitySettingsViewModel.useTotp2FA
                      ? Routes.modify2FAPage
                      : Routes.setup2faInfoPage,
                  conditionToDetermineIfToUse2FA: _securitySettingsViewModel
                      .shouldRequireTOTP2FAForAllSecurityAndBackupSettings,
                ),
              );
            },
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
