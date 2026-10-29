import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/app_backup/app_backup_page.dart";
import "package:cake_wallet/new-ui/pages/app_backup/app_backup_scaffold.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/material.dart";

class BackupCompletePage extends StatelessWidget {
  const BackupCompletePage({super.key});

  @override
  Widget build(BuildContext context) => AppBackupScaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 24,
            children: [
              const SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  children: [
                    Positioned(
                      left: 19,
                      top: 12.5,
                      child: CakeImageWidget(
                        imageUrl: "assets/new-ui/app_backup/backup_file.svg",
                        width: 61.607,
                        height: 75,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CakeImageWidget(
                        imageUrl: "assets/new-ui/app_backup/complete_check.svg",
                        width: 40,
                        height: 40,
                      ),
                    ),
                  ],
                ),
              ),
              AppBackupMessage(title: S.of(context).app_backup_complete),
            ],
          ),
        ),
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            NewPrimaryButton(
              onPressed: () => AppBackupPage.showManagement(context),
              text: S.of(context).app_backup_management,
              color: Theme.of(context).colorScheme.surfaceContainer,
              textColor: Theme.of(context).colorScheme.primary,
            ),
            NewPrimaryButton(
              onPressed: () => AppBackupPage.exitToHome(context),
              text: S.of(context).app_backup_exit_to_home,
              color: Theme.of(context).colorScheme.primary,
              textColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ],
        ),
      );
}
