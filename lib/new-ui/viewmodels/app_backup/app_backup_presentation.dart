part of "app_backup_bloc.dart";

@immutable
sealed class AppBackupPresentation {}

final class BackupCreated extends AppBackupPresentation {}

final class BackupSaved extends AppBackupPresentation {
  BackupSaved({required this.isFirstBackup});

  final bool isFirstBackup;
}

final class BackupFailed extends AppBackupPresentation {
  BackupFailed(this.error);

  final String error;
}

final class PasswordRegenerated extends AppBackupPresentation {}

final class PasswordSaved extends AppBackupPresentation {}
