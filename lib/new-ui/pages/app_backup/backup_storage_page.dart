import "dart:io";

import "package:cake_wallet/core/backup/app_backup_storage.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/app_backup/app_backup_page.dart";
import "package:cake_wallet/new-ui/pages/app_backup/app_backup_scaffold.dart";
import "package:cake_wallet/new-ui/pages/app_backup/app_backup_storage_ui.dart";
import "package:cake_wallet/new-ui/pages/app_backup/backup_storage_info_page.dart";
import "package:cake_wallet/new-ui/viewmodels/app_backup/app_backup_bloc.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class BackupStoragePage extends StatelessWidget {
  const BackupStoragePage({super.key});

  void _select(BuildContext context, AppBackupStorage storage) => Platform.isIOS
      ? AppBackupPage.push(context, BackupStorageInfoPage(storage: storage))
      : context.read<AppBackupBloc>().add(SaveRequested(storage));

  @override
  Widget build(BuildContext context) => BlocBuilder<AppBackupBloc, AppBackupState>(
        buildWhen: (previous, current) => previous.storages != current.storages,
        builder: (context, state) => AppBackupScaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                spacing: 24,
                children: [
                  const BackupBoxIllustration(),
                  Text(
                    S.of(context).app_backup_storage_title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(letterSpacing: -0.08),
                  ),
                  NewListSections(
                    sections: {
                      "": [
                        for (final storage in state.storages)
                          ListItemRegularRow(
                            keyValue: "app_backup_storage_${storage.name}",
                            label: storage.title(context),
                            subtitle: storage.subtitle(context),
                            iconPath: storage.iconPath,
                            onTap: () => _select(context, storage),
                          ),
                      ],
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class BackupBoxIllustration extends StatelessWidget {
  const BackupBoxIllustration({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 100,
        height: 100,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            const CakeImageWidget(
              imageUrl: "assets/new-ui/app_backup/backup_file.svg",
              width: 61.607,
              height: 75,
            ),
            Positioned(
              top: 50,
              child: Container(
                width: 95,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF785636), Color(0xFFA67344)],
                    stops: [0, 0.75],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 50,
              child: Container(
                width: 100,
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFB8875A), Color(0xFF9C6B3F)],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
