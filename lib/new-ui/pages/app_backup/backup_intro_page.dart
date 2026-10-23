import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/app_backup/app_backup_page.dart";
import "package:cake_wallet/new-ui/pages/app_backup/app_backup_scaffold.dart";
import "package:cake_wallet/new-ui/pages/app_backup/backup_contents_page.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/stacked_buttons.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:flutter/material.dart";

class BackupIntroPage extends StatelessWidget {
  const BackupIntroPage({this.aboutOnly = false, super.key});

  final bool aboutOnly;

  @override
  Widget build(BuildContext context) => AppBackupScaffold(
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
            const Center(
              child: CakeImageWidget(
                imageUrl: "assets/new-ui/app_backup/backup_file.svg",
                width: 61.607,
                height: 75,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                S.of(context).app_backup_intro_description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(letterSpacing: -0.07),
              ),
            ),
            const SizedBox(height: 24),
            NewListSections(
              sections: {
                "": [
                  ListItemRegularRow(
                    keyValue: "app_backup_wallet_data",
                    label: S.of(context).app_backup_wallet_data,
                    subtitle: S.of(context).app_backup_wallet_data_description,
                    iconPath: "assets/new-ui/app_backup/intro_wallet.svg",
                    showArrow: false,
                  ),
                  ListItemRegularRow(
                    keyValue: "app_backup_settings",
                    label: S.of(context).settings,
                    subtitle: S.of(context).app_backup_settings_description,
                    iconPath: "assets/new-ui/app_backup/intro_settings.svg",
                    showArrow: false,
                  ),
                  ListItemRegularRow(
                    keyValue: "app_backup_contacts",
                    label: S.of(context).contacts,
                    subtitle: S.of(context).app_backup_contacts_description,
                    iconPath: "assets/new-ui/app_backup/intro_contacts.svg",
                    showArrow: false,
                  ),
                  ListItemRegularRow(
                    keyValue: "app_backup_nodes",
                    label: S.of(context).nodes,
                    iconPath: "assets/new-ui/app_backup/intro_nodes.svg",
                    showArrow: false,
                  ),
                ],
              },
            ),
          ],
        ),
        footer: aboutOnly
            ? NewPrimaryButton(
                onPressed: Navigator.of(context).pop,
                text: S.of(context).close,
                color: Theme.of(context).colorScheme.surfaceContainer,
                textColor: Theme.of(context).colorScheme.primary,
              )
            : StackedButtons(
                primaryText: S.of(context).app_backup_create,
                onPrimary: () => AppBackupPage.push(context, const BackupContentsPage()),
                secondaryText: S.of(context).app_backup_exit,
                onSecondary: () => AppBackupPage.exit(context),
              ),
      );
}
