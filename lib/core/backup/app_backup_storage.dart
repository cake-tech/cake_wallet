import "dart:io";

import "package:cake_wallet/wallet_type_utils.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:file_picker/file_picker.dart";
import "package:flutter/services.dart";
import "package:intl/intl.dart";
import "package:path/path.dart" as p;
import "package:path_provider/path_provider.dart";

enum AppBackupStorage {
  cloud,
  custom;

  static AppBackupStorage? fromRaw(String? raw) =>
      values.where((storage) => storage.name == raw).firstOrNull;
}

class AppBackupStorageService {
  static const _channel = MethodChannel("com.cake_wallet/app_backup");

  Future<String?> iCloudDirectory() async {
    if (!Platform.isIOS) return null;
    try {
      return await _channel.invokeMethod<String>("icloud_documents_path");
    } catch (e) {
      printV("iCloud documents lookup failed: $e");
      return null;
    }
  }

  Future<bool> isDriveInstalled() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>("is_drive_installed") ?? false;
    } catch (e) {
      printV("Drive lookup failed: $e");
      return false;
    }
  }

  Future<List<AppBackupStorage>> availableStorages() async => [
        if (await iCloudDirectory() != null || await isDriveInstalled()) AppBackupStorage.cloud,
        AppBackupStorage.custom,
      ];

  bool keepsFileAfterSave(AppBackupStorage storage) =>
      storage == AppBackupStorage.cloud && Platform.isAndroid;

  Future<Directory> outputDirectory() async {
    final dir = Directory(p.join((await getTemporaryDirectory()).path, "app_backups"));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<String> newBackupPath() async {
    final appName = approximatedAppName.replaceAll(" ", "_").toLowerCase();
    final timestamp = DateFormat("yyyy-MM-dd_HHmm").format(DateTime.now());
    return p.join((await outputDirectory()).path, "${appName}_backup_$timestamp.zip");
  }

  Future<void> clearOutputs() async {
    final dir = Directory(p.join((await getTemporaryDirectory()).path, "app_backups"));
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }

  Future<bool> save(File backup, AppBackupStorage storage) async => switch (storage) {
        AppBackupStorage.cloud =>
          Platform.isAndroid ? await _shareToDrive(backup) : await _saveToICloud(backup),
        AppBackupStorage.custom => await _saveToCustomLocation(backup),
      };

  Future<bool> _saveToICloud(File backup) async =>
      await FilePicker.platform
          .exportFile(sourcePath: backup.path, initialDirectory: await iCloudDirectory()) !=
      null;

  Future<bool> _shareToDrive(File backup) async =>
      await _channel.invokeMethod<bool>("share_to_drive", {"path": backup.path}) ?? false;

  Future<bool> _saveToCustomLocation(File backup) async {
    if (Platform.isIOS || Platform.isAndroid) {
      return await FilePicker.platform.exportFile(sourcePath: backup.path) != null;
    }
    final output = await FilePicker.platform
        .saveFile(fileName: p.basename(backup.path), lockParentWindow: true);
    if (output == null) return false;
    await backup.copy(output);
    return true;
  }

  Future<File?> pickBackupFile() async {
    final path = (await FilePicker.platform.pickFiles(lockParentWindow: true))?.files.firstOrNull?.path;
    return path == null ? null : File(path);
  }

  Future<void> clearPickedFiles() async {
    if (Platform.isIOS || Platform.isAndroid) {
      await FilePicker.platform.clearTemporaryFiles();
    }
  }
}
