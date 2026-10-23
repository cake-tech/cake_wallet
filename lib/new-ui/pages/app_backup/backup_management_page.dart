import "package:cake_wallet/core/backup/app_backup_contents.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/app_backup/app_backup_page.dart";
import "package:cake_wallet/new-ui/pages/app_backup/app_backup_scaffold.dart";
import "package:cake_wallet/new-ui/pages/app_backup/app_backup_storage_ui.dart";
import "package:cake_wallet/new-ui/pages/app_backup/backup_contents_page.dart";
import "package:cake_wallet/new-ui/pages/app_backup/backup_intro_page.dart";
import "package:cake_wallet/new-ui/pages/app_backup/backup_password_page.dart";
import "package:cake_wallet/new-ui/pages/app_backup/backup_preferred_storage_page.dart";
import "package:cake_wallet/new-ui/viewmodels/app_backup/app_backup_bloc.dart";
import "package:cake_wallet/src/widgets/alert_with_two_actions.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/utils/clipboard_util.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:intl/intl.dart";

class BackupManagementPage extends StatelessWidget {
  const BackupManagementPage({super.key});

  Future<void> _confirmPasswordRegeneration(BuildContext context) async {
    final confirmed = await showPopUp<bool>(
      context: context,
      builder: (dialogContext) => AlertWithTwoActions(
        alertTitle: S.of(dialogContext).app_backup_change_password,
        alertContent: S.of(dialogContext).app_backup_regenerate_password_confirmation,
        leftButtonText: S.of(dialogContext).no,
        rightButtonText: S.of(dialogContext).yes,
        actionLeftButton: () => Navigator.of(dialogContext).pop(false),
        actionRightButton: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AppBackupBloc>().add(PasswordRegenerationRequested());
    }
  }

  // not requested by ui, but nice to have in my opinion
  Future<void> _showBackupHash(BuildContext context, String hash) => showPopUp<void>(
        context: context,
        builder: (dialogContext) => AlertWithTwoActions(
          alertTitle: S.of(dialogContext).app_backup_file_hash,
          alertContent: hash,
          alertContentTextWidget: Text(
            hash,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "IBM Plex Mono",
              fontSize: 14,
              color: Theme.of(dialogContext).colorScheme.onSurface,
            ),
          ),
          leftButtonText: S.of(dialogContext).close,
          rightButtonText: S.of(dialogContext).copy,
          actionLeftButton: Navigator.of(dialogContext).pop,
          actionRightButton: () {
            Navigator.of(dialogContext).pop();
            ClipboardUtil.copyToClipboard(context, hash);
          },
        ),
      );

  @override
  Widget build(BuildContext context) => BlocBuilder<AppBackupBloc, AppBackupState>(
        builder: (context, state) => AppBackupScaffold(
          title: "",
          body: state.status != AppBackupStatus.loading
              ? ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    _ManagementHeader(),
                    const SizedBox(height: 16),
                    NewListSections(
                      sections: {
                        "": [
                          ListItemRegularRow(
                            keyValue: "app_backup_show_password",
                            label: S.of(context).app_backup_show_password,
                            onTap: () => AppBackupPage.push(
                              context,
                              const BackupPasswordPage(forSetup: false),
                            ),
                          ),
                          ListItemRegularRow(
                            keyValue: "app_backup_change_password",
                            label: S.of(context).app_backup_change_password,
                            onTap: () => _confirmPasswordRegeneration(context),
                          ),
                          ListItemRegularRow(
                            keyValue: "app_backup_preferred_storage",
                            label: S.of(context).app_backup_preferred_storage,
                            trailingText: state.preferredStorage.shortLabel(context),
                            onTap: () =>
                                AppBackupPage.push(context, const BackupPreferredStoragePage()),
                          ),
                          ListItemRegularRow(
                            keyValue: "app_backup_customize",
                            label: S.of(context).app_backup_customize,
                            subtitle:
                                state.totalSize == null ? "…" : formatBackupSize(state.totalSize!),
                            trailingText: S
                                .of(context)
                                .app_backup_wallets_count(state.selectedCount.toString()),
                            onTap: () => AppBackupPage.push(
                              context,
                              const BackupContentsPage(forSetup: false),
                            ),
                          ),
                        ],
                      },
                    ),
                    if (state.lastBackup != null) ...[
                      const SizedBox(height: 16),
                      NewListSections(
                        sections: {
                          "": [
                            ListItemRegularRow(
                              keyValue: "app_backup_last_backup",
                              label: S.of(context).app_backup_last_backup,
                              subtitle: DateFormat("d MMM yyyy, HH:mm")
                                  .format(state.lastBackup!.createdAt),
                              trailingText: formatBackupSize(state.lastBackup!.sizeInBytes),
                              iconPath: "assets/new-ui/app_backup/backup_file_small.svg",
                              showArrow: false,
                              onLongPress: state.lastBackup!.sha256Hash == null
                                  ? null
                                  : () => _showBackupHash(context, state.lastBackup!.sha256Hash!),
                            ),
                          ],
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    _BackupNowButton(isBackingUp: state.isBusy),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        S.of(context).app_backup_tracking_notice,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              letterSpacing: -0.06,
                            ),
                      ),
                    ),
                  ],
                )
              : const Center(child: CupertinoActivityIndicator()),
        ),
      );
}

class _ManagementHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          spacing: 10,
          children: [
            const CakeImageWidget(
              imageUrl: "assets/new-ui/app_backup/management_header.svg",
              width: 36,
              height: 36,
            ),
            Text(
              S.of(context).app_backup,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(letterSpacing: -0.08),
            ),
            SizedBox(
              width: 250,
              child: Text(
                S.of(context).app_backup_management_description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: -0.06,
                    ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => AppBackupPage.push(context, const BackupIntroPage(aboutOnly: true)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Text(
                    S.of(context).app_backup_about,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: -0.06,
                        ),
                  ),
                  const CakeImageWidget(
                    imageUrl: "assets/new-ui/app_backup/info.svg",
                    width: 14,
                    height: 13.7573,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _BackupNowButton extends StatelessWidget {
  const _BackupNowButton({required this.isBackingUp});

  final bool isBackingUp;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isBackingUp ? null : () => context.read<AppBackupBloc>().add(BackupNowRequested()),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              spacing: 12,
              children: [
                const CakeImageWidget(
                  imageUrl: "assets/new-ui/settings_row_icons/backup.svg",
                  width: 24,
                  height: 24,
                ),
                Expanded(
                  child: Text(
                    S.of(context).app_backup_now,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: -0.07,
                        ),
                  ),
                ),
                isBackingUp
                    ? const CupertinoActivityIndicator()
                    : const CakeImageWidget(
                        imageUrl: "assets/new-ui/app_backup/refresh.svg",
                        width: 24,
                        height: 24,
                      ),
              ],
            ),
          ),
        ),
      );
}
