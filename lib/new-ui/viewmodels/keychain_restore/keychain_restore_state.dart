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
    required this.walletsAvailable,
    required this.walletsSelected,
  });

  final List<KeychainData> walletsAvailable;
  final Set<KeychainData> walletsSelected;
}

final class KeychainRestoreSelection extends KeychainRestoreStateWithWallets {
  const KeychainRestoreSelection({required super.walletsAvailable, required super.walletsSelected});

  KeychainRestoreSelection copyWith({
    List<KeychainData>? walletsAvailable,
    Set<KeychainData>? walletsSelected,
  }) =>
      KeychainRestoreSelection(
        walletsAvailable: walletsAvailable ?? this.walletsAvailable,
        walletsSelected: walletsSelected ?? this.walletsSelected,
      );
}

abstract class KeychainRestoreStateWithWalletProgress extends KeychainRestoreStateWithWallets {
  const KeychainRestoreStateWithWalletProgress({
    required this.walletsRestored,
    required this.walletsFailed,
    required super.walletsAvailable,
    required super.walletsSelected,
  });

  final Set<KeychainData> walletsRestored;
  final Set<KeychainData> walletsFailed;
}

final class KeychainRestoring extends KeychainRestoreStateWithWalletProgress {
  const KeychainRestoring({
    required super.walletsRestored,
    required super.walletsFailed,
    required super.walletsAvailable,
    required super.walletsSelected,
  });

  KeychainRestoring copyWith({
    List<KeychainData>? walletsAvailable,
    Set<KeychainData>? walletsSelected,
    Set<KeychainData>? walletsFailed,
    Set<KeychainData>? walletsRestored,
  }) =>
      KeychainRestoring(
        walletsRestored: walletsRestored ?? this.walletsRestored,
        walletsFailed: walletsFailed ?? this.walletsFailed,
        walletsAvailable: walletsAvailable ?? this.walletsAvailable,
        walletsSelected: walletsSelected ?? this.walletsSelected,
      );
}

final class KeychainRestoreComplete extends KeychainRestoreStateWithWalletProgress {
  const KeychainRestoreComplete({
    required this.walletInfos,
    required super.walletsRestored,
    required super.walletsFailed,
    required super.walletsAvailable,
    required super.walletsSelected,
  });

  final List<WalletInfo> walletInfos;
}
