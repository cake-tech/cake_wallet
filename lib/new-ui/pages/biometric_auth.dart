import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_toggle.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/modal_header.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/view_model/settings/security_settings_view_model.dart";
import "package:flutter/material.dart";
import "package:flutter_mobx/flutter_mobx.dart";

class BiometricAuthPage extends StatelessWidget {
  const BiometricAuthPage({required SecuritySettingsViewModel securitySettingsViewModel, super.key})
      : _securitySettingsViewModel = securitySettingsViewModel;

  final SecuritySettingsViewModel _securitySettingsViewModel;

  @override
  Widget build(BuildContext context) => Observer(
        builder: (context) {
          final displayName = _securitySettingsViewModel.biometricDisplayType?.displayName ?? "";
          final iconPath = _securitySettingsViewModel.biometricDisplayType?.iconPath ?? "";

          return ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                ModalTopBar(
                  title: "",
                  leadingIcon: const Icon(Icons.arrow_back_ios_new),
                  onLeadingPressed: Navigator.of(context).pop,
                  leadingSemanticLabel: S.of(context).seed_alert_back,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    spacing: 24,
                    children: [
                      ModalHeader(
                        title: displayName,
                        message: S.of(context).configure_biometric_authentication,
                        iconPath: iconPath,
                      ),
                      Column(spacing: 4, children: [
                        NewListSections(
                          sections: {
                            "": [
                              ListItemToggle(
                                keyValue: "use bio",
                                label: "${S.of(context).use} ${displayName}",
                                value: _securitySettingsViewModel.allowBiometricalAuthentication,
                                onChanged: (value) {
                                  if (value) {
                                    _securitySettingsViewModel.authService.authenticateAction(
                                      context,
                                      onAuthSuccess: (isAuthenticatedSuccessfully) async {
                                        if (isAuthenticatedSuccessfully) {
                                          if (await _securitySettingsViewModel
                                              .biometricAuthenticated()) {
                                            _securitySettingsViewModel
                                                .setAllowBiometricalAuthentication(
                                              isAuthenticatedSuccessfully,
                                            );
                                          }
                                        } else {
                                          _securitySettingsViewModel
                                              .setAllowBiometricalAuthentication(
                                            isAuthenticatedSuccessfully,
                                          );
                                        }
                                      },
                                      conditionToDetermineIfToUse2FA: _securitySettingsViewModel
                                          .shouldRequireTOTP2FAForAllSecurityAndBackupSettings,
                                    );
                                  } else {
                                    _securitySettingsViewModel
                                        .setAllowBiometricalAuthentication(value);
                                  }
                                },
                              ),
                              ListItemToggle(
                                keyValue: "require pin",
                                label: S.of(context).require_pin_for_transactions,
                                value: _securitySettingsViewModel.pinRequiredForTransactions,
                                onChanged: (value) {
                                  _securitySettingsViewModel.authService.authenticateAction(
                                    context,
                                    isTransaction: true,
                                    onAuthSuccess: (isAuthenticatedSuccessfully) {
                                      if (isAuthenticatedSuccessfully) {
                                        _securitySettingsViewModel.pinRequiredForTransactions =
                                            value;
                                      }
                                    },
                                    conditionToDetermineIfToUse2FA: _securitySettingsViewModel
                                        .shouldRequireTOTP2FAForAllSecurityAndBackupSettings,
                                  );
                                },
                              ),
                            ],
                          },
                        ),
                        Text(S.of(context).require_pin_for_transactions_desc,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 12,),),
                      ],),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
}
