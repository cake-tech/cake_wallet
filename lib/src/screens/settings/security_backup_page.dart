import 'package:cake_wallet/entities/pin_code_required_duration.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/pin_code/pin_code_widget.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_picker_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/view_model/settings/security_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class SecurityBackupPage extends BasePage {
  SecurityBackupPage(this._securitySettingsViewModel);

  @override
  String get title => S.current.security_and_backup;

  final SecuritySettingsViewModel _securitySettingsViewModel;

  @override
  Widget body(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 10),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SettingsCellWithArrow(
          title: S.current.show_keys,
          handler: (_) => _securitySettingsViewModel.checkPinCodeRiquired()
              ? Navigator.of(context).pushNamed(Routes.auth,
                  arguments: (bool isAuthenticatedSuccessfully, AuthPageState auth) {
                  if (isAuthenticatedSuccessfully) {
                    auth.close(route: Routes.showKeys);
                  }
                })
              : Navigator.of(context).pushNamed(Routes.showKeys),
        ),
        StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
        SettingsCellWithArrow(
          title: S.current.create_backup,
          handler: (_) => _securitySettingsViewModel.checkPinCodeRiquired()
              ? Navigator.of(context).pushNamed(Routes.auth,
                  arguments: (bool isAuthenticatedSuccessfully, AuthPageState auth) {
                  if (isAuthenticatedSuccessfully) {
                    auth.close(route: Routes.backup);
                  }
                })
              : Navigator.of(context).pushNamed(Routes.backup),
        ),
        StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
        SettingsCellWithArrow(
            title: S.current.settings_change_pin,
            handler: (_) => Navigator.of(context).pushNamed(Routes.auth,
                    arguments: (bool isAuthenticatedSuccessfully, AuthPageState auth) {
                  auth.close(
                    route: isAuthenticatedSuccessfully ? Routes.setupPin : null,
                    arguments: (PinCodeState<PinCodeWidget> setupPinContext, String _) {
                      setupPinContext.close();
                    },
                  );
                })),
        StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
        Observer(builder: (_) {
          return SettingsSwitcherCell(
              title: S.current.settings_allow_biometrical_authentication,
              value: _securitySettingsViewModel.allowBiometricalAuthentication,
              onValueChange: (BuildContext context, bool value) {
                if (value) {
                  Navigator.of(context).pushNamed(Routes.auth,
                      arguments: (bool isAuthenticatedSuccessfully, AuthPageState auth) async {
                    if (isAuthenticatedSuccessfully) {
                      if (await _securitySettingsViewModel.biometricAuthenticated()) {
                        _securitySettingsViewModel
                            .setAllowBiometricalAuthentication(isAuthenticatedSuccessfully);
                      }
                    } else {
                      _securitySettingsViewModel
                          .setAllowBiometricalAuthentication(isAuthenticatedSuccessfully);
                    }

                    auth.close();
                  });
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
      ]),
    );
  }
}
