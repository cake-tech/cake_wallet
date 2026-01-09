import 'dart:io';
import 'package:cake_wallet/core/backup_service_v3.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/entities/default_settings_migration.dart' show generateBackupPassword;
import 'package:cake_wallet/entities/secret_store_key.dart';
import 'package:cake_wallet/view_model/edit_backup_password_view_model.dart';
import 'package:cw_core/root_dir.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:mobx/mobx.dart';
import 'package:intl/intl.dart';
import 'package:cake_wallet/wallet_type_utils.dart';

part 'backup_view_model.g.dart';

class BackupExportFile {
  BackupExportFile(this.file, {required this.name});

  final String name;
  final File file;
}

class BackupViewModel = BackupViewModelBase with _$BackupViewModel;

abstract class BackupViewModelBase with Store {
  BackupViewModelBase(this.secureStorage, this.backupService, this.editBackupPasswordViewModel)
      : isBackupPasswordVisible = false,
        backupPassword = '',
        state = InitialExecutionState() {
    init();

    reaction((_) => editBackupPasswordViewModel.backupPassword, (value) {
      if(value != backupPassword) {
        backupPassword = value;
      }
    });

    reaction((_)=>backupPassword, (value){
      if(value != editBackupPasswordViewModel.backupPassword) {
        editBackupPasswordViewModel.backupPassword = value;
      }
    });
  }

  final SecureStorage secureStorage;
  final BackupServiceV3 backupService;
  final EditBackupPasswordViewModel editBackupPasswordViewModel;

  @observable
  ExecutionState state;

  @observable
  bool isBackupPasswordVisible;

  @observable
  String backupPassword;

  @action
  Future<void> init() async {
    final key = generateStoreKeyFor(key: SecretStoreKey.backupPassword);
    backupPassword = (await secureStorage.read(key: key)) ?? '';
    if (backupPassword.isEmpty) {
      generateBackupPassword(secureStorage);
    }
  }

  @action
  Future<BackupExportFile?> exportBackup() async {
    try {
      state = IsExecutingState();
      final backupFile = await backupService.exportBackupFile(backupPassword);
      state = ExecutedSuccessfullyState();
      final now = DateTime.now();
      final formatter = DateFormat('yyyy-MM-dd_Hm');
      final snakeAppName = approximatedAppName.replaceAll(' ', '_').toLowerCase();
      final fileName = '${snakeAppName}_backup_${formatter.format(now)}.zip';

      return BackupExportFile(backupFile, name: fileName);
    } catch (e) {
      printV(e.toString());
      state = FailureState(e.toString());
      return null;
    }
  }

  Future<String> saveBackupFileLocally(BackupExportFile backup) async {
    final appDir = await getAppDir();
    final path = '${appDir.path}/${backup.name}';
    if (File(path).existsSync()) {
      File(path).deleteSync();
    }
    await backup.file.copy(path);
    return path;
  }

  Future<void> removeBackupFileLocally(BackupExportFile backup) async {
    final appDir = await getAppDir();
    final path = '${appDir.path}/${backup.name}';
    if (File(path).existsSync()) {
      File(path).deleteSync();
    }
  }

  @action
  void showMasterPassword() => isBackupPasswordVisible = true;

  @action
  Future<void> saveToDownload(String name, File file) async {
    if (!Platform.isAndroid) {
      return;
    }
    const downloadDirPath = '/storage/emulated/0/Download'; // For Android
    final filePath = '$downloadDirPath/${name}';
    final downloadFile = File(filePath);
    if (downloadFile.existsSync()) {
      downloadFile.deleteSync();
    }
    await file.copy(filePath);
  }
}
