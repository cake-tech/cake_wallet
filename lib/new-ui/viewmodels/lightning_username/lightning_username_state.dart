part of 'lightning_username_bloc.dart';

@immutable
sealed class LightningUsernameState {
  final String username;

  LightningUsernameState(this.username);
}

final class LightningUsernameInitial extends LightningUsernameState {
  LightningUsernameInitial(super.username);
}

final class LightningUsernameChecking extends LightningUsernameState {
  LightningUsernameChecking(super.username);
}

final class LightningUsernameError extends LightningUsernameState {
  final UsernameError error;

  LightningUsernameError(super.username, this.error);
}

final class LightningUsernameReady extends LightningUsernameState {
  LightningUsernameReady(super.username);
}

final class LightningUsernameSaving extends LightningUsernameState {
  LightningUsernameSaving(super.username);
}

final class LightningUsernameSaved extends LightningUsernameState {
  LightningUsernameSaved(super.username);
}
