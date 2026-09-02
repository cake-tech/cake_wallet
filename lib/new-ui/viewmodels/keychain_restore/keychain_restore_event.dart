part of "keychain_restore_bloc.dart";

@immutable
sealed class KeychainRestoreEvent {
  const KeychainRestoreEvent();
}

final class Init extends KeychainRestoreEvent {
  const Init();
}

final class WalletToggled extends KeychainRestoreEvent {
  const WalletToggled(this.index);

  final int index;
}

final class RestoreInitiated extends KeychainRestoreEvent {
  const RestoreInitiated();
}

final class WalletOpenSelected extends KeychainRestoreEvent {
  const WalletOpenSelected(this.index);

  final int index;
}