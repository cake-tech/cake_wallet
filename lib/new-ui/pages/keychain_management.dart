import "dart:io";

import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_toggle.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/keychain_restore.dart";
import "package:cake_wallet/new-ui/viewmodels/keychain_management/keychain_management_bloc.dart";
import "package:cake_wallet/new-ui/widgets/keychain_management/keychain_management_steps.dart";
import "package:cake_wallet/new-ui/widgets/modal_header.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/widgets/alert_with_two_actions.dart";
import "package:cake_wallet/src/widgets/base_alert_dialog.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/src/widgets/standard_switch.dart";
import "package:cake_wallet/themes/core/theme_extension.dart";
import "package:cake_wallet/utils/date_formatter.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/view_model/wallet_seed_view_model.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class KeychainManagementPage extends StatelessWidget {
  const KeychainManagementPage({required this.bloc, super.key});

  final KeychainManagementBloc bloc;

  String get cloudServiceName => Platform.isAndroid ? "Google Keystore" : "iCloud Keychain";

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: BlocBuilder<KeychainManagementBloc, KeychainManagementState>(
          bloc: bloc,
          builder: (context, state) => Column(
            children: [
              ModalTopBar(
                title: "",
                leadingIcon: const Icon(Icons.arrow_back_ios_new),
                onLeadingPressed: Navigator.of(context).pop,
                leadingSemanticLabel: S.of(context).seed_alert_back,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    spacing: 24,
                    children: [
                      ModalHeader(
                        iconPath: "assets/new-ui/cloud_keys.svg",
                        message: S.of(context).cloud_keys_desc(cloudServiceName),
                        title: S.of(context).cloud_keys,
                      ),
                      if (state is KeychainManagementNotLoaded) const CupertinoActivityIndicator(),
                      if (state is KeychainManagementLoaded)
                        NewListSections(sections: {
                          if (state.unsupportedKeychainItems.isNotEmpty || state.items.isNotEmpty)
                            "": [
                              ListItemRegularRow(
                                  keyValue: "delete all",
                                  label: S.of(context).delete_all_keychain_data,
                                  onTap: () => _confirmClear(context, state.hasUnrestoredWallets),
                                  foregroundColor: Theme.of(context).colorScheme.error,
                                  showArrow: false)
                            ],
                          if (state.unsupportedKeychainItems.isNotEmpty)
                            S.of(context).unsupported: state.unsupportedKeychainItems
                                .map(
                                  (item) => ListItemRegularRow(
                                    iconPath: deserializeFromInt(item.walletTypeRaw).iconPath,
                                    keyValue: item.name,
                                    label: item.name,
                                    subtitle: S.of(context).unsupported_keychain_item,
                                    showArrow: false,
                                  ),
                                )
                                .toList(),
                        }),
                      if (state is KeychainManagementLoaded)
                        Column(
                            spacing: 12,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                S.of(context).contact_list_wallets,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              if(state.hasUnrestoredWallets)
                                GestureDetector(
                                  onTap: () => _showUnrestoredInfo(context),
                                  child: Row(spacing:4, children: [
                                    Text(S.of(context).some_wallets_unrestored, style: TextStyle(fontSize: 12, color: context.currentTheme.customColors.warningOutlineColor),),
                                    Icon(size:14,Icons.info_outline, color: context.currentTheme.customColors.warningOutlineColor,)
                                  ],),
                                ),
                              NewListSections(sections: {
                                "": state.items
                                    .map(
                                      (item) => ListItemRegularRow(
                                        iconPath: item.type.iconPath,
                                        keyValue: item.name,
                                        label: item.name,
                                        subtitle: item.dateSaved == null
                                            ? S.of(context).not_saved
                                            : "${S.of(context).saved} ${DateFormatter.withCurrentLocal(hasTime: false).format(item.dateSaved!)}",
                                        onTap: item.isRestored ? null : () => _showNotRestored(context, item),
                                        trailingWidget: Row(spacing:8,
                                          children: [
if(!item.isRestored)CakeImageWidget(imageUrl: "assets/new-ui/not_restored.svg",width:24,height:24,colorFilter: ColorFilter.mode(context.currentTheme.customColors.warningOutlineColor,BlendMode.srcIn),),
                                            StandardSwitch(value: item.isBackedUp,
                                            onTapped: () => item.isBackedUp
                                                ? _confirmUnsave(context, item, state.items.indexOf(item))
                                                : _confirmSave(context, state.items.indexOf(item)),),
                                          ],
                                        )
                                      ),
                                    )
                                    .toList(),
                              })
                            ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _confirmClear(BuildContext context, bool hasUnrestoredWallets) async {
    final confirmed = await _showRemovalWarning(
      context,
      description: S.of(context).keychain_remove_all_warning,
      target: S.of(context).all_wallets,
      targetColor: Theme.of(context).colorScheme.error,
      manualBackupText: S.of(context).keychain_manual_backup_all_wallets,
      unrestoredTitle: hasUnrestoredWallets ? S.of(context).some_wallets_unrestored : null,
      unrestoredSubtitle: S.of(context).keychain_remove_unrestored_wallets,
    );

    if (confirmed ?? false) {
      bloc.add(const KeychainCleared());
    }
  }

  Future<void> _confirmUnsave(BuildContext context, KeychainManagementItem item, int index) async {
    final confirmed = await _showRemovalWarning(
      context,
      description: S.of(context).keychain_remove_wallet_warning,
      target: item.name,
      targetColor: Theme.of(context).colorScheme.primary,
      manualBackupText: S.of(context).keychain_manual_backup_this_wallet,
      unrestoredTitle: item.isRestored ? null : S.of(context).wallet_currently_unrestored,
      unrestoredSubtitle: S.of(context).keychain_remove_unrestored_wallet,
    );

    if (confirmed ?? false) {
      bloc.add(ItemUnsaved(index));
    }
  }

  Future<bool?> _showRemovalWarning(
    BuildContext context, {
    required String description,
    required String target,
    required Color targetColor,
    required String manualBackupText,
    required String? unrestoredTitle,
    required String unrestoredSubtitle,
  }) =>
      showPopUp<bool>(
        context: context,
        builder: (dialogContext) {
          final theme = Theme.of(dialogContext);
          final textStyle = theme.textTheme.bodyMedium?.copyWith(fontSize: 14);

          return AlertWithTwoActions(
            alertTitle: S.of(dialogContext).warning_exclamation,
            alertContentTextWidget: Column(
              spacing: 12,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: "$description "),
                      TextSpan(text: target, style: TextStyle(color: targetColor)),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: textStyle,
                ),
                Text(
                  S.of(dialogContext).before_proceeding_keep_in_mind,
                  textAlign: TextAlign.center,
                  style: textStyle?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            leftButtonText: S.of(dialogContext).cancel,
            rightButtonText: S.of(dialogContext).delete,
            actionLeftButton: () => Navigator.of(dialogContext).pop(false),
            actionRightButton: () => Navigator.of(dialogContext).pop(true),
            leftAlertButtonStyle: AlertButtonStyle(
              backgroundColor: theme.colorScheme.surfaceContainer,
              textColor: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
            rightAlertButtonStyle: AlertButtonStyle(
              backgroundColor: theme.colorScheme.errorContainer,
              textColor: theme.colorScheme.onErrorContainer,
            ),
            child: unrestoredTitle == null
                ? KeychainManualBackupStep(
                    centered: true,
                    iconSize: 50,
                    title: manualBackupText,
                    titleColor: dialogContext.currentTheme.customColors.warningOutlineColor,
                  )
                : Column(
                    spacing: 12,
                    children: [
                      KeychainNotRestoredStep(title: unrestoredTitle, subtitle: unrestoredSubtitle),
                      KeychainManualBackupStep(
                        title: manualBackupText,
                        titleColor: theme.colorScheme.primary,
                      ),
                    ],
                  ),
          );
        },
      );

  Future<void> _confirmSave(BuildContext context, int index) async {
    final confirmed = await showPopUp<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return AlertWithTwoActions(
          alertTitle: S.of(dialogContext).save_to_keychain_question,
          alertContent: S.of(dialogContext).keychain_save_wallet_desc,
          leftButtonText: S.of(dialogContext).cancel,
          rightButtonText: S.of(dialogContext).save,
          actionLeftButton: () => Navigator.of(dialogContext).pop(false),
          actionRightButton: () => Navigator.of(dialogContext).pop(true),
          leftAlertButtonStyle: AlertButtonStyle(
            backgroundColor: theme.colorScheme.surfaceContainerHigh,
            textColor: theme.colorScheme.onSurfaceVariant,
          ),
          rightAlertButtonStyle: AlertButtonStyle(
            backgroundColor: theme.colorScheme.primary,
            textColor: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w500,
          ),
          child: KeychainManualBackupStep(
            iconSize: 36,
            faded: false,
            title: S.of(dialogContext).keychain_save_manual_backup_hint,
            titleColor: theme.colorScheme.primary,
          ),
        );
      },
    );

    if (confirmed ?? false) {
      bloc.add(ItemSaved(index));
    }
  }

  Future<void> _showNotRestored(BuildContext context, KeychainManagementItem item) async {
    final confirmed = await showPopUp<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return AlertWithTwoActions(
          alertTitle: S.of(dialogContext).wallet_not_restored,
          leftButtonText: S.of(dialogContext).cancel,
          rightButtonText: S.of(dialogContext).continue_text,
          actionLeftButton: () => Navigator.of(dialogContext).pop(false),
          actionRightButton: () => Navigator.of(dialogContext).pop(true),
          rightAlertButtonStyle: AlertButtonStyle(
            backgroundColor: theme.colorScheme.primary,
            textColor: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w500,
          ),
          child: KeychainWalletNotRestoredContent(
            onViewRecoveryPhrase: item.seed == null
                ? null
                : () => _showRecoveryPhrase(dialogContext, item.seed!),
          ),
        );
      },
    );

    if (!(confirmed ?? false) || !context.mounted) {
      return;
    }

    await Navigator.of(context).pushNamed(
      Routes.keychainRestorePage,
      arguments: KeychainRestorePageParams(isInitial: false, preselectedWalletName: item.name),
    );
    bloc.add(const KeychainReloaded());
  }

  void _showRecoveryPhrase(BuildContext context, String seed) => Navigator.of(context).pushNamed(
        Routes.seed,
        arguments: WalletSeedPageParams(isNewWalletCreated: false, seedOverride: seed),
      );

  void _showUnrestoredInfo(BuildContext context) => showMaterialModalBottomSheet<void>(
        backgroundColor: Colors.transparent,
        context: context,
        builder: (_) => const KeychainUnrestoredWalletsSheet(),
      );
}
