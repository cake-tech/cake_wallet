import 'dart:io';

import 'package:cake_wallet/core/backup.dart';
import 'package:mobx/mobx.dart';

part 'restore_from_backup_view_model.g.dart';

class RestoreFromBackupViewModel = RestoreFromBackupViewModelBase with _$RestoreFromBackupViewModel;

abstract class RestoreFromBackupViewModelBase with Store {
  RestoreFromBackupViewModelBase(this.backupService);

  @observable
  String filePath;

  final BackupService backupService;

  Future<void> import(String password) async {
    if (filePath?.isEmpty ?? true) {
      // FIXME: throw exception;
      return;
    }

    final file = File(filePath);
    final data = await file.readAsBytes();

    await backupService.importBackup(data, password, nonce: null);
  }
}