part of 'lightning_username_bloc.dart';

@immutable
sealed class LightningUsernameEvent {}

final class _Init extends LightningUsernameEvent {}

final class UsernameChanged extends LightningUsernameEvent {
  final String newUsername;

  UsernameChanged(this.newUsername);
}

final class UsernameSaveRequested extends LightningUsernameEvent {}

final class UsernameSaveError extends LightningUsernameEvent {
  final String error;

  UsernameSaveError(this.error);
}
