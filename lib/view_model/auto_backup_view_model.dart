import 'dart:io';

import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/automatic_backup_mode.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/alert_scheduler.dart';
import 'package:cake_wallet/view_model/backup_view_model.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:path_provider/path_provider.dart';

part 'auto_backup_view_model.g.dart';

class AutoBackupViewModel = AutoBackupViewModelBase with _$AutoBackupViewModel;

Future<void> saveBackupFileLocally(Map<String, dynamic> args) async {
  final backupContent = args['backupContent'] as List<int>;
  final path = args['path'] as String;

  final backupFile = File(path);
  await backupFile.writeAsBytes(backupContent);
}

abstract class AutoBackupViewModelBase with Store {
  AutoBackupViewModelBase({
    required this.backupViewModel,
    required this.settingsStore,
  }) : state = InitialExecutionState() {}

  final BackupViewModel backupViewModel;
  final SettingsStore settingsStore;

  @observable
  ExecutionState state;

  @action
  Future<void> runBackup() async {
    try {
      state = IsExecutingState();

      final alertScheduler = await getIt.get<AlertScheduler>();
      final autoBackupMode = settingsStore.autoBackupMode;
      Duration duration = await alertScheduler
          .accessTimeDifference(PreferencesKey.showAutomaticBackupWarningAccessTime);

      if (autoBackupMode == AutomaticBackupMode.daily && duration.inDays >= 1 ||
          autoBackupMode == AutomaticBackupMode.weekly && duration.inDays >= 7 ||
          autoBackupMode == AutomaticBackupMode.minutely && duration.inMinutes >= 1) {
        String backupDirPath = settingsStore.autoBackupDir;

        if (backupDirPath.isEmpty) {
          if (Platform.isAndroid) {
            backupDirPath = "/storage/emulated/0/Documents/Cake Wallet/backups/";
          } else {
            String path = (await getDownloadsDirectory())!.path;
            backupDirPath = "$path/Cake Wallet/backups/";
          }
        }

        final backupDir = Directory(backupDirPath);
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }

        final backup = await backupViewModel.exportBackup();
        final backupFilePath = "$backupDirPath/${backup!.name}";

        await compute(saveBackupFileLocally, {
          'backupContent': backup.content,
          'path': backupFilePath,
        });
      }

      await alertScheduler.updateAccessTime(PreferencesKey.showAutomaticBackupWarningAccessTime);

      state = ExecutedSuccessfullyState();
    } catch (e) {
      print(e);
      state = FailureState(e.toString());
    }
  }
}
