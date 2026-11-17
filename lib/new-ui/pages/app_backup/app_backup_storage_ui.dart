import "dart:io";

import "package:cake_wallet/core/backup/app_backup_storage.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:flutter/widgets.dart";

extension AppBackupStorageUi on AppBackupStorage {
  String get iconPath => switch (this) {
        AppBackupStorage.cloud => Platform.isAndroid
            ? "assets/new-ui/app_backup/google.svg"
            : "assets/new-ui/app_backup/icloud.svg",
        AppBackupStorage.custom => "assets/new-ui/app_backup/folder.svg",
      };

  String title(BuildContext context) => switch (this) {
        AppBackupStorage.cloud =>
          Platform.isAndroid ? S.of(context).app_backup_google : S.of(context).app_backup_icloud,
        AppBackupStorage.custom => S.of(context).app_backup_custom_location,
      };

  String subtitle(BuildContext context) => switch (this) {
        AppBackupStorage.cloud => S.of(context).app_backup_cloud_description,
        AppBackupStorage.custom => S.of(context).app_backup_custom_location_description,
      };

  String shortLabel(BuildContext context) => switch (this) {
        AppBackupStorage.cloud => Platform.isAndroid
            ? S.of(context).app_backup_storage_google
            : S.of(context).app_backup_storage_icloud,
        AppBackupStorage.custom => S.of(context).app_backup_storage_custom,
      };
}
