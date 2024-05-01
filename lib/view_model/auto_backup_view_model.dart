import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/automatic_backup_mode.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/alert_scheduler.dart';
import 'package:cake_wallet/view_model/backup_view_model.dart';
import 'package:mobx/mobx.dart';

class AutoBackupViewModel {
  AutoBackupViewModel({
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
          autoBackupMode == AutomaticBackupMode.weekly && duration.inDays >= 7) {
        final backup = await backupViewModel.exportBackup();
        await backupViewModel.saveBackupFileLocally(backup!);
      }
      state = ExecutedSuccessfullyState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }
}
