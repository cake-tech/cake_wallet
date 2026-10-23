import "dart:io";

import "package:bloc/bloc.dart";
import "package:cake_wallet/core/backup/app_backup_restorer.dart";
import "package:cake_wallet/core/backup/app_backup_storage.dart";
import "package:cake_wallet/core/backup_service_v3.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:meta/meta.dart";

part "app_backup_restore_event.dart";

part "app_backup_restore_state.dart";

class AppBackupRestoreBloc extends Bloc<AppBackupRestoreEvent, AppBackupRestoreState> {
  AppBackupRestoreBloc(this._restorer, this._storageService, this._file)
      : super(const AppBackupRestoreState()) {
    on<RestorePasswordChanged>(
      (event, emit) => emit(state.copyWith(password: event.password, showWrongPassword: false)),
    );
    on<RestoreSubmitted>((event, emit) => _restore(emit, checkBackupApp: true));
    on<AppMismatchConfirmed>((event, emit) => _restore(emit, checkBackupApp: false));
    on<AppMismatchDismissed>(
      (event, emit) =>
          emit(state.copyWith(status: AppBackupRestoreStatus.idle, appMismatch: null)),
    );
  }

  final AppBackupRestorer _restorer;
  final AppBackupStorageService _storageService;
  final File _file;

  Future<void> _restore(
    Emitter<AppBackupRestoreState> emit, {
    required bool checkBackupApp,
  }) async {
    if (checkBackupApp
        ? !state.canSubmit
        : state.status != AppBackupRestoreStatus.appMismatch) return;

    emit(state.copyWith(status: AppBackupRestoreStatus.restoring, appMismatch: null, error: null));
    try {
      await _restorer.restore(_file, state.password, checkBackupApp: checkBackupApp);
      emit(state.copyWith(status: AppBackupRestoreStatus.restored));
    } on IncompatibleBackupAppException catch (e) {
      emit(state.copyWith(status: AppBackupRestoreStatus.appMismatch, appMismatch: e));
    } on AppBackupWrongPasswordException {
      emit(state.copyWith(status: AppBackupRestoreStatus.idle, showWrongPassword: true));
    } catch (e, stackTrace) {
      printV("App backup restore failed: $e\n$stackTrace");
      emit(state.copyWith(status: AppBackupRestoreStatus.failed, error: e.toString()));
      emit(state.copyWith(status: AppBackupRestoreStatus.idle));
    }
  }

  @override
  Future<void> close() async {
    await _storageService.clearPickedFiles();
    return super.close();
  }
}
