part of "keychain_creation_bloc.dart";

@immutable
sealed class KeychainCreationState {
  const KeychainCreationState();
}

final class KeychainCreationNotLoaded extends KeychainCreationState {
  const KeychainCreationNotLoaded();
}

abstract class KeychainCreationStateWithUseKeychain extends KeychainCreationState {
  const KeychainCreationStateWithUseKeychain ({required this.useKeychain});
  final bool useKeychain;
}

final class KeychainStateInput extends KeychainCreationStateWithUseKeychain {
  const KeychainStateInput({required super.useKeychain});

}


final class KeychainStateSaving extends KeychainCreationStateWithUseKeychain{
  const KeychainStateSaving({required super.useKeychain});
}

final class KeychainStateComplete extends KeychainCreationState {
  const KeychainStateComplete({required this.redirectToSeed});

  final bool redirectToSeed;
}
