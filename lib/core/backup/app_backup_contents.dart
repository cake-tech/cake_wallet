import "dart:io";

import "package:cake_wallet/core/backup/app_backup_preferences.dart";
import "package:cake_wallet/core/backup_service_v3.dart";
import "package:cw_core/root_dir.dart";
import "package:cw_core/wallet_info.dart";
import "package:path/path.dart" as p;

class AppBackupContents {
  AppBackupContents(this._preferences);

  final AppBackupPreferences _preferences;

  Future<Set<String>> excludedWalletIds() async {
    final walletIds = (await WalletInfo.getAll()).map((info) => info.id).toSet();
    return _preferences.excludedWalletIds.intersection(walletIds);
  }

  Future<int> walletSize(WalletInfo info) async => _directorySize(
        Directory(p.join((await getAppDir()).path, BackupServiceV3.walletDirArchivePath(info))),
      );

  Future<int> sharedSize() async {
    final appDir = await getAppDir();
    final database = File(p.join(appDir.path, "cake.db"));
    var size = database.existsSync() ? await database.length() : 0;
    await for (final entity in appDir.list(followLinks: false)) {
      if (entity is File && entity.path.endsWith(".hive")) {
        size += await entity.length();
      }
    }
    return size;
  }

  Future<int> _directorySize(Directory dir) async {
    if (!dir.existsSync()) return 0;
    var size = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        size += await entity.length();
      }
    }
    return size;
  }
}

String formatBackupSize(int bytes) {
  if (bytes < 1024 * 1024) {
    return "${(bytes / 1024).ceil()} KB";
  }
  final megabytes = (bytes / (1024 * 1024)).toStringAsFixed(2);
  return '${megabytes.replaceFirst(RegExp(r'\.?0+$'), '')} MB';
}
