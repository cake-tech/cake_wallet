part of "app_backup_restore_bloc.dart";

@immutable
final class AppBackupRestoreState {
  const AppBackupRestoreState({
    this.password = "",
    this.isRestoring = false,
    this.showWrongPassword = false,
  });

  final String password;
  final bool isRestoring;
  final bool showWrongPassword;

  bool get canSubmit => password.isNotEmpty && !showWrongPassword && !isRestoring;

  AppBackupRestoreState copyWith({
    String? password,
    bool? isRestoring,
    bool? showWrongPassword,
  }) =>
      AppBackupRestoreState(
        password: password ?? this.password,
        isRestoring: isRestoring ?? this.isRestoring,
        showWrongPassword: showWrongPassword ?? this.showWrongPassword,
      );
}
