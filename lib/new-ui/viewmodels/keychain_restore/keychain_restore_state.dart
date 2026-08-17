part of "keychain_restore_bloc.dart";

@immutable
sealed class KeychainRestoreState {
  const KeychainRestoreState();
}

final class KeychainRestoreNotLoaded extends KeychainRestoreState {
  const KeychainRestoreNotLoaded();
}

final class KeychainRestoreNoWallets extends KeychainRestoreState {
  const KeychainRestoreNoWallets();
}

final class KeychainRestoreUnavailable extends KeychainRestoreState {
  const KeychainRestoreUnavailable();
}

abstract class KeychainRestoreStateWithWallets extends KeychainRestoreState {
  const KeychainRestoreStateWithWallets({
    required this.walletsUnsupported,
    required this.walletsAvailable,
    required this.walletsSelected,
  });

  final List<KeychainDataV1> walletsAvailable;
  final List<UnsupportedKeychainData> walletsUnsupported;
  final Set<KeychainDataV1> walletsSelected;
}

final class KeychainRestoreSelection extends KeychainRestoreStateWithWallets {
  const KeychainRestoreSelection({required super.walletsAvailable, required super.walletsUnsupported, required super.walletsSelected});

  KeychainRestoreSelection copyWith({
    List<KeychainDataV1>? walletsAvailable,
    List<UnsupportedKeychainData>? walletsUnsupported,
    Set<KeychainDataV1>? walletsSelected,
  }) =>
      KeychainRestoreSelection(
        walletsUnsupported: walletsUnsupported ?? this.walletsUnsupported,
        walletsAvailable: walletsAvailable ?? this.walletsAvailable,
        walletsSelected: walletsSelected ?? this.walletsSelected,
      );
}

abstract class KeychainRestoreStateWithWalletProgress extends KeychainRestoreStateWithWallets {
  const KeychainRestoreStateWithWalletProgress({
    required this.walletsRestored,
    required this.walletsFailed,
    required super.walletsUnsupported,
    required super.walletsAvailable,
    required super.walletsSelected,
  });

  final Set<KeychainDataV1> walletsRestored;
  final Set<KeychainDataV1> walletsFailed;
}

final class KeychainRestoring extends KeychainRestoreStateWithWalletProgress {
  const KeychainRestoring({
    required super.walletsRestored,
    required super.walletsFailed,
    required super.walletsUnsupported,
    required super.walletsAvailable,
    required super.walletsSelected,
  });

  KeychainRestoring copyWith({
    List<KeychainDataV1>? walletsAvailable,
    List<UnsupportedKeychainData>? walletsUnsupported,
    Set<KeychainDataV1>? walletsSelected,
    Set<KeychainDataV1>? walletsFailed,
    Set<KeychainDataV1>? walletsRestored,
  }) =>
      KeychainRestoring(
        walletsRestored: walletsRestored ?? this.walletsRestored,
        walletsUnsupported: walletsUnsupported ?? this.walletsUnsupported,
        walletsFailed: walletsFailed ?? this.walletsFailed,
        walletsAvailable: walletsAvailable ?? this.walletsAvailable,
        walletsSelected: walletsSelected ?? this.walletsSelected,
      );
}

final class KeychainRestoreComplete extends KeychainRestoreStateWithWalletProgress {
  const KeychainRestoreComplete({
    required this.walletInfos,
    required super.walletsRestored,
    required super.walletsUnsupported,
    required super.walletsFailed,
    required super.walletsAvailable,
    required super.walletsSelected,
  });

  final List<WalletInfo> walletInfos;
}
