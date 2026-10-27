import "dart:io";

import "package:bloc/bloc.dart";
import "package:bloc_presentation/bloc_presentation.dart";
import "package:cake_wallet/core/backup/app_backup_restorer.dart";
import "package:cake_wallet/core/backup/app_backup_storage.dart";
import "package:cake_wallet/core/backup_service_v3.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:meta/meta.dart";

part "app_backup_restore_event.dart";

part "app_backup_restore_presentation.dart";

part "app_backup_restore_state.dart";

class AppBackupRestoreBloc extends Bloc<AppBackupRestoreEvent, AppBackupRestoreState>
    with BlocPresentationMixin<AppBackupRestoreState, AppBackupRestorePresentation> {
  AppBackupRestoreBloc(this._restorer, this._storageService, this._file)
      : super(const AppBackupRestoreState()) {
    on<RestorePasswordChanged>(
      (event, emit) => emit(state.copyWith(password: event.password, showWrongPassword: false)),
    );
    on<RestoreSubmitted>((event, emit) => _restore(emit, checkBackupApp: true));
    on<AppMismatchConfirmed>((event, emit) => _restore(emit, checkBackupApp: false));
  }

  final AppBackupRestorer _restorer;
  final AppBackupStorageService _storageService;
  final File _file;

  Future<void> _restore(
    Emitter<AppBackupRestoreState> emit, {
    required bool checkBackupApp,
  }) async {
    if (!state.canSubmit) return;

    emit(state.copyWith(isRestoring: true));
    try {
      await _restorer.restore(_file, state.password, checkBackupApp: checkBackupApp);
    } on IncompatibleBackupAppException catch (e) {
      emit(state.copyWith(isRestoring: false));
      emitPresentation(AppMismatchDetected(e));
    } on AppBackupWrongPasswordException {
      emit(state.copyWith(isRestoring: false, showWrongPassword: true));
    } catch (e, stackTrace) {
      printV("App backup restore failed: $e\n$stackTrace");
      emit(state.copyWith(isRestoring: false));
      emitPresentation(RestoreFailed(e.toString()));
    }
  }

  @override
  Future<void> close() async {
    await _storageService.clearPickedFiles();
    return super.close();
  }
}
