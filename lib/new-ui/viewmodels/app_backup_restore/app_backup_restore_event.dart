part of "app_backup_restore_bloc.dart";

@immutable
sealed class AppBackupRestoreEvent {}

final class RestorePasswordChanged extends AppBackupRestoreEvent {
  RestorePasswordChanged(this.password);

  final String password;
}

final class RestoreSubmitted extends AppBackupRestoreEvent {}

final class AppMismatchConfirmed extends AppBackupRestoreEvent {}
