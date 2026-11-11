

sealed class KeychainRestorePresentationEvent {
  const KeychainRestorePresentationEvent();
}

final class WalletOpened extends KeychainRestorePresentationEvent {
  const WalletOpened();
}