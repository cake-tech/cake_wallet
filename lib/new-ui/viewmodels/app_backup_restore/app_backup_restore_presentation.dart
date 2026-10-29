part of "app_backup_restore_bloc.dart";

@immutable
sealed class AppBackupRestorePresentation {}

final class AppMismatchDetected extends AppBackupRestorePresentation {
  AppMismatchDetected(this.mismatch);

  final IncompatibleBackupAppException mismatch;
}

final class RestoreFailed extends AppBackupRestorePresentation {
  RestoreFailed(this.error);

  final String error;
}
