import 'dart:io';

import 'package:cake_wallet/core/backup_service.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/entities/secret_store_key.dart';
import 'package:cake_wallet/store/secret_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobx/mobx.dart';

part 'backup_view_model.g.dart';

class BackupExportFile {
  BackupExportFile(this.content, {@required this.name});

  final String name;
  final List<int> content;
}

class BackupViewModel = BackupViewModelBase with _$BackupViewModel;

abstract class BackupViewModelBase with Store {
  BackupViewModelBase(this.secureStorage, this.secretStore, this.backupService)
      : isBackupPasswordVisible = false {
    state = InitialExecutionState();
    final key = generateStoreKeyFor(key: SecretStoreKey.backupPassword);
    secretStore.values.observe((change) {
      if (change.key == key) {
        backupPassword = secretStore.read(key);
      }
    }, fireImmediately: true);
  }

  final FlutterSecureStorage secureStorage;
  final SecretStore secretStore;
  final BackupService backupService;

  @observable
  ExecutionState state;

  @observable
  bool isBackupPasswordVisible;

  @observable
  String backupPassword;

  @action
  Future<void> init() async {
    final key = generateStoreKeyFor(key: SecretStoreKey.backupPassword);
    backupPassword = await secureStorage.read(key: key);
  }

  @action
  Future<BackupExportFile> exportBackup() async {
    try {
      state = IsExecutingState();
      final backupContent = await backupService.exportBackup(backupPassword);
      state = ExecutedSuccessfullyState();

      return BackupExportFile(backupContent.toList(),
          name: 'backup_${DateTime.now().toString()}.zip');
    } catch (e) {
      print(e.toString());
      state = FailureState(e.toString());
      return null;
    }
  }

  @action
  void showMasterPassword() => isBackupPasswordVisible = true;

  @action
  Future<void> saveToDownload(String name, List<int> content) async {
    const downloadDirPath = '/storage/emulated/0/Download'; // For Android
    final filePath = '$downloadDirPath/${name}';
    final file = File(filePath);
    await file.writeAsBytes(content);
  }
}
