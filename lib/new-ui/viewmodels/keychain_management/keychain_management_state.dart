part of "keychain_management_bloc.dart";

@immutable
sealed class KeychainManagementState {
  const KeychainManagementState();
}

final class KeychainManagementNotLoaded extends KeychainManagementState {
  const KeychainManagementNotLoaded();
}

final class KeychainManagementUnavailable extends KeychainManagementState {
  const KeychainManagementUnavailable();
}

final class KeychainManagementLoaded extends KeychainManagementState {
  const KeychainManagementLoaded(
      {required this.localWallets,
        required this.keychainWallets,
        required this.unsupportedKeychainItems});

  final List<WalletInfo> localWallets;
  final List<KeychainDataV1> keychainWallets;
  final List<UnsupportedKeychainData> unsupportedKeychainItems;

  // localWallets that don't have the same names as an existing keychain entry
  // in other words, ones that can be saved to the keychain
  // note that you cannot create a wallet that has the same name as a keychain entry
  List<WalletInfo> get savableWallets {
    final unsavableNames = {
      ...keychainWallets.map((item) => item.name),
      ...unsupportedKeychainItems.map((item) => item.name),
    };

    return localWallets
        .where((item) => !unsavableNames.contains(item.name))
        .toList();
  }

  KeychainManagementLoaded copyWith({
    List<WalletInfo>? localWallets,
    List<KeychainDataV1>? keychainWallets,
    List<UnsupportedKeychainData>? unsupportedKeychainItems,
  }) => KeychainManagementLoaded(
      localWallets: localWallets ?? this.localWallets,
      keychainWallets: keychainWallets ?? this.keychainWallets,
      unsupportedKeychainItems:
      unsupportedKeychainItems ?? this.unsupportedKeychainItems,
    );

}
