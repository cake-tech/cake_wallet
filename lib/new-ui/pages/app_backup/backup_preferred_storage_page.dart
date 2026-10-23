import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/app_backup/app_backup_scaffold.dart";
import "package:cake_wallet/new-ui/pages/app_backup/app_backup_storage_ui.dart";
import "package:cake_wallet/new-ui/viewmodels/app_backup/app_backup_bloc.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class BackupPreferredStoragePage extends StatelessWidget {
  const BackupPreferredStoragePage({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<AppBackupBloc, AppBackupState>(
        builder: (context, state) => AppBackupScaffold(
          title: S.of(context).app_backup_preferred_storage,
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            children: [
              NewListSections(
                sections: {
                  "": [
                    for (final storage in state.storages)
                      ListItemRegularRow(
                        keyValue: "app_backup_preferred_${storage.name}",
                        label: storage.title(context),
                        subtitle: storage.subtitle(context),
                        iconPath: storage.iconPath,
                        showArrow: false,
                        trailingWidget: storage == state.preferredStorage
                            ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                            : null,
                        onTap: () =>
                            context.read<AppBackupBloc>().add(PreferredStorageChanged(storage)),
                      ),
                  ],
                },
              ),
            ],
          ),
        ),
      );
}
