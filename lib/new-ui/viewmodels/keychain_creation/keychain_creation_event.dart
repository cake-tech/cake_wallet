part of "keychain_creation_bloc.dart";

@immutable
sealed class KeychainCreationEvent {
  const KeychainCreationEvent();
}

final class _Init extends KeychainCreationEvent {
  const _Init();
}


final class KeychainModeChanged extends KeychainCreationEvent {
  const KeychainModeChanged({required this.useKeychain});

  final bool useKeychain;
}

final class KeychainModeAccepted extends KeychainCreationEvent {
  const KeychainModeAccepted();
}