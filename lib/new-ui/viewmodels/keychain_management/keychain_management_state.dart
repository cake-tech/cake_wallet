part of "keychain_management_bloc.dart";

@immutable
sealed class KeychainManagementState {}

final class KeychainManagementNotLoaded extends KeychainManagementState {}

final class KeychainManagementUnavailable extends KeychainManagementState {}

final class KeychainManagementLoaded extends KeychainManagementState {
  KeychainManagementLoaded(
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
}
