import 'dart:io';

import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/entities/automatic_backup_mode.dart';
import 'package:cake_wallet/entities/exchange_api_mode.dart';
import 'package:cake_wallet/entities/pin_code_required_duration.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/pin_code/pin_code_widget.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_choices_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_picker_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/view_model/settings/choices_list_item.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/store/settings_store.dart';
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
          if (!_isHardwareWallet)
            SettingsCellWithArrow(
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
              title: S.current.create_backup,
              handler: (_) => _authService.authenticateAction(
                context,
                route: Routes.backup,
                conditionToDetermineIfToUse2FA:
                    _securitySettingsViewModel.shouldRequireTOTP2FAForAllSecurityAndBackupSettings,
              ),
            ),
          SettingsCellWithArrow(
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
          if (DeviceInfo.instance.isMobile || Platform.isMacOS || Platform.isLinux)
            Observer(builder: (_) {
              return SettingsSwitcherCell(
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
          Observer(builder: (_) {
            return SettingsPickerCell<PinCodeRequiredDuration>(
              title: S.current.require_pin_after,
              items: PinCodeRequiredDuration.values,
              selectedItem: _securitySettingsViewModel.pinCodeRequiredDuration,
              onItemSelected: (PinCodeRequiredDuration code) {
                _securitySettingsViewModel.setPinCodeRequiredDuration(code);
              },
            );
          }),
          Container(
            padding: const EdgeInsets.only(top: 2, bottom: 2, right: 6),
            margin: const EdgeInsets.only(left: 24, right: 24, top: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(15)),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            child: Column(
              children: [
                SettingsCellWithArrow(
                  title: S.current.create_backup,
                  handler: (_) => _authService.authenticateAction(
                    context,
                    route: Routes.backup,
                    conditionToDetermineIfToUse2FA: _securitySettingsViewModel
                        .shouldRequireTOTP2FAForAllSecurityAndBackupSettings,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0),
                  ),
                ),
                Observer(builder: (_) {
                  return SettingsChoicesCell(
                    bgColor: Colors.black.withOpacity(0),
                    ChoicesListItem<AutomaticBackupMode>(
                      title: S.current.automatic_backups,
                      items: AutomaticBackupMode.all,
                      selectedItem: _securitySettingsViewModel.autoBackupMode,
                      onItemSelected: (AutomaticBackupMode mode) =>
                          _securitySettingsViewModel.setAutomaticBackupMode(mode),
                    ),
                  );
                }),
                if (FeatureFlag.isBackupFolderPickerEnabled) ...[
                  PrimaryButton(
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                    text: S.current.pick_auto_backup_dir,
                    onPressed: () {
                      _securitySettingsViewModel.pickAutomaticBackupsDirectory();
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
