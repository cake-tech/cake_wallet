

sealed class KeychainCreationPresentationEvent {
  const KeychainCreationPresentationEvent();
}

final class KeychainSaveFailed extends KeychainCreationPresentationEvent {
  const KeychainSaveFailed({required this.error});

  final Object error;
}