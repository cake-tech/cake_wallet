part of "app_backup_bloc.dart";

@immutable
sealed class AppBackupEvent {}

final class _Init extends AppBackupEvent {}

final class AppBackupRefreshed extends AppBackupEvent {}

final class _WalletSizeCalculated extends AppBackupEvent {
  _WalletSizeCalculated(this.walletId, this.sizeInBytes);

  final String walletId;
  final int sizeInBytes;
}

final class _SharedSizeCalculated extends AppBackupEvent {
  _SharedSizeCalculated(this.sizeInBytes);

  final int sizeInBytes;
}

final class WalletToggled extends AppBackupEvent {
  WalletToggled(this.walletId);

  final String walletId;
}

final class AllWalletsSelected extends AppBackupEvent {}

final class AllWalletsDeselected extends AppBackupEvent {}

final class VerificationChanged extends AppBackupEvent {
  VerificationChanged(this.input);

  final String input;
}

final class VerificationSubmitted extends AppBackupEvent {}

final class PasswordRegenerationRequested extends AppBackupEvent {}

final class SaveRequested extends AppBackupEvent {
  SaveRequested(this.storage);

  final AppBackupStorage storage;
}

final class PreferredStorageChanged extends AppBackupEvent {
  PreferredStorageChanged(this.storage);

  final AppBackupStorage storage;
}

final class BackupNowRequested extends AppBackupEvent {}
