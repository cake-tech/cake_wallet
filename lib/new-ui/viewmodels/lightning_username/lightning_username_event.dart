part of 'lightning_username_bloc.dart';

@immutable
sealed class LightningUsernameEvent {}

final class _Init extends LightningUsernameEvent {}

final class ChangeUsername extends LightningUsernameEvent {
  final String newUsername;

  ChangeUsername(this.newUsername);
}

final class RequestUsernameSave extends LightningUsernameEvent {}