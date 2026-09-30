part of "keychain_management_bloc.dart";

class KeychainManagementItem {
  KeychainManagementItem(
      {required this.name, required this.type, required this.dateSaved, required this.isRestored});

  final String name;
  final WalletType type;
  final DateTime? dateSaved;
  final bool isRestored;

  bool get isBackedUp => dateSaved != null;


  @override
  bool operator ==(Object other) => other is KeychainManagementItem && other.name == name && other.type == type && other.dateSaved ==dateSaved && other.isRestored == isRestored;

  @override
  int get hashCode => name.hashCode ^ type.hashCode ^ dateSaved.hashCode ^ isRestored.hashCode;

}

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
      {required List<WalletInfo> localWallets,
      required List<KeychainDataV1> keychainWallets,
      required this.unsupportedKeychainItems,})
      : _localWallets = localWallets,
        _keychainWallets = keychainWallets;

  final List<WalletInfo> _localWallets;
  final List<KeychainDataV1> _keychainWallets;

  List<KeychainManagementItem> get items {
    final List<KeychainManagementItem> ret = [];

    for (final wallet in _keychainWallets) {
      ret.add(KeychainManagementItem(
          name: wallet.name,
          type: deserializeFromInt(wallet.walletTypeRaw),
          dateSaved: DateTime.fromMillisecondsSinceEpoch(wallet.creationTime),
          isRestored: _localWallets.any((item) => item.name == wallet.name)));
    }

    for (final wallet in _localWallets) {
      if (!_keychainWallets.any((item) => item.name == wallet.name)) {
        ret.add(KeychainManagementItem(
            name: wallet.name, type: wallet.type, dateSaved: null, isRestored: true));
      }
    }
    ret.sort((a, b)=>a.name.compareTo(b.name));
    return ret;
  }

  bool get hasUnrestoredWallets => items.any((item)=>!item.isRestored);

  final List<UnsupportedKeychainData> unsupportedKeychainItems;

  KeychainManagementLoaded copyWith({
    List<WalletInfo>? localWallets,
    List<KeychainDataV1>? keychainWallets,
    List<UnsupportedKeychainData>? unsupportedKeychainItems,
  }) =>
      KeychainManagementLoaded(
        localWallets: localWallets ?? _localWallets,
        keychainWallets: keychainWallets ?? _keychainWallets,
        unsupportedKeychainItems: unsupportedKeychainItems ?? this.unsupportedKeychainItems,
      );
}
