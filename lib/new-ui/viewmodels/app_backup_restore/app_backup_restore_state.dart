part of "app_backup_restore_bloc.dart";

enum AppBackupRestoreStatus { idle, restoring, appMismatch, restored, failed }

const _unchanged = Object();

@immutable
final class AppBackupRestoreState {
  const AppBackupRestoreState({
    this.status = AppBackupRestoreStatus.idle,
    this.password = "",
    this.showWrongPassword = false,
    this.appMismatch,
    this.error,
  });

  final AppBackupRestoreStatus status;
  final String password;
  final bool showWrongPassword;
  final IncompatibleBackupAppException? appMismatch;
  final String? error;

  bool get canSubmit =>
      password.isNotEmpty && !showWrongPassword && status == AppBackupRestoreStatus.idle;

  AppBackupRestoreState copyWith({
    AppBackupRestoreStatus? status,
    String? password,
    bool? showWrongPassword,
    Object? appMismatch = _unchanged,
    Object? error = _unchanged,
  }) =>
      AppBackupRestoreState(
        status: status ?? this.status,
        password: password ?? this.password,
        showWrongPassword: showWrongPassword ?? this.showWrongPassword,
        appMismatch: appMismatch == _unchanged
            ? this.appMismatch
            : appMismatch as IncompatibleBackupAppException?,
        error: error == _unchanged ? this.error : error as String?,
      );
}
